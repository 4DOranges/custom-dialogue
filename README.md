# custom-dialogue
Custom Dialogue plugin for RS3

Still working on ironing out some edge-cases, but I got it to a previewable stage at least.
This plugin will allow you to make your own custom NPC/Player dialogue, including custom choices.

**Dialogue** has 3-4 parameters, with the last one optional:
* **Name** of the person talking
* **ID** of the model for their chathead
* The **text** being shown
* (optional) the **size** of their chathead model (one of: "tiny", "small", or "large".).
  * This is used to set the camera's FOV, to adjust the size of the model as it's being displayed in the chatbox
  * If this one is not provided, "normal" is used.
Each dialogue object also has 2 optional parameters you can set:
* `.isPlayer` (bool): Whether or not the chathead should be shown on the right side, as if a player is speaking. Default "false"
* `.action` (function): A custom action to execute when the "continue" button is clicked. Default action closes the dialogue.

**Choices** has 3-6 parameters: the **question** being asked & **Option 1-5**. You need at least 2 options.
Options are provided in the format: `{label="Text to show", action=functionToExecuteWhenClicked}`

There is also a **dialogueSequence**, which allows you to easily chain multiple dialogues together. This has a single parameter: a table of dialogue objects.
For example, if we wanted to chain death, orangesAngry and orangesHappy (see below) without the choices, we'd use:
```lua
local convo = dialogueSequence({death, orangesAngry, orangesHappy})
convo:Show()
```

To end on an example, the code to make the preview video work is:
```lua
local death = dialogue("Death", 120646, "So, about that 4D Oranges... Is he a noob?")
local orangesAngry = dialogue("4D Oranges", 103836, "Rude!", "small")
local orangesHappy = dialogue("4D Oranges", 103836, "Thank you! <sprite=18851>", "small")
orangesAngry.isPlayer, orangesHappy.isPlayer = true, true

local opt1 = {label="Yes, he is a noob.", action=function() orangesAngry:Show() end}
local opt2 = {label="No.", action=function() orangesHappy:Show() end}
local choices = choice("Is 4D Oranges a noob?", opt1, opt2)
death.action = function() choices:Show() end
death:Show()
```
