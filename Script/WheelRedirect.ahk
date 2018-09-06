;*******************************************************************************
; 
; マウスホイールのリダイレクト
; 
;*******************************************************************************
;-----------------------------------------------------------------------
; マウス直下のウインドウをスクロール
;-----------------------------------------------------------------------
WheelRedirect(IsFwd, IsHorizontal = 0) {
	MouseGetPos, x, y
	hwnd := DllCall("WindowFromPoint", "int64", x | y << 32, "ptr")
	if (IsHorizontal) {
		Loop, 1 {
			PostMessage, 0x114, %IsFwd%, , , ahk_id %hwnd%
		}
		PostMessage, 0x114, 8, , , ahk_id %hwnd%
	}
	else {
		wp := GetKeyState("LButton") | GetKeyState("RButton") << 1 | GetKeyState("Shift") << 2 
		    | GetKeyState("Ctrl") << 3 | GetKeyState("MButton") << 4 | GetKeyState("XButton1") << 5
		    | GetKeyState("XButton2") << 6
		if (IsFwd) {
			wp |= 0xFF880000
		}
		else {
			wp |= 0x00780000
		}
		lp := y << 16 | x
		SendMessage, 0x20A, %wp%, %lp%, , ahk_id %hwnd%
	}
}
