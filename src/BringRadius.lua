--[[
    BringRadius Module
    Sistema de atracción de NPCs con ejecución basada en delta time
    Coloca este módulo en ServerScriptService o ReplicatedStorage
]]

local BringRadius = {}
BringRadius.__index = BringRadius

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Constantes
local DEFAULT_CONFIG = {
    BRING_RADIUS = 50,
    ATTRACTION_SPEED = 0.5,
    USE_DELTA_TIME = true,
    MAX_SPEED = 100,
    ENABLE_ROTATION = true,
    ROTATION_SPEED = 0.1
}

--[[
    Crear nueva instancia de BringRadius
    @param config table - Configuración personalizada
    @return BringRadius
]]
function BringRadius.new(config)
    local self = setmetatable({}, BringRadius)
    
    self.config = setmetatable(config or {}, {__index = DEFAULT_CONFIG})
    self.activeNPCs = {}
    self.lastUpdateTime = tick()
    self.isRunning = false
    
    return self
end

--[[
    Calcular delta time (tiempo transcurrido desde la última actualización)
    @return number - Delta time en segundos
]]
function BringRadius:GetDeltaTime()
    local currentTime = tick()
    local deltaTime = currentTime - self.lastUpdateTime
    self.lastUpdateTime = currentTime
    return deltaTime
end

--[[
    Atraer NPC hacia un jugador con delta time
    @param npc table - Objeto NPC
    @param player Player - Jugador objetivo
    @param deltaTime number - Tiempo transcurrido
]]
function BringRadius:AttractNPCDelta(npc, player, deltaTime)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local playerPos = player.Character.HumanoidRootPart.Position
    local npcPos = npc.humanoidRootPart.Position
    local direction = (playerPos - npcPos)
    local distance = direction.Magnitude
    
    if distance == 0 then return end
    
    -- Normalizar dirección
    local directionUnit = direction.Unit
    
    -- Calcular velocidad basada en delta time
    local speed = self.config.ATTRACTION_SPEED * 10 -- Convertir a studs/segundo
    if self.config.USE_DELTA_TIME then
        speed = math.min(speed * deltaTime, self.config.MAX_SPEED * deltaTime)
    end
    
    -- Calcular nueva posición
    local newPos = npcPos + directionUnit * speed
    
    -- Aplicar rotación opcional
    if self.config.ENABLE_ROTATION then
        local lookAt = CFrame.lookAt(npcPos, playerPos)
        npc.humanoidRootPart.CFrame = CFrame.new(newPos) * Quaternion.fromEulerAngles(0, 0, 0):toMatrix()
        npc.humanoidRootPart.CFrame = npc.humanoidRootPart.CFrame:Lerp(
            lookAt * CFrame.new(0, 0, 0),
            self.config.ROTATION_SPEED * deltaTime
        )
    else
        npc.humanoidRootPart.CFrame = CFrame.new(newPos) * npc.humanoidRootPart.CFrame.Rotation
    end
end

--[[
    Encontrar jugador más cercano dentro del radio
    @param npc table - Objeto NPC
    @return Player, number - Jugador más cercano y distancia
]]
function BringRadius:FindClosestPlayer(npc)
    local closestPlayer = nil
    local closestDistance = self.config.BRING_RADIUS
    
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local playerPos = player.Character.HumanoidRootPart.Position
            local npcPos = npc.humanoidRootPart.Position
            local distance = (playerPos - npcPos).Magnitude
            
            if distance < closestDistance then
                closestDistance = distance
                closestPlayer = player
            end
        end
    end
    
    return closestPlayer, closestDistance
end

--[[
    Registrar un nuevo NPC
    @param npcModel Model - Modelo del NPC
    @return table - Objeto NPC registrado
]]
function BringRadius:RegisterNPC(npcModel)
    if not npcModel:IsA("Model") then
        error("El NPC debe ser un Model")
        return
    end
    
    local humanoidRootPart = npcModel:WaitForChild("HumanoidRootPart")
    local humanoid = npcModel:WaitForChild("Humanoid")
    
    local npc = {
        model = npcModel,
        humanoidRootPart = humanoidRootPart,
        humanoid = humanoid,
        isActive = false,
        attractedTo = nil,
        createdAt = tick()
    }
    
    table.insert(self.activeNPCs, npc)
    print("✓ NPC registrado: " .. npcModel.Name)
    
    return npc
end

--[[
    Iniciar el sistema de atracción
]]
function BringRadius:Start()
    if self.isRunning then return end
    self.isRunning = true
    
    -- Conexión con RenderStepped para delta time preciso
    self._connection = RunService.RenderStepped:Connect(function()
        if not self.isRunning then return end
        
        local deltaTime = self:GetDeltaTime()
        
        for i = #self.activeNPCs, 1, -1 do
            local npc = self.activeNPCs[i]
            
            -- Eliminar NPCs muertos
            if npc.humanoid.Health <= 0 then
                table.remove(self.activeNPCs, i)
            else
                -- Encontrar jugador más cercano
                local closestPlayer = self:FindClosestPlayer(npc)
                
                if closestPlayer then
                    npc.isActive = true
                    npc.attractedTo = closestPlayer
                    self:AttractNPCDelta(npc, closestPlayer, deltaTime)
                else
                    npc.isActive = false
                    npc.attractedTo = nil
                end
            end
        end
    end)
    
    print("✓ Sistema de BringRadius iniciado")
end

--[[
    Detener el sistema de atracción
]]
function BringRadius:Stop()
    if self._connection then
        self._connection:Disconnect()
    end
    self.isRunning = false
    print("✓ Sistema de BringRadius detenido")
end

--[[
    Obtener estadísticas del sistema
    @return table - Información de NPCs activos
]]
function BringRadius:GetStats()
    local activeCount = 0
    local attractedCount = 0
    
    for _, npc in pairs(self.activeNPCs) do
        if npc.humanoid.Health > 0 then
            activeCount = activeCount + 1
            if npc.isActive then
                attractedCount = attractedCount + 1
            end
        end
    end
    
    return {
        totalNPCs = activeCount,
        attractedNPCs = attractedCount,
        bringRadius = self.config.BRING_RADIUS,
        attractionSpeed = self.config.ATTRACTION_SPEED,
        usingDeltaTime = self.config.USE_DELTA_TIME
    }
end

--[[
    Cambiar configuración en tiempo real
    @param key string - Nombre de la configuración
    @param value any - Nuevo valor
]]
function BringRadius:SetConfig(key, value)
    if DEFAULT_CONFIG[key] ~= nil then
        self.config[key] = value
        print("⚙ Configuración '" .. key .. "' cambiada a: " .. tostring(value))
    else
        warn("Configuración desconocida: " .. key)
    end
end

--[[
    Obtener configuración actual
    @return table - Configuración actual
]]
function BringRadius:GetConfig()
    return self.config
end

--[[
    Limpiar todos los NPCs registrados
]]
function BringRadius:Clear()
    self.activeNPCs = {}
    print("✓ Todos los NPCs han sido eliminados del sistema")
end

return BringRadius
