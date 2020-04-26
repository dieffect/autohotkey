;***********************************************************************************************
; 
; テキストバッファ
; 
;***********************************************************************************************
;-----------------------------------------------------------------------
; テキストバッファの初期化
;-----------------------------------------------------------------------
InitTextBuffer() {
	global TextBuffer := new CTextBuffer()
	TextBuffer.LoadConfig("TextBuffer.ini")
	TextBuffer.Update()
}

;-----------------------------------------------------------------------
; テキストバッファを起動
;-----------------------------------------------------------------------
ShowTextBuffer(x = 0, y = 0) {
	global TextBuffer
	TextBuffer.Show(x, y)
}

;***********************************************************************************************
; テキストバッファ制御
;***********************************************************************************************
class CTextBuffer
{
	static Instance :=
	
	;-----------------------------------------------------------------------
	; コンストラクタ
	;-----------------------------------------------------------------------
	__New() {
		if (IsObject(CTextBuffer.Instance)) {
			this.__Delete()
		}
		CTextBuffer.Instance := this
		
		; 初期化
		this.NoClipBoard := false
		this.MaxMenuLen := 50
		this.MaxTooltipLen := 1024
		this.Items := []
		this.Menus := []
		this.ResultGroup := 0
		this.ResultIndex := 0
		
		; メニュー生成
		PumParams := {"selMethod"   : "fill"	; may be "frame","fill"
					 ;,"selBGColor"	: -1		; background color of selected item, -1 means invert, default - COLOR_MENUHILIGHT
					 ;,"selTColor"	: -1		; text color of selected item, -1 means invert, default - COLOR_HIGHLIGHTTEXT
					 ;,"frameWidth"	: 1			; width of select frame when selMethod = "frame"
					 ;,"oninit"		: ""
					 ;,"onuninit"	: ""
					 ,"onselect"	: "CTextBuffer_PumHandler_"
					 ;,"onrbutton"	: ""
					 ;,"onmbutton"	: ""
					 ,"onrun"		: "CTextBuffer_PumHandler_"
					 ;,"onshow"		: ""
					 ,"onclose"		: "CTextBuffer_PumHandler_"
					 ;,"pumfont"	: ""
					 ,"mnemonicCmd": "run"    	; may be "select","run"
					 ,"onmenuchar" : "CTextBuffer_PumHandler_"}
		this.Pum := new PUM(PumParams)
	}
	
	;-----------------------------------------------------------------------
	; デストラクタ
	;-----------------------------------------------------------------------
	__Delete() {
		Loop % this.Menus.MaxIndex() {
			this.DestroyMenu_(this.Menus[A_Index])
		}
		Loop % this.Items.MaxIndex() {
			this.Items[A_Index] := ""
		}
		this.Items := ""
		this.Pum.Destroy()
	}
	
	;-----------------------------------------------------------------------
	; メニュー表示
	;-----------------------------------------------------------------------
	Show(x = 0, y = 0, flags = "") {
		WinGet, active_id, ID, A
		this.ResultGroup := 0
		this.ResultIndex := 0
		this.Menus[1].Show(x, y, flags)
		WinWaitActive, ahk_id %active_id%, , 1
		
		WinGet, current_active_id, ID, A
		if (current_active_id == active_id) {
			; テキストのインデックスが返ってきた場合はペーストする
			if (this.ResultGroup > 0) {
				; クリップボード経由でペースト
				SetTextToClipboard(this.Items[this.ResultGroup, this.ResultIndex, 3])
				PasteFromClipboard()
				Sleep, 100
				
				CursorCount := this.Items[this.ResultGroup, this.ResultIndex, 4]
				if (CursorCount > 0) {
					Send, % "{Up " CursorCount "}"
				}
				
				CursorCount := this.Items[this.ResultGroup, this.ResultIndex, 5]
				if (CursorCount > 0) {
					Send, % "{Left " CursorCount "}"
				}
				
				CursorCount := this.Items[this.ResultGroup, this.ResultIndex, 6]
				if (CursorCount > 0) {
					Send, % "{Right " CursorCount "}"
				}
			}
		}
	}
	
	;-----------------------------------------------------------------------
	; メニュー更新
	;-----------------------------------------------------------------------
	Update(Group = 1) {
		if (!IsObject(this.Menus[Group])) {
			this.Menus[Group] := this.CreateMenu_()
		}
		
		Loop % this.Items[Group].MaxIndex() {
			Index := A_Index
			Len := this.Items[Group][Index, 1]
			if (Len < 0) {
				; サブメニューを追加
				this.Update(-Len)
				this.AppendSubMenuItem_(this.Menus[Group], this.Menus[-Len]
				                      , this.Items[Group][Index, 2], Index)
			}
			else {
				; 項目を追加
				uid := Group "," Index
				if (Len > this.MaxMenuLen) {
					Str := SubStr(this.Items[Group][Index, 2], 1, this.MaxMenuLen)
					this.AppendTextItem_(this.Menus[Group], Str, uid, Index)
				}
				else {
					this.AppendTextItem_(this.Menus[Group], this.Items[Group][Index, 2], uid, Index)
				}
			}
		}
		
		; キャンセルを追加
		this.AppendSeparatorItem_(this.Menus[Group])
		this.AppendCancelItem_(this.Menus[Group])
	}
	
	;-----------------------------------------------------------------------
	; メニューハンドラ
	;-----------------------------------------------------------------------
	PumHandler_(Msg, Obj) {
		if (Msg == "onselect") {
			Index := Obj.uid
			StringSplit, Index, Index, `,, %A_Space%
			this.PumOnSelect(Index1, Index2, Obj)
		}
		else if (Msg == "onrun") {
			Index := Obj.uid
			StringSplit, Index, Index, `,, %A_Space%
			this.PumOnRun(Index1, Index2, Obj)
		}
		else if (Msg == "onmenuchar") {
			this.PumOnMenuChar(Obj)
		}
		else if (Msg == "onclose") {
			this.PumOnClose()
		}
		else {
			
		}
	}
	
	;-----------------------------------------------------------------------
	; OnSelect
	;-----------------------------------------------------------------------
	PumOnSelect(Group, Index, Obj) {
		if (Group == 0) {
			tooltip
		}
		else {
			if (this.Items[Group][Index, 1] <= 0) {
				tooltip
			}
			else {
				if (this.Items[Group][Index, 1] > this.MaxTooltipLen) {
					Str := SubStr(this.Items[Group][Index, 3], 1, this.MaxTooltipLen)
					Str .= "`n`n----`n※表示文字数の上限までしか表示していません。"
				}
				else {
					Str := this.Items[Group][Index, 3]
				}
				StringReplace, Str, Str, `t, % "    ", All
				rect := Obj.GetRECT()
			    tooltip, % Str, % rect.right, % rect.top
			}
		}
	}
	
	;-----------------------------------------------------------------------
	; OnRun
	;-----------------------------------------------------------------------
	PumOnRun(Group, Index, Obj) {
		this.ResultGroup := Group
		this.ResultIndex := Index
	}
	
	;-----------------------------------------------------------------------
	; OnClose
	;-----------------------------------------------------------------------
	PumOnClose() {
		tooltip
	}
	
	;-----------------------------------------------------------------------
	; OnMenuChar
	;-----------------------------------------------------------------------
	PumOnMenuChar(Obj) {	
		if (Obj == Asc("h")) {
			ControlGetFocus, control, A
			PostMessage, 0x100, 37, 0, %control%, A
		}
		else if (Obj == Asc("k")) {
			ControlGetFocus, control, A
			PostMessage, 0x100, 38, 0, %control%, A
		}
		else if (Obj == Asc("l")) {
			ControlGetFocus, control, A
			PostMessage, 0x100, 39, 0, %control%, A
		}
		else if (Obj == Asc("j")) {
			ControlGetFocus, control, A
			PostMessage, 0x100, 40, 0, %control%, A
		}
		else {
			return 0
		}
		return 1
	}
	
	;-----------------------------------------------------------------------
	; メニュー作成
	;-----------------------------------------------------------------------
	CreateMenu_() {
		MenuParams := {"iconssize"	: 16
					  ;,"tcolor"	: pumAPI.GetSysColor(7)	; default - COLOR_MENUTEXT
					  ;,"bgcolor"	: pumAPI.GetSysColor(4)	; default - COLOR_MENU
					  ;,"nocolors"	: 0
					  ,"noicons"	: 1
					  ;,"notext"	: 0
					  ;,"maxheight"	: 0
					  ,"xmargin"	: 8
					  ,"ymargin"	: 3
					  ,"textMargin"	: -20		; this is a pixels zmount which will be added after the text to make menu look pretty
					  ,"textoffset"	: 5}		; gap between icon and item's text in pixels
		Menu := this.Pum.CreateMenu(MenuParams)
		return Menu
	}
	
	;-----------------------------------------------------------------------
	; メニュー破棄
	;-----------------------------------------------------------------------
	DestroyMenu_(Byref Menu) {
		if (IsObject(Menu)) {
			Menu.Destroy()
		}
		Menu := ""
	}
	
	;-----------------------------------------------------------------------
	; 設定ファイル読み込み
	;-----------------------------------------------------------------------
	LoadConfig(Filename) {
		item := {}
		IniSetup(Filename)
		IniFilePath := IniPath(Filename)
		FileEncoding , UTF-8
		Loop, Read, %IniFilePath%
		{
			;MsgBox, %A_LoopReadLine% ;Debug
			if (RegExMatch(A_LoopReadLine, "^\[(.*)\]", SubPat) > 0) {
				if (item["Type"] != "") {
					;For key, value in item
					;	MsgBox %key% = %value%
					this.AppendSection(item)
					item := {}
				}
				item["Type"] := SubPat1
			}
			if (RegExMatch(A_LoopReadLine, "(^[^;][\S]+)\s*=(.*)", SubPat) > 0) {
				if (SubPat1 != "") {
					if ((SubPat1 == "Parent") || (SubPat1 == "Group")) {
						item[SubPat1] := SubPat2 + 1
					}
					else if (SubPat1 == "Line") {
						if (item["Line"] == "") {
							item["Line"] := SubPat2
						}
						else {
							item["Line"] .= "`n" . SubPat2
						}
					}
					else {
						item[SubPat1] := SubPat2
					}
				}
			}
		}
		if (item["Type"] != "") {
			;For key, value in item
			;	MsgBox %key% = %value%
			this.AppendSection(item)
		}
		
		this.AppendSeparator(1)
		this.AppendCancel(1)
	}

	;-----------------------------------------------------------------------
	; 設定ファイルの項目を追加
	;-----------------------------------------------------------------------
	AppendSection(i) {
		Type := i["Type"]
		if (Type == "Text") {
			this.AppendText(i["Group"], i["Name"], i["Line"])
		}
		else if (Type == "SubMenu") {
			this.AppendSubMenu(i["Parent"], i["Group"], i["Title"])
		}
		else if (Type == "Separator") {
			this.AppendSeparator(i["Group"])
		}
	}

	;-----------------------------------------------------------------------
	; テキスト追加
	;-----------------------------------------------------------------------
	AppendText(Group, Title, Text, CursorUpCount = 0, CursorLeftCount = 0, CursorRightCount = 0) {
		if (!IsObject(this.Items[Group])) {
			this.Items[Group] := []
		}
		
		Index := this.NewIndex_(this.Items[Group])
		this.Items[Group][Index, 1] := StrLen(Text)
		this.Items[Group][Index, 2] := Title
		this.Items[Group][Index, 3] := Text
		this.Items[Group][Index, 4] := CursorUpCount
		this.Items[Group][Index, 5] := CursorLeftCount
		this.Items[Group][Index, 6] := CursorRightCount
	}
	
	;-----------------------------------------------------------------------
	; サブメニュー追加
	;-----------------------------------------------------------------------
	AppendSubMenu(Parent, Group, Title) {
		if (!IsObject(this.Items[Parent])) {
			this.Items[Parent] := []
		}
		Index := this.NewIndex_(this.Items[Parent])
		this.Items[Parent][Index, 1] := -Group
		this.Items[Parent][Index, 2] := Title
	}
	
	;-----------------------------------------------------------------------
	; テキスト追加
	;-----------------------------------------------------------------------
	AppendTextItem_(Byref Menu, Title, uid, Index) {
		Key := this.NewAccessKey_(Index)
		ItemParams := {"uid"			: uid
					  ,"name"			: "&" Key A_SPACE A_SPACE Title
					  ,"icon"			: 0
					  ;,"bold"			: 0
					  ;,"iconUseHandle"	: 0
					  ;,"break"			: 0			;0,1,2
					  ;,"submenu"		: 0
					  ;,"tcolor"		: ""
					  ;,"bgcolor"		: ""
					  ;,"noPrefix"		: 0
					  ;,"disabled"		: 0
					  ;,"noicons"		: -1		;-1 means use parent menu's setting
					  ;,"notext"		: -1
					  ,"issep"			: 0}
		Menu.Add(ItemParams)
	}
	
	;-----------------------------------------------------------------------
	; キャンセル追加
	;-----------------------------------------------------------------------
	AppendCancelItem_(Byref Menu) {
		CancelParams := {"uid"			: 0
					  ,"name"			: "&@  キャンセル"
					  ,"icon"			: 0
					  ;,"bold"			: 0
					  ;,"iconUseHandle"	: 0
					  ;,"break"			: 0			;0,1,2
					  ;,"submenu"		: 0
					  ;,"tcolor"		: ""
					  ;,"bgcolor"		: ""
					  ;,"noPrefix"		: 0
					  ;,"disabled"		: 0
					  ;,"noicons"		: -1		;-1 means use parent menu's setting
					  ;,"notext"		: -1
					  ,"issep"			: 0}
		Menu.Add(CancelParams)
	}
	
	;-----------------------------------------------------------------------
	; サブメニュー追加
	;-----------------------------------------------------------------------
	AppendSubMenuItem_(Byref Menu, Byref SubMenu, SubMenuName, Index) {
		Key := this.NewAccessKey_(Index)
		CancelParams := {"uid"			: 0
					  ,"name"			: "&" Key A_SPACE A_SPACE SubMenuName
					  ,"icon"			: 0
					  ;,"bold"			: 0
					  ;,"iconUseHandle"	: 0
					  ;,"break"			: 0			;0,1,2
					  ,"submenu"		: SubMenu
					  ;,"tcolor"		: ""
					  ;,"bgcolor"		: ""
					  ;,"noPrefix"		: 0
					  ;,"disabled"		: 0
					  ;,"noicons"		: -1		;-1 means use parent menu's setting
					  ;,"notext"		: -1
					  ,"issep"			: 0}
		Menu.Add(CancelParams)
	}
	
	;-----------------------------------------------------------------------
	; セパレーター追加
	;-----------------------------------------------------------------------
	AppendSeparatorItem_(Byref Menu) {
		Menu.Add()
	}
	
	;-----------------------------------------------------------------------
	; 新規メニュー番号取得
	;-----------------------------------------------------------------------
	NewIndex_(Byref Items) {
		Index := Items.MaxIndex()
		++Index
		return Index
	}
	
	;-----------------------------------------------------------------------
	; 新規アクセラレータキー取得
	;-----------------------------------------------------------------------
	NewAccessKey_(Index) {
		KeyList := "1234567890ABCDEFGIMNOPQRSTUVWXYZ"
		if (Index < 0 || StrLen(KeyList) < Index) {
			Index := 1
		}
		Key := SubStr(KeyList, Index, 1)
		return Key
	}
}

;-----------------------------------------------------------------------
; メニューハンドラ
;-----------------------------------------------------------------------
CTextBuffer_PumHandler_(Msg, Obj) {
	CTextBuffer.Instance.PumHandler_(Msg, Obj)
}

;***********************************************************************************************
; インクルード
;***********************************************************************************************
#Include <PUM/PUM_API>
#Include <PUM/PUM>
#include Clipboard.ahk
