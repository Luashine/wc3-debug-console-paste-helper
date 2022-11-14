; https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-createsemaphorea
; says:
; Use the CloseHandle function to close the handle. The system closes the handle automatically when the process terminates. The semaphore object is destroyed when its last handle has been closed. 

; Source: Valik
; https://www.autoitscript.com/forum/topic/5320-new-approach-to-only-allowing-one-instance/

; Modified!
; Creates a singleton semaphore with specified name
; If it does not exist: returns 0 (good, single instance)
; If it does exist: returns 1 (bad, already running)
Func CreateSingletonSemaphore($semaphoreName)
    Local $ERROR_ALREADY_EXISTS = 183
    
	local $retArr = DllCall("kernel32.dll", "int", "CreateSemaphore", "int", 0, "long", 1, "long", 1, "str", $semaphoreName)
	local $semHandle = $retArr[0]
	
    Local $lastError = DllCall("kernel32.dll", "int", "GetLastError")
    If $lastError[0] = $ERROR_ALREADY_EXISTS Then
		return 1
	else
		return 0
	endif
EndFunc; Singleton()