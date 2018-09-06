;***********************************************************************************************
; 
; テキスト関連
; 
;***********************************************************************************************
;***********************************************************************************************
; テキストを開く
;***********************************************************************************************
;-----------------------------------------------------------------------
; 選択したテキストを開く
;-----------------------------------------------------------------------
OpenSelectedText() {
	GetTextViaClipboard(Selected)
	if (Selected == "") {
		MsgBox % "テキストが選択されていません。"
	}
	else {
		Text := ""
		Loop, parse, Selected, `n, `r
		{
			if (A_Index == 1) {
				Text := Trim(A_LoopField)
				Attr := FileExist(Text)
			}
			else {
				NextText := Trim(A_LoopField)
				if (NextText != "") {
					Attr := FileExist(Text . "\" . NextText)
					if (Attr != "") {
						Text .= "\" . NextText
					}
					else {
						Attr := FileExist(Text . NextText)
						Text .= NextText
					}
				}
			}
		}
		
		if (Attr != "") {
			if (InStr(Attr, "D")) {
				Cmd := "Explorer /e," . Text
				Run, %Cmd%
			}
			else {
				if (InStr(Text, "\\") == 1) {
					MsgBox, 0x24, , % Chr(0x22) Text Chr(0x22) " を直接開きますか？"
					IfMsgBox, No
					{
						SplitPath, Text, FileName
						TempDir := TempDirPath()
						TempFileName := TempDir "\" FileName
						FileCopy, %Text%, %TempFileName%, 1
						if (ErrorLevel != 0) {
							MsgBox, 0x10, , % Chr(0x22) A_Temp Chr(0x22) " へのコピーに失敗しました。処理を中断します。"
							return
						}
						Text := TempFileName
					}
				}
				OpenText(Text)
			}
		}
		else {
			OpenText(Text)
		}
	}
}

;-----------------------------------------------------------------------
; テキストを開く
;-----------------------------------------------------------------------
OpenText(Text) {
	Run, % Text, , UseErrorLevel
	if (ErrorLevel != 0) {
		MsgBox % Chr(0x22) Text Chr(0x22) " を開けませんでした。"
	}
}

;***********************************************************************************************
; 引用記号を付加する
;***********************************************************************************************
QuoteSelectedText(Quote) {
	GetTextViaClipboard(Selected, true)
	if (Selected == "") {
		MsgBox % "テキストが選択されていません。"
	}
	else {
		Text := ""
		Loop, parse, Selected, `n, `r
		{
			if (Text != "") {
				Text .= "`r`n"
			}
			Text .= Quote A_LoopField
		}
		SetTextToClipboard(Text)
		send, ^v
	}
}

;***********************************************************************************************
; 改行する
;***********************************************************************************************
InsertNewLine() {
	Send {Home}
	Send {Enter}
	Send {Up}
}

AppendNewLine() {
	Send {End}
	Send {Enter}
}

;***********************************************************************************************
; インクルード
;***********************************************************************************************
#include Clipboard.ahk
#include SystemFunctions.ahk
