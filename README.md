# AntiLewd-Clothes English
I made this plugin with [ChatGPT](https://chat.openai.com/) to delete the "Body" and "Bodysuit" clothes, which are usually NSFW, but you can add more tags

## Features
 - Scans your  **Workspace** for item names.
- Automatically removes matching instances (like “Body”, “Bodysuit”, etc.).
- Generates a runtime script (`RuntimeBodyCleaner`) that also works when the game is published.
- Configurable filters: add or remove keywords easily.
- Ignores player characters and can be restricted to accessories only.

## Installation
- Download `AntiLewd Clothes.rbxmx` from this repository.
- Place it into your Roblox Studio plugins folder
```
AppData\Local\Roblox\Plugins
```

## Usage
- Open the **Plugins** tab → find "BodyCleaner" (It's called that to avoid any problems, but I prefer "AntiLewd Clothes")
- Selected the entire Workspace.
- Click **BodyCleaner_DeleteNow** to clean instantly in Workspace
- Click en **BodyCleaner_InstallRuntime** to automatically add a server script (`RuntimeBodyCleaner`)

## Configuration
- You can edit the keyword list inside the plugin:
```lua
local KEYWORDS = { "body", "bodysuit" }
```
One blacklist to avoid errors
```lua
local BLACKLIST_CONTAINS = { "bodycolors" }
```
- If you only want to delete accessories, you must change the following:
```lua
local ONLY_ACCESSORY = false
```
- change it to True

## Video guide
[![Alt text](https://img.youtube.com/vi/QMSsi-Ebp2s/0.jpg)](https://www.youtube.com/watch?v=QMSsi-Ebp2s)

---

# AntiLewd-Clothes Español
Creé este plugin con [ChatGPT](https://chat.openai.com/) para eliminar las prendas "Body" y "Bodysuit", que suelen ser NSFW. Puedes añadir más etiquetas.

## Características

- Observa tu **Espacio de trabajo** en busca de nombres de objetos.

- Elimina automáticamente las coincidencias (como "Body", "Bodysuit", etc.).

- Genera un script de ejecución (`RuntimeBodyCleaner`) que también funciona al publicar el juego.

- Filtros configurables: añade o elimina palabras clave fácilmente.

- Ignora los personajes jugadores y se puede restringir solo a accesorios.

## Instalación
- Descarga `AntiLewd Clothes.rbxmx` de este repositorio.

- Colócalo en la carpeta de plugins de Roblox Studio:

```
AppData\Local\Roblox\Plugins
```

## Uso

- Abre la pestaña **Plugins** → busca "BodyCleaner" (Se llama así para evitar problemas, pero yo prefiero "AntiLewd Clothes").

- Selecciona todo el espacio de trabajo.

- Haz clic en **BodyCleaner_DeleteNow** para limpiar instantáneamente en el Espacio de Trabajo.

- Haz clic en **BodyCleaner_InstallRuntime** para añadir automáticamente un script de servidor (`RuntimeBodyCleaner`).

## Configuración

- Puedes editar la lista de palabras clave dentro del plugin:

```lua
local KEYWORDS = { "body", "bodysuit" }

``` 
- Una lista negra para evitar problemas:

```lua
local BLACKLIST_CONTAINS = { "bodycolors" }

```
- Si solo quieres eliminar los accesorios, debes cambiar lo siguiente:

```lua
local ONLY_ACCESSORY = false

```
- Cámbialo a True

## Video guia

[![Alt text](https://img.youtube.com/vi/QMSsi-Ebp2s/0.jpg)](https://www.youtube.com/watch?v=QMSsi-Ebp2s)
