﻿;***********************************************************************************************
; 
; ウィンドウ関連
; 
;***********************************************************************************************
;***********************************************************************************************
; ウィンドウ最大化のトグル
;***********************************************************************************************
WinMaximizeToggle() {
	WinGet, maxp, MinMax, A
	if maxp = 1
	    WinRestore, A
	else 
	    WinMaximize,A
	return
}

;***********************************************************************************************
; インクルード
;***********************************************************************************************
