local addonName, root = ... --[[@type string, table]]
---@class BetterBagsOpenable: AceModule AceDB
local addon = LibStub('AceAddon-3.0'):NewAddon(root, addonName)

---@class BetterBags: AceAddon
local BetterBags = LibStub('AceAddon-3.0'):GetAddon('BetterBags')
---@class Categories: AceModule
local categories = BetterBags:GetModule('Categories')
---@class Debug: AceModule
local debug = BetterBags:GetModule('Debug')
---@class Config: AceModule
local config = BetterBags:GetModule('Config')
local devMode = false
--@do-not-package@
devMode = true
--@end-do-not-package@

---@class Profile
local profile = {
	CategoryColor = {r = 0.17, g = 0.93, b = 0.93, a = 1},
	FilterGenericUse = false,
	FilterToys = true,
	FilterAppearance = true,
	FilterMounts = true,
	FilterRepGain = true,
	CreatableItem = true
}

function addon:OnInitialize()
	--Setup DB
	self.DataBase = LibStub('AceDB-3.0'):New('BetterBagsOpenableDB', {profile = profile}, true)
	self.DB = self.DataBase.profile ---@type Profile
end

--Get Locale
local REP_USE_TEXT = QUEST_REPUTATION_REWARD_TOOLTIP:match('%%d%s*(.-)%s*%%s')
local Localized = {
	deDE = {
		['Use: Teaches you how to summon this mount'] = 'Benutzen: Lehrt Euch, dieses Reittier herbeizurufen',
		['Use: Collect the appearance'] = 'Benutzen: Sammelt das Aussehen',
		['reputation with'] = 'Ruf bei',
		['reputation towards'] = 'Ruf bei'
	},
	esES = {
		['Use: Teaches you how to summon this mount'] = 'Uso: Te enseña a invocar esta montura',
		['Use: Collect the appearance'] = 'Uso: Recoge la apariencia',
		['reputation with'] = 'reputación con',
		['reputation towards'] = 'reputación hacia'
	},
	frFR = {
		['Use: Teaches you how to summon this mount'] = 'Utilisation: Vous apprend à invoquer cette monture',
		['Use: Collect the appearance'] = "Utilisation: Collectionnez l'apparence",
		['reputation with'] = 'réputation auprès',
		['reputation towards'] = 'réputation envers'
	}
}

local Locale = GetLocale()
function GetLocaleString(key)
	if Localized[Locale] then
		return Localized[Locale][key]
	end
	return key
end

--Setup Options
--we define a full options table to make linter happy.
---@type AceConfig.OptionsTable
local options = {
	name = 'Openable',
	type = 'group',
	args = {
		Color = {
			type = 'color',
			order = 0,
			name = 'Color',
			desc = 'Change the color of the category. Reload UI to see changes.',
			get = function()
				return addon.DB.CategoryColor.r, addon.DB.CategoryColor.g, addon.DB.CategoryColor.b
			end,
			set = function(_, r, g, b)
				addon.DB.CategoryColor = {r = r, g = g, b = b, a = 1}
			end
		},
		Modes = {
			type = 'group',
			inline = true,
			name = 'Filter Modes',
			order = 10,
			set = function(info, value)
				addon.DB[info[#info]] = value
			end,
			get = function(info)
				return addon.DB[info[#info]]
			end,
			args = {
				FilterGenericUse = {
					type = 'toggle',
					width = 'full',
					order = 0,
					name = 'Filter Generic `Use:` Items',
					desc = 'Filter all items that have a "Use" effect'
					-- get = function()
					-- 	return addon.DB.FilterGenericUse
					-- end,
					-- set = function(_, value)
					-- 	addon.DB.FilterGenericUse = value
					-- end
				},
				FilterToys = {
					type = 'toggle',
					width = 'full',
					order = 1,
					name = 'Filter Toys',
					desc = 'Filter all items with `' .. ITEM_TOY_ONUSE .. '` in the tooltip'
					-- get = function()
					-- 	return addon.DB.FilterToys
					-- end,
					-- set = function(_, value)
					-- 	addon.DB.FilterToys = value
					-- end
				},
				FilterMounts = {
					type = 'toggle',
					width = 'full',
					order = 1,
					name = 'Filter Mounts',
					desc = 'Filter all items with `' .. GetLocaleString('Use: Teaches you how to summon this mount') .. '` in the tooltip'
					-- get = function()
					-- 	return addon.DB.FilterMounts
					-- end,
					-- set = function(_, value)
					-- 	addon.DB.FilterMounts = value
					-- end
				},
				FilterAppearance = {
					type = 'toggle',
					width = 'full',
					order = 2,
					name = 'Filter Appearance Items',
					desc = 'Filter all items with `' .. ITEM_COSMETIC_LEARN .. '` in the tooltip'
					-- get = function()
					-- 	return addon.DB.FilterAppearance
					-- end,
					-- set = function(_, value)
					-- 	addon.DB.FilterAppearance = value
					-- end
				},
				FilterRepGain = {
					type = 'toggle',
					width = 'full',
					order = 2,
					name = 'Reputaion Gain Items',
					desc = 'Filter all items with `' .. ITEM_SPELL_TRIGGER_ONUSE .. '` and `' .. REP_USE_TEXT .. '` in the tooltip'
					-- get = function()
					-- 	return addon.DB.FilterRepGain
					-- end,
					-- set = function(_, value)
					-- 	addon.DB.FilterRepGain = value
					-- end
				},
				CreatableItem = {
					type = 'toggle',
					width = 'full',
					order = 3,
					name = 'Filter Creatable Items',
					desc = 'Filter all items with `' .. ITEM_CREATE_LOOT_SPEC_ITEM .. '` in the tooltip'
					-- get = function()
					-- 	return addon.DB.CreatableItem
					-- end,
					-- set = function(_, value)
					-- 	addon.DB.CreatableItem = value
					-- end
				}
			}
		}
	}
}

config:AddPluginConfig('Openable', options.args)

local function Log(msg)
	if not devMode then
		return
	end
	---@diagnostic disable-next-line: undefined-field
	debug:Log('Openable', msg)
end

function RGBToHex(rgbTable)
	local r = math.floor(rgbTable.r * 255 + 0.5)
	local g = math.floor(rgbTable.g * 255 + 0.5)
	local b = math.floor(rgbTable.b * 255 + 0.5)
	return string.format('|cFF%02X%02X%02X', r, g, b)
end

local Tooltip = CreateFrame('GameTooltip', 'BBOpenable', nil, 'GameTooltipTemplate')
-- local PREFIX = '|cff2beefd'
local function PREFIX()
	return RGBToHex(addon.DB.CategoryColor)
end

local SearchItems = {
	'Open the container',
	'Use: Open',
	ITEM_OPENABLE
}

---@param data ItemData
local function filter(data)
	local Consumable = data.itemInfo.itemType == 'Consumable' or data.itemInfo.itemSubType == 'Consumables'
	if data.itemInfo.isCraftingReagent or Consumable or data.itemInfo.itemType == 'Quest' or data.itemInfo.itemType == 'Armor' or data.itemInfo.itemType == 'Battle Pets' then
		return
	end

	Tooltip:ClearLines()
	Log('Filtering ' .. data.itemHash)
	Log('Bag ID: ' .. data.bagid .. ' Slot ID: ' .. data.slotid)
	--Set the Item in the tooltip
	Tooltip:SetOwner(UIParent, 'ANCHOR_NONE')
	Tooltip:SetBagItem(data.bagid, data.slotid)
	Log('NumLines ' .. Tooltip:NumLines())

	for i = 1, Tooltip:NumLines() do
		local line = _G['BBOpenableTextLeft' .. i]
		local LineText = line:GetText()
		Log(LineText)

		--Search for the strings in the tooltip
		for _, v in pairs(SearchItems) do
			if string.find(LineText, v) then
				return PREFIX() .. 'Openable'
			end
		end

		if addon.DB.FilterAppearance and (string.find(LineText, ITEM_COSMETIC_LEARN) or string.find(LineText, GetLocaleString('Use: Collect the appearance'))) then
			return PREFIX() .. 'Cosmetics'
		end

		-- Remove (%s). from ITEM_CREATE_LOOT_SPEC_ITEM
		local CreateItemString = ITEM_CREATE_LOOT_SPEC_ITEM:gsub(' %(%%s%)%.', '')
		if addon.DB.CreatableItem and (string.find(LineText, CreateItemString) or string.find(LineText, 'Create a soulbound item for your class')) then
			return PREFIX() .. 'Creatable Items'
		end

		if LineText == LOCKED then
			return PREFIX() .. 'Lockboxes'
		end

		if addon.DB.FilterToys and string.find(LineText, ITEM_TOY_ONUSE) then
			return PREFIX() .. 'Toys'
		end

		if
			addon.DB.FilterRepGain and (string.find(LineText, REP_USE_TEXT) or string.find(LineText, GetLocaleString('reputation towards')) or string.find(LineText, GetLocaleString('reputation with'))) and
				string.find(LineText, ITEM_SPELL_TRIGGER_ONUSE)
		 then
			return PREFIX() .. 'Reputation'
		end

		if addon.DB.FilterMounts and (string.find(LineText, GetLocaleString('Use: Teaches you how to summon this mount')) or string.find(LineText, 'Drakewatcher Manuscript')) then
			return PREFIX() .. 'Mounts'
		end

		if addon.DB.FilterGenericUse and string.find(LineText, ITEM_SPELL_TRIGGER_ONUSE) then
			return PREFIX() .. 'Generic Use Items'
		end
	end
end

categories:RegisterCategoryFunction('libs-openable', filter)
