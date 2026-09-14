--[[
    Rayfield UI para Blox Fruits - INSTANT BRING (Atracción Instantánea)
    Trae todos los NPCs al jugador INSTANTÁNEAMENTE
    Coloca este script en StarterPlayer > StarterCharacterScripts o StarterGui
]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Variables del juego Blox Fruits
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- ════════════════════════════════════════════════════════════════
-- SISTEMA DE INSTANT BRING (ATRACCIÓN INSTANTÁNEA)
-- ════════════════════════════════════════════════════════════════

local InstantBring = {}
InstantBring.__index = InstantBring

function InstantBring.new(config)
    local self = setmetatable({}, InstantBring)
    self.config = config or {
        BRING_RADIUS = 100,
        INSTANT_MODE = true,
        TELEPORT_OFFSET = 5,
        FREEZE_NPC = false
    }
    self.isRunning = false
    self.bringCount = 0
    return self
end

function InstantBring:BringAllNPCs()
    if not character:FindFirstChild("HumanoidRootPart") then return 0 end
    
    local playerPos = character.HumanoidRootPart.Position
    local bringCount = 0
    
    -- Obtener todos los NPCs en el rango
    for _, npc in pairs(workspace:GetDescendants()) do
        if npc:IsA("Model") and npc:FindFirstChild("Humanoid") and npc:FindFirstChild("HumanoidRootPart") then
            if npc.Parent ~= character and not Players:FindFirstChild(npc.Name) then
                local npcPos = npc.HumanoidRootPart.Position
                local distance = (playerPos - npcPos).Magnitude
                
                -- Si el NPC está en rango y vivo
                if distance < self.config.BRING_RADIUS and npc.Humanoid.Health > 0 then
                    -- TELEPORTACIÓN INSTANTÁNEA
                    local offset = npcPos - playerPos
                    local direction = offset.Unit
                    
                    -- Teletransportar el NPC cerca del jugador
                    local newPos = playerPos + direction * self.config.TELEPORT_OFFSET
                    npc.HumanoidRootPart.CFrame = CFrame.new(newPos)
                    
                    -- Opcional: Congelar el NPC
                    if self.config.FREEZE_NPC then
                        npc.HumanoidRootPart.CanCollide = false
                        npc.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
                    end
                    
                    bringCount = bringCount + 1
                end
            end
        end
    end
    
    self.bringCount = bringCount
    return bringCount
end

function InstantBring:ContinuousBring()
    self.isRunning = true
    
    self._connection = RunService.RenderStepped:Connect(function()
        if not self.isRunning or not character:FindFirstChild("HumanoidRootPart") then return end
        self:BringAllNPCs()
    end)
end

function InstantBring:Stop()
    if self._connection then
        self._connection:Disconnect()
    end
    self.isRunning = false
end

function InstantBring:GetNPCCount()
    if not character:FindFirstChild("HumanoidRootPart") then return 0 end
    
    local playerPos = character.HumanoidRootPart.Position
    local count = 0
    
    for _, npc in pairs(workspace:GetDescendants()) do
        if npc:IsA("Model") and npc:FindFirstChild("Humanoid") and npc:FindFirstChild("HumanoidRootPart") then
            if npc.Parent ~= character and not Players:FindFirstChild(npc.Name) then
                local npcPos = npc.HumanoidRootPart.Position
                local distance = (playerPos - npcPos).Magnitude
                
                if distance < self.config.BRING_RADIUS and npc.Humanoid.Health > 0 then
                    count = count + 1
                end
            end
        end
    end
    
    return count
end

function InstantBring:SetConfig(key, value)
    if self.config[key] ~= nil then
        self.config[key] = value
        return true
    end
    return false
end

-- Crear instancia del sistema INSTANT BRING
local instantBring = InstantBring.new({
    BRING_RADIUS = 100,
    INSTANT_MODE = true,
    TELEPORT_OFFSET = 5,
    FREEZE_NPC = false
})

-- ════════════════════════════════════════════════════════════════
-- INTERFAZ RAYFIELD
-- ════════════════════════════════════════════════════════════════

local Window = Rayfield:CreateWindow({
    Name = "⚡ Blox Fruits - INSTANT BRING",
    LoadingTitle = "Cargando...",
    LoadingSubtitle = "Sistema de Atracción Instantánea",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "BloxFruitsInstantBring",
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

local MainTab = Window:CreateTab("⚡ INSTANT BRING", 0)

local MainSection = MainTab:CreateSection("🎯 ATRACCIÓN INSTANTÁNEA")

local isBringingActive = false

MainTab:CreateButton({
    Name = "⚡ TRAER TODOS LOS NPCs (UNA VEZ)",
    Callback = function()
        local count = instantBring:BringAllNPCs()
        Rayfield:Notify({
            Title = "⚡ NPCs Traídos",
            Content = "Se trajeron " .. count .. " NPCs instantáneamente",
            Duration = 2,
            Image = 4483362458
        })
    end
})

MainTab:CreateButton({
    Name = "▶️ MODO CONTINUO (Traer constantemente)",
    Callback = function()
        if not isBringingActive then
            instantBring:ContinuousBring()
            isBringingActive = true
            Rayfield:Notify({
                Title = "▶️ Modo Continuo Activado",
                Content = "Atrayendo NPCs constantemente...",
                Duration = 2,
                Image = 4483362458
            })
        end
    end
})

MainTab:CreateButton({
    Name = "⏹️ DETENER MODO CONTINUO",
    Callback = function()
        if isBringingActive then
            instantBring:Stop()
            isBringingActive = false
            Rayfield:Notify({
                Title = "⏹️ Modo Continuo Detenido",
                Content = "Sistema desactivado",
                Duration = 2,
                Image = 4483362458
            })
        end
    end
})

-- Sección de Configuración
local ConfigSection = MainTab:CreateSection("⚙️ CONFIGURACIÓN")

local radiusSlider = MainTab:CreateSlider({
    Name = "📏 Radio de Detección",
    Range = {10, 500},
    Increment = 10,
    Suffix = " studs",
    CurrentValue = 100,
    Flag = "RadiusSlider",
    Callback = function(Value)
        instantBring:SetConfig("BRING_RADIUS", Value)
    end
})

local offsetSlider = MainTab:CreateSlider({
    Name = "📍 Distancia al Jugador",
    Range = {1, 50},
    Increment = 1,
    Suffix = " studs",
    CurrentValue = 5,
    Flag = "OffsetSlider",
    Callback = function(Value)
        instantBring:SetConfig("TELEPORT_OFFSET", Value)
    end
})

MainTab:CreateToggle({
    Name = "❄️ Congelar NPCs al Traer",
    CurrentValue = false,
    Flag = "FreezeToggle",
    Callback = function(Value)
        instantBring:SetConfig("FREEZE_NPC", Value)
    end
})

-- ════════════════════════════════════════════════════════════════
-- PESTAÑA DE ESTADÍSTICAS
-- ════════════════════════════════════════════════════════════════

local StatsTab = Window:CreateTab("📊 ESTADÍSTICAS", 0)

local statsLabel = StatsTab:CreateLabel("Cargando...")

task.spawn(function()
    while true do
        task.wait(0.5)
        local npcCount = instantBring:GetNPCCount()
        
        statsLabel:Set(
            "═══════════════════════════════════════\n" ..
            "📊 INFORMACIÓN EN TIEMPO REAL\n" ..
            "═══════════════════════════════════════\n\n" ..
            "👾 NPCs Disponibles: " .. npcCount .. "\n" ..
            "📏 Radio de Detección: " .. instantBring.config.BRING_RADIUS .. " studs\n" ..
            "📍 Distancia: " .. instantBring.config.TELEPORT_OFFSET .. " studs\n" ..
            "❄️ Congelar: " .. tostring(instantBring.config.FREEZE_NPC) .. "\n" ..
            "🟢 Estado: " .. (isBringingActive and "🔴 ACTIVO" or "⚪ INACTIVO") .. "\n" ..
            "═══════════════════════════════════════"
        )
    end
end)

-- ════════════════════════════════════════════════════════════════
-- PESTAÑA DE ATAJOS
-- ════════════════════════════════════════════════════════════════

local KeyBindTab = Window:CreateTab("⌨️ ATAJOS", 0)

KeyBindTab:CreateKeybind({
    Name = "⚡ Traer Todos (Insta)",
    CurrentKeybind = "R",
    HoldToInteract = false,
    Flag = "InstantBringKey",
    Callback = function(Keybind)
        local count = instantBring:BringAllNPCs()
        Rayfield:Notify({
            Title = "⚡ TRAÍDO",
            Content = count .. " NPCs traídos",
            Duration = 1
        })
    end
})

KeyBindTab:CreateKeybind({
    Name = "▶️/⏹️ Modo Continuo",
    CurrentKeybind = "T",
    HoldToInteract = false,
    Flag = "ContinuousKey",
    Callback = function(Keybind)
        isBringingActive = not isBringingActive
        if isBringingActive then
            instantBring:ContinuousBring()
            Rayfield:Notify({
                Title = "▶️ Activado",
                Content = "Modo continuo encendido",
                Duration = 1
            })
        else
            instantBring:Stop()
            Rayfield:Notify({
                Title = "⏹️ Desactivado",
                Content = "Modo continuo apagado",
                Duration = 1
            })
        end
    end
})

KeyBindTab:CreateKeybind({
    Name = "➕ Aumentar Radio",
    CurrentKeybind = "Up",
    HoldToInteract = false,
    Flag = "IncreaseRadiusKey",
    Callback = function(Keybind)
        local currentRadius = instantBring.config.BRING_RADIUS
        local newRadius = math.min(currentRadius + 20, 500)
        instantBring:SetConfig("BRING_RADIUS", newRadius)
        radiusSlider:Set(newRadius)
        Rayfield:Notify({
            Title = "📏 Radio",
            Content = newRadius .. " studs",
            Duration = 1
        })
    end
})

KeyBindTab:CreateKeybind({
    Name = "➖ Disminuir Radio",
    CurrentKeybind = "Down",
    HoldToInteract = false,
    Flag = "DecreaseRadiusKey",
    Callback = function(Keybind)
        local currentRadius = instantBring.config.BRING_RADIUS
        local newRadius = math.max(currentRadius - 20, 10)
        instantBring:SetConfig("BRING_RADIUS", newRadius)
        radiusSlider:Set(newRadius)
        Rayfield:Notify({
            Title = "📏 Radio",
            Content = newRadius .. " studs",
            Duration = 1
        })
    end
})

-- ════════════════════════════════════════════════════════════════
-- PESTAÑA DE PRESETS
-- ════════════════════════════════════════════════════════════════

local PresetsTab = Window:CreateTab("⚡ PRESETS", 0)

PresetsTab:CreateButton({
    Name = "🔪 Modo Duelo (Radio Pequeño)",
    Callback = function()
        instantBring:SetConfig("BRING_RADIUS", 50)
        instantBring:SetConfig("TELEPORT_OFFSET", 3)
        radiusSlider:Set(50)
        offsetSlider:Set(3)
        Rayfield:Notify({
            Title = "🔪 Modo Duelo",
            Content = "Radio: 50 | Distancia: 3",
            Duration = 2
        })
    end
})

PresetsTab:CreateButton({
    Name = "⚔️ Modo Combate Normal",
    Callback = function()
        instantBring:SetConfig("BRING_RADIUS", 100)
        instantBring:SetConfig("TELEPORT_OFFSET", 5)
        radiusSlider:Set(100)
        offsetSlider:Set(5)
        Rayfield:Notify({
            Title = "⚔️ Modo Combate",
            Content = "Radio: 100 | Distancia: 5",
            Duration = 2
        })
    end
})

PresetsTab:CreateButton({
    Name = "🌊 Modo Granja Total",
    Callback = function()
        instantBring:SetConfig("BRING_RADIUS", 250)
        instantBring:SetConfig("TELEPORT_OFFSET", 8)
        radiusSlider:Set(250)
        offsetSlider:Set(8)
        Rayfield:Notify({
            Title = "🌊 Modo Granja",
            Content = "Radio: 250 | Distancia: 8",
            Duration = 2
        })
    end
})

PresetsTab:CreateButton({
    Name = "🔥 MODO EXTREMO (MÁXIMO RANGO)",
    Callback = function()
        instantBring:SetConfig("BRING_RADIUS", 500)
        instantBring:SetConfig("TELEPORT_OFFSET", 10)
        radiusSlider:Set(500)
        offsetSlider:Set(10)
        Rayfield:Notify({
            Title = "🔥 MODO EXTREMO",
            Content = "¡TRAE TODOS LOS ENEMIGOS!",
            Duration = 2
        })
    end
})

-- ════════════════════════════════════════════════════════════════
-- PESTAÑA DE INFORMACIÓN
-- ════════════════════════════════════════════════════════════════

local InfoTab = Window:CreateTab("ℹ️ INFO", 0)

InfoTab:CreateLabel(
    "⚡ INSTANT BRING SYSTEM\n\n" ..
    "Sistema de atracción INSTANTÁNEA para Blox Fruits\n\n" ..
    "🎯 CARACTERÍSTICAS:\n" ..
    "✓ Trae NPCs INSTANTÁNEAMENTE\n" ..
    "✓ Modo continuo para granja\n" ..
    "✓ Radio configurable (10-500 studs)\n" ..
    "✓ Distancia al jugador personalizable\n" ..
    "✓ Opción de congelación\n" ..
    "✓ Atajos de teclado rápidos\n\n" ..
    "⌨️ CONTROLES:\n" ..
    "R - Traer todos (Instantáneo)\n" ..
    "T - Activar/Desactivar continuo\n" ..
    "↑ - Aumentar radio\n" ..
    "↓ - Disminuir radio\n\n" ..
    "⚠️ USO BAJO TU RESPONSABILIDAD"
)

InfoTab:CreateButton({
    Name = "📋 Ver Configuración",
    Callback = function()
        print("═══════════════════════════════════")
        print("CONFIGURACIÓN ACTUAL - INSTANT BRING")
        print("═══════════════════════════════════")
        for key, value in pairs(instantBring.config) do
            print(key .. ": " .. tostring(value))
        end
        print("═══════════════════════════════════")
    end
})

-- Notificación inicial
Rayfield:Notify({
    Title = "⚡ INSTANT BRING ACTIVADO",
    Content = "Presiona R para traer todos los NPCs instantáneamente",
    Duration = 4,
    Image = 4483362458
})

-- Actualizar cuando el jugador muere
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    if isBringingActive then
        instantBring:Stop()
        isBringingActive = false
        task.wait(0.5)
        instantBring:ContinuousBring()
        isBringingActive = true
    end
end)

return Window
