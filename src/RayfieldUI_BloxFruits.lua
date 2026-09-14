--[[
    Rayfield UI para Blox Fruits - BringRadius System
    Interface visual para control de NPCs en Blox Fruits
    Coloca este script en StarterPlayer > StarterCharacterScripts o StarterGui
]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Variables del juego Blox Fruits
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- Crear instancia de BringNPC (compatible con Blox Fruits)
local BringNPC = {}
BringNPC.__index = BringNPC

function BringNPC.new(config)
    local self = setmetatable({}, BringNPC)
    self.config = config or {
        BRING_RADIUS = 50,
        ATTRACTION_SPEED = 0.5,
        USE_DELTA_TIME = true,
        MAX_SPEED = 100,
        ENABLE_ROTATION = true
    }
    self.activeNPCs = {}
    self.isRunning = false
    self.lastUpdateTime = tick()
    return self
end

function BringNPC:GetDeltaTime()
    local currentTime = tick()
    local deltaTime = currentTime - self.lastUpdateTime
    self.lastUpdateTime = currentTime
    return deltaTime
end

function BringNPC:AttractNPC(npc, targetPos, deltaTime)
    if not npc:FindFirstChild("HumanoidRootPart") then return end
    
    local npcPos = npc.HumanoidRootPart.Position
    local direction = (targetPos - npcPos)
    local distance = direction.Magnitude
    
    if distance == 0 then return end
    
    local directionUnit = direction.Unit
    local speed = self.config.ATTRACTION_SPEED * 10
    if self.config.USE_DELTA_TIME then
        speed = math.min(speed * deltaTime, self.config.MAX_SPEED * deltaTime)
    end
    
    local newPos = npcPos + directionUnit * speed
    
    if npc:FindFirstChild("HumanoidRootPart") then
        npc.HumanoidRootPart.CFrame = CFrame.new(newPos) * npc.HumanoidRootPart.CFrame.Rotation
    end
end

function BringNPC:FindNPCsInRadius()
    local npcs = {}
    local playerPos = character:FindFirstChild("HumanoidRootPart").Position
    
    -- Buscar enemigos en el workspace
    for _, npc in pairs(workspace:GetDescendants()) do
        if npc:IsA("Model") and npc:FindFirstChild("Humanoid") and npc:FindFirstChild("HumanoidRootPart") then
            if npc.Parent ~= character and not Players:FindFirstChild(npc.Name) then
                local npcPos = npc.HumanoidRootPart.Position
                local distance = (playerPos - npcPos).Magnitude
                
                if distance < self.config.BRING_RADIUS and npc.Humanoid.Health > 0 then
                    table.insert(npcs, npc)
                end
            end
        end
    end
    
    return npcs
end

function BringNPC:Start()
    if self.isRunning then return end
    self.isRunning = true
    
    self._connection = RunService.RenderStepped:Connect(function()
        if not self.isRunning or not character:FindFirstChild("HumanoidRootPart") then return end
        
        local deltaTime = self:GetDeltaTime()
        local playerPos = character.HumanoidRootPart.Position
        local npcs = self:FindNPCsInRadius()
        
        for _, npc in pairs(npcs) do
            if npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0 then
                self:AttractNPC(npc, playerPos, deltaTime)
            end
        end
    end)
end

function BringNPC:Stop()
    if self._connection then
        self._connection:Disconnect()
    end
    self.isRunning = false
end

function BringNPC:GetStats()
    local npcs = self:FindNPCsInRadius()
    return {
        totalNPCs = #npcs,
        bringRadius = self.config.BRING_RADIUS,
        attractionSpeed = self.config.ATTRACTION_SPEED,
        usingDeltaTime = self.config.USE_DELTA_TIME
    }
end

function BringNPC:SetConfig(key, value)
    if self.config[key] ~= nil then
        self.config[key] = value
        return true
    end
    return false
end

-- Crear instancia del sistema
local bringNPC = BringNPC.new({
    BRING_RADIUS = 50,
    ATTRACTION_SPEED = 0.5,
    USE_DELTA_TIME = true,
    MAX_SPEED = 100,
    ENABLE_ROTATION = true
})

-- Crear la ventana principal de Rayfield
local Window = Rayfield:CreateWindow({
    Name = "🎮 Blox Fruits - NPC Bring",
    LoadingTitle = "Cargando Sistema...",
    LoadingSubtitle = "Iniciando BringRadius para Blox Fruits",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "BloxFruitsBring",
        FileName = "config.json"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    },
    KeySystem = false
})

-- ════════════════════════════════════════════════════════════════
-- PESTAÑA PRINCIPAL
-- ════════════════════════════════════════════════════════════════

local MainTab = Window:CreateTab("🏠 Principal", 0)

local ControlSection = MainTab:CreateSection("⚙️ Control del Sistema")

local isRunning = false

MainTab:CreateButton({
    Name = "▶️ Iniciar Bring",
    Callback = function()
        if not isRunning then
            bringNPC:Start()
            isRunning = true
            Rayfield:Notify({
                Title = "✅ Bring Activado",
                Content = "Comenzando a atraer NPCs hacia ti",
                Duration = 2,
                Image = 4483362458
            })
        end
    end
})

MainTab:CreateButton({
    Name = "⏹️ Detener Bring",
    Callback = function()
        if isRunning then
            bringNPC:Stop()
            isRunning = false
            Rayfield:Notify({
                Title = "⏹️ Bring Detenido",
                Content = "NPCs dejarán de ser atraídos",
                Duration = 2,
                Image = 4483362458
            })
        end
    end
})

-- Sección de Configuración
local ConfigSection = MainTab:CreateSection("🎛️ Configuración")

local radiusSlider = MainTab:CreateSlider({
    Name = "📏 Radio de Atracción",
    Range = {10, 300},
    Increment = 5,
    Suffix = " studs",
    CurrentValue = 50,
    Flag = "RadiusSlider",
    Callback = function(Value)
        bringNPC:SetConfig("BRING_RADIUS", Value)
    end
})

local speedSlider = MainTab:CreateSlider({
    Name = "⚡ Velocidad de Atracción",
    Range = {0.1, 3},
    Increment = 0.1,
    Suffix = "x",
    CurrentValue = 0.5,
    Flag = "SpeedSlider",
    Callback = function(Value)
        bringNPC:SetConfig("ATTRACTION_SPEED", Value)
    end
})

local maxSpeedSlider = MainTab:CreateSlider({
    Name = "🚀 Velocidad Máxima",
    Range = {10, 500},
    Increment = 10,
    Suffix = " studs/s",
    CurrentValue = 100,
    Flag = "MaxSpeedSlider",
    Callback = function(Value)
        bringNPC:SetConfig("MAX_SPEED", Value)
    end
})

-- Sección de Características
local FeaturesSection = MainTab:CreateSection("🌟 Características")

MainTab:CreateToggle({
    Name = "⏱️ Delta Time (Recomendado)",
    CurrentValue = true,
    Flag = "DeltaTimeToggle",
    Callback = function(Value)
        bringNPC:SetConfig("USE_DELTA_TIME", Value)
    end
})

MainTab:CreateToggle({
    Name = "🔄 Rotación Automática",
    CurrentValue = true,
    Flag = "RotationToggle",
    Callback = function(Value)
        bringNPC:SetConfig("ENABLE_ROTATION", Value)
    end
})

-- ════════════════════════════════════════════════════════════════
-- PESTAÑA DE ESTADÍSTICAS
-- ════════════════════════════════════════════════════════════════

local StatsTab = Window:CreateTab("📊 Estadísticas", 0)

local StatsSection = StatsTab:CreateSection("📈 Información en Vivo")

-- Label de estadísticas que se actualiza cada segundo
local statsLabel = StatsTab:CreateLabel("Cargando...")

task.spawn(function()
    while true do
        task.wait(1)
        local stats = bringNPC:GetStats()
        
        statsLabel:Set(
            "═══════════════════════════════\n" ..
            "📈 ESTADÍSTICAS EN VIVO\n" ..
            "═══════════════════════════════\n\n" ..
            "👾 NPCs en Rango: " .. stats.totalNPCs .. "\n" ..
            "📏 Radio: " .. stats.bringRadius .. " studs\n" ..
            "⚡ Velocidad: " .. string.format("%.2f", stats.attractionSpeed) .. "x\n" ..
            "⏱️ Delta Time: " .. tostring(stats.usingDeltaTime) .. "\n" ..
            "🟢 Estado: " .. (isRunning and "ACTIVO" or "INACTIVO") .. "\n" ..
            "═══════════════════════════════"
        )
    end
end)

StatsTab:CreateButton({
    Name = "🔄 Actualizar Estadísticas",
    Callback = function()
        local stats = bringNPC:GetStats()
        Rayfield:Notify({
            Title = "📊 Estadísticas",
            Content = "NPCs: " .. stats.totalNPCs .. " | Radio: " .. stats.bringRadius .. " studs",
            Duration = 3,
            Image = 4483362458
        })
    end
})

-- ════════════════════════════════════════════════════════════════
-- PESTAÑA DE PRESETS
-- ════════════════════════════════════════════════════════════════

local PresetsTab = Window:CreateTab("⚡ Presets", 0)

local PresetsSection = PresetsTab:CreateSection("🎮 Modos Predefinidos")

PresetsTab:CreateButton({
    Name = "🐢 Modo Defensivo",
    Callback = function()
        bringNPC:SetConfig("BRING_RADIUS", 30)
        bringNPC:SetConfig("ATTRACTION_SPEED", 0.3)
        radiusSlider:Set(30)
        speedSlider:Set(0.3)
        Rayfield:Notify({
            Title = "🐢 Modo Defensivo",
            Content = "Radio reducido para máxima precisión",
            Duration = 2,
            Image = 4483362458
        })
    end
})

PresetsTab:CreateButton({
    Name = "⚔️ Modo Combate",
    Callback = function()
        bringNPC:SetConfig("BRING_RADIUS", 60)
        bringNPC:SetConfig("ATTRACTION_SPEED", 0.6)
        radiusSlider:Set(60)
        speedSlider:Set(0.6)
        Rayfield:Notify({
            Title = "⚔️ Modo Combate",
            Content = "Configuración equilibrada para combate",
            Duration = 2,
            Image = 4483362458
        })
    end
})

PresetsTab:CreateButton({
    Name = "⚡ Modo Ofensivo",
    Callback = function()
        bringNPC:SetConfig("BRING_RADIUS", 100)
        bringNPC:SetConfig("ATTRACTION_SPEED", 1.0)
        radiusSlider:Set(100)
        speedSlider:Set(1.0)
        Rayfield:Notify({
            Title = "⚡ Modo Ofensivo",
            Content = "Radio amplio para máxima agresión",
            Duration = 2,
            Image = 4483362458
        })
    end
})

PresetsTab:CreateButton({
    Name = "🔥 Modo Extremo",
    Callback = function()
        bringNPC:SetConfig("BRING_RADIUS", 200)
        bringNPC:SetConfig("ATTRACTION_SPEED", 1.5)
        radiusSlider:Set(200)
        speedSlider:Set(1.5)
        Rayfield:Notify({
            Title = "🔥 Modo Extremo",
            Content = "¡Trae TODOS los enemigos!",
            Duration = 2,
            Image = 4483362458
        })
    end
})

PresetsTab:CreateButton({
    Name = "🌊 Granja de Enemigos",
    Callback = function()
        bringNPC:SetConfig("BRING_RADIUS", 150)
        bringNPC:SetConfig("ATTRACTION_SPEED", 0.8)
        radiusSlider:Set(150)
        speedSlider:Set(0.8)
        Rayfield:Notify({
            Title = "🌊 Modo Granja",
            Content = "Óptimo para farmear enemigos",
            Duration = 2,
            Image = 4483362458
        })
    end
})

-- ════════════════════════════════════════════════════════════════
-- PESTAÑA DE ATAJOS
-- ════════════════════════════════════════════════════════════════

local KeyBindTab = Window:CreateTab("⌨️ Atajos", 0)

local KeyBindSection = KeyBindTab:CreateSection("⌨️ Teclas de Atajo")

KeyBindTab:CreateKeybind({
    Name = "Activar/Desactivar Bring",
    CurrentKeybind = "F",
    HoldToInteract = false,
    Flag = "ToggleBringKey",
    Callback = function(Keybind)
        isRunning = not isRunning
        if isRunning then
            bringNPC:Start()
            Rayfield:Notify({
                Title = "✅ Activado",
                Content = "Sistema activado con F",
                Duration = 1
            })
        else
            bringNPC:Stop()
            Rayfield:Notify({
                Title = "⏹️ Desactivado",
                Content = "Sistema desactivado con F",
                Duration = 1
            })
        end
    end
})

KeyBindTab:CreateKeybind({
    Name = "Aumentar Radio",
    CurrentKeybind = "E",
    HoldToInteract = false,
    Flag = "IncreaseRadiusKey",
    Callback = function(Keybind)
        local currentRadius = bringNPC.config.BRING_RADIUS
        local newRadius = math.min(currentRadius + 10, 300)
        bringNPC:SetConfig("BRING_RADIUS", newRadius)
        radiusSlider:Set(newRadius)
        Rayfield:Notify({
            Title = "📏 Radio",
            Content = "Nuevo radio: " .. newRadius .. " studs",
            Duration = 1
        })
    end
})

KeyBindTab:CreateKeybind({
    Name = "Disminuir Radio",
    CurrentKeybind = "Q",
    HoldToInteract = false,
    Flag = "DecreaseRadiusKey",
    Callback = function(Keybind)
        local currentRadius = bringNPC.config.BRING_RADIUS
        local newRadius = math.max(currentRadius - 10, 10)
        bringNPC:SetConfig("BRING_RADIUS", newRadius)
        radiusSlider:Set(newRadius)
        Rayfield:Notify({
            Title = "📏 Radio",
            Content = "Nuevo radio: " .. newRadius .. " studs",
            Duration = 1
        })
    end
})

-- ════════════════════════════════════════════════════════════════
-- PESTAÑA DE INFORMACIÓN
-- ════════════════════════════════════════════════════════════════

local InfoTab = Window:CreateTab("ℹ️ Información", 0)

InfoTab:CreateLabel(
    "🎮 BLOX FRUITS NPC BRING SYSTEM\n\n" ..
    "Sistema avanzado de atracción de NPCs para Blox Fruits\n\n" ..
    "CARACTERÍSTICAS:\n" ..
    "✓ Delta Time para movimiento suave\n" ..
    "✓ Radio de atracción configurable\n" ..
    "✓ Múltiples presets\n" ..
    "✓ Estadísticas en vivo\n" ..
    "✓ Atajos de teclado\n\n" ..
    "USO:\n" ..
    "1. Presiona F para activar/desactivar\n" ..
    "2. Ajusta el radio con Q/E\n" ..
    "3. Elige un preset para rápida configuración\n\n" ..
    "⚠️ USO BAJO TU RESPONSABILIDAD"
)

InfoTab:CreateButton({
    Name = "📋 Ver Configuración",
    Callback = function()
        print("═══════════════════════════════════")
        print("CONFIGURACIÓN ACTUAL")
        print("═══════════════════════════════════")
        for key, value in pairs(bringNPC.config) do
            print(key .. ": " .. tostring(value))
        end
        print("═══════════════════════════════════")
    end
})

-- Notificación inicial
Rayfield:Notify({
    Title = "✨ ¡Bienvenido!",
    Content = "Sistema de Bring Radius para Blox Fruits cargado.\nPresiona F para activar",
    Duration = 4,
    Image = 4483362458
})

-- Actualizar cuando el jugador muere
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    if isRunning then
        bringNPC:Stop()
        isRunning = false
        task.wait(0.5)
        bringNPC:Start()
        isRunning = true
    end
end)

return Window
