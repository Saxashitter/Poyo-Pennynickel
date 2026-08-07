local Dialogue = {}

Dialogue.Characters = {}
Dialogue.Textsets = {}

Dialogue.LinePosition = 0
Dialogue.LineTics = 0
Dialogue.LineIndex = 0
Dialogue.LineDelay = 0

Dialogue.CurrentText = nil

function PoyoPennynickel.setTextset(name)
	if not Dialogue.Textsets[name] then return end

	Dialogue.CurrentText = name

	Dialogue.LinePosition = 0
	Dialogue.LineTics = Dialogue.Textsets[name].text[1].speed
	Dialogue.LineIndex = 1
	Dialogue.LineDelay = Dialogue.Textsets[name].text[1].tics or 0
end

function PoyoPennynickel.endTextset()
	Dialogue.LinePosition = 0
	Dialogue.LineTics = 0
	Dialogue.LineIndex = 0
	Dialogue.LineDelay = 0

	Dialogue.CurrentText = nil
end

COM_AddCommand("test", function()
	PoyoPennynickel.setTextset("template")
end, COM_ADMIN)

addHook("ThinkFrame", function()
	if not Dialogue.CurrentText then return end

	local textset = Dialogue.Textsets[Dialogue.CurrentText]
	local current_line = textset.text[Dialogue.LineIndex]
	local character = Dialogue.Characters[current_line.character]

	if Dialogue.LineTics then
		Dialogue.LineTics = $ - 1

	elseif Dialogue.LinePosition < #current_line.text then
		Dialogue.LineTics = current_line.speed
		Dialogue.LinePosition = $ + 1
		S_StartSound(nil, character.sound)

	elseif Dialogue.LineDelay then
		Dialogue.LineDelay = $ - 1

	elseif Dialogue.LineIndex < #textset.text then
		Dialogue.LineIndex = $ + 1
		Dialogue.LinePosition = 0
		Dialogue.LineTics = textset.text[Dialogue.LineIndex].speed
		Dialogue.LineDelay = textset.text[Dialogue.LineIndex].tics or 0

	else
		PoyoPennynickel.endTextset()

	end
end)

addHook("NetVars", function(network)
	Dialogue.LinePosition = network($)
	Dialogue.LinePosition = network($)
	Dialogue.LineTics = network($)
	Dialogue.LineIndex = network($)

	Dialogue.TextIndex = network($)
	Dialogue.CurrentText = network($)
end)

PoyoPennynickel.Dialogue = Dialogue