local configPath = getCheatEngineDir().."SWEP1RCR_CM.cfg"
local exePath = "SWEP1RCR.exe"

local aiLevel = "8.64"
local aiSpread = "20.00"
local deathMin = "325.00"
local deathDrop = "140.00"

local pid = nil
local loadState = 0

local asm = [==[
// Cheat Menu in Pause Screen
SWEP1RCR.exe+2A951:
mov dword ptr [SWEP1RCR.exe+10C044],01
mov eax,[esp+0C]
push SWEP1RCR.exe+B93C4
push eax
call SWEP1RCR.exe+9EB80
add esp,08
mov eax, 00000001
pop esi
ret
nop
nop
nop

// Invicibility
SWEP1RCR.exe+2A5D7:
jmp SWEP1RCR.exe+2A5FA

// AI Level
SWEP1RCR.exe+2A627:
jmp SWEP1RCR.exe+2A649

// AI Spread
SWEP1RCR.exe+2A671:
jmp SWEP1RCR.exe+2A683

// Death SpeedMin
SWEP1RCR.exe+2A6A5:
jmp SWEP1RCR.exe+2A6B7

// Death SpeedDrop
SWEP1RCR.exe+2A6D9:
jmp SWEP1RCR.exe+2A6EB

// Spline Markers
SWEP1RCR.exe+2A70D:
jmp SWEP1RCR.exe+2A720

// Mirrored Mode
SWEP1RCR.exe+2A750:
jmp SWEP1RCR.exe+2A763

// Vehicle Stats
SWEP1RCR.exe+2A7AD:
jmp SWEP1RCR.exe+2A7BD

// Skip Processing Checks
SWEP1RCR.exe+2AA20:
jmp SWEP1RCR.exe+2AA2D

SWEP1RCR.exe+2AA40:
jmp SWEP1RCR.exe+2AA4D

SWEP1RCR.exe+2AA6F:
jmp SWEP1RCR.exe+2AA7C

SWEP1RCR.exe+2AA9E:
jmp SWEP1RCR.exe+2AAAB

SWEP1RCR.exe+2AACD:
jmp SWEP1RCR.exe+2AAD6

SWEP1RCR.exe+2AAF8:
jmp SWEP1RCR.exe+2AB01

SWEP1RCR.exe+2AB14:
jmp SWEP1RCR.exe+2AB1D

SWEP1RCR.exe+2AB67:
jmp SWEP1RCR.exe+2AB70


]==]

function onActivate()
	if (TrainerOrigin ~= nil) then
		configPath = TrainerOrigin.."SWEP1RCR_CM.cfg"
	end

	loadSettings()
end

function patchGame()
	print("patchGame")
	reinitializeSymbolhandler()
	-- Enable Cheat Menu
	autoAssemble(asm)


	local inj = injectSettings()
	autoAssemble(inj)
end

function injectSettings()

	local byte = {}
	byte.invincibility = "01"
	byte.splineMarkers = "01"
	byte.mirroredMode = "40"

	if (not PRCM.CMToggleBox1.Checked) then
		byte.invincibility = "00"
	end

	if (not PRCM.CMToggleBox6.Checked) then
		byte.splineMarkers = "00"
	end

	if (not PRCM.CMToggleBox7.Checked) then
		byte.mirroredMode = "00"
	end

	return string.format([==[
globalAlloc(EventLoad,1)
EventLoad:
db 0

globalAlloc(EventUnload,1)
EventUnload:
db 0

globalAlloc(Injection,1024)
globalAlloc(Ejection,1024)

define(SettingInvincibility,%s)
define(SettingAiLevel,(float)%.2f)
define(SettingAiSpread,(float)%.2f)
define(SettingDeathMin,(float)%.2f)
define(SettingDeathDrop,(float)%.2f)
define(SettingSplines,%s)
define(SettingMirrored,%s)

Injection:
mov [SWEP1RCR.exe+10CA28],SettingInvincibility
mov [SWEP1RCR.exe+C707C],SettingAiLevel
mov [SWEP1RCR.exe+C7080],SettingAiSpread
mov [SWEP1RCR.exe+C7BB8],SettingDeathMin
mov [SWEP1RCR.exe+C7BBC],SettingDeathDrop
mov [SWEP1RCR.exe+10CA24],SettingSplines
mov [SWEP1RCR.exe+A996DD],SettingMirrored
mov [EventLoad],1
cmp [SWEP1RCR.exe+10CA3C],ebx
je SWEP1RCR.exe+63DF8
jmp SWEP1RCR.exe+63BDC

Ejection:
mov [EventUnload],1
xor eax,eax
pop edi
pop esi
pop ebp
pop ebx
add esp,40
ret

SWEP1RCR.exe+63BD0:
jmp Injection

SWEP1RCR.exe+63E8D:
jmp Ejection
]==],
	byte.invincibility,
	(aiLevel / 10.00),
	aiSpread,
	deathMin,
	deathDrop,
	byte.splineMarkers,
	byte.mirroredMode)
end

function onTimer(sender)
	local id = getProcessIDFromProcessName("SWEP1RCR.exe")

	if (id ~= nil) and (id ~= pid) then
		if (id ~= getOpenedProcessID()) then
			openProcess(id)
		end
        local threads = createStringlist()
        getThreadlist(threads)
		if (threads ~= nil) and (threads.Count > 2) then
			pid = id
			patchGame()
		else
			pid = nil
		end
	end

	local linked = (pid ~= nil)

	if (linked) then
		PRCM.CELabel8.font.color = 0xff9933
		PRCM.CELabel8.Caption = "SWEP1RCR.exe ("..pid..") Linked"
		watchForLoading()
	else
		PRCM.CELabel8.font.color = 0xA0A0A0
		PRCM.CELabel8.Caption = "Looking for SWEP1RCR.exe"
	end

    local enabled = (loadState == 0)
	PRCM.CMPanel1.Enabled = enabled
	PRCM.CMPanel2.Enabled = enabled
	PRCM.CMPanel3.Enabled = enabled
	PRCM.CMPanel4.Enabled = enabled
	PRCM.CMPanel5.Enabled = enabled
	PRCM.CMPanel6.Enabled = enabled
	PRCM.CMPanel7.Enabled = enabled
end

function watchForLoading()
	if (readBytes("EventLoad",1,false) == 0x01) then
        
		writeBytes("EventLoad",0x00)
		loadState = loadState + 1

		print("Event Load " .. loadState)
	end

	if (readBytes("EventUnload",1,false) == 0x01) then
        
		writeBytes("EventUnload",0x00)

		if (loadState > 0) then
			loadState = loadState - 1
			print("Event Unload " .. loadState)

			-- Invincibility
			PRCM.CMToggleBox1.Checked = (readBytes("SWEP1RCR.exe+10CA28", 1, false) == 0x01)
			if (PRCM.CMToggleBox1.Checked) then
				PRCM.CMToggleBox1.Caption = "On"
			else
				PRCM.CMToggleBox1.Caption = "Off"
			end

			-- AI Difficulty
			aiLevel = string.format("%.2f",(readFloat("SWEP1RCR.exe+C707C") * 10.00))
			PRCM.CMEdit2.Text = aiLevel

			-- AI Spread
			aiSpread = string.format("%.2f",(readFloat("SWEP1RCR.exe+C7080")))
			PRCM.CMEdit3.Text = aiSpread
			
			-- Death SpeedMin
			deathMin = string.format("%.2f",(readFloat("SWEP1RCR.exe+C7BB8")))
			PRCM.CMEdit4.Text = deathMin
			
			-- Death SpeedDrop
			deathDrop = string.format("%.2f",(readFloat("SWEP1RCR.exe+C7BBC")))
			PRCM.CMEdit5.Text = deathDrop

			-- Spline Markers
			PRCM.CMToggleBox6.Checked = (readBytes("SWEP1RCR.exe+10CA24", 1, false) == 0x01)
			if (PRCM.CMToggleBox6.Checked) then
				PRCM.CMToggleBox6.Caption = "On"
			else
				PRCM.CMToggleBox6.Caption = "Off"
			end

			-- Mirrored Mode
			PRCM.CMToggleBox7.Checked = (readBytes("SWEP1RCR.exe+A996DD", 1, false) == 0x40)
			if (PRCM.CMToggleBox7.Checked) then
				PRCM.CMToggleBox7.Caption = "On"
			else
				PRCM.CMToggleBox7.Caption = "Off"
			end
			
			saveSettings(false)
		end
	end
end

function saveSettings(reinject)
	local file = io.open(configPath, "w")
	if (file ~= nil) then
		file:write(tostring(PRCM.CMToggleBox1.Checked).."\n")
		file:write(aiLevel.."\n")
		file:write(aiSpread.."\n")
		file:write(deathMin.."\n")
		file:write(deathDrop.."\n")
		file:write(tostring(PRCM.CMToggleBox6.Checked).."\n")
		file:write(tostring(PRCM.CMToggleBox7.Checked).."\n")
		file:close()
	end

	if (reinject) then
		local inj = injectSettings()
		autoAssemble(inj)
	end
end

function loadSettings()
	local file = io.open(configPath, "r")

	if (file ~= nil) then
		PRCM.CMToggleBox1.Checked = (file:read() == "true")
		aiLevel = file:read()
		aiSpread = file:read()
		deathMin = file:read()
		deathDrop = file:read()
		PRCM.CMToggleBox6.Checked = (file:read() == "true")
		PRCM.CMToggleBox7.Checked = (file:read() == "true")
		PRCM.CMEdit2.Text = aiLevel
		PRCM.CMEdit3.Text = aiSpread
		PRCM.CMEdit4.Text = deathMin
		PRCM.CMEdit5.Text = deathDrop
		file:close()
	end
end

function toggleButton(sender)
	if (sender.Checked) then
		sender.Caption = "On"
	else
		sender.Caption = "Off"
	end
	saveSettings(true)
end

function changeAiLevel(sender)
	local input = tostring(tonumber(sender.Text))
	if (input == sender.Text) then
		local val = tonumber(string.format("%.2f", input))
		val = math.max(math.min(val, 20.00), 0.00)
		aiLevel = string.format("%.2f", val)
		saveSettings(true)
	end
	sender.Text = aiLevel
end

function changeAiSpread(sender)
	local input = tostring(tonumber(sender.Text))
	if (input == sender.Text) then
		local val = tonumber(string.format("%.2f", input))
		val = math.max(math.min(val, 200.00), 2.00)
		aiSpread = string.format("%.2f", val)
		saveSettings(true)
	end
    sender.Text = aiSpread
end

function changeSpeedMin(sender)
	local input = tostring(tonumber(sender.Text))
	if (input == sender.Text) then
		local val = tonumber(string.format("%.2f", input))
		val = math.max(math.min(val, 1000.00), 20.00)
		deathMin = string.format("%.2f", val)
		saveSettings(true)
	end
	sender.Text = deathMin
end

function changeSpeedDrop(sender)
	local input = tostring(tonumber(sender.Text))
	if (input == sender.Text) then
		local val = tonumber(string.format("%.2f", input))
		val = math.max(math.min(val, 500.00), 20.00)
		deathDrop = string.format("%.2f", val)
		saveSettings(true)
	end
	sender.Text = deathDrop
end

PRCM:show()