;***********************************************************************************************
; 
; クリップボード関連
; 
;***********************************************************************************************
;***********************************************************************************************
; クリップボードイベント
;***********************************************************************************************
OnClipboardChange:
	Critical
	++ClCount
; 	tooltip, % "0[" ClCount "] " NoClipBoardEvent, 0,0
	if (NoClipBoardEvent != 1) {
; 		tooltip, % "1[" ClCount "] " NoClipBoardEvent, 0,0
		ClipboardHistory_OnClipboardChange()
		Sleep, 50
; 		tooltip, % "2[" ClCount "] " NoClipBoardEvent, 0,0
	}
; 	tooltip, % "3[" ClCount "] " NoClipBoardEvent ": [" A_EventInfo "] ", 0,0
	NoClipBoardEvent := 0
;	tooltip
	Critical,Off
return

;***********************************************************************************************
; クリップボード操作
;***********************************************************************************************
;-----------------------------------------------------------------------
; 初期化
;-----------------------------------------------------------------------
InitClipboard() {
	global NoClipBoardEvent := 0
}

;-----------------------------------------------------------------------
; クリップボードにテキストを取得
;-----------------------------------------------------------------------
GetTextViaClipboard(Byref Text, IsCut = false, NoEvent = true) {
	global NoClipBoardEvent
	
	; クリップボードイベントを無視するかどうか設定する
	NoClipBoardEvent := (NoEvent) ? 1 : 2
	
	; クリップボードのバックアップ
	Cb := ClipboardAll
	
	; クリップボードへ取り込む
	Clipboard := ""
	if (IsCut) {
		Send ^x
	}
	else {
		Send ^c
	}
	ClipWait 1
	NoClipBoardEvent := 0
	if (ErrorLevel == 0) {
		Text := Clipboard
	}
	else {
		Text := ""
	}
	
	; クリップボードを元に戻す
	SetTextToClipboard(Cb)
}

;-----------------------------------------------------------------------
; クリップボードにテキストを設定
;-----------------------------------------------------------------------
SetTextToClipboard(Text, NoEvent = true) {
	global NoClipBoardEvent
	
	if (Text == "") {
		ClipBoard := ""
	}
	else {
		; クリップボードイベントを無視するかどうか設定する
		NoClipBoardEvent := (NoEvent) ? 1 : 2
		
		; クリップボードに入れる
		ClipBoard := Text
		
		; クリップボードイベント終了待ち
		Limit := 100
		While (NoClipBoardEvent != 0) {
			--Limit
			if (Limit == 0) {
				NoClipBoardEvent := 0
				break
			}
			Sleep, 10
		}
	}
}

;-----------------------------------------------------------------------
; クリップボード貼り付け
;-----------------------------------------------------------------------
PasteFromClipboard() {
	WinGetClass, Name
	if (Name == "mintty") {
		send, +{Insert}
	}
	else {
		send, ^v
	}
}

;***********************************************************************************************
; インクルード
;***********************************************************************************************
#include ClipboardHistory.ahk