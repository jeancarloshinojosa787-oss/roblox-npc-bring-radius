--[[
    COMBO SUPREMO: INSTANT BRING + FAST ATTACK CUSTOMIZADO
    Blox Fruits Delta - Atracción de NPCs + Ataque Rápido Simultáneo
    Coloca este script en StarterPlayer > StarterCharacterScripts
]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Variables del juego
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- ════════════════════════════════════════════════════════════════
-- SISTEMA DE FAST ATTACK PERSONALIZADO
-- ════════════════════════════════════════════════════════════════

local FastAttackCustom = {}
FastAttackCustom.__index = FastAttackCustom

function FastAttackCustom.new(config)
    local self = setmetatable({}, FastAttackCustom)
    self.config = config or {
        ENABLED = false,
        RANGE = 1200,
        ATTACK_SPEED = 0.01,
        USE_REMOTE = true
    }
    self.connection = nil
    return self
end

function FastAttackCustom:GetRemotes()
    local Net = ReplicatedStorage:FindFirstChild("Modules")
    if Net then
        Net = Net:FindFirstChild("Net")
        if Net then
            return Net:FindFirstChild("RE/RegisterHit"), Net:FindFirstChild("RE/RegisterAttack")
        end
    end
    return nil, nil
end

function FastAttackCustom:AttackMultipleTargets(targets)
    pcall(function()
        if not targets or #targets == 0 then return end

        local RegisterHit, RegisterAttack = self:GetRemotes()
        if not RegisterHit or not RegisterAttack then return end

        local allTargets = {}

        for _, targetChar in pairs(targets) do
            local head = targetChar:FindFirstChild("Head")
            if head then
                table.insert(allTargets, { targetChar, head })
            end
        end

        if #allTargets == 0 then return end

        RegisterAttack:FireServer(0)

        local hitArgs = {
            allTargets[1][2],
            allTargets
        }

        RegisterHit:FireServer(unpack(hitArgs))
    end)
end

function FastAttackCustom:FindTargetsInRange()
    if not character:FindFirstChild("HumanoidRootPart") then return {} end
    
    local myHRP = character.HumanoidRootPart
    local targetsInRange = {}

    -- Buscar jugadores
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")

            if humanoid and hrp and humanoid.Health > 0 then
                local dist = (hrp.Position - myHRP.Position).Magnitude
                if dist <= self.config.RANGE then
                    table.insert(targetsInRange, player.Character)
                end
            end
        end
    end

    -- Buscar NPCs
    local enemiesFolder = workspace:FindFirstChild("Enemies")
    if enemiesFolder then
        for _, npc in pairs(enemiesFolder:GetChildren()) do
            local humanoid = npc:FindFirstChild("Humanoid")
            local hrp = npc:FindFirstChild("HumanoidRootPart")

            if humanoid and hrp and humanoid.Health > 0 then
                local dist = (hrp.Position - myHRP.Position).Magnitude
                if dist <= self.config.RANGE then
                    table.insert(targetsInRange, npc)
                end
            end
        end
    end

    return targetsInRange
end

function FastAttackCustom:Start()
    if self.connection then return end
    
    self.connection = task.spawn(function()
        while self.config.ENABLED do
            task.wait(self.config.ATTACK_SPEED)

            local targets = self:FindTargetsInRange()
            if #targets > 0 then
                self:AttackMultipleTargets(targets)
            end
        end
    end)
end

function FastAttackCustom:Stop()
    if self.connection then
        task.cancel(self.connection)
        self.connection = nil
    end
end

function FastAttackCustom:SetConfig(key, value)
    if self.config[key] ~= nil then
        self.config[key] = value
        return true
    end
    return false
end

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
        FREEZE_NPC = false,
        BATCH_SIZE = 10,
        BATCH_DELAY = 0.01
    }
    self.isRunning = false
    self.bringCount = 0
    self.npcCache = {}
    self.lastCacheTime = 0
    return self
end

function InstantBring:UpdateNPCCache()
    local currentTime = tick()
    if currentTime - self.lastCacheTime < 0.1 then
        return self.npcCache
    end
    
    self.lastCacheTime = currentTime
    self.npcCache = {}
    
    if not character:FindFirstChild("HumanoidRootPart") then return {} end
    
    local playerPos = character.HumanoidRootPart.Position
    
    for _, npc in pairs(workspace:GetDescendants()) do
        if npc:IsA("Model") and npc:FindFirstChild("Humanoid") and npc:FindFirstChild("HumanoidRootPart") then
            if npc.Parent ~= character and not Players:FindFirstChild(npc.Name) then
                local npcPos = npc.HumanoidRootPart.Position
                local distance = (playerPos - npcPos).Magnitude
                
                if distance < self.config.BRING_RADIUS and npc.Humanoid.Health > 0 then
                    table.insert(self.npcCache, npc)
                end
            end
        end
    end
    
    return self.npcCache
end

function InstantBring:BringAllNPCsOptimized()
    if not character:FindFirstChild("HumanoidRootPart") then return 0 end
    
    local playerPos = character.HumanoidRootPart.Position
    local bringCount = 0
    
    local npcsInRange = self:UpdateNPCCache()
    
    for i, npc in pairs(npcsInRange) do
        if i % self.config.BATCH_SIZE == 0 then
            task.wait(self.config.BATCH_DELAY)
        end
        
        if npc:FindFirstChild("HumanoidRootPart") and npc:FindFirstChild("Humanoid") then
            if npc.Humanoid.Health > 0 then
                local offset = npc.HumanoidRootPart.Position - playerPos
                local direction = offset.Unit
                
                local newPos = playerPos + direction * self.config.TELEPORT_OFFSET
                npc.HumanoidRootPart.CFrame = CFrame.new(newPos)
                
                if self.config.FREEZE_NPC then
                    npc.HumanoidRootPart.CanCollide = false
                    npc.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
                end
                
                bringCount = bringCount + 1
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
        self:BringAllNPCsOptimized()
    end)
end

function InstantBring:Stop()
    if self._connection then
        self._connection:Disconnect()
    end
    self.isRunning = false
end

function InstantBring:GetNPCCount()
    return #self:UpdateNPCCache()
end

function InstantBring:SetConfig(key, value)
    if self.config[key] ~= nil then
        self.config[key] = value
        return true
    end
    return false
end

-- Crear instancias
local instantBring = InstantBring.new({
    BRING_RADIUS = 100,
    INSTANT_MODE = true,
    TELEPORT_OFFSET = 5,
    FREEZE_NPC = false,
    BATCH_SIZE = 10,
    BATCH_DELAY = 0.01
})

local fastAttack = FastAttackCustom.new({
    ENABLED = false,
    RANGE = 1200,
    ATTACK_SPEED = 0.01,
    USE_REMOTE = true
})

-- ════════════════════════════════════════════════════════════════
-- INTERFAZ RAYFIELD
-- ════════════════════════════════════════════════════════════════

local Window = Rayfield:CreateWindow({
    Name = "⚡ COMBO SUPREMO - Bring + Fast Attack",
    LoadingTitle = "Cargando...",
    LoadingSubtitle = "Sistema Completo Blox Fruits",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "BloxFruitsCombo",
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

local MainTab = Window:CreateTab("⚡ CONTROL PRINCIPAL", 0)

local isBringingActive = false
local isAttackingActive = false

local MainSection = MainTab:CreateSection("🎯 CONTROL RÁPIDO")

MainTab:CreateButton({
    Name = "🚀 ACTIVAR TODO (Bring + Attack)",
    Callback = function()
        if not isBringingActive then
            instantBring:ContinuousBring()
            isBringingActive = true
        end
        if not isAttackingActive then
            fastAttack.config.ENABLED = true
            fastAttack:Start()
            isAttackingActive = true
        end
        Rayfield:Notify({
            Title = "🚀 ACTIVADO",
            Content = "Bring + Fast Attack en funcionamiento",
            Duration = 2,
            Image = 4483362458
        })
    end
})

MainTab:CreateButton({
    Name = "⏹️ DETENER TODO",
    Callback = function()
        instantBring:Stop()
        isBringingActive = false
        fastAttack.config.ENABLED = false
        fastAttack:Stop()
        isAttackingActive = false
        Rayfield:Notify({
            Title = "⏹️ DETENIDO",
            Content = "Todos los sistemas desactivados",
            Duration = 2,
            Image = 4483362458
        })
    end
})

-- Sección BRING
local BringSection = MainTab:CreateSection("📍 ATRACCIÓN DE NPCs")

MainTab:CreateButton({
    Name = "📍 TRAER NPCs",
    Callback = function()
        if not isBringingActive then
            instantBring:ContinuousBring()
            isBringingActive = true
            Rayfield:Notify({
                Title = "📍 Bring Activado",
                Content = "Trayendo NPCs...",
                Duration = 1,
                Image = 4483362458
            })
        end
    end
})

MainTab:CreateButton({
    Name = "⏹️ Parar Bring",
    Callback = function()
        if isBringingActive then
            instantBring:Stop()
            isBringingActive = false
            Rayfield:Notify({
                Title = "⏹️ Bring Detenido",
                Content = "NPCs dejarán de moverse",
                Duration = 1,
                Image = 4483362458
            })
        end
    end
})

-- Sección ATTACK
local AttackSection = MainTab:CreateSection("⚔️ ATAQUE RÁPIDO")

MainTab:CreateButton({
    Name = "⚔️ ATACAR",
    Callback = function()
        if not isAttackingActive then
            fastAttack.config.ENABLED = true
            fastAttack:Start()
            isAttackingActive = true
            Rayfield:Notify({
                Title = "⚔️ Ataque Activado",
                Content = "Atacando enemigos...",
                Duration = 1,
                Image = 4483362458
            })
        end
    end
})

MainTab:CreateButton({
    Name = "⏹️ Parar Ataque",
    Callback = function()
        if isAttackingActive then
            fastAttack.config.ENABLED = false
            fastAttack:Stop()
            isAttackingActive = false
            Rayfield:Notify({
                Title = "⏹️ Ataque Detenido",
                Content = "Ataques pausados",
                Duration = 1,
                Image = 4483362458
            })
        end
    end
})

-- ════════════════════════════════════════════════════════════════
-- PESTAÑA DE CONFIGURACIÓN
-- ════════════════════════════════════════════════════════════════

local ConfigTab = Window:CreateTab("⚙️ CONFIGURACIÓN", 0)

local ConfigBringSection = ConfigTab:CreateSection("📍 Configuración Bring")

local radiusSlider = ConfigTab:CreateSlider({
    Name = "📏 Radio Bring",
    Range = {10, 500},
    Increment = 10,
    Suffix = " studs",
    CurrentValue = 100,
    Flag = "RadiusSlider",
    Callback = function(Value)
        instantBring:SetConfig("BRING_RADIUS", Value)
    end
})

local offsetSlider = ConfigTab:CreateSlider({
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

local batchSlider = ConfigTab:CreateSlider({
    Name = "📦 Tamaño de Lote",
    Range = {5, 50},
    Increment = 5,
    Suffix = " NPCs",
    CurrentValue = 10,
    Flag = "BatchSlider",
    Callback = function(Value)
        instantBring:SetConfig("BATCH_SIZE", Value)
    end
})

local ConfigAttackSection = ConfigTab:CreateSection("⚔️ Configuración Ataque")

local attackRangeSlider = ConfigTab:CreateSlider({
    Name = "📏 Rango Ataque",
    Range = {100, 2000},
    Increment = 100,
    Suffix = " studs",
    CurrentValue = 1200,
    Flag = "AttackRangeSlider",
    Callback = function(Value)
        fastAttack:SetConfig("RANGE", Value)
    end
})

local attackSpeedSlider = ConfigTab:CreateSlider({
    Name = "⚡ Velocidad Ataque",
    Range = {0.001, 0.1},
    Increment = 0.001,
    Suffix = "s",
    CurrentValue = 0.01,
    Flag = "AttackSpeedSlider",
    Callback = function(Value)
        fastAttack:SetConfig("ATTACK_SPEED", Value)
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
            "📍 NPCs en Rango: " .. npcCount .. "\n" ..
            "📏 Radio Bring: " .. instantBring.config.BRING_RADIUS .. " studs\n" ..
            "📍 Distancia: " .. instantBring.config.TELEPORT_OFFSET .. " studs\n" ..
            "⚔️ Rango Ataque: " .. fastAttack.config.RANGE .. " studs\n" ..
            "⚡ Velocidad Ataque: " .. string.format("%.4f", fastAttack.config.ATTACK_SPEED) .. "s\n" ..
            "🟢 Bring: " .. (isBringingActive and "✅ ACTIVO" or "❌ INACTIVO") .. "\n" ..
            "⚔️ Ataque: " .. (isAttackingActive and "✅ ACTIVO" or "❌ INACTIVO") .. "\n" ..
            "═══════════════════════════════════════"
        )
    end
end)

-- ════════════════════════════════════════════════════════════════
-- PESTAÑA DE ATAJOS
-- ════════════════════════════════════════════════════════════════

local KeyBindTab = Window:CreateTab("⌨️ ATAJOS", 0)

KeyBindTab:CreateKeybind({
    Name = "🚀 Activar/Desactivar TODO",
    CurrentKeybind = "U",
    HoldToInteract = false,
    Flag = "ToggleAllKey",
    Callback = function(Keybind)
        if isBringingActive or isAttackingActive then
            instantBring:Stop()
            isBringingActive = false
            fastAttack.config.ENABLED = false
            fastAttack:Stop()
            isAttackingActive = false
            Rayfield:Notify({
                Title = "⏹️ Detenido",
                Content = "Todos los sistemas apagados",
                Duration = 1
            })
        else
            instantBring:ContinuousBring()
            isBringingActive = true
            fastAttack.config.ENABLED = true
            fastAttack:Start()
            isAttackingActive = true
            Rayfield:Notify({
                Title = "🚀 Activado",
                Content = "Bring + Attack en funcionamiento",
                Duration = 1
            })
        end
    end
})

KeyBindTab:CreateKeybind({
    Name = "📍 Toggle Bring",
    CurrentKeybind = "R",
    HoldToInteract = false,
    Flag = "ToggleBringKey",
    Callback = function(Keybind)
        isBringingActive = not isBringingActive
        if isBringingActive then
            instantBring:ContinuousBring()
        else
            instantBring:Stop()
        end
    end
})

KeyBindTab:CreateKeybind({
    Name = "⚔️ Toggle Attack",
    CurrentKeybind = "T",
    HoldToInteract = false,
    Flag = "ToggleAttackKey",
    Callback = function(Keybind)
        isAttackingActive = not isAttackingActive
        fastAttack.config.ENABLED = isAttackingActive
        if isAttackingActive then
            fastAttack:Start()
        else
            fastAttack:Stop()
        end
    end
})

KeyBindTab:CreateKeybind({
    Name = "➕ Aumentar Rango",
    CurrentKeybind = "Up",
    HoldToInteract = false,
    Flag = "IncreaseRangeKey",
    Callback = function(Keybind)
        local newRange = math.min(instantBring.config.BRING_RADIUS + 20, 500)
        instantBring:SetConfig("BRING_RADIUS", newRange)
        radiusSlider:Set(newRange)
    end
})

KeyBindTab:CreateKeybind({
    Name = "➖ Disminuir Rango",
    CurrentKeybind = "Down",
    HoldToInteract = false,
    Flag = "DecreaseRangeKey",
    Callback = function(Keybind)
        local newRange = math.max(instantBring.config.BRING_RADIUS - 20, 10)
        instantBring:SetConfig("BRING_RADIUS", newRange)
        radiusSlider:Set(newRange)
    end
})

-- ════════════════════════════════════════════════════════════════
-- PESTAÑA DE INFORMACIÓN
-- ════════════════════════════════════════════════════════════════

local InfoTab = Window:CreateTab("ℹ️ INFORMACIÓN", 0)

InfoTab:CreateLabel(
    "⚡ COMBO SUPREMO\n\n" ..
    "Sistema completo para Blox Fruits Delta\n" ..
    "BRING + FAST ATTACK SIMULTÁNEO\n\n" ..
    "🎯 CARACTERÍSTICAS:\n" ..
    "✓ Atracción de NPCs instantánea\n" ..
    "✓ Fast Attack con remotes personalizados\n" ..
    "✓ Detección de jugadores y NPCs\n" ..
    "✓ Control total de velocidades\n" ..
    "✓ Atajos de teclado\n" ..
    "✓ Estadísticas en vivo\n\n" ..
    "⌨️ CONTROLES:\n" ..
    "U - Activar/Desactivar TODO\n" ..
    "R - Toggle Bring\n" ..
    "T - Toggle Attack\n" ..
    "↑/↓ - Ajustar rango\n\n" ..
    "⚠️ USO BAJO TU RESPONSABILIDAD"
)

-- Notificación inicial
Rayfield:Notify({
    Title = "⚡ COMBO SUPREMO CARGADO",
    Content = "Presiona U para activar todo",
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
    if isAttackingActive then
        fastAttack:Stop()
        isAttackingActive = false
        task.wait(0.5)
        fastAttack:Start()
        isAttackingActive = true
    end
end)

return Window
