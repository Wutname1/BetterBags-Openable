---@class BetterBags: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon('BetterBags')
---@class Categories: AceModule
local categories = addon:GetModule('Categories')
---@class Debug: AceModule
local debug = addon:GetModule('Debug')

local function Log(msg)
	debug:Log('Openable', msg)
end

local Tooltip = CreateFrame('GameTooltip', 'BBOpenable', nil, 'GameTooltipTemplate')
local OPENABLE_CATEGORY_TITLE = '|cff2beefd Openable'
local LOCKBOXES_CATEGORY_TITLE = '|cff2beefd Lockboxes'

local SearchItems = {
	'Open the container',
	'Use: Open',
	'Right Click to Open'
}

---@param data ItemData
local function filter(data)
	Tooltip:ClearLines()
	Log('Filtering ' .. data.itemHash)
	Log('Bag ID: ' .. data.bagid .. ' Slot ID: ' .. data.slotid)
	--Set the Item in the tooltip
	Tooltip:SetOwner(UIParent, 'ANCHOR_NONE')
	Tooltip:SetBagItem(data.bagid, data.slotid)
	Log('NumLines ' .. Tooltip:NumLines())

	for i = 1, Tooltip:NumLines() do
		line = _G['BBOpenableTextLeft' .. i]
		local LineText = line:GetText()
		Log(LineText)
		--Search for the strings in the tooltip
		for _, v in pairs(SearchItems) do
			if string.find(LineText, v) then
				return OPENABLE_CATEGORY_TITLE
			end
		end
		if LineText == LOCKED then
			return LOCKBOXES_CATEGORY_TITLE
		end
	end
end

categories:RegisterCategoryFunction('reg', filter)
