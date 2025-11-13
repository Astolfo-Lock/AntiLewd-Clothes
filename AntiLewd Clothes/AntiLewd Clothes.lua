-- BodyCleanerPlugin/Main (RunContext = Plugin)
-- Autor: tú + tu cariñito 💖
-- Plugin que borra instancias cuyo nombre CONTENGA palabras clave (p.ej. "body", "bodysuit")
-- y además instala un runtime para que también se limpie en el juego publicado.

----------------------------------------------------------------
-- CONFIG (ajústala a tu gusto)
----------------------------------------------------------------
local KEYWORDS = { "body", "bodysuit" }     -- palabras a buscar dentro del nombre (insensible a mayúsculas)
local BLACKLIST_CONTAINS = { "bodycolors" } -- evita falsos positivos, añade lo que necesites

-- Tipo de objetivo
local ONLY_ACCESSORY = false   -- true = sólo Accessory; false = cualquier clase

-- Ámbito en runtime (juego publicado / Play)
local APPLY_TO_WORKSPACE = true      -- limpia mapa/objetos del Workspace
local APPLY_TO_NPCS = true           -- limpia NPCs (Model + Humanoid que NO sean jugadores)
local APPLY_TO_PLAYERS = true        -- limpia jugadores: accesorios/objetos en Character

-- Qué borrar dentro de personajes/NPCs (si APPLY_TO_NPCS / APPLY_TO_PLAYERS está activo)
local AFFECT_ACCESSORIES = true      -- borra accesorios por nombre
local AFFECT_ANY_PART = false        -- si lo activas, puede borrar MeshPart/Parts con keywords (¡cuidado!)
                                     -- normalmente basta con AFFECT_ACCESSORIES = true
----------------------------------------------------------------

-- Ícono del botón (sube un Decal y pon su id aquí)
local BUTTON_ICON = "rbxassetid://90708775197073"

----------------------------------------------------------------
-- Servicios
----------------------------------------------------------------
local Selection = game:GetService("Selection")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

----------------------------------------------------------------
-- Utilidades comunes
----------------------------------------------------------------
local function toLower(s)
	return (typeof(s) == "string") and string.lower(s) or ""
end

local function hasKeyword(name: string): boolean
	local lower = toLower(name)

	-- blacklist primero
	for _, bad in ipairs(BLACKLIST_CONTAINS) do
		if string.find(lower, toLower(bad), 1, true) then
			return false
		end
	end

	for _, kw in ipairs(KEYWORDS) do
		if string.find(lower, toLower(kw), 1, true) then
			return true
		end
	end
	return false
end

local function isHumanoidModel(model: Instance): boolean
	if not model then return false end
	if model:IsA("Model") and model:FindFirstChildOfClass("Humanoid") then
		return true
	end
	return false
end

local function isPlayerCharacter(inst: Instance): boolean
	local model = inst:FindFirstAncestorOfClass("Model")
	if model and model:FindFirstChildOfClass("Humanoid") then
		return Players:GetPlayerFromCharacter(model) ~= nil
	end
	return false
end

local function isNPCCharacter(inst: Instance): boolean
	local model = inst:FindFirstAncestorOfClass("Model")
	if model and model:FindFirstChildOfClass("Humanoid") then
		return Players:GetPlayerFromCharacter(model) == nil
	end
	return false
end

-- Filtro de clase según settings
local function passesClassFilter(inst: Instance, inCharacterContext: boolean): boolean
	if inCharacterContext then
		-- Dentro de personajes/NPCs
		if AFFECT_ACCESSORIES and inst:IsA("Accessory") then
			return true
		end
		if AFFECT_ANY_PART and (inst:IsA("BasePart") or inst:IsA("MeshPart")) then
			return true
		end
		return false
	else
		-- Fuera de personajes (mapa / objetos sueltos)
		if ONLY_ACCESSORY then
			return inst:IsA("Accessory")
		else
			return true -- cualquier clase
		end
	end
end

local function shouldDelete(inst: Instance): boolean
	if not inst or not inst.Parent then return false end
	if not hasKeyword(inst.Name) then return false end

	local inPlayer = isPlayerCharacter(inst)
	local inNPC    = isNPCCharacter(inst)

	if inPlayer then
		if not APPLY_TO_PLAYERS then return false end
		return passesClassFilter(inst, true)
	elseif inNPC then
		if not APPLY_TO_NPCS then return false end
		return passesClassFilter(inst, true)
	else
		-- Mapa/Workspace
		if not APPLY_TO_WORKSPACE then return false end
		return passesClassFilter(inst, false)
	end
end

----------------------------------------------------------------
-- Limpieza en Studio (cuando haces click en "Eliminar ahora")
----------------------------------------------------------------
local function collectMatchesFromRoot(root: Instance, bag: { Instance })
	-- raíz
	if shouldDelete(root) then
		table.insert(bag, root)
	end
	-- descendientes
	for _, d in ipairs(root:GetDescendants()) do
		if shouldDelete(d) then
			table.insert(bag, d)
		end
	end
end

local function getScanRoots(): { Instance }
	local sel = Selection:Get()
	if #sel > 0 then
		return sel
	end
	return { workspace }
end

local function runDelete()
	local victims = {}
	for _, root in ipairs(getScanRoots()) do
		if root and root.Parent then
			collectMatchesFromRoot(root, victims)
		end
	end

	if #victims == 0 then
		print("[BodyCleaner] No se encontraron coincidencias.")
		return
	end

	ChangeHistoryService:SetWaypoint("Before BodyCleaner")
	table.sort(victims, function(a, b)
		local okA, A = pcall(function() return a:GetFullName() end)
		local okB, B = pcall(function() return b:GetFullName() end)
		A = okA and A or a.Name
		B = okB and B or b.Name
		return A < B
	end)

	print(string.format("[BodyCleaner] Eliminando %d instancia(s):", #victims))
	for _, inst in ipairs(victims) do
		local ok, path = pcall(function() return inst:GetFullName() end)
		print("  - " .. (ok and path or inst.Name))
		inst:Destroy()
	end
	ChangeHistoryService:SetWaypoint("After BodyCleaner")
	print("[BodyCleaner] Listo (Studio).")
end

----------------------------------------------------------------
-- Generador de código runtime (ServerScriptService)
----------------------------------------------------------------
local function serializeStringArray(arr: {string}): string
	local parts = {}
	for _, v in ipairs(arr) do
		table.insert(parts, string.format("%q", v))
	end
	return "{ " .. table.concat(parts, ", ") .. " }"
end

local function buildRuntimeSource(): string
	return ([[-- RuntimeBodyCleaner (Server)
-- Autogenerado por BodyCleanerPlugin. Limpia mapa, NPCs y (opcional) jugadores.

local Players = game:GetService("Players")

-- ===== CONFIG AUTOINSTALADA (refleja la del plugin) =====
local KEYWORDS = %s
local BLACKLIST_CONTAINS = %s

local ONLY_ACCESSORY = %s

local APPLY_TO_WORKSPACE = %s
local APPLY_TO_NPCS      = %s
local APPLY_TO_PLAYERS   = %s

local AFFECT_ACCESSORIES = %s
local AFFECT_ANY_PART    = %s
-- ========================================================

local function toLower(s) return (typeof(s) == "string") and string.lower(s) or "" end

local function hasKeyword(name)
	local lower = toLower(name)
	for _, bad in ipairs(BLACKLIST_CONTAINS) do
		if string.find(lower, toLower(bad), 1, true) then
			return false
		end
	end
	for _, kw in ipairs(KEYWORDS) do
		if string.find(lower, toLower(kw), 1, true) then
			return true
		end
	end
	return false
end

local function isHumanoidModel(model)
	return model and model:IsA("Model") and model:FindFirstChildOfClass("Humanoid") ~= nil
end

local function isPlayerCharacter(inst)
	local model = inst:FindFirstAncestorOfClass("Model")
	if model and isHumanoidModel(model) then
		return Players:GetPlayerFromCharacter(model) ~= nil
	end
	return false
end

local function isNPCCharacter(inst)
	local model = inst:FindFirstAncestorOfClass("Model")
	if model and isHumanoidModel(model) then
		return Players:GetPlayerFromCharacter(model) == nil
	end
	return false
end

local function passesClassFilter(inst, inCharacterContext)
	if inCharacterContext then
		if AFFECT_ACCESSORIES and inst:IsA("Accessory") then
			return true
		end
		if AFFECT_ANY_PART and (inst:IsA("BasePart") or inst:IsA("MeshPart")) then
			return true
		end
		return false
	else
		if ONLY_ACCESSORY then
			return inst:Is("Accessory")
		else
			return true
		end
	end
end

local function shouldDelete(inst)
	if not inst or not inst.Parent then return false end
	if not hasKeyword(inst.Name) then return false end

	local inPlayer = isPlayerCharacter(inst)
	local inNPC    = isNPCCharacter(inst)

	if inPlayer then
		if not APPLY_TO_PLAYERS then return false end
		return passesClassFilter(inst, true)
	elseif inNPC then
		if not APPLY_TO_NPCS then return false end
		return passesClassFilter(inst, true)
	else
		if not APPLY_TO_WORKSPACE then return false end
		return passesClassFilter(inst, false)
	end
end

local function cleanInstance(inst)
	if inst and inst.Parent and shouldDelete(inst) then
		inst:Destroy()
	end
end

-- Limpieza inicial de todo el Workspace
if APPLY_TO_WORKSPACE or APPLY_TO_NPCS or APPLY_TO_PLAYERS then
	for _, d in ipairs(workspace:GetDescendants()) do
		cleanInstance(d)
	end
end

-- Mantener Workspace limpio en tiempo real
workspace.DescendantAdded:Connect(cleanInstance)

-- Limpiar personajes (jugadores) al spawnear y cuando agreguen cosas
if APPLY_TO_PLAYERS then
	local function hookCharacter(char)
		-- pase inicial
		for _, d in ipairs(char:GetDescendants()) do
			cleanInstance(d)
		end
		-- lo nuevo que se agregue al character
		char.DescendantAdded:Connect(cleanInstance)
	end

	Players.PlayerAdded:Connect(function(plr)
		plr.CharacterAdded:Connect(function(char)
			hookCharacter(char)
		end)
		-- por si el character ya existe
		if plr.Character then
			hookCharacter(plr.Character)
		end
	end)

	-- para personajes ya conectados (en caso de ejecutar en caliente)
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character then
			hookCharacter(plr.Character)
		end
	end
end
]]):format(
		serializeStringArray(KEYWORDS),
		serializeStringArray(BLACKLIST_CONTAINS),
		tostring(ONLY_ACCESSORY),
		tostring(APPLY_TO_WORKSPACE),
		tostring(APPLY_TO_NPCS),
		tostring(APPLY_TO_PLAYERS),
		tostring(AFFECT_ACCESSORIES),
		tostring(AFFECT_ANY_PART)
	)
end

local function installRuntime()
	local NAME = "_RuntimeBodyCleaner"
	local existing = ServerScriptService:FindFirstChild(NAME)
	local src = buildRuntimeSource()

	if existing and existing:IsA("Script") then
		existing.Source = src
		print("[BodyCleaner] Runtime actualizado en ServerScriptService/" .. NAME)
	else
		local s = Instance.new("Script")
		s.Name = NAME
		s.Source = src
		s.Parent = ServerScriptService
		print("[BodyCleaner] Runtime instalado en ServerScriptService/" .. NAME)
	end
end

----------------------------------------------------------------
-- UI del plugin
----------------------------------------------------------------
local toolbar = plugin:CreateToolbar("Cleaners")

local btnClean = toolbar:CreateButton(
	"BodyCleaner_DeleteNow",
	"Escanea selección o Workspace y elimina coincidencias (Studio)",
	BUTTON_ICON
)
btnClean.ClickableWhenViewportHidden = true
btnClean.Click:Connect(runDelete)

local btnInstall = toolbar:CreateButton(
	"BodyCleaner_InstallRuntime",
	"Instala/Actualiza el script de runtime en ServerScriptService",
	BUTTON_ICON
)
btnInstall.ClickableWhenViewportHidden = true
btnInstall.Click:Connect(installRuntime)

-- Command Palette
plugin:CreatePluginAction(
	"BodyCleanerAction_Clean",
	"BodyCleaner: Eliminar ahora",
	"Escanea y elimina coincidencias (Studio)",
	BUTTON_ICON
).Triggered:Connect(runDelete)

plugin:CreatePluginAction(
	"BodyCleanerAction_InstallRuntime",
	"BodyCleaner: Instalar runtime",
	"Instala/Actualiza el Script en ServerScriptService",
	BUTTON_ICON
).Triggered:Connect(installRuntime)

print("[BodyCleaner] Plugin listo. Usa los botones en Plugins → Cleaners.")
