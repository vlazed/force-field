TOOL.Category = "Construction"
TOOL.Name = "#tool.forcefield.name"
TOOL.Command = nil
TOOL.ConfigName = ""

TOOL.ClientConVar["key"] = 0
TOOL.ClientConVar["toggle"] = 1
TOOL.ClientConVar["starton"] = 1

TOOL.ClientConVar["shape"] = 0
TOOL.ClientConVar["magnitude"] = 15
TOOL.ClientConVar["direction"] = "0 0 0"
TOOL.ClientConVar["flip"] = 0
TOOL.ClientConVar["length"] = 10
TOOL.ClientConVar["width"] = 10
TOOL.ClientConVar["height"] = 10
TOOL.ClientConVar["decay"] = 0

---@module "forcefield.constants"
local constants = include("forcefield/constants.lua")
local forceFieldShape, forceFieldDecay = constants.forceFieldShape, constants.forceFieldDecay

---@class ForceFieldParams
---@field key integer
---@field toggle boolean
---@field startOn boolean
---@field shape ForceFieldShape
---@field size Vector
---@field force Vector
---@field flip boolean
---@field decay ForceFieldDecay

local firstReload = true
function TOOL:Think()
	if CLIENT and firstReload then
		self:RebuildControlPanel()
		firstReload = false
	end
end

function TOOL:Holster()
	self:ClearObjects()
end

local function stringToVector(str)
	local t = string.Split(str, " ")
	return Vector(t[1], t[2], t[3])
end

function AddForceField(ply, ent, params) end

---Add a force field  or update an existing one
---@param tr table|TraceResult
---@return boolean
function TOOL:LeftClick(tr)
	if tr.HitSky then
		return false
	end
	if CLIENT then
		return true
	end

	-- TODO: Add CanTool methods for prop protection
	-- Add sandbox limits for forcefield entities

	local ply = self:GetOwner()

	---@type ForceFieldParams
	local params = {
		key = self:GetClientNumber("key", 0),
		shape = self:GetClientNumber("shape", 0),
		toggle = tobool(self:GetClientBool("toggle", true)),
		startOn = tobool(self:GetClientBool("starton", true)),
		flip = tobool(self:GetClientBool("flip", true)),
		size = Vector(
			self:GetClientNumber("length", 0),
			self:GetClientNumber("width", 0),
			self:GetClientNumber("height", 0)
		),
		force = stringToVector(self:GetClientInfo("direction")) * self:GetClientNumber("magnitude"),
		decay = self:GetClientNumber("decay", 0),
	}

	local forcefield = IsValid(tr.Entity) and tr.Entity:GetClass() == "ent_forcefield" and tr.Entity
	---@cast forcefield ent_forcefield
	if not IsValid(forcefield) then
		forcefield = ents.Create("ent_forcefield")
		---@cast forcefield ent_forcefield
		forcefield:SetPos(tr.HitPos + vector_up * 10)
		forcefield:Spawn()
	end

	forcefield:SetSize(params.size)
	forcefield:SetForce(params.force)
	forcefield:SetShape(params.shape)
	forcefield:SetKey(params.key)
	forcefield:SetToggle(params.toggle)
	forcefield:SetActive(params.startOn)
	forcefield:SetFlip(params.flip)
	forcefield:SetDecay(params.decay)

	numpad.OnDown(ply, params.key, "forcefield_press", forcefield)
	numpad.OnUp(ply, params.key, "forcefield_release", forcefield)

	undo.Create("Forcefield")
	undo.AddEntity(forcefield)
	undo.SetPlayer(self:GetOwner())
	undo.Finish("Forcefield")

	return true
end

---Copy a forcefield's parameters
---@param tr table|TraceResult
---@return boolean
function TOOL:RightClick(tr)
	return true
end

if SERVER then
	return
end

local cvarList = TOOL:BuildConVarList()

---Helper for DForm
---@param cPanel ControlPanel|DForm
---@param name string
---@param type "ControlPanel"|"DForm"
---@return ControlPanel|DForm
local function makeCategory(cPanel, name, type)
	---@type DForm|ControlPanel
	local category = vgui.Create(type, cPanel)

	category:SetLabel(name)
	cPanel:AddItem(category)
	return category
end

---@param cPanel ControlPanel|DForm
function TOOL.BuildCPanel(cPanel)
	cPanel:ToolPresets("forcefield", cvarList)

	---@param vectorString string
	local function evaluateVectorEntry(vectorString)
		local v = string.Split(vectorString, " ")
		return not v[4] and tonumber(v[1]) and tonumber(v[2]) and tonumber(v[3])
	end

	local parametersCategory = makeCategory(cPanel, "#tool.forcefield.parameters", "ControlPanel")
	parametersCategory:SetExpanded(true)
	---@class ShapeCombo: DComboBox
	local shapeCombo = parametersCategory:ComboBox("#tool.forcefield.shape", "forcefield_shape")
	shapeCombo:AddChoice("#tool.forcefield.shape.ball", forceFieldShape.ball)
	shapeCombo:AddChoice("#tool.forcefield.shape.box", forceFieldShape.box)

	---@class DecayCombo: DComboBox
	local decayCombo = parametersCategory:ComboBox("#tool.forcefield.decay", "forcefield_decay")
	decayCombo:AddChoice("#tool.forcefield.decay.constant", forceFieldDecay.constant)
	decayCombo:AddChoice("#tool.forcefield.decay.inverse", forceFieldDecay.inverse)
	decayCombo:AddChoice("#tool.forcefield.decay.inverse_square", forceFieldDecay.inverse_square)

	parametersCategory
		:NumSlider("#tool.forcefield.magnitude", "forcefield_magnitude", 0, 100, 3)
		:SetTooltip("#tool.forcefield.magnitude.tooltip")

	---@class DirectionEntry: DTextEntry
	local directionEntry = parametersCategory:TextEntry("#tool.forcefield.direction", "forcefield_direction")
	directionEntry.ok = true
	directionEntry.oldValue = directionEntry:GetValue()
	local getDirection = parametersCategory:Button("#tool.forcefield.direction.view", "")
	getDirection:SetTooltip("#tool.forcefield.direction.view.tooltip")

	parametersCategory:CheckBox("#tool.forcefield.flip", "forcefield_flip"):SetTooltip("tool.forcefield.flip.tooltip")

	local sizeCategory = makeCategory(parametersCategory, "#tool.forcefield.size", "ControlPanel")
	sizeCategory:SetExpanded(false)
	sizeCategory:NumSlider("#tool.forcefield.size.x", "forcefield_length", 0, 100, 3)
	sizeCategory:NumSlider("#tool.forcefield.size.y", "forcefield_width", 0, 100, 3)
	sizeCategory:NumSlider("#tool.forcefield.size.z", "forcefield_height", 0, 100, 3)

	function directionEntry:OnChange()
		local text = self:GetValue()
		self.ok = evaluateVectorEntry(text)
		if self.ok then
			self.oldValue = text
		end
	end

	function directionEntry:OnValueChange(newVal)
		if not self.ok then
			self:SetValue(self.oldValue)
			self.ok = true
		end
	end

	---@diagnostic disable-next-line: inject-field
	function getDirection:DoClick()
		local eyeVector = LocalPlayer():EyeAngles():Forward()
		GetConVar("forcefield_direction"):SetString(tostring(eyeVector))
	end

	local controlCategory = makeCategory(cPanel, "#tool.forcefield.control", "ControlPanel")
	controlCategory:KeyBinder("#tool.forcefield.key", "forcefield_key"):SetTooltip("#tool.forcefield.key.tooltip")
	controlCategory:CheckBox("#tool.forcefield.toggle", "forcefield_toggle")
	controlCategory:CheckBox("#tool.forcefield.starton", "forcefield_starton")
end

TOOL.Information = {
	{ name = "left", stage = 0 },
	{ name = "right", stage = 0 },
}
