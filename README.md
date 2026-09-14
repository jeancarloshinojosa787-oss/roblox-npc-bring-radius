# 🎮 Roblox NPC Bring Radius System

Sistema avanzado de atracción de NPCs con ejecución basada en **delta time** para Roblox.

## ✨ Características

- ✅ **Delta Time Execution** - Movimiento suave e independiente de FPS
- ✅ **Atracción de Radio** - NPCs se atraen hacia jugadores dentro de un radio
- ✅ **Rotación Automática** - NPCs rotan hacia el jugador
- ✅ **Configuración Dinámica** - Cambiar parámetros en tiempo real
- ✅ **Estadísticas en Vivo** - Monitoreo del sistema
- ✅ **Optimizado** - Usa RenderStepped para máximo rendimiento

## 📦 Instalación

1. Descarga el archivo `src/BringRadius.lua`
2. Colócalo en `ServerScriptService` o `ReplicatedStorage`
3. Usa el ejemplo `examples/ServerScript.lua` para implementarlo

## 🚀 Uso Rápido

```lua
local BringRadius = require(game.ServerScriptService:WaitForChild("BringRadius"))

-- Crear instancia
local bringSystem = BringRadius.new({
    BRING_RADIUS = 50,
    ATTRACTION_SPEED = 0.5,
    USE_DELTA_TIME = true
})

-- Registrar NPCs
bringSystem:RegisterNPC(npcModel)

-- Iniciar sistema
bringSystem:Start()
```

## ⚙️ Configuración

| Parámetro | Tipo | Default | Descripción |
|-----------|------|---------|-------------|
| `BRING_RADIUS` | number | 50 | Radio de atracción en studs |
| `ATTRACTION_SPEED` | number | 0.5 | Velocidad de atracción (0.1-1) |
| `USE_DELTA_TIME` | boolean | true | Activar delta time |
| `MAX_SPEED` | number | 100 | Velocidad máxima en studs/s |
| `ENABLE_ROTATION` | boolean | true | Rotar NPCs hacia jugador |
| `ROTATION_SPEED` | number | 0.1 | Velocidad de rotación |

## 📋 Métodos Disponibles

### `BringRadius.new(config)`
Crea una nueva instancia del sistema.

### `RegisterNPC(npcModel)`
Registra un NPC para ser atraído.

### `Start()`
Inicia el sistema de atracción.

### `Stop()`
Detiene el sistema.

### `SetConfig(key, value)`
Cambia configuración en tiempo real.

### `GetStats()`
Retorna estadísticas del sistema.

### `GetConfig()`
Obtiene la configuración actual.

### `Clear()`
Elimina todos los NPCs registrados.

## 🎮 Ejemplo Completo

```lua
local BringRadius = require(game.ServerScriptService:WaitForChild("BringRadius"))

local bringSystem = BringRadius.new({
    BRING_RADIUS = 50,
    ATTRACTION_SPEED = 0.5,
    USE_DELTA_TIME = true
})

local NPCFolder = workspace:WaitForChild("NPCs")

-- Registrar NPCs existentes
for _, npc in pairs(NPCFolder:GetChildren()) do
    bringSystem:RegisterNPC(npc)
end

-- Detectar nuevos NPCs
NPCFolder.ChildAdded:Connect(function(child)
    if child:IsA("Model") then
        bringSystem:RegisterNPC(child)
    end
end)

-- Iniciar
bringSystem:Start()

-- Estadísticas
while true do
    task.wait(5)
    local stats = bringSystem:GetStats()
    print("NPCs Atraídos: " .. stats.attractedNPCs)
end
```

## 🔧 Estructura de NPC

El NPC debe tener:
- ✓ `HumanoidRootPart` (posición y rotación)
- ✓ `Humanoid` (para detectar salud)

```
NPC (Model)
├── HumanoidRootPart (Part)
├── Humanoid
└── Otros componentes (Cabeza, Torso, etc.)
```

## 📊 Delta Time

El sistema usa **RenderStepped** para calcular el delta time preciso:
- Movimiento suave independiente de FPS
- No depende de `task.wait()`
- Óptimo rendimiento en servidores con lag

## 🐛 Solución de Problemas

### NPCs no se mueven
- Verifica que tengan `HumanoidRootPart` y `Humanoid`
- Asegúrate que `bringSystem:Start()` se ejecutó
- Revisa que `USE_DELTA_TIME` esté en `true`

### NPCs se mueven muy lento/rápido
- Ajusta `ATTRACTION_SPEED` (0.1 a 1)
- Aumenta/disminuye `MAX_SPEED`

### NPCs no se rotan
- Verifica que `ENABLE_ROTATION` esté en `true`
- Ajusta `ROTATION_SPEED` si es muy lento

## 📁 Estructura del Proyecto

```
roblox-npc-bring-radius/
├── README.md
├── src/
│   └── BringRadius.lua          (Módulo principal)
└── examples/
    ├── ServerScript.lua         (Ejemplo de uso básico)
    └── QuickReference.lua       (15 casos de uso)
```

## 📄 Licencia

MIT License - Siéntete libre de usar y modificar

## 👨‍💻 Autor

**jeancarloshinojosa787-oss**

---

¿Necesitas ayuda? Abre un issue en el repositorio.
