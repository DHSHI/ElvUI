local E, L, V, P, G = unpack(ElvUI); -- Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local AB = E:GetModule("ActionBars");

--Cache global variables
--Lua functions
local _G = _G
local ceil, mod = math.ceil, math.mod
--WoW API / Variables
local CreateFrame = CreateFrame
local GetBindingKey = GetBindingKey
local PetHasActionBar = PetHasActionBar
local GetPetActionInfo = GetPetActionInfo
local GetPetActionsUsable = GetPetActionsUsable
local SetDesaturation = SetDesaturation
local PetActionBar_ShowGrid = PetActionBar_ShowGrid
local PetActionBar_UpdateCooldowns = PetActionBar_UpdateCooldowns
local NUM_PET_ACTION_SLOTS = NUM_PET_ACTION_SLOTS

local bar = CreateFrame("Frame", "ElvUI_BarPet", E.UIParent)
bar:SetFrameStrata("LOW")

function AB:UpdatePet()
	if ((event == "UNIT_FLAGS" or event == "UNIT_AURA") and arg1 ~= "pet") then return end
	if (event == "UNIT_PET" and arg1 ~= "player") then return end

	for i = 1, NUM_PET_ACTION_SLOTS do
		local buttonName = "PetActionButton"..i
		local button = _G[buttonName]
		local icon = _G[buttonName.."Icon"]
		local autoCast = _G[buttonName.."AutoCastable"]
		local shine = _G[buttonName.."AutoCast"]
		local name, subtext, texture, isToken, isActive, autoCastAllowed, autoCastEnabled = GetPetActionInfo(i)

		if not isToken then
			icon:SetTexture(texture)
			button.tooltipName = name
		else
			icon:SetTexture(_G[texture])
			button.tooltipName = _G[name]
		end

		button.isToken = isToken
		button.tooltipSubtext = subtext

		if isActive --[[and name ~= "PET_ACTION_FOLLOW"]] then
			button:SetChecked(true)
		else
			button:SetChecked(false)
		end

		if autoCastAllowed then
			autoCast:Show()
		else
			autoCast:Hide()
		end

		if autoCastEnabled then
			shine:Show()
		else
			shine:Hide()
		end

		if texture then
			if GetPetActionsUsable() then
				SetDesaturation(icon, nil)
			else
				SetDesaturation(icon, 1)
			end
			icon:Show()
		else
			icon:Hide()
		end

		if not PetHasActionBar() and texture --[[and name ~= "PET_ACTION_FOLLOW"]] then
			SetDesaturation(icon, 1)
			button:SetChecked(false)
		end
	end

	if not PetHasActionBar() then
		bar:Hide()
	else
		bar:Show()
	end
end

function AB:PositionAndSizeBarPet()
	local buttonSpacing = E:Scale(self.db.barPet.buttonspacing)
	local backdropSpacing = E:Scale((self.db.barPet.backdropSpacing or self.db.barPet.buttonspacing))
	local buttonsPerRow = self.db.barPet.buttonsPerRow
	local numButtons = self.db.barPet.buttons
	local size = E:Scale(self.db.barPet.buttonsize)
	local autoCastSize = (size / 2) - (size / 7.5)
	local point = self.db.barPet.point
	local numColumns = ceil(numButtons / buttonsPerRow)
	local widthMult = self.db.barPet.widthMult
	local heightMult = self.db.barPet.heightMult

	bar.db = self.db.barPet
	bar.db.position = nil --Depreciated

	if numButtons < buttonsPerRow then
		buttonsPerRow = numButtons
	end

	if numColumns < 1 then
		numColumns = 1
	end

	if self.db.barPet.backdrop == true then
		bar.backdrop:Show()
	else
		bar.backdrop:Hide()
		--Set size multipliers to 1 when backdrop is disabled
		widthMult = 1
		heightMult = 1
	end

	local barWidth = (size * (buttonsPerRow * widthMult)) + ((buttonSpacing * (buttonsPerRow - 1)) * widthMult) + (buttonSpacing * (widthMult-1)) + ((self.db.barPet.backdrop == true and (E.Border + backdropSpacing) or E.Spacing)*2)
	local barHeight = (size * (numColumns * heightMult)) + ((buttonSpacing * (numColumns - 1)) * heightMult) + (buttonSpacing * (heightMult-1)) + ((self.db.barPet.backdrop == true and (E.Border + backdropSpacing) or E.Spacing)*2)
	bar:SetWidth(barWidth)
	bar:SetHeight(barHeight)

	if self.db.barPet.enabled then
		bar:SetScale(1)
		bar:SetAlpha(bar.db.alpha)
		E:EnableMover(bar.mover:GetName())
	else
		bar:SetScale(0.0001)
		bar:SetAlpha(0)
		E:DisableMover(bar.mover:GetName())
	end

	local horizontalGrowth, verticalGrowth
	if point == "TOPLEFT" or point == "TOPRIGHT" then
		verticalGrowth = "DOWN"
	else
		verticalGrowth = "UP"
	end

	if point == "BOTTOMLEFT" or point == "TOPLEFT" then
		horizontalGrowth = "RIGHT"
	else
		horizontalGrowth = "LEFT"
	end

	bar.mouseover = self.db.barPet.mouseover
	if bar.mouseover then
		bar:SetAlpha(0)
	else
		bar:SetAlpha(bar.db.alpha)
	end

	if self.db.barPet.inheritGlobalFade then
		bar:SetParent(self.fadeParent)
	else
		bar:SetParent(E.UIParent)
	end

	local button, lastButton, lastColumnButton, autoCast, shine
	local firstButtonSpacing = (self.db.barPet.backdrop == true and (E.Border + backdropSpacing) or E.Spacing)
	for i = 1, NUM_PET_ACTION_SLOTS do
		button = _G["PetActionButton"..i]
		lastButton = _G["PetActionButton"..i - 1]
		autoCast = _G["PetActionButton"..i.."AutoCastable"]
		shine = _G["PetActionButton"..i.."AutoCast"]
		lastColumnButton = _G["PetActionButton"..i - buttonsPerRow]

		button:SetParent(bar)
		button:ClearAllPoints()
		E:Size(button, size)
		E:SetOutside(autoCast, button, autoCastSize, autoCastSize)
		--shine:SetInside(button)
		button:Show()

		if i == 1 then
			local x, y
			if point == "BOTTOMLEFT" then
				x, y = firstButtonSpacing, firstButtonSpacing
			elseif point == "TOPRIGHT" then
				x, y = -firstButtonSpacing, -firstButtonSpacing
			elseif point == "TOPLEFT" then
				x, y = firstButtonSpacing, -firstButtonSpacing
			else
				x, y = -firstButtonSpacing, firstButtonSpacing
			end

			E:Point(button, point, bar, point, x, y)
		elseif mod((i - 1), buttonsPerRow) == 0 then
			local x = 0
			local y = -buttonSpacing
			local buttonPoint, anchorPoint = "TOP", "BOTTOM"
			if verticalGrowth == "UP" then
				y = buttonSpacing
				buttonPoint = "BOTTOM"
				anchorPoint = "TOP"
			end
			E:Point(button, buttonPoint, lastColumnButton, anchorPoint, x, y)
		else
			local x = buttonSpacing
			local y = 0
			local buttonPoint, anchorPoint = "LEFT", "RIGHT"
			if horizontalGrowth == "LEFT" then
				x = -buttonSpacing
				buttonPoint = "RIGHT"
				anchorPoint = "LEFT"
			end

			E:Point(button, buttonPoint, lastButton, anchorPoint, x, y)
		end

		if i > numButtons then
			button:SetScale(0.0001)
			button:SetAlpha(0)
		else
			button:SetScale(1)
			button:SetAlpha(bar.db.alpha)
		end

		self:StyleButton(button)
	end

	--Fix issue with mover not updating size when bar is hidden
	bar:GetScript("OnSizeChanged")(bar)
end

function AB:UpdatePetBindings()
	local color = self.db.fontColor

	for i = 1, NUM_PET_ACTION_SLOTS do
		if self.db.hotkeytext then
			local key = GetBindingKey("BONUSACTIONBUTTON"..i)
			_G["PetActionButton"..i.."HotKey"]:Show()
			_G["PetActionButton"..i.."HotKey"]:SetText(key)
			_G["PetActionButton"..i.."HotKey"]:SetTextColor(color.r, color.g, color.b)
			self:FixKeybindText(_G["PetActionButton"..i])
		else
			_G["PetActionButton"..i.."HotKey"]:Hide()
		end
	end
end

function AB:CreateBarPet()
	E:CreateBackdrop(bar, "Default")
	bar.backdrop:SetAllPoints()
	bar:EnableMouse(true)
	if self.db.bar4.enabled then
		E:Point(bar, "RIGHT", ElvUI_Bar4, "LEFT", -4, 0)
	else
		E:Point(bar, "RIGHT", E.UIParent, "RIGHT", -4, 0)
	end

	PetActionBarFrame.showgrid = 1
	PetActionBar_ShowGrid()

	self:HookScript(bar, "OnEnter", "Bar_OnEnter")
	self:HookScript(bar, "OnLeave", "Bar_OnLeave")
	for i = 1, NUM_PET_ACTION_SLOTS do
		self:HookScript(_G["PetActionButton"..i], "OnEnter", "Button_OnEnter")
		self:HookScript(_G["PetActionButton"..i], "OnLeave", "Button_OnLeave")
	end

	self:RegisterEvent("SPELLS_CHANGED", "UpdatePet")
	self:RegisterEvent("PLAYER_CONTROL_GAINED", "UpdatePet")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdatePet")
	self:RegisterEvent("PLAYER_CONTROL_LOST", "UpdatePet")
	self:RegisterEvent("PET_BAR_UPDATE", "UpdatePet")
	self:RegisterEvent("UNIT_PET", "UpdatePet")
	self:RegisterEvent("UNIT_FLAGS", "UpdatePet")
	self:RegisterEvent("UNIT_AURA", "UpdatePet")
	self:RegisterEvent("PLAYER_FARSIGHT_FOCUS_CHANGED", "UpdatePet")
	self:RegisterEvent("PET_BAR_UPDATE_COOLDOWN", PetActionBar_UpdateCooldowns)

	E:CreateMover(bar, "ElvBar_Pet", L["Pet Bar"], nil, nil, nil,"ALL,ACTIONBARS")

	self:PositionAndSizeBarPet()
	self:UpdatePetBindings()
end
