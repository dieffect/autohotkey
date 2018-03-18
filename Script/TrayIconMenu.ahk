;***********************************************************************************************
; 
; トレイアイコンメニュー
; 
;***********************************************************************************************
;***********************************************************************************************
; トレイアイコンメニュー
;***********************************************************************************************
;-----------------------------------------------------------------------
; トレイアイコンメニューのカスタマイズ
;-----------------------------------------------------------------------
CustomTrayMenu() {
	Menu, Tray, NoStandard
	Menu, Tray, Add, &1  実行履歴, TrayMenuLinesMostRecentlyExecuted
	Menu, Tray, Add, &2  変数一覧, TrayMenuVariablesAndTheirContents
	Menu, Tray, Add, &3  ホットキー, TrayMenuHotkeysAndTheirMethods
	Menu, Tray, Add, &4  操作履歴, TrayMenuKeyHistoryAndScriptInfo
	Menu, Tray, Add
	Menu, Tray, Add, &5  Window Spy, TrayMenuWindowSpy
	Menu, Tray, Add, &6  スクリプト編集, TrayMenuEditThisScript
	Menu, Tray, Add, &7  AutoHotKeyフォルダを開く, TrayMenuOpenAutoHotKeyFolder
	Menu, Tray, Add, &8  Tempフォルダを開く, TrayMenuOpenAutoHotKeyTempFolder
	Menu, Tray, Add
	Menu, Tray, Add, &9  無効化, TrayMenuSuspendHotkeys
	Menu, Tray, Add, &0  スレッド停止, TrayMenuPauseScript
	Menu, Tray, Add, &A  リロード, TrayMenuReloadThisScript
	Menu, Tray, Add, &B  ヘルプ, TrayMenuHelp
	Menu, Tray, Add, &C  終了, TrayMenuExit
}

;-----------------------------------------------------------------------
; Lines most recently executed
;-----------------------------------------------------------------------
TrayMenuLinesMostRecentlyExecuted:
	ListLines
return

;-----------------------------------------------------------------------
; Variables and their contents
;-----------------------------------------------------------------------
TrayMenuVariablesAndTheirContents:
	ListVars
return

;-----------------------------------------------------------------------
; Hotkeys and their methods
;-----------------------------------------------------------------------
TrayMenuHotkeysAndTheirMethods:
	ListHotKeys
return

;-----------------------------------------------------------------------
; Key history and script info
;-----------------------------------------------------------------------
TrayMenuKeyHistoryAndScriptInfo:
	KeyHistory
return

;-----------------------------------------------------------------------
; Help
;-----------------------------------------------------------------------
TrayMenuHelp:
	Run, AutoHotkey.chm
return

;-----------------------------------------------------------------------
; Window Spy
;-----------------------------------------------------------------------
TrayMenuWindowSpy:
	Run, "%A_AhkPath%" "WindowSpy.ahk"
return

;-----------------------------------------------------------------------
; Reload This Script
;-----------------------------------------------------------------------
TrayMenuReloadThisScript:
	Reload
return

;-----------------------------------------------------------------------
; Edit This Script
;-----------------------------------------------------------------------
TrayMenuEditThisScript:
	Editor := AppIniRead("Editor", "Path", "notepad.exe")
	Run, %Editor% %A_ScriptFullPath%
return

;-----------------------------------------------------------------------
; Open AutoHotKey Folder
;-----------------------------------------------------------------------
TrayMenuOpenAutoHotKeyFolder:
	SplitPath, A_AhkPath,, dir
	Run, % "Explorer /e," . dir
return

;-----------------------------------------------------------------------
; Open AutoHotKey Temp Folder
;-----------------------------------------------------------------------
TrayMenuOpenAutoHotKeyTempFolder:
	TempDir := TempDirPath()
	Run, % "Explorer /e," . TempDir
return

;-----------------------------------------------------------------------
; Suspend Hotkeys
;-----------------------------------------------------------------------
TrayMenuSuspendHotkeys:
	if (A_IsSuspended) {
		Menu, Tray, Uncheck, &9  無効化
		Suspend, Off
	}
	else {
		Menu, Tray, Check, &9  無効化
		Suspend, On
	}
return

;-----------------------------------------------------------------------
; Pause Script
;-----------------------------------------------------------------------
TrayMenuPauseScript:
	if (A_IsPaused) {
		Menu, Tray, Uncheck, &0  スレッド停止
		Pause, Off
		HotkeySw("LButton", "On")
		HotkeySw("RButton", "On")
	}
	else {
		Menu, Tray, Check, &0  スレッド停止
		HotkeySw("LButton", "Off")
		HotkeySw("RButton", "Off")
		Pause, On
	}
return

;-----------------------------------------------------------------------
; Exit
;-----------------------------------------------------------------------
TrayMenuExit:
	ExitApp
return

;***********************************************************************************************
; インクルード
;***********************************************************************************************
#include SystemFunctions.ahk
#include KeyFunctions.ahk
