;***********************************************************************************************
; 
; キー関連
; 
;***********************************************************************************************
;***********************************************************************************************
; x2キーハンドラ
;***********************************************************************************************
x2Key(Key, Func) {
	if ((A_PriorHotkey != A_ThisHotKey) || (A_TimeSincePriorHotkey > 200)) {
		KeyWait, %Key%
	}
	else {
		CallFunc(Func)
	}
}

;***********************************************************************************************
; キー送信
;***********************************************************************************************
SendKey(RealKey, SimulateKey, Delay = 0.5, Repeat = 0.25) {
	real := Trim(RealKey, "{}")
    SendInput, {Blind}%SimulateKey%
    KeyWait, %real%, T%Delay%
    if (ErrorLevel <> 0) {
        if (InStr(SimulateKey, "}")) {
            sim := RTrim(SimulateKey, "}")
        }
        else {
            sim := "{" + SimulateKey
        }
        key := sim " down}"
        ;ToolTip, %RealKey% => %real% / %SimulateKey% => %key% / %Delay% / %Repeat%, 0, 0
        While (ErrorLevel <> 0) {
            SendInput, {Blind}%key%
            KeyWait, %real%, T%Repeat%
        }
        key := sim " up}"
        SendInput, {Blind}%key%
        ;ToolTip, %RealKey% => %real% / %SimulateKey% => %key% / %Delay% / %Repeat%, 0, 0
    }
}

;***********************************************************************************************
; IME制御付きキー送信
;***********************************************************************************************
SendKeyWithIME(RealKey, SimulateKey, ImeState, Delay = 0.25, Repeat = 0.01) {
	if (IME_GET()) {
		if (IME_GetConverting()) {
			Send, {Esc}
		}
	}
	IME_SET(ImeState)
	SendKey(RealKey, SimulateKey, Delay, Repeat)
}

;***********************************************************************************************
; ホットキー切り替え
;***********************************************************************************************
HotKeySw(Key, Sw) {
	Hotkey, %Key%, , UseErrorLevel
	if ((ErrorLevel == 5) || (ErrorLevel == 6)) {
		; MsgBox, % "Hotkey(" Key ") does not exist"
	}
	else {
		Hotkey, %Key%, %Sw%
	}
}

;***********************************************************************************************
; 拡張キーの文字列を取得
;***********************************************************************************************
GetExKeyStr(Forced) {
	Str := ""
	
	if (InStr(Forced, "+") || GetKeyState("Shift", "P")) {
		Str .= "+"
	}
	if (InStr(Forced, "^") || GetKeyState("Ctrl", "P")) {
		Str .= "^"
	}
	if (InStr(Forced, "!") || GetKeyState("Alt", "P")) {
		Str .= "!"
	}
	if (InStr(Forced, "#") || GetKeyState("LWin", "P") || GetKeyState("RWin", "P")) {
		Str .= "#"
	}
	
	return Str
}

;***********************************************************************************************
; IME
;***********************************************************************************************
ToggleIME() {
    if (IME_GET() == 0) {
        IME_SET(1)
    }
    else {
        IME_SET(0)
    }
}

;***********************************************************************************************
; SandS
;***********************************************************************************************
SandS_Func(ExeMode=1,ITimout="0.1")
{
    MatchList := "1,2,3,4,5,6,7,8,9,0,-,^,\,q,w,e,r,t,y,u,i,o,p,@,[,a,s,d,f,g,h,j,k,l,`;,:,],z,x,c,v,b,n,m,`,,.,/"
    EndKeys := "{Tab}{Enter}{Esc}{BS}{Del}{Ins}{Home}{End}{Pgup}{Pgdn}{Up}{Down}{Left}{Right}{F1}{F2}{F3}{F4}{F5}{F6}{F7}{F8}{F9}{F10}{F11}{F12}{sc073}"    ; {sc073}:右下\

    Hotkey,$Space,OFF                   ;ｷｰﾘﾋﾟｰﾄ ｲﾍﾞﾝﾄ多発防止 2008.9.21
    SetBatchLines,-1
    SetKeyDelay,-1

    ifEqual,ExeMode,0,      Send,{Shift Down}
    ifEqual,ExeMode,2,      BlockInput,ON

    key_count := 0
    Loop 
    {
        Input,input_keys,I L1 T%ITimout%,%EndKeys%,%MatchList%

        ; 特殊キー： Send用に {} で包んどく
        ifInstring ErrorLevel, EndKey:
        {
            StringReplace,input_keys,ErrorLevel, EndKey:
            input_keys = {%input_keys%}
        }
        ;[^] : controlﾓﾃﾞﾌｧｲﾔとの混同防止  2008.09.21
        ifEqual,input_keys,^,   SetEnv,input_keys,{%input_keys%}
        ;[,] : ThinkPadだと何故か上手く送れないので変換しておく 2008.09.21
        StringReplace,input_keys,input_keys,`,,<

        StringReplace,input_keys,input_keys,%A_Space%,,ALL  ;Space除去
        len := StrLen(input_keys)
        if (len > 0)
        {   ;同時押し修飾キーチェック
            if (GetKeyState("Ctrl","P"))
                modifier_key := "^"
            if (GetKeyState("Alt","P"))
                modifier_key := "!" . modifier_key
            if (GetKeyState("LWin","P") || GetKeyState("RWin","P"))
                modifier_key := "#" . modifier_key

            ifNotEqual,ExeMode,0,      SetEnv,modifier_key,+%modifier_key%
            SendInput,%modifier_key%%input_keys%
            key_count += len
        }

        if !GetKeyState("Space","P")
            break
    }
    ifEqual,ExeMode,2,      BlockInput,OFF
    ifEqual,ExeMode,0,      Send,{Shift Up}

    ;入力文字が一つもない場合は Space 送信
    ifEqual key_count,0,   Send,{Space}
    Hotkey,$Space,ON                    ;ｷｰﾘﾋﾟｰﾄ ｲﾍﾞﾝﾄ多発防止 2008.9.21
}

;***********************************************************************************************
; インクルード
;***********************************************************************************************
#Include <IME/IME>
#include SystemFunctions.ahk
#Include <IME/IME> 
