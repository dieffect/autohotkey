;***********************************************************************************************
; 
; ポップアップランチャー
; 
;***********************************************************************************************
;-----------------------------------------------------------------------
; メニュー初期化
;-----------------------------------------------------------------------
InitPopupLauncher() {
	global PopupLauncher := new CPopupLauncher()
	PopupLauncher.LoadConfig("PopupLauncher.ini")
	PopupLauncher.Update()
}

;-----------------------------------------------------------------------
; メニュー起動
;-----------------------------------------------------------------------
ShowPopupLauncher(x = 0, y = 0) {
	global PopupLauncher
	PopupLauncher.Show(x, y)
}

;***********************************************************************************************
; ランチャー制御
;***********************************************************************************************
class CPopupLauncher
{
	static Instance :=
	
	;-----------------------------------------------------------------------
	; コンストラクタ
	;-----------------------------------------------------------------------
	__New() {
		if (IsObject(CPopupLauncher.Instance)) {
			this.__Delete()
		}
		CPopupLauncher.Instance := this
		
		; 初期化
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
					 ;,"onselect"	: "CPopupLauncher_PumHandler_"
					 ,"onrbutton"	: "CPopupLauncher_PumHandler_"
					 ;,"onmbutton"	: ""
					 ,"onrun"		: "CPopupLauncher_PumHandler_"
					 ;,"onshow"		: ""
					 ;,"onclose"	: ""
					 ;,"pumfont"	: ""
					 ,"mnemonicCmd": "run"    	; may be "select","run"
					 ,"onmenuchar" : "CPopupLauncher_PumHandler_"}
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
		this.ResultGroup := 0
		this.ResultIndex := 0
		this.Menus[1].Show(x, y, flags)
		this.Exec_(this.ResultGroup, this.ResultIndex)
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
			Type := this.Items[Group][Index, 1]
			
			; サブメニューを追加
			if (Type == "SubMenu") {
				SubGroup := this.Items[Group][Index, 2]
				this.Update(SubGroup)
				this.AppendSubMenuItem_(this.Menus[Group], this.Menus[SubGroup]
				                      , this.Items[Group][Index, 3], Index)
			}
			; 項目を追加
			else if ((Type == "App") || (Type == "Script")) {
				uid := Group "," Index
				this.AppendMenuItem_(this.Menus[Group], this.Items[Group][Index, 2]
				                   , this.Items[Group][Index, 3], uid, Index)
			}
			; セパレーターを追加
			else if (Type == "Separator") {
				this.AppendSeparatorItem_(this.Menus[Group])
			}
			; キャンセルを追加
			else if (Type == "Cancel") {
				this.AppendCancelItem_(this.Menus[Group])
			}
			else {
				
			}
		}
	}
	
	;-----------------------------------------------------------------------
	; メニューハンドラ
	;-----------------------------------------------------------------------
	PumHandler_(Msg, Obj) {
		if (Msg == "onrbutton") {
			Index := Obj.uid
			StringSplit, Index, Index, `,, %A_Space%
			this.PumOnRButton(Index1, Index2, Obj)
		}
		else if (Msg == "onrun") {
			Index := Obj.uid
			StringSplit, Index, Index, `,, %A_Space%
			this.PumOnRun(Index1, Index2, Obj)
		}
/*
		else if (Msg == "onselect") {
			Index := Obj.uid
			StringSplit, Index, Index, `,, %A_Space%
			this.PumOnSelect(Index1, Index2, Obj)
		}
*/
		else if (Msg == "onmenuchar") {
			this.PumOnMenuChar(Obj)
		}
		else {
			
		}
	}
	
/*
	;-----------------------------------------------------------------------
	; OnSelect
	;-----------------------------------------------------------------------
	PumOnSelect(Group, Index, Obj) {
		;Tooltip, % this.Items[Group][Index, 1], 0, 0
	}
*/	
	;-----------------------------------------------------------------------
	; OnRButton
	;-----------------------------------------------------------------------
	PumOnRButton(Group, Index, Obj) {
		this.Open_(Group, Index)
	}
	
	;-----------------------------------------------------------------------
	; OnRun
	;-----------------------------------------------------------------------
	PumOnRun(Group, Index, Obj) {
		this.ResultGroup := Group
		this.ResultIndex := Index
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
				if ((SubPat1 != "") && (SubPat2 != "")) {
					if ((SubPat1 == "Parent") || (SubPat1 == "Group")) {
						item[SubPat1] := SubPat2 + 1
					}
					else if (SubPat1 == "ParamN") {
						if (item["ParamN"] == "") {
							item["ParamN"] := [SubPat2]
						}
						else {
							item["ParamN"].Push(SubPat2)
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
		if (Type == "Application") {
			this.AppendApp(i["Group"], i["Name"], i["AppPath"], i["Param"], i["ExecDir"])
		}
		else if (Type == "Script") {
			this.AppendScript(i["Group"], i["Name"], i["Script"], i["Param"])
		}
		else if (Type == "SubMenu") {
			this.AppendSubMenu(i["Parent"], i["Group"], i["Title"])
		}
		else if (Type == "Separator") {
			this.AppendSeparator(i["Group"])
		}
	}
	
	;-----------------------------------------------------------------------
	; アプリケーション追加
	;-----------------------------------------------------------------------
	AppendApp(Group, Name, AppPath, Param = "", ExecDir = "") {
		if (!IsObject(this.Items[Group])) {
			this.Items[Group] := []
		}
		Index := this.NewIndex_(this.Items[Group])
		this.Items[Group][Index, 1] := "App"
		this.Items[Group][Index, 2] := Name
		this.Items[Group][Index, 3] := AppPath
		this.Items[Group][Index, 4] := Param
		this.Items[Group][Index, 5] := ExecDir
	}
	
	;-----------------------------------------------------------------------
	; スクリプト追加
	;-----------------------------------------------------------------------
	AppendScript(Group, Name, Script, Params) {
		if (!IsObject(this.Items[Group])) {
			this.Items[Group] := []
		}
		Index := this.NewIndex_(this.Items[Group])
		this.Items[Group][Index, 1] := "Script"
		this.Items[Group][Index, 2] := Name
		this.Items[Group][Index, 3] := Script
		this.Items[Group][Index, 4] := Params
	}
	
	;-----------------------------------------------------------------------
	; サブメニュー追加
	;-----------------------------------------------------------------------
	AppendSubMenu(Parent, Group, Title) {
		if (!IsObject(this.Items[Parent])) {
			this.Items[Parent] := []
		}
		Index := this.NewIndex_(this.Items[Parent])
		this.Items[Parent][Index, 1] := "SubMenu"
		this.Items[Parent][Index, 2] := Group
		this.Items[Parent][Index, 3] := Title
	}
	
	;-----------------------------------------------------------------------
	; セパレーター追加
	;-----------------------------------------------------------------------
	AppendSeparator(Group) {
		if (!IsObject(this.Items[Group])) {
			this.Items[Group] := []
		}
		Index := this.NewIndex_(this.Items[Group])
		this.Items[Group][Index, 1] := "Separator"
	}
	
	;-----------------------------------------------------------------------
	; キャンセル追加
	;-----------------------------------------------------------------------
	AppendCancel(Group) {
		if (!IsObject(this.Items[Group])) {
			this.Items[Group] := []
		}
		Index := this.NewIndex_(this.Items[Group])
		this.Items[Group][Index, 1] := "Cancel"
	}
	
	;-----------------------------------------------------------------------
	; 実行
	;-----------------------------------------------------------------------
	Exec_(Group, Index) {
		if (this.Items[Group][Index, 1] == "App") {
			RunApp(this.Items[Group][Index, 3], this.Items[Group][Index, 4], this.Items[Group][Index, 5])
		}
		else if (this.Items[Group][Index, 1] == "Script") {
			param := [this.Items[Group][Index, 3]]
			For index, value in this.Items[Group][Index, 4]
				param.Push(value) 
			CallFunc(param)
		}
		else {
			
		}
	}
	
	;-----------------------------------------------------------------------
	; 開く
	;-----------------------------------------------------------------------
	Open_(Group, Index) {
		if (this.Items[Group][Index, 1] == "App") {
			AppPath := ExpandEnvironmentVriables(this.Items[Group][Index, 3])
			SplitPath, AppPath,, AppDir
			Cmd := "Explorer /e," . AppDir
			Run, %Cmd%
			this.Menus[1].EndMenu()
		}
	}
	
	;-----------------------------------------------------------------------
	; メニュー作成
	;-----------------------------------------------------------------------
	CreateMenu_() {
		MenuParams := {"iconssize"	: 16
					  ;,"tcolor"	: pumAPI.GetSysColor(7)	; default - COLOR_MENUTEXT
					  ;,"bgcolor"	: pumAPI.GetSysColor(4)	; default - COLOR_MENU
					  ;,"nocolors"	: 0
					  ;,"noicons"	: 0
					  ;,"notext"	: 0
					  ;,"maxheight"	: 0
					  ,"xmargin"	: 3
					  ,"ymargin"	: 1
					  ,"textMargin"	: -15		; this is a pixels zmount which will be added after the text to make menu look pretty
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
	; メニュー項目追加
	;-----------------------------------------------------------------------
	AppendMenuItem_(Byref Menu, Title, Icon, uid, Index) {
		Key := this.NewAccessKey_(Index)
		if (Icon != "") {
			Icon .= ":0"
		}
		else {
			Icon := 0
		}
		ItemParams := {"uid"			: uid
					  ,"name"			: "&" Key A_SPACE A_SPACE Title
					  ,"icon"			: Icon
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
CPopupLauncher_PumHandler_(Msg, Obj) {
	CPopupLauncher.Instance.PumHandler_(Msg, Obj)
}

;-----------------------------------------------------------------------
; インクルード
;-----------------------------------------------------------------------
#Include <PUM/PUM_API>
#Include <PUM/PUM>
#include SystemFunctions.ahk
