local holder = CreateFrame("Frame")

holder.lastFrames = {}
holder.timeUntilLastUpdate = 3

-- Utils

local function Round(num, numDecimalPlaces)
	local mult = 10^(numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
end

local function ReduceTable(list, fn, init)
    local acc = init
	if #list == 0 then
		return 0
	elseif #list == 1 then
		return list[0]
	end
    for k, v in ipairs(list) do
        if 1 == k and not init then
            acc = v
        else
            acc = fn(acc, v)
        end
    end
    return acc
end

-- Display

function holder:displayScaleDisplay()
	if self.settings.displayRenderScale or self.settings.displayControlFps then
		self.scaleDisplay:Show()
	else
		self.scaleDisplay:Hide()
	end
end

function holder:displayRenderScale()
	self:displayScaleDisplay()
	if self.settings.displayRenderScale then
		self.scaleText:Show()
	else
		self.scaleText:Hide()
	end
end

function holder:displayControlFps()
	self:displayScaleDisplay()
	if self.settings.displayControlFps then
		self.framesText:Show()
	else
		self.framesText:Hide()
	end
end

function holder:createOptionsUI()
	self.options = CreateFrame("Frame", "DynamicRenderResolutionSettings", UIParent)
	local category = Settings.RegisterCanvasLayoutCategory(self.options, "DynamicRenderRes")
	Settings.RegisterAddOnCategory(category)

	-- Downscale
	local downscaleTitle = self.options:CreateFontString("ARTWORK", nil, "GameFontNormalLarge")
	downscaleTitle:SetPoint("TOPLEFT", 16, -16)
	downscaleTitle:SetText("Upscaling")

	local downscaleDescription = self.options:CreateFontString("ARTWORK", nil, "GameTooltipText")
	downscaleDescription:SetPoint("TOPLEFT", 20, -40)
	downscaleDescription:SetText("Decrease render resolution below 100% when FPS falls below the set target. Improves performance.")

	local downscaleEnabledChekBox = CreateFrame("CheckButton", "DRRDownscaleEnabledCheckbox", self.options, "UICheckButtonTemplate")
	downscaleEnabledChekBox:SetPoint("TOPLEFT", 20, -80)
	downscaleEnabledChekBox:HookScript("OnClick", function(self, button, down)
		holder:SetRenderScale(1)
		holder.settings.downscaleEnabled = downscaleEnabledChekBox:GetChecked()
	end)
	downscaleEnabledChekBox:SetChecked(holder.settings.downscaleEnabled)
	getglobal(downscaleEnabledChekBox:GetName() .. 'Text'):SetText("Enabled")

	local minRenderScaleSlider = CreateFrame("Slider", "DRRMinRenderScaleSlider", self.options, "UISliderTemplateWithLabels")
	minRenderScaleSlider:SetPoint("TOPLEFT", 120, -85)
	minRenderScaleSlider:SetSize(140, 18)
	minRenderScaleSlider:SetMinMaxValues(Round(GetMinRenderScale() + 0), 100)
	minRenderScaleSlider:SetObeyStepOnDrag(true)
	minRenderScaleSlider:SetValue(holder.settings.minRenderScale * 100)
	minRenderScaleSlider:SetValueStep(4)
	minRenderScaleSlider:HookScript("OnValueChanged", function(self, value)
		local roundedValue = Round(value)
		getglobal(minRenderScaleSlider:GetName() .. 'Text'):SetText(roundedValue);
		holder.settings.minRenderScale = roundedValue / 100
	end);
	getglobal(minRenderScaleSlider:GetName() .. 'Low'):SetText(string.format("%s%%", Round(GetMinRenderScale() * 100, 0)));
    getglobal(minRenderScaleSlider:GetName() .. 'High'):SetText('100%');
    getglobal(minRenderScaleSlider:GetName() .. 'Text'):SetText(minRenderScaleSlider:GetValue());

	local downscaleBelowFpsSlider = CreateFrame("Slider", "DRRDownscaleBelowFpsSlider", self.options, "UISliderTemplateWithLabels")
	downscaleBelowFpsSlider:SetPoint("TOPLEFT", 300, -85)
	downscaleBelowFpsSlider:SetSize(140, 18)
	downscaleBelowFpsSlider:SetMinMaxValues(0, 240)
	downscaleBelowFpsSlider:SetObeyStepOnDrag(true)
	downscaleBelowFpsSlider:SetValue(holder.settings.downscaleBelowFps)
	downscaleBelowFpsSlider:SetValueStep(1)
	downscaleBelowFpsSlider:HookScript("OnValueChanged", function(self, value)
		local roundedValue = Round(value)
		getglobal(downscaleBelowFpsSlider:GetName() .. 'Text'):SetText(roundedValue);
		holder.settings.downscaleBelowFps = roundedValue
	end);
	getglobal(downscaleBelowFpsSlider:GetName() .. 'Low'):SetText("0 fps");
    getglobal(downscaleBelowFpsSlider:GetName() .. 'High'):SetText("240 fps");
    getglobal(downscaleBelowFpsSlider:GetName() .. 'Text'):SetText(downscaleBelowFpsSlider:GetValue());

	local downscaleReturnFpsSlider = CreateFrame("Slider", "DRRDownscaleReturnFpsSlider", self.options, "UISliderTemplateWithLabels")
	downscaleReturnFpsSlider:SetPoint("TOPLEFT", 480, -85)
	downscaleReturnFpsSlider:SetSize(140, 18)
	downscaleReturnFpsSlider:SetMinMaxValues(0, 240)
	downscaleReturnFpsSlider:SetObeyStepOnDrag(true)
	downscaleReturnFpsSlider:SetValue(holder.settings.downscaleReturnFps)
	downscaleReturnFpsSlider:SetValueStep(1)
	downscaleReturnFpsSlider:HookScript("OnValueChanged", function(self, value)
		local roundedValue = Round(value)
		getglobal(downscaleReturnFpsSlider:GetName() .. 'Text'):SetText(roundedValue);
		holder.settings.downscaleReturnFps = roundedValue
	end);
	getglobal(downscaleReturnFpsSlider:GetName() .. 'Low'):SetText("0 fps");
    getglobal(downscaleReturnFpsSlider:GetName() .. 'High'):SetText("240 fps");
    getglobal(downscaleReturnFpsSlider:GetName() .. 'Text'):SetText(downscaleReturnFpsSlider:GetValue());

	-- Upscale
	local upscaleTitle = self.options:CreateFontString("ARTWORK", nil, "GameFontNormalLarge")
	upscaleTitle:SetPoint("TOPLEFT", 16, -136)
	upscaleTitle:SetText("Supersampling")

	local upscaleDescription = self.options:CreateFontString("ARTWORK", nil, "GameTooltipText")
	upscaleDescription:SetPoint("TOPLEFT", 20, -160)
	upscaleDescription:SetText("Increase render resolution above 100% when FPS is above the set target. Improves image quality")


	local upscaleEnabledChekBox = CreateFrame("CheckButton", "DRRUpscaleEnabledCheckBox", self.options, "UICheckButtonTemplate")
	upscaleEnabledChekBox:SetPoint("TOPLEFT", 20, -200)
	upscaleEnabledChekBox:HookScript("OnClick", function(self, button, down)
		holder:SetRenderScale(1)
		holder.settings.upscaleEnabled = upscaleEnabledChekBox:GetChecked()
	end)
	upscaleEnabledChekBox:SetChecked(holder.settings.upscaleEnabled)
	getglobal(upscaleEnabledChekBox:GetName() .. 'Text'):SetText("Enabled")

	local maxRenderScaleSlider = CreateFrame("Slider", "DRRMaxRenderScaleSlider", self.options, "UISliderTemplateWithLabels")
	maxRenderScaleSlider:SetPoint("TOPLEFT", 120, -205)
	maxRenderScaleSlider:SetSize(140, 18)
	maxRenderScaleSlider:SetMinMaxValues(100, Round(GetMaxRenderScale() * 100))
	maxRenderScaleSlider:SetObeyStepOnDrag(true)
	maxRenderScaleSlider:SetValue(holder.settings.maxRenderScale * 100)
	maxRenderScaleSlider:SetValueStep(4)
	maxRenderScaleSlider:HookScript("OnValueChanged", function(self, value)
		local roundedValue = Round(value)
		getglobal(maxRenderScaleSlider:GetName() .. 'Text'):SetText(roundedValue);
		holder.settings.maxRenderScale = roundedValue / 100
	end);
	getglobal(maxRenderScaleSlider:GetName() .. 'Low'):SetText('100%');
    getglobal(maxRenderScaleSlider:GetName() .. 'High'):SetText(string.format("%s%%", Round(GetMaxRenderScale() * 100, 200)));
    getglobal(maxRenderScaleSlider:GetName() .. 'Text'):SetText(maxRenderScaleSlider:GetValue());

	local upscaleAboveFpsSlider = CreateFrame("Slider", "DRRUpscaleAboveFpsSlider", self.options, "UISliderTemplateWithLabels")
	upscaleAboveFpsSlider:SetPoint("TOPLEFT", 300, -205)
	upscaleAboveFpsSlider:SetSize(140, 18)
	upscaleAboveFpsSlider:SetMinMaxValues(0, 240)
	upscaleAboveFpsSlider:SetObeyStepOnDrag(true)
	upscaleAboveFpsSlider:SetValue(holder.settings.upscaleAboveFps)
	upscaleAboveFpsSlider:SetValueStep(1)
	upscaleAboveFpsSlider:HookScript("OnValueChanged", function(self, value)
		local roundedValue = Round(value)
		getglobal(upscaleAboveFpsSlider:GetName() .. 'Text'):SetText(roundedValue);
		holder.settings.upscaleAboveFps = roundedValue
	end);
	getglobal(upscaleAboveFpsSlider:GetName() .. 'Low'):SetText("0 fps");
    getglobal(upscaleAboveFpsSlider:GetName() .. 'High'):SetText("240 fps");
    getglobal(upscaleAboveFpsSlider:GetName() .. 'Text'):SetText(upscaleAboveFpsSlider:GetValue());

	local upscaleReturnFpsSlider = CreateFrame("Slider", "DRRUpscaleReturnFpsSlider", self.options, "UISliderTemplateWithLabels")
	upscaleReturnFpsSlider:SetPoint("TOPLEFT", 480, -205)
	upscaleReturnFpsSlider:SetSize(140, 18)
	upscaleReturnFpsSlider:SetMinMaxValues(0, 240)
	upscaleReturnFpsSlider:SetObeyStepOnDrag(true)
	upscaleReturnFpsSlider:SetValue(holder.settings.upscaleReturnFps)
	upscaleReturnFpsSlider:SetValueStep(1)
	upscaleReturnFpsSlider:HookScript("OnValueChanged", function(self, value)
		local roundedValue = Round(value)
		getglobal(upscaleReturnFpsSlider:GetName() .. 'Text'):SetText(roundedValue);
		holder.settings.upscaleReturnFps = roundedValue
	end);
	getglobal(upscaleReturnFpsSlider:GetName() .. 'Low'):SetText("0 fps");
    getglobal(upscaleReturnFpsSlider:GetName() .. 'High'):SetText("240 fps");
    getglobal(upscaleReturnFpsSlider:GetName() .. 'Text'):SetText(upscaleReturnFpsSlider:GetValue());

	-- Behaviour
	local downscaleTitle = self.options:CreateFontString("ARTWORK", nil, "GameFontNormalLarge")
	downscaleTitle:SetPoint("TOPLEFT", 16, -256)
	downscaleTitle:SetText("General Behaviour")

	local gracePeriodDescription = self.options:CreateFontString("ARTWORK", nil, "GameTooltipText")
	gracePeriodDescription:SetPoint("TOPLEFT", 20, -280)
	gracePeriodDescription:SetText("Minimum time that must pass between subsequent render scale changes. Best kept minimal, \nalthough render scale changes might cause frametime spikes due to engine limitation")

	local renderScaleGracePeriodSlider = CreateFrame("Slider", "DRRRenderScaleGracePeriodSlider", self.options, "UISliderTemplateWithLabels")
	renderScaleGracePeriodSlider:SetPoint("TOPLEFT", 20, -340)
	renderScaleGracePeriodSlider:SetSize(600, 18)
	renderScaleGracePeriodSlider:SetMinMaxValues(0, 60)
	renderScaleGracePeriodSlider:SetObeyStepOnDrag(true)
	renderScaleGracePeriodSlider:SetValue(holder.settings.renderScaleChangeGracePeriod)
	renderScaleGracePeriodSlider:SetValueStep(0.1)
	renderScaleGracePeriodSlider:HookScript("OnValueChanged", function(self, value)
		local roundedValue = Round(value, 1)
		getglobal(renderScaleGracePeriodSlider:GetName() .. 'Text'):SetText(roundedValue);
		holder.settings.renderScaleChangeGracePeriod = roundedValue
	end);
	getglobal(renderScaleGracePeriodSlider:GetName() .. 'Low'):SetText("0 sec");
    getglobal(renderScaleGracePeriodSlider:GetName() .. 'High'):SetText("60 sec");
    getglobal(renderScaleGracePeriodSlider:GetName() .. 'Text'):SetText(Round(renderScaleGracePeriodSlider:GetValue(), 1));

	local averageSamplesDescription = self.options:CreateFontString("ARTWORK", nil, "GameTooltipText")
	averageSamplesDescription:SetPoint("TOPLEFT", 20, -400)
	averageSamplesDescription:SetText("Number of frames throughout which average FPS is measured. This helps balance too eager scaling \nupdates due to inconsistent frametime")

	local fpsAverageSamplesSlider = CreateFrame("Slider", "DRRFpsAverageSamplesSlider", self.options, "UISliderTemplateWithLabels")
	fpsAverageSamplesSlider:SetPoint("TOPLEFT", 20, -460)
	fpsAverageSamplesSlider:SetSize(600, 18)
	fpsAverageSamplesSlider:SetMinMaxValues(1, 500)
	fpsAverageSamplesSlider:SetObeyStepOnDrag(true)
	fpsAverageSamplesSlider:SetValue(holder.settings.averagedFrames)
	fpsAverageSamplesSlider:SetValueStep(1)
	fpsAverageSamplesSlider:HookScript("OnValueChanged", function(self, value)
		local roundedValue = Round(value, 1)
		getglobal(fpsAverageSamplesSlider:GetName() .. 'Text'):SetText(roundedValue);
		holder.settings.averagedFrames = roundedValue
	end)
	getglobal(fpsAverageSamplesSlider:GetName() .. 'Low'):SetText("1 sample");
    getglobal(fpsAverageSamplesSlider:GetName() .. 'High'):SetText("500 samples");
    getglobal(fpsAverageSamplesSlider:GetName() .. 'Text'):SetText(Round(fpsAverageSamplesSlider:GetValue(), 1));

	local displayRenderScaleCheckbox = CreateFrame("CheckButton", "DRRDisplayRenderScaleCheckbox", self.options, "UICheckButtonTemplate")
	displayRenderScaleCheckbox:SetPoint("TOPLEFT", 20, -520)
	displayRenderScaleCheckbox:HookScript("OnClick", function(self, button, down)
		holder.settings.displayRenderScale = displayRenderScaleCheckbox:GetChecked()
		holder:displayRenderScale()
	end)
	displayRenderScaleCheckbox:SetChecked(holder.settings.displayRenderScale)
	getglobal(displayRenderScaleCheckbox:GetName() .. 'Text'):SetText("Display Render Scale")

	local displayControlFpsCheckbox = CreateFrame("CheckButton", "DRRDisplayControlFpsCheckbox", self.options, "UICheckButtonTemplate")
	displayControlFpsCheckbox:SetPoint("TOPLEFT", 240, -520)
	displayControlFpsCheckbox:HookScript("OnClick", function(self, button, down)
		holder.settings.displayControlFps = displayControlFpsCheckbox:GetChecked()
		holder:displayControlFps()
	end)
	displayControlFpsCheckbox:SetChecked(holder.settings.displayControlFps)
	getglobal(displayControlFpsCheckbox:GetName() .. 'Text'):SetText("Display Control FPS")
end

function holder:createScaleDisplay()
	self.scaleDisplay = CreateFrame("Frame", "DynamicRenderResolutionScaleDisplay", UIParent, "BackdropTemplate")
	self.scaleDisplay:Hide()
	self.scaleDisplay:SetPoint("CENTER")
	self.scaleDisplay:SetSize(32, 26)
	
	self.scaleDisplay:SetMovable(true)
	self.scaleDisplay:SetUserPlaced(true)
	self.scaleDisplay:SetClampedToScreen(true)
	self.scaleDisplay:HookScript("OnMouseDown", function(self, button)
		self:StartMoving()
	end)
	self.scaleDisplay:HookScript("OnMouseUp", function(self, button)
		self:StopMovingOrSizing()
	end)
	self.scaleText = self.scaleDisplay:CreateFontString(nil, "OVERLAY", "GameTooltipText")
	self.scaleText:SetPoint("CENTER", 0, 6)
	self.framesText = self.scaleDisplay:CreateFontString(nil, "OVERLAY", "GameTooltipText")
	self.framesText:SetPoint("CENTER", 0, -6)
end

-- Handlers

function holder:UpdateControlFps()
	self.controlFps = ReduceTable(self.lastFrames, function(a, b) return a + b end) / #self.lastFrames

end

function holder:onEvent(event, ...)
	if event == "ADDON_LOADED" then
		-- Create Saved Variables
		if not DynamicRenderResolutionDB then
			DynamicRenderResolutionDB = {}
			DynamicRenderResolutionDB.downscaleEnabled = false
			DynamicRenderResolutionDB.upscaleEnabled = false
			DynamicRenderResolutionDB.renderScaleStep = 0.04
			DynamicRenderResolutionDB.renderScaleChangeGracePeriod = 6
			DynamicRenderResolutionDB.minRenderScale = 0.88
			DynamicRenderResolutionDB.maxRenderScale = 1.12
			DynamicRenderResolutionDB.downscaleBelowFps = 72
			DynamicRenderResolutionDB.downscaleReturnFps = 80
			DynamicRenderResolutionDB.upscaleAboveFps = 110
			DynamicRenderResolutionDB.upscaleReturnFps = 100
			DynamicRenderResolutionDB.averagedFrames = 200
			DynamicRenderResolutionDB.displayRenderScale = false
			DynamicRenderResolutionDB.displayControlFps = false
		end
		self.settings = DynamicRenderResolutionDB
		self:createOptionsUI()
		self:UnregisterEvent("ADDON_LOADED")
	elseif event == "FIRST_FRAME_RENDERED" then
		self.renderScale = C_CVar.GetCVar("RenderScale") + 0
		self:UpdateControlFps()
		self:HookScript("OnUpdate", self.onUpdate)
		C_Timer.NewTicker(0.1, function()
			holder:UpdateControlFps()
			if holder.settings.displayRenderScale then
				holder.scaleText:SetText(holder.renderScale)
			end
			if holder.settings.displayControlFps then
				holder.framesText:SetText(Round(holder.controlFps))
			end
		end)
		self:displayRenderScale()
		self:displayControlFps()
		self:UnregisterEvent("FIRST_FRAME_RENDERED")
	elseif event == "PLAYER_LOGIN" then
		self:SetRenderScale(1)
	elseif event == "PLAYER_LEAVING_WORLD" then
		self:SetRenderScale(1)
	end
end

function holder:SetRenderScale(renderScale)
	if (renderScale < self.settings.minRenderScale) then
		self.renderScale = self.settings.minRenderScale
	elseif (renderScale > self.settings.maxRenderScale) then
		self.renderScale = self.settings.maxRenderScale
	else
		self.renderScale = renderScale
	end
	self.timeUntilLastUpdate = self.settings.renderScaleChangeGracePeriod
	C_CVar.SetCVar("RenderScale", renderScale)
end

function holder:IncreaseRenderScale(renderScale, times)
	self:SetRenderScale(renderScale + (times or 1) * self.settings.renderScaleStep)
end

function holder:DecreaseRenderScale(renderScale, times)
	self:SetRenderScale(renderScale - (times or 1) * self.settings.renderScaleStep)
end

function holder:HasCameraMoved()
	local x, y = GetCursorDelta()
	return IsMouseButtonDown() and not (x == 0 and y == 0)
end

function holder:WeighRenderStep(targetFps)
	local fpsDelta = math.abs(1 - (self.controlFps / targetFps))
	local weight = fpsDelta / (self.settings.renderScaleStep * 2)
	return math.max(1, math.floor(weight))
end

function holder:onUpdate(elapsed)
	table.insert(self.lastFrames, 0, GetFramerate())
	if (#self.lastFrames > self.settings.averagedFrames) then
		table.remove(self.lastFrames)
	end

	self.timeUntilLastUpdate = self.timeUntilLastUpdate - elapsed
	if self.timeUntilLastUpdate > 0 or self:HasCameraMoved() then
		return
	end

	if self.renderScale < 1 then
		if (self.controlFps < self.settings.downscaleBelowFps) and self.settings.downscaleEnabled then
			local weight = self:WeighRenderStep(self.settings.downscaleBelowFps)
			self:DecreaseRenderScale(self.renderScale, weight)
		elseif (self.controlFps > self.settings.downscaleReturnFps) and (self.settings.downscaleBelowFps < self.settings.downscaleReturnFps) then
			local weight = self:WeighRenderStep(self.settings.downscaleReturnFps)
			self:IncreaseRenderScale(self.renderScale, weight)
		end
	elseif self.renderScale > 1 then
		if (self.controlFps > self.settings.upscaleAboveFps) and self.settings.upscaleEnabled then
			local weight = self:WeighRenderStep(self.settings.upscaleAboveFps)
			self:IncreaseRenderScale(self.renderScale, weight)
		elseif (self.controlFps < self.settings.upscaleReturnFps) and (self.settings.upscaleAboveFps > self.settings.upscaleReturnFps) then
			local weight = self:WeighRenderStep(self.settings.upscaleReturnFps)
			self:DecreaseRenderScale(self.renderScale, weight)
		end
	else
		if (self.controlFps < self.settings.downscaleBelowFps) and self.settings.downscaleEnabled then
			local weight = self:WeighRenderStep(self.settings.downscaleBelowFps)
			self:DecreaseRenderScale(self.renderScale, weight)
		elseif (self.controlFps > self.settings.upscaleAboveFps) and self.settings.upscaleEnabled then
			local weight = self:WeighRenderStep(self.settings.upscaleAboveFps)
			self:IncreaseRenderScale(self.renderScale, weight)
		end
	end
end

-- Register Addon

holder:RegisterEvent("ADDON_LOADED")
holder:RegisterEvent("FIRST_FRAME_RENDERED")
holder:RegisterEvent("PLAYER_LOGIN")
holder:RegisterEvent("PLAYER_LEAVING_WORLD")
holder:HookScript("OnEvent", holder.onEvent)
holder:createScaleDisplay()


SLASH_DRR1 = "/drr"
SLASH_DRR2 = "/dynamicrenderres"
SLASH_DRR3 = "/dynamicrenderresolution"

SlashCmdList.DRR = function(msg, editBox)
	InterfaceOptionsFrame_OpenToCategory(holder.options)
end