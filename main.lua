--[[
* TODO
	* No-head dialogue box
	* CLEAN UP CODE
]]--
local ogDiag = ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__MES_WINDOW)
local diagParent = ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__NPC_CHAT_HOLDER)
local diagPanel, bgResource, dragHandle
local clickHookActive = false

function createDragHandle()
	dragHandle = ui.Rectangle.new(diagParent)
	dragHandle:SetPos(diagPanel.root.x+15, diagPanel.root.y+15)
	dragHandle:SetSize(diagPanel.root.width-55, 36)
	dragHandle.rgba = 0x00000000
	dragHandle.clickthrough = false
	dragHandle.dragConfig.draggedComponent = diagParent
	dragHandle:Subscribe(ui.Hook.ONDRAG, function(self, x, y)
	    local parentPos = diagParent.xyGlobal
	    diagPanel.root:SetPos(x - parentPos.x - 15,y - parentPos.y - 15)
	    self:SetPos(x - parentPos.x,y - parentPos.y)
	end)
end

local function closeDialogue()
    if dragHandle then
        dragHandle:Destroy()
        dragHandle = nil
    end

    if diagPanel then
        diagPanel:Destroy()
        diagPanel = nil
    end

    if clickHookActive then
        diagParent:Unsubscribe(ui.Hook.ONCLICK, "custom-dialogue-close")
        clickHookActive = false
    end

    activeDialogue = nil
end

local activeDialogue = nil
local Dialogue = {}
Dialogue.__index = Dialogue
Dialogue.isPlayer = false
Dialogue.action = nil
function dialogue(npcName, modelID, dialogueText, modelSize)
	return setmetatable({
		npcName = npcName,
		modelID = modelID,
		dialogueText = dialogueText,
		modelSize = modelSize
	}, Dialogue)
end

function Dialogue:Close()
	if activeDialogue == self then
		closeDialogue()
	end
end

function Dialogue:Show(npcName, modelID, dialogueText, modelSize)
	closeDialogue()

	activeDialogue = self
	local npcName = self.npcName
	local modelID = self.modelID
	local dialogueText = self.dialogueText
	local modelSize = self.modelSize

	local textX, chatheadX
	local chatheadWidth = 67
	local chatheadMargin = 24

	bgResource = Plugin.resources.dialogue_bg
	bgResource:Load()
	diagPanel = prettyui.SimpleView.new(diagParent, {
		x = ogDiag.x-15,
		y = ogDiag.y-12,
		width = ogDiag.width+15,
		height = ogDiag.height+15,
		scrollable = false,
	})

	if self.isPlayer then
		textX = 20
		chatheadX = ogDiag.width - chatheadWidth * 2 + 9
	else
		textX = 160
		chatheadX = chatheadMargin
	end

	-- Create an invisible drag handle
	createDragHandle()

	-- Chatbox background
	diagPanel:AddSprite(bgResource, {
		width = ogDiag.width,
		height = ogDiag.height,
		rowBackgroundEdgeToEdge = true,
	})

	-- Circular background
	diagPanel:AddSprite(8124, {
		x = chatheadX,
		y = 22,
		width = chatheadWidth,
		height = 134
	})
	diagPanel:AddSprite(6964, {
		x = chatheadX + chatheadWidth,
		y = 22,
		width = chatheadWidth,
		height = 134
	})

	local npctext = diagPanel:AddText({
		text = dialogueText or "PLACEHOLDER",
		font = id.Font.NOTOSANS_12,
		x = textX,
		y = 62,
		width = 350,
		height = 70,
		colour = 0x000000ff,
		shadowed = false
	})
	npctext:AlignTo(ui.AlignMode.CENTRE)

	local npcname = diagPanel:AddText({
		text = npcName or "PLACEHOLDER",
		font = id.Font.CINZEL_12PT_BOLD,
		x = 139,
		y = 20,
		width = 276,
		height = 30,
		colour = 0xF0BE79FF
	})
	npcname:AlignTo(ui.AlignMode.CENTRE)

	-- Create the camera
	local fov = 60.0
	if modelSize == "tiny" then
		fov = 25.0
	elseif modelSize == "small" then
		fov = 35.0
	elseif modelSize == "large" then
		fov = 75.0
	end

	local lookVector
	if self.isPlayer then
		lookVector = Vector3.new(0.0, 50.0, 0.0)
	else
		lookVector = Vector3.new(-200.0, 50.0, 0.0)
	end
	local camera = ui.ModelCameraInfo.new()
	camera:SetFOV(fov, 0)
	camera:SetPosition(Vector3.new(350.0, 0.0, -1800.0), 0)
	camera.useLookAt = true
	camera.clearColour = Vector4.new(0.0, 0.0, 0.0, 0.0)
	camera:SetLookAt(lookVector, 0)

	-- Create the model group
	local modelGroup = ui.ModelGroup.new(diagPanel.root)
	modelGroup:SetSize(chatheadWidth * 2, chatheadWidth * 2)
	modelGroup:SetPos(chatheadX, 22)

	-- Assign the camera
	modelGroup:SwitchCamera(modelGroup:AddCamera(camera), ui.ModelCameraTransition.NONE, -1, 0)
	modelGroup:SetSize(120, chatheadWidth*2)

	-- Create the chathead
		-- Create the chathead
	local chathead = ui.Model.new(modelGroup)
	chathead:SetSize(chatheadWidth * 2, chatheadWidth * 2)
	chathead:SetModel(ui.ModelType.MODEL, modelID or 39830)
	chathead.animID = 9807

	local lookDirection
	if self.isPlayer then
		lookDirection = Vector3.new(math.rad(45/3), math.rad(0), math.rad(-10))
	else
		lookDirection = Vector3.new(math.rad(-45), math.rad(-10), math.rad(10))
	end
	chathead:SetTransform(
	    Vector3.new(0, 0, 0),
	    lookDirection,
	    Vector3.new(1, 1, 1),
	    0
	)

	local contButton = diagPanel:AddSprite(18635,{
		inline = false,
		toggleable = false,
		width = 80,
		height = 19,
		x = 237,
		y = 131
	})
	contButton.root:Subscribe(ui.Hook.ONMOUSEOVER, function (button, x, y)
		button.sprite = 18636
	end)
	contButton.root:Subscribe(ui.Hook.ONMOUSELEAVE, function (button, x, y)
		button.sprite = 18635
	end)
	contButton.root:Subscribe(ui.Hook.ONCLICK, function (button, x, y)
		button.sprite = 18637
	end)
	contButton.root:Subscribe(ui.Hook.ONRELEASE, function (button, x, y)
		button.sprite = 18635
		self:Close()
		if self.action then self.action() end
	end)


	diagPanel.root:Subscribe(ui.Hook.ONKEY, function(self, code, char) -- Close diag
		if char == 27 then activeDialogue:Close() end
	end)
	diagParent:Subscribe(ui.Hook.ONCLICK, "custom-dialogue-close", function (self, x, y) 
		if activeDialogue then activeDialogue:Close() end
	end)

	clickHookActive = true
end

--[[
======
CHOICE
======
]]--
local Choice = {}
Choice.__index = Choice
function choice(title, opt1, opt2, opt3, opt4, opt5)
	return setmetatable({
		title = title,
		opt1 = opt1,
		opt2 = opt2,
		opt3 = opt3,
		opt4 = opt4,
		opt5 = opt5,
	}, Choice)
end

function Choice:Close()
	if activeDialogue == self then
		closeDialogue()
	end
end

function Choice:Show(title, opt1, opt2, opt3, opt4, opt5)
	closeDialogue()

	activeDialogue = self
	local title = self.title
	local opt1 = self.opt1
	local opt2 = self.opt2
	local opt3 = self.opt3
	local opt4 = self.opt4
	local opt5 = self.opt5

	local options = {opt1, opt2, opt3, opt4, opt5}
	local n = #options
	if n < 2 then
		log("A Choice window requires at least 2 options.")
		return
	end

	bgResource = Plugin.resources.dialogue_bg
	bgResource:Load()
	diagPanel = prettyui.SimpleView.new(diagParent, {
		x = ogDiag.x-15,
		y = ogDiag.y-12,
		width = ogDiag.width+15,
		height = ogDiag.height+15,
		scrollable = false,
	})

	-- Create an invisible drag handle
	createDragHandle()

	-- Chatbox background
	diagPanel:AddSprite(bgResource, {
		width = ogDiag.width,
		height = ogDiag.height,
		rowBackgroundEdgeToEdge = true,
	})

	local choiceTitle = diagPanel:AddText({
		text = title or "PLACEHOLDER",
		font = id.Font.CINZEL_12PT_BOLD,
		x = 10,
		y = 18,
		width = 492,
		height = 30,
		colour = 0xF0BE79FF,
		isShadowed = true
	})
	choiceTitle:AlignTo(ui.AlignMode.CENTRE)
	local closeBtn = diagPanel:AddSprite(32974, {
		x = -31,
		y = 24,
		width = 19,
		height = 19,
		xAnchor = 1
	})
	closeBtn.root:Subscribe(ui.Hook.ONMOUSEOVER, function (self, x, y)
		self.sprite = 32975
	end)
	closeBtn.root:Subscribe(ui.Hook.ONMOUSELEAVE, function (self, x, y)
		self.sprite = 32974
	end)
	closeBtn.root:Subscribe(ui.Hook.ONCLICK, function (self, x, y)
		self.sprite = 32975
	end)
	closeBtn.root:Subscribe(ui.Hook.ONRELEASE, function (self, x, y)
		self.sprite = 32974
		activeDialogue:Close()
	end)
	closeBtn.root:Subscribe(ui.Hook.ONCLICK, "custom-dialogue-close", function (self, x, y) 
		if activeDialogue then activeDialogue:Close() end
	end)
	closeBtn.root:MoveToFront()
	closeBtn.root.clickthrough = false

	local font = config.Font.FromID(id.Font.MUSEO_SANS_11PT_REGULAR)
	-- Determine the width of the longest option
	local maxWidth = 0
	for _, option in ipairs(options) do
	    local width = font:GetStringWidth(option.label)
	    maxWidth = math.max(maxWidth, width)
	end
	local barWidth = maxWidth + 70 -- 35px for each end
	local startX = math.floor((ogDiag.width - barWidth) / 2) + 10

	local spacing = clamp(10 - 5 * (n - 3), 1, 10)
	local startY = math.floor((100 - (n * 18 + (n - 1) * spacing)) / 2) - 1
	for i, option in ipairs(options) do
	    local y = startY + (i - 1) * (18 + spacing) + 50

	    local optBorderLeft = diagPanel:AddSprite(9059, {
	        x = startX,
	        y = y,
	        width = 35,
	        height = 20,
	    })
	    local optBorderMiddle = diagPanel:AddSprite(9060, {
	        x = startX + 35,
	        y = y,
	        width = maxWidth+10,
	        height = 20,
	    })
	    local optBorderRight = diagPanel:AddSprite(9061, {
	        x = startX + 35 + maxWidth+10,
	        y = y,
	        width = 35,
	        height = 20,
	    })

	    local function choiceHover()
			optBorderLeft.root.sprite = 9062
			optBorderMiddle.root.sprite = 9063
			optBorderRight.root.sprite = 9064
		end

		local function choiceHoverEnd()
			optBorderLeft.root.sprite = 9059
			optBorderMiddle.root.sprite = 9060
			optBorderRight.root.sprite = 9061
		end

		local function selectOption()
	    	closeDialogue()
	    	if option.action then option.action() end
	    end
	    
		optBorderLeft.root:Subscribe(ui.Hook.ONMOUSEOVER, choiceHover)
	    optBorderMiddle.root:Subscribe(ui.Hook.ONMOUSEOVER, choiceHover)
	    optBorderRight.root:Subscribe(ui.Hook.ONMOUSEOVER, choiceHover)

	    optBorderLeft.root:Subscribe(ui.Hook.ONMOUSELEAVE, choiceHoverEnd)
	    optBorderMiddle.root:Subscribe(ui.Hook.ONMOUSELEAVE, choiceHoverEnd)
	    optBorderRight.root:Subscribe(ui.Hook.ONMOUSELEAVE, choiceHoverEnd)

	    optBorderLeft.root:Subscribe(ui.Hook.ONCLICK, selectOption)
	    optBorderMiddle.root:Subscribe(ui.Hook.ONCLICK, selectOption)
	    optBorderRight.root:Subscribe(ui.Hook.ONCLICK, selectOption)

	    local choiceNumber = diagPanel:AddText({
	        text = tostring(i) .. ".",
	        font = font.id,
	        x = startX + 8,
	        y = y+1,
	        width = 35,
	        height = 18,
	        colour = 0xE3D7CFFF,
	        shadowed = false
	    })
	    choiceNumber:AlignTo(ui.AlignMode.CENTRE)

	    local choiceLabel = diagPanel:AddText({
	        text = option.label or "PLACEHOLDER",
	        font = font.id,
	        x = startX + 43,
	        y = y+1,
	        width = maxWidth,
	        height = 18,
	        colour = 0xE3D7CFFF,
	        shadowed = false
	    })
	    choiceLabel:AlignTo(ui.AlignMode.CENTRE)
	end

	diagPanel.root:Subscribe(ui.Hook.ONKEY, function(self, code, char) -- Close diag
		if char == 27 then activeDialogue:Close() end
	end)
	diagParent:Subscribe(ui.Hook.ONCLICK, "custom-dialogue-close", function (self, x, y) 
		if activeDialogue then activeDialogue:Close() end
	end)

	clickHookActive = true
end

function dialogueSequence(dialogues)
	if #dialogues < 2 then return end

	for i=1, #dialogues-1 do
		dialogues[i].action = function() dialogues[i+1]:Show() end
	end

	return dialogues[1]
end

function PluginShutdown()
	if qsParent then
		qsParent:Destroy()
		qsParent = nil
	end
	closeDialogue()
end

return {
	dialogue = dialogue,
	choice = choice,
	sequence = dialogueSequence
}