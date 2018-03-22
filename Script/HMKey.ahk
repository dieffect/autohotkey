﻿;***********************************************************************************************
; 
; 変換/無変換 修飾キー割り当て
; 
;***********************************************************************************************
;-----------------------------------------------------------------------
; メニュー初期化
;-----------------------------------------------------------------------
InitHMKey() {
	if (AppIniRead("HM_Modifier", "Enable", "false") != "true") {
		return
	}
	CHM_Modifier.Instance := new CHM_Modifier()
}

;-----------------------------------------------------------------------
; 変換/無変換 修飾キー割り当て
;-----------------------------------------------------------------------
HMKey(Key, HKey = "", MKey = "", HMKey = "") {
	if (!IsObject(CHM_Modifier.Instance)) {
		Send, {Blind}{%Key%}
		return
	}
	CHM_Modifier.Instance.KeyHandler(Key, HKey, MKey, HMKey)
}

;-----------------------------------------------------------------------
; キーマップ用のハンドラ
;-----------------------------------------------------------------------
HMKeyDoNothing:
return

HMKeyName:
	Key := SubStr(A_ThisHotkey, 2)
	CHM_Modifier.Instance.KeyHandler("{" Key "}")
return

HMKeyArrow:
	Key := SubStr(A_ThisHotkey, 2)
	ArrowKey(Key, Key)
return

;***********************************************************************************************
; 変換/無変換 修飾キー制御
;***********************************************************************************************
class CHM_Modifier
{
	static Instance :=
	Mod_Henkan :=
	Mod_Muhenkan :=
	Mod_Henkan_Muhenkan :=

	;-----------------------------------------------------------------------
	; コンストラクタ
	;-----------------------------------------------------------------------
	__New() {
		if (IsObject(CHM_Modifier.Instance)) {
			this.__Delete()
		}
		CHM_Modifier.Instance := this

		this.Mod_Henkan := AppIniRead("HM_Modifier", "Henkan", "^")
		this.Mod_Muhenkan := AppIniRead("HM_Modifier", "Muhenkan", "!")
		this.Mod_Henkan_Muhenkan := AppIniRead("HM_Modifier", "Henkan_Muhenkan", "^!")

		this.MapDefaultKeys()
	}
	
	;-----------------------------------------------------------------------
	; デストラクタ
	;-----------------------------------------------------------------------
	__Delete() {
	}

	;-----------------------------------------------------------------------
	; デフォルトキーマップ
	;-----------------------------------------------------------------------
	MapDefaultKeys() {
		; 変換/無変換 キーを無効化する
		this.Map("*vk1C", "HMKeyDoNothing") ; [変換]
		this.Map("*vk1D", "HMKeyDoNothing") ; [無変換]

		; 日本語キーボード
		JpKeys := [	 "vkBB"
					,"vkBA"
					,"vkE2"
					,"vkF3"		; [全角/半角] ※IMEのON/OFFで発生するイベントが違う。
					,"vkF4"		;               Sendで送信する場合はどちらでも同じ
					,"vkF0"		; [Caps Lock / 英数]
					,"vkF2"]	; [ひらがな/カタカナ]
		for index, element in JpKeys {
			this.Map("*" . element)
		}

		; ファンクション(F1-F24)
		Loop, 24 {
			this.Map("*F" . A_Index)
		}

		; 数値,アルファベット,記号
		Characters := "0123456789abcdefghijklmnopqrstuvwxyz-^\@[;:],./"
		Loop, Parse, Characters
		{
			this.Map("*" . A_LoopField)
		}

		; 方向キー
		ArrowKeys := ["Left", "Right", "Up", "Down"]
		for index, element in ArrowKeys {
			this.Map("*" . element, "HMKeyArrow")
		}

		; 記号/空白/制御
		Controls := ["Space", "Tab", "Enter", "BS", "Del", "Ins", "Home", "End"
					, "PgUp", "PgDn", "Esc", "AppsKey", "PrintScreen", "Pause"
					, "Break", "Sleep", "CtrlBreak", "CapsLock", "ScrollLock"]
		for index, element in Controls {
			this.Map("*" . element)
		}

		; テンキー(※"NumLock"はトグルキーなので対象外)
		Numpads := ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"
				, "Dot", "Del", "Ins", "Clear", "Up", "Down", "Left", "Right"
				, "Home", "End", "PgUp", "PgDn", "Div", "Mult", "Add", "Sub", "Enter"]
		for index, element in Numpads {
			this.Map("*Numpad" . element)
		}

		; メディア
		Medias := ["Browser_Back", "Browser_Forward", "Browser_Refresh"
				, "Browser_Favorites", "Browser_Home"
				, "Volume_Mute", "Volume_Down", "Volume_Up"
				, "Media_Next", "Media_Prev", "Media_Stop", "Media_Play_Pause"
				, "Launch_Mail", "Launch_Media", "Launch_App1", "Launch_App2"]
		for index, element in Medias {
			this.Map("*" . element)
		}
	}

	Map(Key, Label = "HMKeyName") {
		; ホットキーが定義されていない場合のみ、定義する。
		Hotkey, %Key%, , UseErrorLevel
		if ((ErrorLevel == 5) || (ErrorLevel == 6)) {
			Hotkey, %Key%, %Label%
		}
	}

	;-----------------------------------------------------------------------
	; 変換/無変換 キーハンドラ
	; Key: 変換/無変換 が押されていない場合のキーまたはコマンド
	; HKey: 変換が押されている場合のキーまたはコマンド
	; MKey: 無変換が押されている場合のキーまたはコマンド
	; HMKey: 変換と無変換が押されている場合のキーまたはコマンド
	;-----------------------------------------------------------------------
	KeyHandler(Key, HKey = "", MKey = "", HMKey = "") {
		Mod := 0
		if (GetKeyState("vk1C", "P")) {
			Mod += 1
		}
		if (GetKeyState("vk1D", "P")) {
			Mod += 2
		}
		
		if ((Mod == 1) && (this.Mod_Henkan)) {
			this.DefKeyCmd_(HKey, Key, this.Mod_Henkan)
		}
		else if ((Mod == 2) && (this.Mod_Muhenkan)) {
			this.DefKeyCmd_(MKey, Key, this.Mod_Muhenkan)
		}
		else if ((Mod == 3) && (this.Mod_Henkan_Muhenkan)) {
			this.DefKeyCmd_(HMKey, Key, this.Mod_Henkan_Muhenkan)
		}
		else {
			this.KeyCmd_(Key, "")
		}
	}

	;-----------------------------------------------------------------------
	; キーまたはコマンドの実行
	; Cmd: キーまたはコマンド
	; DefCmd: Cmdが指定されていない場合のキーまたはコマンド
	; DefMod: 修飾キー(※DefCmdがキーの場合に有効)
	;-----------------------------------------------------------------------
	DefKeyCmd_(Cmd, DefCmd, DefMod) {
		if (Cmd == "") {
			this.KeyCmd_(DefCmd, DefMod)
		}
		else {
			this.KeyCmd_(Cmd, "")
		}
	}

	;-----------------------------------------------------------------------
	; キーまたはコマンドの実行
	; Cmd: キーまたはコマンド
	; Mod: 修飾キー(※キーの場合に有効)
	;-----------------------------------------------------------------------
	KeyCmd_(Cmd, Mod) {
		if (Cmd != "") {
			if (IsObject(Cmd)) {
				CallFunc(Cmd)
			}
			else {
				Send, {Blind}%Mod%%Cmd%
			}
		}
	}
}

;***********************************************************************************************
; インクルード
;***********************************************************************************************
#include SystemFunctions.ahk