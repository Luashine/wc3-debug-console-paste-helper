Func toBoolean($var)
	If IsBool($var) then
		return $var
	elseif IsNumber($var) then
		return $var = 0 ? False : True
	elseif IsString($var) then
		local $str = StringLower($var)
		if $str = "true" or $str = "1" or $str = "+" or $str = "y" or $str = "yes" then
			return True
		elseif $str = "false" or $str = "0" or $str = "-" or $str = "n" or $str = "no" then
			return False
		endif
	else
		MsgBox(16, @ScriptName, "toBoolean conversion error" & @CRLF _
		& "Could not convert input to boolean." & @CRLF _
		& "Value (as String):" & @CRLF _
		& String($var) _
		)
	endif
endfunc

; this is executed before single-instance check, idc
Global Const $CFG_NAME = "wc3-code-paste-config.ini"

If FileExists($CFG_NAME) = 1 then
	Global Const $CFG_SEND_KEY_DELAY = Number(IniRead($CFG_NAME, "general", "SendKeyDelay", 50))
	Global Const $CFG_SEND_KEY_DOWN_DELAY = Number(IniRead($CFG_NAME, "general", "SendKeyDownDelay", 100))
	
	Global Const $CFG_ENABLE_SOUND = toBoolean(IniRead($CFG_NAME, "sound", "enabled", True))
	
	; inclusive 127 UTF-8 characters. Tested on v1.32.10
	Global Const $WC3_CHAT_LENGTH_LIMIT = Number(IniRead($CFG_NAME, "warcraft", "chat_length_limit", 127))
else
	IniWrite($CFG_NAME, "general", "SendKeyDelay", "50")
	IniWrite($CFG_NAME, "general", "SendKeyDownDelay", "100")
	IniWrite($CFG_NAME, "sound", "enabled", "true")
	IniWrite($CFG_NAME, "warcraft", "chat_length_limit", "127")
Endif




