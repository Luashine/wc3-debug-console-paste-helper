#include <MsgBoxConstants.au3>
#include <StringConstants.au3>
#include <Misc.au3>
#include <WinAPIvkeysConstants.au3>
#include <Process.au3>

#include "CreateSemaphore_udf.au3"
#include "config.au3"

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
	$textLines[0] = $text
	
	;displayArray($textLines) ; correct here
	
	if UBound($textLines) <= 1 then
		MsgBox(0, "Error", "Expected more than 1 element after split")
		local $arr[1] = [""]
		return $arr
	elseif UBound($textLines) == 2 then
		; nothing needs to be changed, paste the line as is
		if enforceLineLengthArr($textLines, 1, 1) then
			return $textLines
		else
			local $empty[1] = [""]
			return $empty
		endif
	else
		; count non-whitespace lines for array alloc
		Local $nonEmptyLineCount = 0
		for $i = 1 to UBound($textLines) - 1
			; has non-whitespace character?
			if StringRegExp($textLines[$i], "\S") = 1 then
				$nonEmptyLineCount += 1
			endif
		next
		
		; lastLineNonEmpty is an index, [0] has the full string
		Local $wc3Lines[$nonEmptyLineCount + 1]
		$wc3Lines[0] = $text
		
		; fill in array
		local $wc3LinesIndex = 1
		local $textLinesIndexLast = UBound($textLines) - 1
		for $i = 1 to $textLinesIndexLast
			; has non-whitespace character?
			if StringRegExp($textLines[$i], "\S") = 1 then
				; 1. if not last line, prepend ">"
				; 2. Strip leading/trailing white-spaces
				$wc3Lines[$wc3LinesIndex] = ($i <> $textLinesIndexLast ? ">" : "") & _
					StringStripWS( _
						StringStripWS($textLines[$i], $STR_STRIPLEADING), _
					$STR_STRIPTRAILING)
				
				$wc3LinesIndex += 1
			endif
		next
		Local $wc3LinesIndexLast = $wc3LinesIndex-1
		
		;displayArray($wc3Lines) ; correct
		;Sleep(750)
		
		if enforceLineLengthArr($wc3Lines, 1, $wc3LinesIndexLast) then
			return $wc3Lines
		else
			; fall-through to empty end
		endif
	endif
	
	local $empty[1] = [""]
	return $empty
Endfunc

; Checks an entire array of string lines
; Returns true if OK and below limit
; Returns false otherwise and displays a MsgBox
Func enforceLineLengthArr(ByRef $arrLines, $firstIndex, $lastIndex)
	for $i = $firstIndex to $lastIndex
		local $wc3Line = $arrLines[$i]
		
		if enforceLineLength($wc3Line, $i) = false then
			return false
		endif
	Next
	return true
Endfunc

; Checks a string
; $wc3Line: string to check
; $lineNum: this is to help with multi-line strings, when an error msg is displayed
; Returns true if OK and below limit
; Returns false otherwise and displays a MsgBox
Func enforceLineLength($wc3Line, $lineNum = 1)
	;if StringLen($wc3Line) > $WC3_CHAT_LENGTH_LIMIT then
	local $length = BinaryLen(StringToBinary($wc3Line, $SB_UTF8))
	if $length > $WC3_CHAT_LENGTH_LIMIT then
		MsgBox($MB_ICONERROR, "Error: Line too long", "The line is too long for WC3 chat!" & @CRLF _
		& "Line length (bytes): " & $length _
		& " (max: " & $WC3_CHAT_LENGTH_LIMIT & ")" & @CRLF _
		& "Line number (approx): " & $lineNum & @CRLF _
		& @CRLF & $wc3Line)
		
		return false
	endif
	return true
Endfunc

Func copyPasteCodeToWc3()
	Local $wc3Lines = getClipboardLinesForWc3()
	if $wc3Lines[0] <> "" then
		local $sendKeyDelay_restore = AutoItSetOption("SendKeyDelay")
		local $sendKeyDownDelay_restore = AutoItSetOption("SendKeyDownDelay")
		AutoItSetOption("SendKeyDelay", $CFG_SEND_KEY_DELAY)
		AutoItSetOption("SendKeyDownDelay", $CFG_SEND_KEY_DOWN_DELAY)
		
		Send("{ESCAPE}") ; Close chat if open
		for $i = 1 to UBound($wc3Lines)-1
			
			ClipPut($wc3Lines[$i])
			Send("{ENTER}")
			Send("^v") ; CTRL+V to paste (small v, capital V does not work)
			
			Send("{ENTER}")
			Sleep(20)
		next
		
		AutoItSetOption("SendKeyDelay", $sendKeyDelay_restore)
		AutoItSetOption("SendKeyDownDelay", $sendKeyDownDelay_restore)
		ClipPut($wc3Lines[0]) ; restore clipboard
		BeepOptional(800,200)
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

Func BeepOptional($freqHz = 500, $durationMs = 1000)
	if $CFG_ENABLE_SOUND then
		Beep($freqHz, $durationMs)
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
		
		BeepOptional(500,200)
		copyPasteCodeToWc3()
		
		Sleep(300)
	endif
	
	Sleep(100)
Wend
DllClose($user32H)

Sleep(2000)

