﻿;***********************************************************************************************
; 
; システム関連
; 
;***********************************************************************************************
;***********************************************************************************************
; Volatile環境変数の設定
;***********************************************************************************************
SetVolatileEnv() {
	Loop, HKEY_CURRENT_USER ,Volatile Environment, 1, 0
	{
		if (a_LoopRegType != KEY) {
			RegRead, value
			if (ErrorLevel == 0) {
				EnvSet, %A_LoopRegName%, %value%
			}
		}
	}
}

;***********************************************************************************************
; 環境変数を展開する
;***********************************************************************************************
ExpandEnvironmentVriables(text) {
	nSize := DllCall("ExpandEnvironmentStrings", "Str", text, "Str", NULL, "UInt", 0, "UInt")
	VarSetCapacity(Dest, size := (nSize * (1 << !!A_IsUnicode)) + !A_IsUnicode)
	DllCall("ExpandEnvironmentStrings", "Str", text, "Str", Dest, "UInt", size, "UInt")
	return Dest
}

;***********************************************************************************************
; スクリプトを実行
;***********************************************************************************************
RunSubScript(ScriptName, RelativeScriptPath) {
	SplitPath, A_AhkPath,, AppDir
	Run, %A_AhkPath% %ScriptName%, %AppDir%\%RelativeScriptPath%, , ProcessId
	return ProcessId
}

;***********************************************************************************************
; アプリケーションを実行
;***********************************************************************************************
RunApp(AppPath, Param, ExecDir, State = "") {
	if (ExecDir == "") {
		SplitPath, AppPath,, ExecDir
	}
	expAppPath := ExpandEnvironmentVriables(AppPath)
	expExecDir := ExpandEnvironmentVriables(ExecDir)
	Run, "%expAppPath%" %Param%, %expExecDir%, %State%, ProcessId
	if (ProcessId != "") {
		WinWait, ahk_pid %ProcessId%, , 5
		if (ErrorLevel == 0) {
			WinActivate, ahk_pid %ProcessId%
		}
	}
	return ProcessId
}

;***********************************************************************************************
; 設定ファイル
;***********************************************************************************************
;-----------------------------------------------------------------------
; 設定ファイルがあるかどうか
;-----------------------------------------------------------------------
IniExists(Filename) {
	SplitPath, A_AhkPath,, AppDir
	ConfigDir := AppDir . "\Config"
	
	Attr := FileExist(ConfigDir)
	if ((Attr == "") || !InStr(Attr, "D")) {
		FileCreateDir, %ConfigDir%
		return false
	}
	
	Attr := FileExist(ConfigDir . "\" . Filename)
	return (Attr != "") && !InStr(Attr, "D")
}

;-----------------------------------------------------------------------
; 設定ファイルのフルパス
;-----------------------------------------------------------------------
IniPath(Filename) {
	SplitPath, A_AhkPath,, AppDir
	return AppDir . "\Config\" . Filename
}

;-----------------------------------------------------------------------
; アプリケーション設定の読み出し
;-----------------------------------------------------------------------
AppIniRead(Section, Key, Default) {
	inipath := IniPath("AutoHotKey.ini")
	FileEncoding , UTF-8
	IniRead, OutputVar, %inipath%, %Section%, %Key%, %A_Space%
	if (OutputVar == "") {
		OutputVar := Default
	}
	return OutputVar
}

;-----------------------------------------------------------------------
; 設定ファイルのセットアップ
;-----------------------------------------------------------------------
IniSetup(Filename) {
	Path := IniPath(Filename)
	FileCopy, %Path%.sample, %Path%, 0
}

;***********************************************************************************************
; テンポラリフォルダ
;***********************************************************************************************
;-----------------------------------------------------------------------
; テンポラリフォルダの初期化
;-----------------------------------------------------------------------
InitTempDir() {
	DeleteTempDir()
	CreateTempDir()
}

;-----------------------------------------------------------------------
; テンポラリフォルダパスの取得
;-----------------------------------------------------------------------
TempDirPath() {
	TempDir := A_Temp "\AutoHotkey"
	return TempDir
}

;-----------------------------------------------------------------------
; テンポラリフォルダがあるかどうか
;-----------------------------------------------------------------------
TempDirExists() {
	Exists := false
	TempDir := TempDirPath()
	Attr := FileExist(TempDir)
	if (Attr != "") {
		if (InStr(Attr, "D")) {
			Exists := true
		}
	}
	
	return Exists
}

;-----------------------------------------------------------------------
; テンポラリフォルダの作成
;-----------------------------------------------------------------------
CreateTempDir() {
	if (!TempDirExists()) {
		TempDir := TempDirPath()
		FileCreateDir, %TempDir%
		if (ErrorLevel != 0) {
			MsgBox, テンポラリフォルダの作成に失敗しました。
			ExitApp
		}
	}
	
	return TempDir
}

;-----------------------------------------------------------------------
; テンポラリフォルダの削除
;-----------------------------------------------------------------------
DeleteTempDir() {
	if (TempDirExists()) {
		TempDir := TempDirPath()
		FileRemoveDir, %TempDir%, 1
	}
}

;***********************************************************************************************
; 関数呼び出し
;***********************************************************************************************
CallFunc(f) {
	Func := f[1]
	Argc := f.Length() - 1
	;Tooltip, Func:%Func% / Argc:%Argc% ; Debug
	if (Argc == 0) {
		%Func%()
	}
	else if (Argc == 1) {
		%Func%(f[2])
	}
	else if (Argc == 2) {
		%Func%(f[2], f[3])
	}
	else if (Argc == 3) {
		%Func%(f[2], f[3], f[4])
	}
	else if (Argc == 4) {
		%Func%(f[2], f[3], f[4], f[5])
	}
	else if (Argc == 5) {
		%Func%(f[2], f[3], f[4], f[5], f[6])
	}
	else if (Argc == 6) {
		%Func%(f[2], f[3], f[4], f[5], f[6], f[7])
	}
	else if (Argc == 7) {
		%Func%(f[2], f[3], f[4], f[5], f[6], f[7], f[8])
	}
	else if (Argc == 8) {
		%Func%(f[2], f[3], f[4], f[5], f[6], f[7], f[8], f[9])
	}
	else if (Argc == 9) {
		%Func%(f[2], f[3], f[4], f[5], f[6], f[7], f[8], f[9], f[10])
	}
	else {
		Msgbox, 関数のに渡せる引数は最大9個です:%Argc%。
	}
}

;***********************************************************************************************
; インクルード
;***********************************************************************************************
