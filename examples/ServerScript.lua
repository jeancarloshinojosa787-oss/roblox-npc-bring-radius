--[[
    EJEMPLO DE USO - BringRadius Sistema
    Coloca este script en ServerScriptService
]]

local BringRadius = require(game.ServerScriptService:WaitForChild("BringRadius"))

-- Crear instancia con configuración personalizada
local bringSystem = BringRadius.new({
    BRING_RADIUS = 50,           -- Radio de atracción en studs
    ATTRACTION_SPEED = 0.5,      -- Velocidad de atracción
    USE_DELTA_TIME = true,       -- Usar delta time para movimiento suave
    MAX_SPEED = 100,             -- Velocidad máxima
    ENABLE_ROTATION = true,      -- Rotar NPCs hacia el jugador
    ROTATION_SPEED = 0.1         -- Velocidad de rotación
})

-- Esperar a que exista la carpeta de NPCs
local NPCFolder = workspace:WaitForChild("NPCs")

-- Registrar NPCs existentes
for _, npcModel in pairs(NPCFolder:GetChildren()) do
    if npcModel:IsA("Model") then
        bringSystem:RegisterNPC(npcModel)
    end
end

-- Detectar nuevos NPCs añadidos a la carpeta
NPCFolder.ChildAdded:Connect(function(child)
    if child:IsA("Model") then
        task.wait(0.1) -- Pequeña espera para que el NPC se inicialice
        bringSystem:RegisterNPC(child)
    end
end)

-- INICIAR EL SISTEMA
bringSystem:Start()

-- Mostrar estadísticas cada 5 segundos
task.spawn(function()
    while true do
        task.wait(5)
        local stats = bringSystem:GetStats()
        print("━━━ ESTADÍSTICAS DE BRING RADIUS ━━━")
        print("NPCs Activos: " .. stats.totalNPCs)
        print("NPCs Atraídos: " .. stats.attractedNPCs)
        print("Radio de Atracción: " .. stats.bringRadius .. " studs")
        print("Velocidad: " .. stats.attractionSpeed)
        print("Usando Delta Time: " .. tostring(stats.usingDeltaTime))
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    end
end)

-- EJEMPLO: Cambiar configuración en tiempo real
task.wait(10)
bringSystem:SetConfig("BRING_RADIUS", 75)  -- Aumentar radio a 75 studs
bringSystem:SetConfig("ATTRACTION_SPEED", 0.8)  -- Aumentar velocidad

-- Para detener el sistema (opcional):
-- bringSystem:Stop()

-- Para limpiar todos los NPCs (opcional):
-- bringSystem:Clear()
