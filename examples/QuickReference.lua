--[[
    GUÍA DE REFERENCIA RÁPIDA - BringRadius
    Copiar y pegar estos ejemplos para diferentes casos de uso
]]

-- ============================================
-- 1. CONFIGURACIÓN BÁSICA
-- ============================================
local BringRadius = require(game.ServerScriptService:WaitForChild("BringRadius"))
local bringSystem = BringRadius.new()
bringSystem:Start()

-- ============================================
-- 2. CONFIGURACIÓN AVANZADA
-- ============================================
local bringSystem = BringRadius.new({
    BRING_RADIUS = 100,      -- NPCs se atraen desde 100 studs
    ATTRACTION_SPEED = 1.0,  -- Muy rápido
    USE_DELTA_TIME = true,
    MAX_SPEED = 150,
    ENABLE_ROTATION = true,
    ROTATION_SPEED = 0.2
})

-- ============================================
-- 3. REGISTRAR UN NPC
-- ============================================
local npc = workspace.NPCs.MyNPC
bringSystem:RegisterNPC(npc)

-- ============================================
-- 4. REGISTRAR MÚLTIPLES NPCs
-- ============================================
for _, npc in pairs(workspace.NPCs:GetChildren()) do
    if npc:IsA("Model") then
        bringSystem:RegisterNPC(npc)
    end
end

-- ============================================
-- 5. AUTO-REGISTRO DE NPCs NUEVOS
-- ============================================
workspace.NPCs.ChildAdded:Connect(function(child)
    if child:IsA("Model") then
        task.wait(0.1)
        bringSystem:RegisterNPC(child)
    end
end)

-- ============================================
-- 6. CAMBIAR CONFIGURACIÓN EN TIEMPO REAL
-- ============================================
-- Aumentar radio
bringSystem:SetConfig("BRING_RADIUS", 150)

-- Aumentar velocidad
bringSystem:SetConfig("ATTRACTION_SPEED", 1.0)

-- Desactivar rotación
bringSystem:SetConfig("ENABLE_ROTATION", false)

-- ============================================
-- 7. OBTENER ESTADÍSTICAS
-- ============================================
local stats = bringSystem:GetStats()
print("NPCs Activos: " .. stats.totalNPCs)
print("NPCs Atraídos: " .. stats.attractedNPCs)
print("Radio: " .. stats.bringRadius)

-- ============================================
-- 8. MONITOREO CONTINUO
-- ============================================
task.spawn(function()
    while true do
        task.wait(1)
        local stats = bringSystem:GetStats()
        if stats.totalNPCs > 0 then
            print("Porcentaje atraído: " .. math.floor((stats.attractedNPCs / stats.totalNPCs) * 100) .. "%")
        end
    end
end)

-- ============================================
-- 9. DETENER EL SISTEMA
-- ============================================
bringSystem:Stop()

-- ============================================
-- 10. LIMPIAR TODOS LOS NPCs
-- ============================================
bringSystem:Clear()

-- ============================================
-- 11. REINICIAR EL SISTEMA
-- ============================================
bringSystem:Stop()
task.wait(1)
bringSystem = BringRadius.new()
bringSystem:Start()

-- ============================================
-- 12. CASO DE USO: EVENTO DE JEFE
-- ============================================
local bossSystem = BringRadius.new({
    BRING_RADIUS = 75,
    ATTRACTION_SPEED = 0.8
})

local boss = workspace.Bosses.MainBoss
bossSystem:RegisterNPC(boss)
bossSystem:Start()

-- Cuando el jefe muere
boss.Humanoid.Died:Connect(function()
    bossSystem:Stop()
    print("Jefe derrotado")
end)

-- ============================================
-- 13. CASO DE USO: ZONA ACTIVADA
-- ============================================
local zonaSystem = BringRadius.new()
local isZoneActive = false

local touchPart = workspace.ZonaTrigger
touchPart.Touched:Connect(function(hit)
    if not isZoneActive and hit.Parent:FindFirstChild("Humanoid") then
        isZoneActive = true
        zonaSystem:Start()
        print("¡Zona activada! NPCs comenzando atracción")
    end
end)

-- ============================================
-- 14. CASO DE USO: CAMBIO DINÁMICO DE DIFICULTAD
-- ============================================
local diffSystem = BringRadius.new()
local difficulty = 1

function SetDifficulty(level)
    difficulty = level
    if level == 1 then
        diffSystem:SetConfig("BRING_RADIUS", 50)
        diffSystem:SetConfig("ATTRACTION_SPEED", 0.5)
    elseif level == 2 then
        diffSystem:SetConfig("BRING_RADIUS", 75)
        diffSystem:SetConfig("ATTRACTION_SPEED", 0.8)
    elseif level == 3 then
        diffSystem:SetConfig("BRING_RADIUS", 100)
        diffSystem:SetConfig("ATTRACTION_SPEED", 1.0)
    end
    print("Dificultad cambiada a: " .. level)
end

SetDifficulty(1)
task.wait(30)
SetDifficulty(2)
task.wait(30)
SetDifficulty(3)

-- ============================================
-- 15. CASO DE USO: ACTIVACIÓN POR COMANDO
-- ============================================
local Players = game:GetService("Players")
local cmdSystem = BringRadius.new()

Players.PlayerAdded:Connect(function(player)
    player.Chatted:Connect(function(msg)
        if msg == "/bringnpcs" then
            if not cmdSystem.isRunning then
                cmdSystem:Start()
                print("Bring radius activado")
            else
                cmdSystem:Stop()
                print("Bring radius desactivado")
            end
        end
    end)
end)
