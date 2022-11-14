#include <MsgBoxConstants.au3>
#include <StringConstants.au3>
#include <Misc.au3>
#include <WinAPIvkeysConstants.au3>
#include <Process.au3>

#include "CreateSemaphore_udf.au3"

; Attempted:
; See with API Monitor v2 whether game uses RegisterHotkey: NO
; Hook other Clipboard functions: None showed up
; Try PostMessage for unattended pasting: Nope
; Plain Send: works :/


Func displayArray(ByRef $array)
    Local $arrayLength = UBound($array)

    For $i = 0 To $arrayLength - 1
        MsgBox($MB_OK, "displayArray", $array[$i])
    Next
EndFunc

Func getClipboardLinesForWc3()
	local $text = ClipGet()
	if @error <> 0 then
		SoundPlay(@WindowsDir & "\media\Windows Critical Stop.wav", $SOUND_NOWAIT)
		local $empty[1] = [""]
		return $empty
	endif

	; Regular copied text contains \r\n line endings
	
	; StringReplace($text, @CR, "")
	; local $crCount = @extended
	; StringReplace($text, @LF, "")
	; local $lfCount = @extended
	
	; MsgBox(0, "New line count:", _
		; "Occurrences: " & @CRLF & _
		; "CR = " & $crCount & @CRLF & _
		; "LF = " & $lfCount & @CRLF _
	; )
	
	; The array will purposefully contain empty lines
	; Index 0 is array size, but we will put the original clipboard text here
	local $textLines = StringSplit($text, @CRLF) ; default splits at \r AND \n each
	
	;displayArray($textLines) ; correct here
	
	if UBound($textLines) <= 1 then
		MsgBox(0, "Error", "Expected more than 1 element after split")
	elseif UBound($textLines) == 2 then
		; nothing needs to be changed, paste the line as is
		return $textLines
	else
	
		local $lastLineNonEmpty = 0
		for $i = 1 to UBound($textLines) - 1
			; has non-whitespace character?
			if StringRegExp($textLines[$i], "\S") = 1 then
				$lastLineNonEmpty = $i
			endif
		next
		
		; lastLineNonEmpty is an index, [0] has the full string
		local $wc3Lines[$lastLineNonEmpty + 1]
		$wc3Lines[0] = $text
		
		for $i = 1 to $lastLineNonEmpty
			local $textLine = $textLines[$i]
			
			if StringLen($textLine) == 0 then
				; skip
				ContinueLoop
			endif
			
			; strip leading and trailing whitespace-type chars
			local $wc3Line = StringStripWS( _
				StringStripWS($textLine, $STR_STRIPLEADING), _
				$STR_STRIPTRAILING)
			
			if $i <> $lastLineNonEmpty then
				; add continuation character
				$wc3Lines[$i] = ">" & $wc3Line
			else
				; final line, execute after this
				$wc3Lines[$i] = $wc3Line
			endif
		next
		
		;displayArray($wc3Lines) ; correct
		;Sleep(750)
		
		return $wc3Lines
	endif
	
	local $arr[1] = [""]
	return $arr
Endfunc

Func copyPasteCodeToWc3()
	Local $wc3Lines = getClipboardLinesForWc3()
	if $wc3Lines[0] <> "" then
		local $sendKeyDelay_restore = AutoItSetOption("SendKeyDelay")
		local $sendKeyDownDelay_restore = AutoItSetOption("SendKeyDownDelay")
		AutoItSetOption("SendKeyDelay", 50)
		AutoItSetOption("SendKeyDownDelay", 100)
		
		Send("{ENTER}")
		for $i = 1 to UBound($wc3Lines)-1
			local $line = $wc3Lines[$i]
			if $line == "" then
				ContinueLoop
			endif
			
			ClipPut($line)
			Send("{ENTER}")
			Send("^v") ; CTRL+V to paste (small v, capital V does not work)
			
			Send("{ENTER}")
			Sleep(20)
		next
		
		AutoItSetOption("SendKeyDelay", $sendKeyDelay_restore)
		AutoItSetOption("SendKeyDownDelay", $sendKeyDownDelay_restore)
		ClipPut($wc3Lines[0]) ; restore clipboard
		Beep(800,300)
	endif
Endfunc

; Modified original Au3 code, instead of a string takes a literal hex value
Func _IsPressedFast($vk_key, $vDLL = "user32.dll")
	Local $aCall = DllCall($vDLL, "short", "GetAsyncKeyState", "int", $vk_key)
	If @error Then Return SetError(@error, @extended, False)
	Return BitAND($aCall[0], 0x8000) <> 0
EndFunc   ;==>_IsPressedFast

Func enforceSingleInstance()
	local $semName = "wc3-paste-helper-au3"
	local $exitCode = CreateSingletonSemaphore($semName)
	
	if $exitCode <> 0 then ; more than one running
		MsgBox($MB_ICONERROR, "The program is already running!", "This program is already launched: '" & $semName & "'. Close the last instance before you launch it again." & @CRLF & "Exiting...")
		Exit 1
	endif
Endfunc

enforceSingleInstance()
Global $user32H = DllOpen("user32.dll")
While 1

	; VK_CONTROL - Any CTRL
	if _IsPressedFast($VK_CONTROL, $user32H) _
		and _IsPressedFast($VK_B, $user32H) then
		
		while _IsPressedFast($VK_CONTROL, $user32H)
			Sleep(50)
			; Wait for CTRL to be unpressed, or it will be bugged
			; and remain in CTRL_DOWN state system-wide!
		Wend
		
		Beep(500,300)
		copyPasteCodeToWc3()
		
		Sleep(300)
	endif
	
	Sleep(100)
Wend
DllClose($user32H)

Sleep(2000)

