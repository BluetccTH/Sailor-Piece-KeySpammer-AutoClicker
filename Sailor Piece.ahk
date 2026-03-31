#Requires AutoHotkey v2.0
#SingleInstance Force

; =========================================================
;  Blue.tcc Macro | KUROMI 
;  AutoHotkey v2.0
; =========================================================

IniFile := "AutoSub.ini"
DefaultPresets := "Default"

; =========================
; KUROMI PREMIUM COLORS
; =========================
BgColor          := "120D16"
CardColor        := "18111D"
CardColor2       := "1D1524"
TextColor        := "F8EEFF"
SubTextColor     := "D9B8FF"
AccentColor      := "8E42E8"
AccentColor2     := "FF7CCF"
DangerColor      := "FF5D8B"
SuccessColor     := "72FFC1"
BorderColor      := "4C335F"
InputBg          := "151019"
TitleTextColor   := "FFFFFF"
PanelOverlay     := "171019"

; =========================
; GLOBALS
; =========================
global IsActive := false
global OldToggleKey := ""
global ToggleKey := "F1"
global StartTime := 0
global KeyTasks := []
global KeyEdits := []
global DelayEdits := []
global SlotCount := 2

global DebugMode := false
global LastLogMsg := ""
global LogMsgCount := 0
global LogHistory := []
global UseClicker := false
global ClickDelay := 100
global UseMeleeSwap := false
global MeleeSwapDelay := 5000
global UseTower := false
global TowerDuration := 5
global CurrentMode := "Normal"
global CurrentMelee := 1

; GUI globals
global MainGui := ""
global DebugGui := ""
global DebugEdit := ""
global BgPic := ""

global DDLPreset := ""
global DDLMode := ""
global BtnHotkey := ""

global CheckMelee := ""
global CheckTower := ""
global CheckClick := ""
global CheckDebug := ""

global EditMeleeDelay := ""
global EditTowerTime := ""
global EditClickDelay := ""

global StatusGlow := ""
global StatusCircle := ""
global StatusText := ""
global RuntimeText := ""

global PanelSlots := ""
global PanelMode := ""
global PanelClick := ""
global PanelSystem := ""

global LblMode := ""
global LblClick := ""
global LblSystem := ""

; =========================
; BACKGROUND IMAGE AUTO DETECT
; =========================
BgImagePath := ""
for ext in ["jpg", "jpeg", "png", "bmp"] {
    testFile := A_ScriptDir "\kuromi." ext
    if FileExist(testFile) {
        BgImagePath := testFile
        break
    }
}

; =========================
; FIRST TIME SETUP
; =========================
if !FileExist(IniFile) {
    Result := MsgBox(
        "No configuration has been found`n`n"
        . "OK = Agree to auto subscribe`n"
        . "Cancel = Exit",
        "First Time Setup",
        "OKCancel Iconi"
    )

    if (Result = "Cancel")
        ExitApp()

    Run("https://www.tiktok.com/@blue.tcc?sub_confirmation=1")
    Sleep(12000) ; 

    TargetID := WinGetID("A")
    WinActivate("ahk_id " TargetID)
    Sleep(300)

    WinGetPos(&X, &Y, &W, &H, "ahk_id " TargetID)

    
    clickX := Round(X + (W / 1.6458))
    clickY := Round(Y + (H / 4.9648))

    Click(clickX, clickY) 

    Sleep(100)
    Send("{Tab}")
    Sleep(300)
    Send("{Enter}")

    IniWrite(DefaultPresets, IniFile, "Meta", "Presets")
    IniWrite("e", IniFile, "Default", "Key1")
    IniWrite("100", IniFile, "Default", "Delay1")
}

PresetList := IniRead(IniFile, "Meta", "Presets", DefaultPresets)

; =========================
; DEBUG GUI
; =========================
DebugGui := Gui("+AlwaysOnTop -MaximizeBox +ToolWindow", "Kuromi Debug Log")
DebugGui.BackColor := BgColor
DebugGui.SetFont("s9 c" TextColor, "Consolas")
DebugEdit := DebugGui.Add("Edit", "x10 y10 w400 h450 ReadOnly Multi -Wrap Background" CardColor " c" TextColor)

DebugGui.OnEvent("Close", (*) => (
    IsSet(CheckDebug) && IsObject(CheckDebug) ? (CheckDebug.Value := 0) : 0,
    ToggleDebugGui()
))

LogDebug(Msg) {
    global DebugMode, DebugEdit, LastLogMsg, LogMsgCount, LogHistory
    if (!DebugMode)
        return

    Timestamp := FormatTime(A_Now, "HH:mm:ss")

    if (Msg = LastLogMsg) {
        LogMsgCount++
        if (LogHistory.Length > 0)
            LogHistory[LogHistory.Length] := "[" Timestamp "] " Msg " (x" LogMsgCount ")"
        else
            LogHistory.Push("[" Timestamp "] " Msg " (x" LogMsgCount ")")
    } else {
        LastLogMsg := Msg
        LogMsgCount := 1
        LogHistory.Push("[" Timestamp "] " Msg)
        if (LogHistory.Length > 180)
            LogHistory.RemoveAt(1)
    }

    OutText := ""
    for item in LogHistory
        OutText .= item "`n"

    DebugEdit.Value := OutText
    SendMessage(0x115, 7, 0, DebugEdit.Hwnd) ; WM_VSCROLL / SB_BOTTOM
}

ToggleDebugGui(*) {
    global DebugMode, CheckDebug, DebugGui
    if !(IsSet(CheckDebug) && IsObject(CheckDebug))
        return

    DebugMode := CheckDebug.Value

    if (DebugMode) {
        DebugGui.Show("w420 h470 NoActivate")
        LogDebug("--- Kuromi Premium Debug Enabled ---")
    } else {
        DebugGui.Hide()
    }
}

; =========================
; MAIN GUI
; =========================
MainGui := Gui("+AlwaysOnTop -MaximizeBox -DPIScale", "Blue.tcc | Kuromi 💜🖤")
MainGui.OnEvent("Close", (*) => ExitApp())
MainGui.BackColor := BgColor
MainGui.SetFont("s9 c" TextColor, "Segoe UI")

; -------------------------
; BACKGROUND LAYER
; -------------------------
if (BgImagePath != "") {
    BgPic := MainGui.Add("Picture", "x0 y0 w380 h900", BgImagePath)
}

; =========================
; HEADER (Overlay Style)
; =========================
HeaderBg := MainGui.Add("Text", "x8 y8 w364 h46 +0x200 Background" CardColor2)
HeaderBg.OnEvent("Click", StartDragWindow)
HeaderBg.OnEvent("DoubleClick", (*) => Run("https://discord.gg/WTYgx6CPeh"))

HeaderTitle := MainGui.Add("Text", "x18 y15 w344 h18 Center BackgroundTrans cFFFFFF", "💜 KUROMI • Blue.tcc 🖤")
HeaderTitle.SetFont("s12 w700", "Segoe UI")
HeaderTitle.OnEvent("Click", StartDragWindow)
HeaderTitle.OnEvent("DoubleClick", (*) => Run("https://discord.gg/WTYgx6CPeh"))

HeaderSub := MainGui.Add("Text", "x18 y34 w344 h12 Center BackgroundTrans c" SubTextColor, "Double Click Header To Join Discord")
HeaderSub.SetFont("s7 w400", "Segoe UI")
HeaderSub.OnEvent("Click", StartDragWindow)
HeaderSub.OnEvent("DoubleClick", (*) => Run("https://discord.gg/WTYgx6CPeh"))

; =========================
; DECOR / PANEL BACKS
; =========================

PanelPreset := MainGui.Add("Text", "x12 y66 w356 h70 Background" CardColor2)
PanelSlots  := MainGui.Add("Text", "x12 y145 w356 h10 Background" PanelOverlay)
PanelMode   := MainGui.Add("Text", "x12 y0 w356 h10 Background" PanelOverlay)
PanelClick  := MainGui.Add("Text", "x12 y0 w356 h10 Background" PanelOverlay)
PanelSystem := MainGui.Add("Text", "x12 y0 w356 h10 Background" PanelOverlay)

; =========================
; PRESET SECTION
; =========================
LblPreset := MainGui.Add("Text", "x22 y74 w200 h18 BackgroundTrans c" SubTextColor, "💾 Preset Manager")
LblPreset.SetFont("s9 w700", "Segoe UI")

DDLPreset := MainGui.Add("DropDownList", "x24 y98 w140 Choose1 Background" InputBg, StrSplit(PresetList, "|"))
DDLPreset.OnEvent("Change", (guiCtrl, *) => LoadPresetSettings(guiCtrl.Text))

BtnNew := MainGui.Add("Button", "x172 y97 w54 h28", "NEW")
BtnDel := MainGui.Add("Button", "x232 y97 w54 h28", "DEL")
BtnSave := MainGui.Add("Button", "x292 y97 w60 h28", "SAVE")

BtnNew.OnEvent("Click", CreateNewPreset)
BtnDel.OnEvent("Click", DeletePreset)
BtnSave.OnEvent("Click", (*) => SaveAndApply(true))

; =========================
; SLOT SECTION
; =========================
LblSlots := MainGui.Add("Text", "x22 y152 w200 h18 BackgroundTrans c" SubTextColor, "⌨️ Key Tasks")
LblSlots.SetFont("s9 w700", "Segoe UI")

MainGui.Add("Text", "x24 y176 w130 BackgroundTrans c" SubTextColor, "Target Key")
MainGui.Add("Text", "x208 y176 w120 BackgroundTrans c" SubTextColor, "Delay (ms)")

global SlotContainerY := 198

Loop 10 {
    YPos := SlotContainerY + ((A_Index - 1) * 30)

    ke := MainGui.Add("Edit", "x24 y" YPos " w140 h24 Background" InputBg " c" TextColor)
    de := MainGui.Add("Edit", "x208 y" YPos " w120 h24 Background" InputBg " c" TextColor)

    ke.OnEvent("Change", (*) => SaveAndApply(false))
    de.OnEvent("Change", (*) => SaveAndApply(false))

    KeyEdits.Push(ke)
    DelayEdits.Push(de)
}

BtnAddSlot := MainGui.Add("Button", "w150 h30", "➕ ADD SLOT")
BtnRemoveSlot := MainGui.Add("Button", "w150 h30", "➖ REMOVE SLOT")
BtnAddSlot.OnEvent("Click", (*) => ChangeSlotCount(1))
BtnRemoveSlot.OnEvent("Click", (*) => ChangeSlotCount(-1))

; =========================
; MODE SECTION
; =========================
LblMode := MainGui.Add("Text", "x22 y0 w200 h18 BackgroundTrans c" SubTextColor, "⚙️ Mode Settings")
LblMode.SetFont("s9 w700", "Segoe UI")

TxtMode := MainGui.Add("Text", "w70 BackgroundTrans c" TextColor, "Mode:")
DDLMode := MainGui.Add("DropDownList", "w200 Choose1 Background" InputBg, ["Normal", "Boss Rush", "Infinite Tower"])
DDLMode.OnEvent("Change", (*) => (UpdateGuiLayout(), SaveAndApply(false)))

CheckMelee := MainGui.Add("Checkbox", "w180 c" TextColor, "Enable Melee Swap")
CheckMelee.OnEvent("Click", (*) => SaveAndApply(false))

BtnSetM1 := MainGui.Add("Button", "w150 h26", "Set Melee 1")
BtnSetM2 := MainGui.Add("Button", "w150 h26", "Set Melee 2")
BtnSetM1.OnEvent("Click", (*) => GrabPos(1))
BtnSetM2.OnEvent("Click", (*) => GrabPos(2))

TxtSwap := MainGui.Add("Text", "w150 BackgroundTrans c" TextColor, "Swap Interval (ms):")
EditMeleeDelay := MainGui.Add("Edit", "w150 h24 Background" InputBg " c" TextColor, "5000")
EditMeleeDelay.OnEvent("Change", (*) => SaveAndApply(false))

CheckTower := MainGui.Add("Checkbox", "w180 c" TextColor, "Enable Tower Reset")
CheckTower.OnEvent("Click", (*) => SaveAndApply(false))

TxtTowerTime := MainGui.Add("Text", "w150 BackgroundTrans c" TextColor, "Tower Reset (Mins):")
EditTowerTime := MainGui.Add("Edit", "w150 h24 Background" InputBg " c" TextColor, "5")
EditTowerTime.OnEvent("Change", (*) => SaveAndApply(false))

; =========================
; CLICKER SECTION
; =========================
LblClick := MainGui.Add("Text", "x22 y0 w200 h18 BackgroundTrans c" SubTextColor, "🖱️ Auto Clicker")
LblClick.SetFont("s9 w700", "Segoe UI")

CheckClick := MainGui.Add("Checkbox", "w180 vUseClick c" TextColor, "Enable Auto Clicker")
CheckClick.OnEvent("Click", (*) => SaveAndApply(false))

EditClickDelay := MainGui.Add("Edit", "w150 h24 Background" InputBg " c" TextColor, "100")
EditClickDelay.OnEvent("Change", (*) => SaveAndApply(false))

; =========================
; SYSTEM SECTION
; =========================
LblSystem := MainGui.Add("Text", "x22 y0 w200 h18 BackgroundTrans c" SubTextColor, "💻 System")
LblSystem.SetFont("s9 w700", "Segoe UI")

TxtHotkey := MainGui.Add("Text", "w90 BackgroundTrans c" SubTextColor, "Toggle Key:")
BtnHotkey := MainGui.Add("Button", "w200 h30", "F1")
BtnHotkey.OnEvent("Click", RecordHotkey)

CheckDebug := MainGui.Add("Checkbox", "w180 c" TextColor, "Enable Debug Log")
CheckDebug.OnEvent("Click", ToggleDebugGui)

StatusGlow := MainGui.Add("Text", "w16 h16 Background" DangerColor)
StatusCircle := MainGui.Add("Text", "w12 h12 Background" DangerColor)
StatusText := MainGui.Add("Text", "w70 BackgroundTrans c" TextColor " vStatusTxt", "OFF")
RuntimeText := MainGui.Add("Text", "w160 Right BackgroundTrans c" SubTextColor " vRuntimeTxt", "Runtime: 0s")

; =========================
; INITIAL LOAD
; =========================
LoadPresetSettings(DDLPreset.Text)

; =========================================================
; FUNCTIONS
; =========================================================

StartDragWindow(*) {
    global MainGui
    PostMessage(0xA1, 2,,, "ahk_id " MainGui.Hwnd) ; WM_NCLBUTTONDOWN HTCAPTION
}

ChangeSlotCount(change) {
    global SlotCount
    newCount := SlotCount + change
    if (newCount < 2 || newCount > 10)
        return

    SlotCount := newCount
    UpdateGuiLayout()
    SaveAndApply(false)
}

UpdateGuiLayout() {
    global SlotCount, SlotContainerY
    global KeyEdits, DelayEdits
    global BtnAddSlot, BtnRemoveSlot
    global DDLMode, TxtMode
    global CheckMelee, BtnSetM1, BtnSetM2, TxtSwap, EditMeleeDelay
    global CheckTower, TxtTowerTime, EditTowerTime
    global CheckClick, EditClickDelay
    global TxtHotkey, BtnHotkey, CheckDebug
    global StatusGlow, StatusCircle, StatusText, RuntimeText
    global PanelSlots, PanelMode, PanelClick, PanelSystem
    global LblMode, LblClick, LblSystem
    global MainGui, BgPic

    Loop 10 {
        if (A_Index <= SlotCount) {
            KeyEdits[A_Index].Visible := true
            DelayEdits[A_Index].Visible := true
        } else {
            KeyEdits[A_Index].Visible := false
            DelayEdits[A_Index].Visible := false
            KeyEdits[A_Index].Value := ""
        }
    }

    CurrentModeLocal := DDLMode.Text
    if (CurrentModeLocal = "")
        CurrentModeLocal := "Normal"

    ShowMelee := (CurrentModeLocal = "Boss Rush" || CurrentModeLocal = "Infinite Tower")
    ShowTower := (CurrentModeLocal = "Infinite Tower")

    ; ---------- SLOT PANEL ----------
    NextY := SlotContainerY + (SlotCount * 30) + 10
    BtnAddSlot.Move(24, NextY)
    BtnRemoveSlot.Move(186, NextY)
    NextY += 40

    PanelSlots.Move(12, 145, 356, NextY - 145 + 8)
    NextY += 12

    ; ---------- MODE PANEL ----------
    StartY_Mode := NextY
    LblMode.Move(22, StartY_Mode + 8)
    NextY += 32

    TxtMode.Move(24, NextY + 4)
    DDLMode.Move(100, NextY)
    NextY += 34

    if (ShowMelee) {
        CheckMelee.Visible := true
        BtnSetM1.Visible := true
        BtnSetM2.Visible := true
        TxtSwap.Visible := true
        EditMeleeDelay.Visible := true

        CheckMelee.Move(24, NextY)
        NextY += 30

        BtnSetM1.Move(24, NextY)
        BtnSetM2.Move(186, NextY)
        NextY += 32

        TxtSwap.Move(24, NextY + 4)
        EditMeleeDelay.Move(186, NextY)
        NextY += 32
    } else {
        CheckMelee.Visible := false
        BtnSetM1.Visible := false
        BtnSetM2.Visible := false
        TxtSwap.Visible := false
        EditMeleeDelay.Visible := false
    }

    if (ShowTower) {
        CheckTower.Visible := true
        TxtTowerTime.Visible := true
        EditTowerTime.Visible := true

        CheckTower.Move(24, NextY)
        NextY += 30

        TxtTowerTime.Move(24, NextY + 4)
        EditTowerTime.Move(186, NextY)
        NextY += 32
    } else {
        CheckTower.Visible := false
        TxtTowerTime.Visible := false
        EditTowerTime.Visible := false
    }

    PanelMode.Move(12, StartY_Mode, 356, NextY - StartY_Mode + 8)
    NextY += 12

    ; ---------- CLICKER PANEL ----------
    StartY_Click := NextY
    LblClick.Move(22, StartY_Click + 8)
    NextY += 32

    CheckClick.Move(24, NextY + 2)
    EditClickDelay.Move(186, NextY)
    NextY += 34

    PanelClick.Move(12, StartY_Click, 356, NextY - StartY_Click + 8)
    NextY += 12

    ; ---------- SYSTEM PANEL ----------
    StartY_System := NextY
    LblSystem.Move(22, StartY_System + 8)
    NextY += 32

    TxtHotkey.Move(24, NextY + 5)
    BtnHotkey.Move(100, NextY)
    NextY += 38

    CheckDebug.Move(24, NextY)
    NextY += 30

    StatusGlow.Move(24, NextY + 3, 16, 16)
    StatusCircle.Move(26, NextY + 5, 12, 12)
    StatusText.Move(48, NextY + 1)
    RuntimeText.Move(170, NextY + 1)
    NextY += 30

    PanelSystem.Move(12, StartY_System, 356, NextY - StartY_System + 10)
    NextY += 14

    TotalHeight := NextY

    ; resize background image if exists
    try if IsObject(BgPic)
        BgPic.Move(0, 0, 380, TotalHeight + 10)

    MainGui.Show("w380 h" TotalHeight " NoActivate")
    WinRedraw(MainGui.Hwnd)
}

GrabPos(num) {
    global IniFile, DDLPreset

    ToolTip("Click on the item in your inventory...")
    KeyWait("LButton", "D")
    MouseGetPos(&mX, &mY)
    IniWrite(mX, IniFile, DDLPreset.Text, "M" num "X")
    IniWrite(mY, IniFile, DDLPreset.Text, "M" num "Y")
    ToolTip("Position " num " Saved! 💜")
    LogDebug("Melee Position " num " saved at X:" mX " Y:" mY)
    Sleep(1000)
    ToolTip()
}

LoadPresetSettings(PName) {
    global SlotCount, BtnHotkey, KeyEdits, DelayEdits, DDLMode
    global CheckClick, EditClickDelay, CheckMelee, EditMeleeDelay
    global CheckTower, EditTowerTime

    SlotCount := Number(IniRead(IniFile, PName, "SavedSlots", 2))
    if (SlotCount < 2)
        SlotCount := 2
    if (SlotCount > 10)
        SlotCount := 10

    BtnHotkey.Text := IniRead(IniFile, PName, "ToggleKey", "F1")

    Loop 10 {
        if (A_Index <= SlotCount) {
            KeyEdits[A_Index].Value := IniRead(IniFile, PName, "Key" A_Index, "")
            DelayEdits[A_Index].Value := IniRead(IniFile, PName, "Delay" A_Index, "100")
        } else {
            KeyEdits[A_Index].Value := ""
            DelayEdits[A_Index].Value := "100"
        }
    }

    SavedMode := IniRead(IniFile, PName, "MacroMode", "Normal")
    try DDLMode.Choose(SavedMode)
    catch
        DDLMode.Choose(1)

    if (DDLMode.Text = "")
        DDLMode.Choose(1)

    CheckClick.Value := IniRead(IniFile, PName, "UseClicker", 0)
    EditClickDelay.Value := IniRead(IniFile, PName, "ClickDelay", "100")

    CheckMelee.Value := IniRead(IniFile, PName, "UseMeleeSwap", 0)
    EditMeleeDelay.Value := IniRead(IniFile, PName, "MeleeSwapDelay", "5000")

    CheckTower.Value := IniRead(IniFile, PName, "UseTower", 0)
    EditTowerTime.Value := IniRead(IniFile, PName, "TowerTime", "5")

    UpdateGuiLayout()
    UpdateSettings(false)
}

SaveAndApply(ShowMsg := false) {
    global SlotCount, IniFile, DDLPreset, KeyEdits, DelayEdits
    global DDLMode, CheckClick, EditClickDelay
    global CheckMelee, EditMeleeDelay
    global CheckTower, EditTowerTime
    global BtnHotkey

    PName := DDLPreset.Text
    IniWrite(SlotCount, IniFile, PName, "SavedSlots")

    Loop 10 {
        if (A_Index <= SlotCount) {
            IniWrite(KeyEdits[A_Index].Value, IniFile, PName, "Key" A_Index)
            IniWrite(DelayEdits[A_Index].Value, IniFile, PName, "Delay" A_Index)
        } else {
            try IniDelete(IniFile, PName, "Key" A_Index)
            try IniDelete(IniFile, PName, "Delay" A_Index)
        }
    }

    IniWrite(DDLMode.Text, IniFile, PName, "MacroMode")
    IniWrite(CheckClick.Value, IniFile, PName, "UseClicker")
    IniWrite(EditClickDelay.Value, IniFile, PName, "ClickDelay")

    IniWrite(CheckMelee.Value, IniFile, PName, "UseMeleeSwap")
    IniWrite(EditMeleeDelay.Value, IniFile, PName, "MeleeSwapDelay")

    IniWrite(CheckTower.Value, IniFile, PName, "UseTower")
    IniWrite(EditTowerTime.Value, IniFile, PName, "TowerTime")

    IniWrite(BtnHotkey.Text, IniFile, PName, "ToggleKey")
    UpdateSettings(ShowMsg)
}

ParseTowerTime(timeStr) {
    timeStr := Trim(timeStr)
    if InStr(timeStr, ":") {
        parts := StrSplit(timeStr, ":")
        m := (parts.Length >= 1 && IsNumber(parts[1])) ? Number(parts[1]) : 0
        s := (parts.Length >= 2 && IsNumber(parts[2])) ? Number(parts[2]) : 0
        return m + (s / 60)
    }
    return IsNumber(timeStr) ? Number(timeStr) : 5
}

UpdateSettings(ShowMsg := false) {
    global KeyTasks, UseClicker, ClickDelay, ToggleKey, OldToggleKey, IsActive
    global UseMeleeSwap, MeleeSwapDelay, UseTower, TowerDuration, CurrentMode
    global SlotCount, KeyEdits, DelayEdits
    global EditClickDelay, EditMeleeDelay, EditTowerTime
    global DDLMode, CheckClick, CheckMelee, CheckTower, BtnHotkey

    if (OldToggleKey != "") {
        try Hotkey(OldToggleKey, "Off")
    }

    StopAllTimers()
    KeyTasks := []

    Loop SlotCount {
        k := Trim(KeyEdits[A_Index].Value)
        d := Trim(DelayEdits[A_Index].Value)

        if (k = "")
            continue

        thisDelay := IsNumber(d) ? Number(d) : 100
        KeyTasks.Push({k: k, d: thisDelay, fn: SendSpecificKey.Bind(k)})
    }

    ClickDelay := IsNumber(EditClickDelay.Value) ? Number(EditClickDelay.Value) : 100
    MeleeSwapDelay := IsNumber(EditMeleeDelay.Value) ? Number(EditMeleeDelay.Value) : 5000
    TowerDuration := ParseTowerTime(EditTowerTime.Value)

    CurrentMode := DDLMode.Text
    UseClicker := CheckClick.Value
    UseMeleeSwap := (CurrentMode = "Boss Rush" || CurrentMode = "Infinite Tower") ? CheckMelee.Value : 0
    UseTower := (CurrentMode = "Infinite Tower") ? CheckTower.Value : 0

    ToggleKey := BtnHotkey.Text

    try Hotkey(ToggleKey, ToggleSpam, "On")
    OldToggleKey := ToggleKey

    if (ShowMsg)
        MsgBox("Settings Applied 💜", "Kuromi", "Iconi T1")
}

ToggleSpam(*) {
    global IsActive, StartTime, CurrentMelee, UseTower, TowerDuration
    global StatusGlow, StatusCircle, StatusText, SuccessColor

    IsActive := !IsActive

    if (IsActive) {
        StartTime := A_TickCount
        CurrentMelee := 1
        LogDebug("Macro Toggled: ON (Starting Melee " CurrentMelee ")")
        ResumeMacro()

        if (UseTower && TowerDuration > 0) {
            LogDebug("Tower Reset Timer set for " TowerDuration " mins.")
            SetTimer(DoTowerReset, -(TowerDuration * 60000))
        }

        SetTimer(UpdateRuntime, 1000)
        StatusGlow.Opt("Background" SuccessColor)
        StatusCircle.Opt("Background" SuccessColor)
        StatusText.Value := "ON"
    } else {
        LogDebug("Macro Toggled: OFF")
        StopAllTimers()
    }
}

PauseMacro() {
    global KeyTasks
    for task in KeyTasks
        SetTimer(task.fn, 0)

    try SetTimer(DoTheClick, 0)
    try SetTimer(DoMeleeSwap, 0)
}

ResumeMacro() {
    global KeyTasks, UseClicker, ClickDelay, UseMeleeSwap, MeleeSwapDelay

    for task in KeyTasks
        SetTimer(task.fn, task.d)

    if (UseClicker)
        SetTimer(DoTheClick, ClickDelay)

    if (UseMeleeSwap)
        SetTimer(DoMeleeSwap, MeleeSwapDelay)
}

SafeSleep(duration) {
    global IsActive
    endTime := A_TickCount + duration
    while (A_TickCount < endTime) {
        if (!IsActive)
            return false
        Sleep(50)
    }
    return true
}

DoTowerReset() {
    global IsActive, UseTower, TowerDuration

    if (!IsActive)
        return

    LogDebug("Tower Reset: Pause Macro & Initiating sequence...")
    PauseMacro()

    Loop 5 {
        if (!IsActive) {
            LogDebug("Tower Reset aborted (macro turned off).")
            break
        }

        if WinActive("A") {
            LogDebug("Tower Reset: Sending Esc -> R -> Enter")
            Send("{Esc}")
            Sleep(200)

            Send("r")
            Sleep(200)

            Send("{Enter}")

            if (A_Index < 5) {
                if (!SafeSleep(7000))
                    break
            }
        } else {
            if (!SafeSleep(1000))
                break
        }
    }

    if (IsActive) {
        LogDebug("Tower Reset: Waiting 20 seconds for loading screen...")
        SafeSleep(20000)
    }

    if (IsActive) {
        if (WinActive("A")) {
            LogDebug("Tower Reset: Sending 1 to equip unit")
            Send("1")
            Sleep(200)
        }

        LogDebug("Tower Reset complete. Resuming macro.")
        ResumeMacro()
        if (UseTower && TowerDuration > 0)
            SetTimer(DoTowerReset, -(TowerDuration * 60000))
    }
}

DoMeleeSwap() {
    global CurrentMelee, UseTower
    global DDLPreset, IniFile

    if !WinActive("A")
        return

    PName := DDLPreset.Text
    mX := IniRead(IniFile, PName, "M" CurrentMelee "X", 0)
    mY := IniRead(IniFile, PName, "M" CurrentMelee "Y", 0)

    if (mX = 0) {
        LogDebug("Melee Swap Failed: Position " CurrentMelee " not set!")
        return
    }

    Click(mX, mY)
    Sleep(50)
    Send("1")

    if (UseTower) {
        Sleep(50)
        Send("2")
    }

    CurrentMelee := (CurrentMelee = 1) ? 2 : 1
    LogDebug("Swapped active weapon to Melee " CurrentMelee)
}

StopAllTimers() {
    global IsActive, StatusGlow, StatusCircle, StatusText, DangerColor

    IsActive := false
    PauseMacro()
    try SetTimer(DoTowerReset, 0)
    SetTimer(UpdateRuntime, 0)

    StatusGlow.Opt("Background" DangerColor)
    StatusCircle.Opt("Background" DangerColor)
    StatusText.Value := "OFF"
}

SendSpecificKey(keyToSend) {
    if WinActive("A") {
        Send(keyToSend)
        LogDebug("Executed Key: " keyToSend)
    }
}

DoTheClick() {
    if WinActive("A") {
        Click()
        LogDebug("Executed Click")
    }
}

UpdateRuntime() {
    global StartTime, RuntimeText
    Elapsed := Floor((A_TickCount - StartTime) / 1000)
    Mins := Floor(Elapsed / 60)
    Secs := Mod(Elapsed, 60)
    RuntimeText.Value := "Runtime: " (Mins > 0 ? Mins "m " : "") Secs "s"
}

RecordHotkey(*) {
    global BtnHotkey
    BtnHotkey.Text := "..."

    ih := InputHook("L1", "{F1}{F2}{F3}{F4}{F5}{F6}{F7}{F8}{F9}{F10}{F11}{F12}")
    ih.Start()

    NewKey := ""
    while (ih.InProgress) {
        if GetKeyState("XButton1", "P") {
            NewKey := "XButton1"
            ih.Stop()
            break
        }
        if GetKeyState("XButton2", "P") {
            NewKey := "XButton2"
            ih.Stop()
            break
        }
        if GetKeyState("MButton", "P") {
            NewKey := "MButton"
            ih.Stop()
            break
        }
        Sleep(10)
    }

    if (NewKey = "")
        NewKey := (ih.EndKey != "") ? ih.EndKey : ih.Input

    if (NewKey != "") {
        BtnHotkey.Text := NewKey
        SaveAndApply(false)
    } else {
        BtnHotkey.Text := "F1"
        SaveAndApply(false)
    }
}

CreateNewPreset(*) {
    global PresetList, IniFile, DDLPreset

    IB := InputBox("Name:", "New Preset")
    if (IB.Result = "Cancel" || Trim(IB.Value) = "")
        return

    NewPresetName := Trim(IB.Value)

    
    for item in StrSplit(PresetList, "|") {
        if (item = NewPresetName) {
            MsgBox("Preset already exists.", "Kuromi", "Icon!")
            return
        }
    }

    PresetList .= "|" NewPresetName
    IniWrite(PresetList, IniFile, "Meta", "Presets")

    DDLPreset.Delete()
    DDLPreset.Add(StrSplit(PresetList, "|"))
    DDLPreset.Text := NewPresetName
    SaveAndApply(false)
}

DeletePreset(*) {
    global PresetList, IniFile, DDLPreset

    if (StrSplit(PresetList, "|").Length <= 1)
        return

    TargetPreset := DDLPreset.Text
    Result := MsgBox("Delete preset '" TargetPreset "' ?", "Confirm Delete", "YesNo Icon!")

    if (Result != "Yes")
        return

    try IniDelete(IniFile, TargetPreset)

    NewList := ""
    for index, item in StrSplit(PresetList, "|") {
        if (item != TargetPreset)
            NewList .= (NewList = "" ? "" : "|") item
    }

    PresetList := NewList
    IniWrite(PresetList, IniFile, "Meta", "Presets")

    DDLPreset.Delete()
    DDLPreset.Add(StrSplit(PresetList, "|"))
    DDLPreset.Choose(1)
    LoadPresetSettings(DDLPreset.Text)
}