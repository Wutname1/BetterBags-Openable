local addonName, root = ... --[[@type string, table]]
---@class BetterBagsOpenable: AceModule AceDB
local addon = LibStub('AceAddon-3.0'):NewAddon(root, addonName)
local DataBase, DB = {}, {}

---@class BetterBags: AceAddon
local BetterBags = LibStub('AceAddon-3.0'):GetAddon('BetterBags')
---@class Categories: AceModule
local categories = BetterBags:GetModule('Categories')
---@class Debug: AceModule
local debug = BetterBags:GetModule('Debug')
---@class Config: AceModule
local config = BetterBags:GetModule('Config')

function addon:OnInitialize()
	---@class Profile
	local profile = {
		FilterGenericUse = false,
		FilterToys = true,
		FilterAppearance = true,
		CreatableItem = true
	}

	--Setup DB
	DataBase = LibStub('AceDB-3.0'):New('SpartanUIDB', {profile = profile}, true)

	DB = DataBase.profile

	--Setup Options
	local options = {
		FilterGenericUse = {
			type = 'toggle',
			width = 'full',
			order = 0,
			name = 'Filter Generic `Use:` Items',
			desc = 'Filter all items that have a "Use" effect',
			get = function()
				return DB.FilterGenericUse
			end,
			set = function(_, value)
				DB.FilterGenericUse = value
			end
		},
		FilterToys = {
			type = 'toggle',
			width = 'full',
			order = 1,
			name = 'Filter Toys',
			desc = 'Filter all items with `' .. ITEM_TOY_ONUSE .. '` in the tooltip',
			get = function()
				return DB.FilterToys
			end,
			set = function(_, value)
				DB.FilterToys = value
			end
		},
		FilterAppearance = {
			type = 'toggle',
			width = 'full',
			order = 2,
			name = 'Filter Appearance Items',
			desc = 'Filter all items with `' .. ITEM_COSMETIC_LEARN .. '` in the tooltip',
			get = function()
				return DB.FilterAppearance
			end,
			set = function(_, value)
				DB.FilterAppearance = value
			end
		},
		CreatableItem = {
			type = 'toggle',
			width = 'full',
			order = 3,
			name = 'Filter Creatable Items',
			desc = 'Filter all items with `' .. ITEM_CREATE_LOOT_SPEC_ITEM .. '` in the tooltip',
			get = function()
				return DB.CreatableItem
			end,
			set = function(_, value)
				DB.CreatableItem = value
			end
		}
	}

	config:AddPluginConfig('Openable', options)
end

local function Log(msg)
	debug:Log('Openable', msg)
end

local Tooltip = CreateFrame('GameTooltip', 'BBOpenable', nil, 'GameTooltipTemplate')
local PREFIX = '|cff2beefd'
local OPENABLE_CATEGORY_TITLE = '|cff2beefd Openable'

local SearchItems = {
	'Open the container',
	'Use: Open',
	ITEM_OPENABLE
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

		if LineText == ITEM_COSMETIC_LEARN then
			return PREFIX .. 'Cosmetics'
		end

		-- Remove (%s). from ITEM_CREATE_LOOT_SPEC_ITEM
		local CreateItemString = ITEM_CREATE_LOOT_SPEC_ITEM:gsub(' %(%%s%)%.', '')
		if DB.CreatableItem then
			if string.find(LineText, CreateItemString) then
				return PREFIX .. 'Creatable Items'
			end
		end

		if LineText == LOCKED then
			return PREFIX .. 'Lockboxes'
		end

		if DB.FilterGenericUse then
			if string.find(LineText, ITEM_TOY_ONUSE) then
				return PREFIX .. 'Toys'
			end
		end

		if DB.FilterGenericUse then
			if string.find(LineText, ITEM_SPELL_TRIGGER_ONUSE) then
				return PREFIX .. 'Generic Use Items'
			end
		end
	end
end

categories:RegisterCategoryFunction('reg', filter)
