AddCSLuaFile()

---@class ent_forcefield: ENT
---@field SetShape fun(self: ent_forcefield, shape: integer)
---@field GetShape fun(self: ent_forcefield): shape: integer
---@field SetKey fun(self: ent_forcefield, key: integer)
---@field GetKey fun(self: ent_forcefield): key: integer
---@field SetDecay fun(self: ent_forcefield, decay: integer)
---@field GetDecay fun(self: ent_forcefield): decay: integer
---@field SetSize fun(self: ent_forcefield, size: Vector)
---@field GetSize fun(self: ent_forcefield): size: Vector
---@field SetForce fun(self: ent_forcefield, force: Vector)
---@field GetForce fun(self: ent_forcefield): force: Vector
---@field SetFlip fun(self: ent_forcefield, flip: boolean)
---@field GetFlip fun(self: ent_forcefield): flip: boolean
---@field SetToggle fun(self: ent_forcefield, toggle: boolean)
---@field GetToggle fun(self: ent_forcefield): toggle: boolean
---@field SetActive fun(self: ent_forcefield, active: boolean)
---@field GetActive fun(self: ent_forcefield): active: boolean
local ENT = ENT

ENT.Type = "anim"

ENT.PrintName = "Force Field"
ENT.Author = "vlazed"

ENT.Purpose = ""
ENT.Instructions = ""

ENT.Editable = true

---@module "forcefield.constants"
local constants = include("forcefield/constants.lua")
local forceFieldShape = constants.forceFieldShape
local forceFieldDecay = constants.forceFieldDecay

function ENT:SetupDataTables()
	self:NetworkVar("Vector", 0, "Size")
	self:NetworkVar("Vector", 1, "Force")

	self:NetworkVar("Bool", 0, "Flip")
	self:NetworkVar("Bool", 1, "Toggle")
	self:NetworkVar("Bool", 2, "Active")

	self:NetworkVar("Int", 0, "Shape")
	self:NetworkVar("Int", 1, "Key")
	self:NetworkVar("Int", 2, "Decay")

	self:NetworkVarNotify("Force", function(entity, name, old, new)
		---@cast entity ent_forcefield
		---@cast new Vector
		entity.Magnitude = new:Length()
	end)

	self:NetworkVarNotify("Size", function(entity, name, old, new)
		---@cast entity ent_forcefield
		---@cast new Vector
		entity.SizeLength = new:Length()
	end)
end

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end

---Most code comes from
---https://github.com/Facepunch/garrysmod/blob/5536088d22b8c079102cfafed1a81f26050701c0/garrysmod/gamemodes/base/entities/entities/prop_effect.lua#L12
function ENT:Initialize()
	local Radius = 6
	local mins = Vector(1, 1, 1) * Radius * -0.5
	local maxs = Vector(1, 1, 1) * Radius * 0.5

	self.Magnitude = 0
	self.SizeLength = 0

	if SERVER then
		self:SetModel("models/props_junk/watermelon01.mdl")

		-- Don't use the model's physics - create a box instead
		self:PhysicsInitBox(mins, maxs)
		self:SetSolid(SOLID_VPHYSICS)

		-- Set up our physics object here
		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			phys:Wake()
			phys:EnableGravity(false)
			phys:EnableDrag(false)
			phys:EnableCollisions(false)
		end
	else
		-- So addons can override this
		self.GripMaterial = Material("sprites/grip")
		self.GripMaterialHover = Material("sprites/grip_hover")

		self:DrawShadow(false)
		self:SetCollisionGroup(COLLISION_GROUP_WORLD)
	end

	-- Set collision bounds exactly
	self:SetCollisionBounds(mins, maxs)
end

-- Copied from base_gmodentity.lua
ENT.MaxWorldTipDistance = 256
function ENT:BeingLookedAtByLocalPlayer()
	local ply = LocalPlayer()
	if not IsValid(ply) then
		return false
	end

	local view = ply:GetViewEntity()
	local dist = self.MaxWorldTipDistance
	dist = dist * dist

	-- If we're spectating a player, perform an eye trace
	if view:IsPlayer() then
		---@diagnostic disable-next-line: undefined-field
		return view:EyePos():DistToSqr(self:GetPos()) <= dist and view:GetEyeTrace().Entity == self
	end

	-- If we're not spectating a player, perform a manual trace from the entity's position
	local pos = view:GetPos()

	if pos:DistToSqr(self:GetPos()) <= dist then
		return util.TraceLine({
			start = pos,
			endpos = pos + (view:GetAngles():Forward() * dist),
			filter = view,
		}).Entity == self
	end

	return false
end

local COLOR_RED = Color(255, 0, 0)

function ENT:DrawShape()
	local shape = self:GetShape()
	if shape == forceFieldShape.box then
		local mins, maxs = -self:GetSize() * 0.5, self:GetSize() * 0.5
		render.DrawWireframeBox(
			self:GetPos(),
			self:GetAngles(),
			mins,
			maxs,
			self:GetActive() and color_white or COLOR_RED
		)
	elseif shape == forceFieldShape.ball then
		render.DrawWireframeSphere(
			self:GetPos(),
			self:GetSize():Length() * 0.5,
			10,
			10,
			self:GetActive() and color_white or COLOR_RED
		)
	end
end

function ENT:Draw()
	---@diagnostic disable-next-line: deprecated
	if GetConVarNumber("cl_draweffectrings") == 0 then
		return
	end

	-- Don't draw the grip if there's no chance of us picking it up
	local ply = LocalPlayer()
	local wep = ply:GetActiveWeapon()
	if not IsValid(wep) then
		return
	end

	local weapon_name = wep:GetClass()

	if weapon_name ~= "weapon_physgun" and weapon_name ~= "gmod_tool" then
		return
	end

	if self:BeingLookedAtByLocalPlayer() then
		render.SetMaterial(self.GripMaterialHover)
	else
		render.SetMaterial(self.GripMaterial)
	end

	render.DrawSprite(self:GetPos(), 16, 16, color_white)

	self:DrawShape()
end

---@return Entity[]
function ENT:GetEntities()
	local shape = self:GetShape()
	local pos = self:GetPos()
	if shape == forceFieldShape.box then
		local mins, maxs = -self:GetSize() * 0.5, self:GetSize() * 0.5
		return ents.FindInBox(pos + mins, pos + maxs)
	elseif shape == forceFieldShape.ball then
		return ents.FindInSphere(pos, self.SizeLength * 0.5)
	end

	return {}
end

function ENT:GetDecayFunction()
	if self:GetDecay() == forceFieldDecay.inverse then
		return function(x)
			if x == 0 then
				return 0
			end
			return 1 / x
		end
	elseif self:GetDecay() == forceFieldDecay.inverse_square then
		return function(x)
			if x == 0 then
				return 0
			end
			return 1 / x ^ 2
		end
	end

	return function(x)
		return 1
	end
end

---@param entity Entity
function ENT:ApplyForce(entity)
	local shape = self:GetShape()

	local origin = self:GetPos()
	local physCount = entity:GetPhysicsObjectCount()
	local flip = self:GetFlip() and -1 or 1
	local decayFunction = self:GetDecayFunction()
	if shape == forceFieldShape.ball then
		for i = 0, physCount - 1 do
			local physObj = entity:GetPhysicsObjectNum(i)
			local endPos = physObj:GetPos()
			local tr = util.TraceLine({
				start = origin,
				endpos = endPos,
			})
			local direction = flip * (endPos - origin)
			local distanceFactor = decayFunction((endPos - origin):Length())
			direction:Normalize()
			physObj:ApplyForceOffset(
				distanceFactor * physObj:GetMass() * direction * self.Magnitude,
				tr.HitPos or endPos
			)
		end
	elseif shape == forceFieldShape.box then
		for i = 0, physCount - 1 do
			local physObj = entity:GetPhysicsObjectNum(i)
			local endPos = physObj:GetPos()
			local tr = util.TraceLine({
				start = origin,
				endpos = endPos,
			})
			physObj:ApplyForceOffset(physObj:GetMass() * flip * self:GetForce(), tr.HitPos or endPos)
		end
	end
end

local entityPass = {
	["prop_ragdoll"] = true,
	["prop_physics"] = true,
}

function ENT:Think()
	if CLIENT then
		local radius = self:GetSize() * 0.5
		self:SetRenderBounds(-radius, radius)
		return
	end

	if self:GetActive() then
		local entities = self:GetEntities()
		for _, entity in ipairs(entities) do
			if entity ~= self and entityPass[entity:GetClass()] then
				self:ApplyForce(entity)
			end
		end
	end

	self:NextThink(CurTime())
	return true
end

function ENT:PhysicsUpdate(physobj)
	if CLIENT then
		return
	end

	-- Don't do anything if the player isn't holding us
	if not self:IsPlayerHolding() and not self:IsConstrained() then
		physobj:SetVelocity(vector_origin)
		physobj:Sleep()
	end
end

if SERVER then
	-- The press and release code come from the Advanced Particle Controller
	-- They've been edited to make StyLua formatting work
	-- Gonna simplify things by reusing implementations that almost everyone is used to
	local function press(pl, ent)
		if not ent or not IsValid(ent) then
			return
		end

		if ent:GetToggle() then
			if ent:GetActive() == false then
				ent:SetActive(true)
			else
				ent:SetActive(false)
			end
		else
			ent:SetActive(true)
		end
	end

	local function release(pl, ent)
		if not ent or not IsValid(ent) then
			return
		end

		if ent:GetToggle() then
			return
		end

		ent:SetActive(false)
	end

	numpad.Register("forcefield_press", press)
	numpad.Register("forcefield_release", release)
end
