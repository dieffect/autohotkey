;***********************************************************************************************
; 
; AutoHotKey
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
	#Persistent
	#SingleInstance force
	#InstallKeybdHook
	#InstallMouseHook
	#MaxHotkeysPerInterval 200
	CoordMode, Mouse, Screen
	CoordMode, Caret, Screen
	CoordMode, Tooltip, Screen
	SendMode Input
	SetWorkingDir %A_ScriptDir%
	SetTitleMatchMode, 2
	OnExit, ExitSub
	CheckHotKeyFile()
	IniSetup("AutoHotKey.ini")
	InitTempDir()
	CustomTrayMenu()
	SetVolatileEnv()
	InitHMKey()
	SubProcessPid := RunSubScript("SubProcess.ahk", "Script")
return

;-----------------------------------------------------------------------
; 終了処理
;-----------------------------------------------------------------------
ExitSub:
	DeleteTempDir()
	ExitSubProcess()
	Process, WaitClose, %SubProcessPid%, 10
	if (ErrorLevel != 0) {
		Process, WaitClose, %SubProcessPid%
	}
ExitApp

;***********************************************************************************************
; ホットキー定義ファイルの確認
;***********************************************************************************************
CheckHotKeyFile()
{
	Filename := "HotKeys.ahk"
	if (!IniExists(Filename)) {
		IniSetup(Filename)
		Reload
	}
}

;***********************************************************************************************
; インクルード
;***********************************************************************************************
; Configディレクトリ
#include %A_ScriptDir%/Config
#include *i HotKeys.ahk

; Scriptディレクトリ
#include %A_ScriptDir%/Script
#include SubProcessIF.ahk
#include SystemFunctions.ahk
#include TrayIconMenu.ahk
#include WheelRedirect.ahk
#include KeyFunctions.ahk
#include TextFunctions.ahk
#include HMKey.ahk

; カレントディレクトリ
#include %A_ScriptDir%
