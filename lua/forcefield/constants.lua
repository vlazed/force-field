AddCSLuaFile()

local constants = {}

---@enum ForceFieldShape
constants.forceFieldShape = {
	box = 0,
	ball = 1,
}

---@enum ForceFieldDecay
constants.forceFieldDecay = {
	constant = 0,
	inverse = 1,
	inverse_square = 2,
}

return constants
