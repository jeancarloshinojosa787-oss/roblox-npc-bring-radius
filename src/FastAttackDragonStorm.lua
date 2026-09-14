--[[
    FAST ATTACK DRAGON STORM - Blox Fruits Delta
    Script de ataque rápido optimizado para Dragon Storm
    Coloca este script en StarterPlayer > StarterCharacterScripts
]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Variables del juego
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- ════════════════════════════════════════════════════════════════
-- SISTEMA DE FAST ATTACK DRAGON STORM
-- ════════════════════════════════════════════════════════════════

local FastAttack = {}
FastAttack.__index = FastAttack

function FastAttack.new(config)
    local self = setmetatable({}, FastAttack)
    self.config = config or {
        ATTACK_SPEED = 0.5,      -- Velocidad de ataque (0.1 a 1)
        AUTO_CLICK = true,       -- Activar clicks automáticos
        DRAGON_STORM_DELAY = 0.1, -- Delay entre Dragon Storms
        COMBO_MODE = true,       -- Combo de ataques
        TARGET_RANGE = 50,       -- Rango de detección de enemigos
        AUTO_MOVE_TO_TARGET = true, -- Moverse automáticamente al enemigo
        MOVEMENT_SPEED = 2,      -- Velocidad de movimiento
        AUTO_SWITCH_ABILITY = true  -- Cambiar automáticamente a Dragon Storm
    }
    self.isRunning = false
    self.lastAttackTime = 0
    self.lastDragonStormTime = 0
    self.currentTarget = nil
    self.attackCount = 0
    return self
end

function FastAttack:FindNearestEnemy()
    if not character:FindFirstChild("HumanoidRootPart") then return nil end
    
    local playerPos = character.HumanoidRootPart.Position
    local nearestEnemy = nil
    local nearestDistance = self.config.TARGET_RANGE
    
    -- Buscar enemigos en el workspace
    for _, npc in pairs(workspace:GetDescendants()) do
        if npc:IsA("Model") and npc:FindFirstChild("Humanoid") and npc:FindFirstChild("HumanoidRootPart") then
            if npc.Parent ~= character and not Players:FindFirstChild(npc.Name) then
                local npcPos = npc.HumanoidRootPart.Position
                local distance = (playerPos - npcPos).Magnitude
                
                if distance < nearestDistance and npc.Humanoid.Health > 0 then
                    nearestDistance = distance
                    nearestEnemy = npc
                end
            end
        end
    end
    
    return nearestEnemy
end

function FastAttack:MoveToTarget(target)
    if not character:FindFirstChild("HumanoidRootPart") or not target:FindFirstChild("HumanoidRootPart") then return end
    
    local playerHRP = character.HumanoidRootPart
    local targetPos = target.HumanoidRootPart.Position
    local direction = (targetPos - playerHRP.Position).Unit
    
    -- Mover hacia el enemigo
    local newPos = playerHRP.Position + direction * self.config.MOVEMENT_SPEED
    playerHRP.CFrame = CFrame.new(newPos)
end

function FastAttack:PerformAttack()
    local currentTime = tick()
    
    if currentTime - self.lastAttackTime < self.config.ATTACK_SPEED then
        return
    end
    
    self.lastAttackTime = currentTime
    
    -- Simular click del mouse para ataque
    if self.config.AUTO_CLICK then
        local mouse = player:GetMouse()
        mouse:SendMouseMovement(0, 0)
        game:GetService("VirtualUser"):CaptureController()
        game:GetService("VirtualUser"):Button1Down(Vector2.new(
            math.random(100, game:GetService("RunService").RenderStepped:Wait() and 1920 or 1024),
            math.random(100, game:GetService("RunService").RenderStepped:Wait() and 1080 or 768)
        ))
        task.wait(0.05)
        game:GetService("VirtualUser"):Button1Up()
    end
    
    self.attackCount = self.attackCount + 1
end

function FastAttack:UseDragonStorm()
    local currentTime = tick()
    
    if currentTime - self.lastDragonStormTime < self.config.DRAGON_STORM_DELAY then
        return
    end
    
    self.lastDragonStormTime = currentTime
    
    -- Llamar a la habilidad Dragon Storm
    local remoteEvent = player:WaitForChild("PlayerGui"):FindFirstChild("RemoteEvent")
    if remoteEvent then
        remoteEvent:FireServer("DragonStorm")
    end
    
    -- Alternativa: Usar tecla X para activar habilidad
    UserInputService:SendKeyEvent(true, Enum.KeyCode.X, false)
    task.wait(0.05)
    UserInputService:SendKeyEvent(false, Enum.KeyCode.X, false)
end

function FastAttack:StartContinuousAttack()
    self.isRunning = true
    
    self._connection = RunService.RenderStepped:Connect(function()
        if not self.isRunning or not character:FindFirstChild("HumanoidRootPart") then return end
        
        local target = self:FindNearestEnemy()
        
        if target then
            self.currentTarget = target
            
            -- Mover hacia el enemigo
            if self.config.AUTO_MOVE_TO_TARGET then
                self:MoveToTarget(target)
            end
            
            -- Realizar ataque normal
            self:PerformAttack()
            
            -- Usar Dragon Storm
            if self.config.COMBO_MODE then
                self:UseDragonStorm()
            end
        end
    end)
end

function FastAttack:Stop()
    if self._connection then
        self._connection:Disconnect()
    end
    self.isRunning = false
    self.attackCount = 0
end

function FastAttack:SetConfig(key, value)
    if self.config[key] ~= nil then
        self.config[key] = value
        return true
    end
    return false
end

function FastAttack:GetStats()
    return {
        attackCount = self.attackCount,
        attackSpeed = self.config.ATTACK_SPEED,
        targetRange = self.config.TARGET_RANGE,
        movementSpeed = self.config.MOVEMENT_SPEED,
        hasTarget = self.currentTarget ~= nil,
        targetName = self.currentTarget and self.currentTarget.Name or "Ninguno"
    }
end

-- Crear instancia del sistema
local fastAttack = FastAttack.new({
    ATTACK_SPEED = 0.5,
    AUTO_CLICK = true,
    DRAGON_STORM_DELAY = 0.1,
    COMBO_MODE = true,
    TARGET_RANGE = 50,
    AUTO_MOVE_TO_TARGET = true,
    MOVEMENT_SPEED = 2,
    AUTO_SWITCH_ABILITY = true
})

-- ════════════════════════════════════════════════════════════════
-- INTERFAZ RAYFIELD
-- ════════════════════════════════════════════════════════════════

local Window = Rayfield:CreateWindow({
    Name = "⚔️ Fast Attack Dragon Storm - Blox Fruits",
    LoadingTitle = "Cargando...",
    LoadingSubtitle = "Sistema de Ataque Rápido Dragon Storm",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "BloxFruitsFastAttack",
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

local MainTab = Window:CreateTab("⚔️ ATAQUE RÁPIDO", 0)

local MainSection = MainTab:CreateSection("🎯 CONTROL DE ATAQUE")

local isAttackActive = false

MainTab:CreateButton({
    Name = "▶️ INICIAR ATAQUE RÁPIDO",
    Callback = function()
        if not isAttackActive then
            fastAttack:StartContinuousAttack()
            isAttackActive = true
            Rayfield:Notify({
                Title = "⚔️ Ataque Iniciado",
                Content = "Sistema de ataque rápido activado",
                Duration = 2,
                Image = 4483362458
            })
        end
    end
})

MainTab:CreateButton({
    Name = "⏹️ DETENER ATAQUE",
    Callback = function()
        if isAttackActive then
            fastAttack:Stop()
            isAttackActive = false
            Rayfield:Notify({
                Title = "⏹️ Ataque Detenido",
                Content = "Sistema desactivado",
                Duration = 2,
                Image = 4483362458
            })
        end
    end
})

-- Sección de Configuración
local ConfigSection = MainTab:CreateSection("⚙️ CONFIGURACIÓN DE ATAQUE")

local speedSlider = MainTab:CreateSlider({
    Name = "⚡ Velocidad de Ataque",
    Range = {0.1, 1},
    Increment = 0.1,
    Suffix = "x",
    CurrentValue = 0.5,
    Flag = "SpeedSlider",
    Callback = function(Value)
        fastAttack:SetConfig("ATTACK_SPEED", Value)
    end
})

local dragonStormDelaySlider = MainTab:CreateSlider({
    Name = "🐉 Delay Dragon Storm",
    Range = {0.05, 0.5},
    Increment = 0.05,
    Suffix = "s",
    CurrentValue = 0.1,
    Flag = "DragonStormDelaySlider",
    Callback = function(Value)
        fastAttack:SetConfig("DRAGON_STORM_DELAY", Value)
    end
})

local rangeSlider = MainTab:CreateSlider({
    Name = "📏 Rango de Detección",
    Range = {10, 200},
    Increment = 10,
    Suffix = " studs",
    CurrentValue = 50,
    Flag = "RangeSlider",
    Callback = function(Value)
        fastAttack:SetConfig("TARGET_RANGE", Value)
    end
})

local movementSpeedSlider = MainTab:CreateSlider({
    Name = "🏃 Velocidad de Movimiento",
    Range = {0.5, 5},
    Increment = 0.5,
    Suffix = "x",
    CurrentValue = 2,
    Flag = "MovementSpeedSlider",
    Callback = function(Value)
        fastAttack:SetConfig("MOVEMENT_SPEED", Value)
    end
})

-- Sección de Características
local FeaturesSection = MainTab:CreateSection("🌟 CARACTERÍSTICAS")

MainTab:CreateToggle({
    Name = "🖱️ Auto Click",
    CurrentValue = true,
    Flag = "AutoClickToggle",
    Callback = function(Value)
        fastAttack:SetConfig("AUTO_CLICK", Value)
    end
})

MainTab:CreateToggle({
    Name = "🐉 Combo Dragon Storm",
    CurrentValue = true,
    Flag = "ComboToggle",
    Callback = function(Value)
        fastAttack:SetConfig("COMBO_MODE", Value)
    end
})

MainTab:CreateToggle({
    Name = "🎯 Auto Mover a Enemigo",
    CurrentValue = true,
    Flag = "AutoMoveToggle",
    Callback = function(Value)
        fastAttack:SetConfig("AUTO_MOVE_TO_TARGET", Value)
    end
})

MainTab:CreateToggle({
    Name = "⚙️ Cambiar Habilidad Auto",
    CurrentValue = true,
    Flag = "AutoSwitchToggle",
    Callback = function(Value)
        fastAttack:SetConfig("AUTO_SWITCH_ABILITY", Value)
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
        local stats = fastAttack:GetStats()
        
        statsLabel:Set(
            "═══════════════════════════════════════\n" ..
            "📊 INFORMACIÓN EN TIEMPO REAL\n" ..
            "═══════════════════════════════════════\n\n" ..
            "⚔️ Ataques Realizados: " .. stats.attackCount .. "\n" ..
            "⚡ Velocidad Ataque: " .. string.format("%.1f", stats.attackSpeed) .. "x\n" ..
            "📏 Rango: " .. stats.targetRange .. " studs\n" ..
            "🏃 Velocidad Movimiento: " .. string.format("%.1f", stats.movementSpeed) .. "x\n" ..
            "🎯 Objetivo Actual: " .. stats.targetName .. "\n" ..
            "🐉 Estado: " .. (stats.hasTarget and "✅ ATACANDO" or "❌ BUSCANDO") .. "\n" ..
            "🟢 Estado Sistema: " .. (isAttackActive and "🔴 ACTIVO" or "⚪ INACTIVO") .. "\n" ..
            "═══════════════════════════════════════"
        )
    end
end)

-- ════════════════════════════════════════════════════════════════
-- PESTAÑA DE ATAJOS
-- ════════════════════════════════════════════════════════════════

local KeyBindTab = Window:CreateTab("⌨️ ATAJOS", 0)

KeyBindTab:CreateKeybind({
    Name = "⚔️ Iniciar/Parar Ataque",
    CurrentKeybind = "V",
    HoldToInteract = false,
    Flag = "ToggleAttackKey",
    Callback = function(Keybind)
        isAttackActive = not isAttackActive
        if isAttackActive then
            fastAttack:StartContinuousAttack()
            Rayfield:Notify({
                Title = "⚔️ Activado",
                Content = "Ataque rápido iniciado",
                Duration = 1
            })
        else
            fastAttack:Stop()
            Rayfield:Notify({
                Title = "⏹️ Desactivado",
                Content = "Ataque detenido",
                Duration = 1
            })
        end
    end
})

KeyBindTab:CreateKeybind({
    Name = "⚡ Aumentar Velocidad",
    CurrentKeybind = "Up",
    HoldToInteract = false,
    Flag = "IncreaseSpeedKey",
    Callback = function(Keybind)
        local currentSpeed = fastAttack.config.ATTACK_SPEED
        local newSpeed = math.min(currentSpeed + 0.1, 1)
        fastAttack:SetConfig("ATTACK_SPEED", newSpeed)
        speedSlider:Set(newSpeed)
        Rayfield:Notify({
            Title = "⚡ Velocidad",
            Content = string.format("%.1f", newSpeed) .. "x",
            Duration = 1
        })
    end
})

KeyBindTab:CreateKeybind({
    Name = "🔽 Disminuir Velocidad",
    CurrentKeybind = "Down",
    HoldToInteract = false,
    Flag = "DecreaseSpeedKey",
    Callback = function(Keybind)
        local currentSpeed = fastAttack.config.ATTACK_SPEED
        local newSpeed = math.max(currentSpeed - 0.1, 0.1)
        fastAttack:SetConfig("ATTACK_SPEED", newSpeed)
        speedSlider:Set(newSpeed)
        Rayfield:Notify({
            Title = "⚡ Velocidad",
            Content = string.format("%.1f", newSpeed) .. "x",
            Duration = 1
        })
    end
})

KeyBindTab:CreateKeybind({
    Name = "🐉 Usar Dragon Storm",
    CurrentKeybind = "X",
    HoldToInteract = false,
    Flag = "DragonStormKey",
    Callback = function(Keybind)
        fastAttack:UseDragonStorm()
        Rayfield:Notify({
            Title = "🐉 Dragon Storm",
            Content = "Habilidad activada",
            Duration = 1
        })
    end
})

-- ════════════════════════════════════════════════════════════════
-- PESTAÑA DE PRESETS
-- ════════════════════════════════════════════════════════════════

local PresetsTab = Window:CreateTab("⚡ PRESETS", 0)

PresetsTab:CreateButton({
    Name = "🐢 Modo Lento (Preciso)",
    Callback = function()
        fastAttack:SetConfig("ATTACK_SPEED", 0.3)
        fastAttack:SetConfig("DRAGON_STORM_DELAY", 0.2)
        fastAttack:SetConfig("MOVEMENT_SPEED", 1)
        speedSlider:Set(0.3)
        dragonStormDelaySlider:Set(0.2)
        movementSpeedSlider:Set(1)
        Rayfield:Notify({
            Title = "🐢 Modo Lento",
            Content = "Ataques precisos",
            Duration = 2
        })
    end
})

PresetsTab:CreateButton({
    Name = "🚗 Modo Normal",
    Callback = function()
        fastAttack:SetConfig("ATTACK_SPEED", 0.5)
        fastAttack:SetConfig("DRAGON_STORM_DELAY", 0.1)
        fastAttack:SetConfig("MOVEMENT_SPEED", 2)
        speedSlider:Set(0.5)
        dragonStormDelaySlider:Set(0.1)
        movementSpeedSlider:Set(2)
        Rayfield:Notify({
            Title = "🚗 Modo Normal",
            Content = "Equilibrado",
            Duration = 2
        })
    end
})

PresetsTab:CreateButton({
    Name = "⚡ Modo Rápido",
    Callback = function()
        fastAttack:SetConfig("ATTACK_SPEED", 0.2)
        fastAttack:SetConfig("DRAGON_STORM_DELAY", 0.05)
        fastAttack:SetConfig("MOVEMENT_SPEED", 3.5)
        speedSlider:Set(0.2)
        dragonStormDelaySlider:Set(0.05)
        movementSpeedSlider:Set(3.5)
        Rayfield:Notify({
            Title = "⚡ Modo Rápido",
            Content = "Ataque muy rápido",
            Duration = 2
        })
    end
})

PresetsTab:CreateButton({
    Name = "🔥 Modo Extremo (Máximo)",
    Callback = function()
        fastAttack:SetConfig("ATTACK_SPEED", 0.1)
        fastAttack:SetConfig("DRAGON_STORM_DELAY", 0.05)
        fastAttack:SetConfig("MOVEMENT_SPEED", 5)
        fastAttack:SetConfig("TARGET_RANGE", 150)
        speedSlider:Set(0.1)
        dragonStormDelaySlider:Set(0.05)
        movementSpeedSlider:Set(5)
        rangeSlider:Set(150)
        Rayfield:Notify({
            Title = "🔥 Modo Extremo",
            Content = "¡MÁXIMA VELOCIDAD!",
            Duration = 2
        })
    end
})

PresetsTab:CreateButton({
    Name = "🐉 Modo Dragon Storm Puro",
    Callback = function()
        fastAttack:SetConfig("ATTACK_SPEED", 0.2)
        fastAttack:SetConfig("DRAGON_STORM_DELAY", 0.08)
        fastAttack:SetConfig("COMBO_MODE", true)
        fastAttack:SetConfig("AUTO_CLICK", false)
        speedSlider:Set(0.2)
        dragonStormDelaySlider:Set(0.08)
        Rayfield:Notify({
            Title = "🐉 Dragon Storm Puro",
            Content = "Solo Dragon Storm repetido",
            Duration = 2
        })
    end
})

-- ════════════════════════════════════════════════════════════════
-- PESTAÑA DE INFORMACIÓN
-- ════════════════════════════════════════════════════════════════

local InfoTab = Window:CreateTab("ℹ️ INFO", 0)

InfoTab:CreateLabel(
    "⚔️ FAST ATTACK DRAGON STORM\n\n" ..
    "Sistema de ataque rápido optimizado para Blox Fruits Delta\n" ..
    "Especializado en Dragon Storm\n\n" ..
    "🎯 CARACTERÍSTICAS:\n" ..
    "✓ Ataque automático ultra rápido\n" ..
    "✓ Dragon Storm automático\n" ..
    "✓ Movimiento inteligente\n" ..
    "✓ Detección automática de enemigos\n" ..
    "✓ Múltiples presets\n" ..
    "✓ Control total de velocidades\n\n" ..
    "⌨️ CONTROLES:\n" ..
    "V - Activar/Desactivar ataque\n" ..
    "X - Usar Dragon Storm\n" ..
    "↑/↓ - Cambiar velocidad\n\n" ..
    "💡 TIPS:\n" ..
    "• Usa modo rápido para granjas\n" ..
    "• Usa modo lento para precisión\n" ..
    "• Asegúrate de tener Dragon Storm equipado\n\n" ..
    "⚠️ USO BAJO TU RESPONSABILIDAD"
)

InfoTab:CreateButton({
    Name = "📋 Ver Configuración",
    Callback = function()
        print("═══════════════════════════════════")
        print("CONFIGURACIÓN ACTUAL - FAST ATTACK")
        print("═══════════════════════════════════")
        for key, value in pairs(fastAttack.config) do
            print(key .. ": " .. tostring(value))
        end
        print("═══════════════════════════════════")
    end
})

-- Notificación inicial
Rayfield:Notify({
    Title = "⚔️ FAST ATTACK DRAGON STORM",
    Content = "Presiona V para iniciar el ataque rápido",
    Duration = 4,
    Image = 4483362458
})

-- Actualizar cuando el jugador muere
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    if isAttackActive then
        fastAttack:Stop()
        isAttackActive = false
        task.wait(0.5)
        fastAttack:StartContinuousAttack()
        isAttackActive = true
    end
end)

return Window
