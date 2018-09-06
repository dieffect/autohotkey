﻿;***********************************************************************************************
; 
; サブプロセス
; 
;***********************************************************************************************
;***********************************************************************************************
; 自動実行
;***********************************************************************************************
;-----------------------------------------------------------------------
; 初期化処理
;-----------------------------------------------------------------------
InitSub:
	#NoEnv
	#NoTrayIcon
	#Persistent
	#SingleInstance force
	#InstallKeybdHook
	#InstallMouseHook
	CoordMode, Mouse, Screen
	CoordMode, Caret, Screen
	CoordMode, Tooltip, Screen
	SetWorkingDir %A_ScriptDir%
	SetVolatileEnv()
	InitClipboard()
	InitPopupLauncher()
	InitClipboardHistory(100)
	InitTextBuffer()
return

;-----------------------------------------------------------------------
; 終了処理
;-----------------------------------------------------------------------
vk3B::
ExitApp

;***********************************************************************************************
; ポップアップランチャー
;***********************************************************************************************
;-----------------------------------------------------------------------
; カーソル位置
;-----------------------------------------------------------------------
vk07::
	ShowPopupLauncher(A_CaretX, A_CaretY)
return

;-----------------------------------------------------------------------
; マウス位置
;-----------------------------------------------------------------------
vk0E::
	MouseGetPos x, y
	ShowPopupLauncher(x, y)
return

;***********************************************************************************************
; テキストバッファ
;***********************************************************************************************
;-----------------------------------------------------------------------
; カーソル位置
;-----------------------------------------------------------------------
vk0F::
	ShowTextBuffer(A_CaretX, A_CaretY)
return

;-----------------------------------------------------------------------
; マウス位置
;-----------------------------------------------------------------------
vk16::
	MouseGetPos x, y
	ShowTextBuffer(x, y)
return

;***********************************************************************************************
; クリップボード履歴
;***********************************************************************************************
;-----------------------------------------------------------------------
; カーソル位置
;-----------------------------------------------------------------------
vk1A::
	ShowClipboardHistory(A_CaretX, A_CaretY)
return

;-----------------------------------------------------------------------
; マウス位置
;-----------------------------------------------------------------------
vk3A::
	MouseGetPos x, y
	ShowClipboardHistory(x, y)
return

;***********************************************************************************************
; 空き仮想キーコード
;***********************************************************************************************
vk3C::
vk3D::
vk3E::
vk3F::
vk40::
return

;***********************************************************************************************
; インクルード
;***********************************************************************************************
#include Clipboard.ahk
#include PopupLauncher.ahk
#include ClipboardHistory.ahk
#include TextBuffer.ahk
#include WheelRedirect.ahk
#include TextFunctions.ahk
