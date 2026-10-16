<#
qa_key_os_harness.ps1 — [대형 기획 15] Q-2 실제 OS 레벨 키 입력 하네스.

왜 필요한가: N-1(2026-10-15)은 Input.parse_input_event()로 엔진 내부에 InputEventKey를
직접 주입해 "방향키/스페이스 흐름"을 검증했고 통과했지만, 사용자는 "실제 플레이에서는
방향키/스페이스가 안 먹는다"고 보고했다 — 엔진 내부 주입은 OS가 실제로 키 입력을
윈도우에 전달하는 경로(창이 OS 포커스를 받는지, 메시지 펌프가 정상인지 등)를 전혀
거치지 않으므로 그 경로의 문제를 놓칠 수 있다. 이 스크립트는 실제 Godot 창을 띄우고,
Win32 API로 그 창을 진짜 전면(포그라운드)으로 만든 뒤, SendKeys로 진짜 OS 키 이벤트를
보낸다 — Godot이 그 입력을 실제로 받아 포커스를 옮겼는지는 code/qa/visual_qa.gd의
GAME_QA_FOCUS_LOG=1이 찍는 "[FocusLog] focus=<NodePath>" 로그로 객관적으로 확인한다
(화면도 QA_SHOW_WINDOW=1로 항상 보이게 띄운다).

**중요(이 하네스를 만들며 발견한 환경 특성)**: 이 세션(무인 자동화)에서 단순
Microsoft.VisualBasic의 AppActivate(pid)는 예외 없이 "성공"한 것처럼 보이지만 실제로는
포그라운드가 전혀 안 바뀐다(diagnostic 확인 결과 — 이 환경은 늘 다른 창이 전면을 쥐고
있어서 Windows의 포그라운드 탈취 방지 정책에 막힘). **EnumWindows로 Godot PID의 최상위
창을 직접 찾고, AttachThreadInput()으로 현재 포그라운드 스레드에 입력을 붙인 뒤
SetForegroundWindow()를 호출하는 방식만 실제로 통한다** — 아래 구현이 그 방식이다.
AppActivate/일반 SetForegroundWindow만 쓰는 접근은 이 환경에서 거짓 성공을 낸다는 점을
다음에 이 하네스를 고칠 사람은 반드시 유의할 것.

사용법:
  powershell -File scripts/qa_key_os_harness.ps1 [-Scene <씬이름>] [-Keys "Right,Right,Space,Down,Space"]
    [-WarmupMs 3000] [-KeyDelayMs 450] [-LogPath <경로>]

  -Scene 생략 시: GAME_START를 비워 "진짜 평상시 실행"(project.godot의 main_scene=
    character_select)으로 띄운다 — 가장 신뢰도 높은 "실제 플레이" 재현.
  -Scene 지정 시: GAME_START=<Scene>으로 그 화면부터 시작한다(예: dungeon_map,
    combat_test, event, shop, story_event). 화면 진입 경로만 QA 전용이고, 그 다음
    보내는 키 입력 자체는 여전히 진짜 OS 키 이벤트다(N-1의 엔진 내부 주입과는 종류가
    다름). GAME_QA_FRAME을 아주 크게 줘서 캡처 타이머가 끼어들어 창을 끄지 않게 한다.

예:
  powershell -File scripts/qa_key_os_harness.ps1 -Keys "Right"
  powershell -File scripts/qa_key_os_harness.ps1 -Scene dungeon_map -Keys "Down,Space"

결과: qa_out/os_key_harness_<scene>.log 에 Godot stdout 전체([FocusLog]/[VisualQA] 줄이
핵심)가 저장되고, 이 스크립트도 같은 줄을 콘솔에 바로 요약 출력한다.
#>
param(
    [string]$Scene = "",
    [string]$Keys = "",
    [int]$WarmupMs = 3000,
    [int]$KeyDelayMs = 450,
    [string]$LogPath = "",
    [int]$ExtraWaitMs = 1200
)

$ErrorActionPreference = "Stop"

$ProjectDir = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$GodotBin = $env:GODOT_BIN
if (-not $GodotBin) { $GodotBin = "D:/Godot/Godot_v4.7.2-stable_win64.exe" }

$SceneLabel = if ($Scene) { $Scene } else { "character_select" }
if (-not $LogPath) {
    $LogPath = Join-Path $ProjectDir ("qa_out/os_key_harness_" + $SceneLabel + ".log")
}
New-Item -ItemType Directory -Force -Path (Split-Path $LogPath) | Out-Null
$ErrLogPath = "$LogPath.err"

Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public class QaWin32 {
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr hWnd);
    [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
}
"@

## PowerShell 스크립트블록이 EnumWindows 네이티브 콜백으로 마샬링되면 보통의 함수
## 렉시컬 스코프가 아니라 호출 시점 스코프에서 실행될 수 있어, 함수 로컬 변수에
## $script: 로 쓰면 함수가 보는 변수와 콜백이 쓰는 변수가 서로 다른 스코프로 갈라지는
## 버그가 났다(처음 버전은 이 함수가 없는 top-level 스크립트였어서 우연히 맞았음) —
## 그래서 "찾은 결과"는 함수 바깥(진짜 스크립트 스코프)의 전용 변수 하나로 고정한다.
$script:QaFoundHwnd = [IntPtr]::Zero

function Find-TopWindowForPid([uint32]$targetPid) {
    $script:QaFoundHwnd = [IntPtr]::Zero
    $cb = {
        param($hWnd, $lParam)
        [uint32]$wp = 0
        [QaWin32]::GetWindowThreadProcessId($hWnd, [ref]$wp) | Out-Null
        if ($wp -eq $targetPid -and [QaWin32]::IsWindowVisible($hWnd)) {
            $script:QaFoundHwnd = $hWnd
            return $false
        }
        return $true
    }
    [QaWin32]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null
    return $script:QaFoundHwnd
}

function Force-Foreground([IntPtr]$hWnd) {
    # 단순 SetForegroundWindow/AppActivate는 이 환경에서 예외 없이 "성공"처럼 보이지만
    # 실제로는 전면이 안 바뀐다(스크립트 상단 주석 참고) — AttachThreadInput으로 현재
    # 포그라운드 스레드에 입력을 붙여야만 실제로 통한다.
    $fg = [QaWin32]::GetForegroundWindow()
    [uint32]$fgPid = 0
    $fgThread = [QaWin32]::GetWindowThreadProcessId($fg, [ref]$fgPid)
    $curThread = [QaWin32]::GetCurrentThreadId()
    [QaWin32]::AttachThreadInput($curThread, $fgThread, $true) | Out-Null
    [QaWin32]::ShowWindow($hWnd, 9) | Out-Null  # SW_RESTORE
    [QaWin32]::BringWindowToTop($hWnd) | Out-Null
    $ok = [QaWin32]::SetForegroundWindow($hWnd)
    [QaWin32]::AttachThreadInput($curThread, $fgThread, $false) | Out-Null
    return $ok
}

$env:GAME_QA_FOCUS_LOG = "1"
$env:QA_SHOW_WINDOW = "1"
if ($Scene) {
    $env:GAME_START = $Scene
    $env:GAME_QA_FRAME = "600000"
} else {
    Remove-Item Env:GAME_START -ErrorAction SilentlyContinue
    Remove-Item Env:GAME_QA_FRAME -ErrorAction SilentlyContinue
}

Write-Host "[harness] launching godot (scene='$SceneLabel') log=$LogPath"
$proc = Start-Process -FilePath $GodotBin `
    -ArgumentList @("--path", $ProjectDir, "--position", "100,100") `
    -PassThru -NoNewWindow `
    -RedirectStandardOutput $LogPath -RedirectStandardError $ErrLogPath

Start-Sleep -Milliseconds $WarmupMs

$hwnd = Find-TopWindowForPid ([uint32]$proc.Id)
if ($hwnd -eq [IntPtr]::Zero) {
    Write-Host "[harness] 경고: Godot 최상위 창을 못 찾음(pid=$($proc.Id))"
} else {
    $fgOk = Force-Foreground $hwnd
    Write-Host "[harness] Force-Foreground result=$fgOk hwnd=$hwnd"
}
Start-Sleep -Milliseconds 400

Add-Type -AssemblyName System.Windows.Forms

# 실제로 전면이 바뀌었는지 확인(거짓 성공 방지) — hwnd와 실제 GetForegroundWindow()가
# 일치하는지 로그에 남긴다.
$actualFg = [QaWin32]::GetForegroundWindow()
Write-Host "[harness] foreground check: godot_hwnd=$hwnd actual_fg_hwnd=$actualFg match=$($hwnd -eq $actualFg)"

$keyMap = @{
    "Right" = "{RIGHT}"
    "Left" = "{LEFT}"
    "Up" = "{UP}"
    "Down" = "{DOWN}"
    "Space" = " "
    "Enter" = "{ENTER}"
    "Escape" = "{ESC}"
}

if ($Keys) {
    foreach ($k in ($Keys -split ",")) {
        $k = $k.Trim()
        if (-not $k) { continue }
        $token = $keyMap[$k]
        if (-not $token) {
            Write-Host "[harness] 알 수 없는 키 토큰: $k (무시)"
            continue
        }
        if ($hwnd -ne [IntPtr]::Zero) { Force-Foreground $hwnd | Out-Null }
        Write-Host "[harness] send: $k"
        [System.Windows.Forms.SendKeys]::SendWait($token)
        Start-Sleep -Milliseconds $KeyDelayMs
    }
}

Start-Sleep -Milliseconds $ExtraWaitMs

# 강제 종료(Stop-Process -Force)는 버퍼링된 stdout을 날릴 수 있어, 먼저 창을 정상
# 종료(Alt+F4 -> Godot의 WM_CLOSE_REQUEST -> get_tree().quit())시켜 로그가 flush될
# 기회를 준 뒤에만 안전장치로 강제 종료한다.
if ($hwnd -ne [IntPtr]::Zero) { Force-Foreground $hwnd | Out-Null }
[System.Windows.Forms.SendKeys]::SendWait("%{F4}")
$exited = $proc.WaitForExit(4000)
if (-not $exited) {
    Write-Host "[harness] 정상 종료 안 됨 -> 강제 종료"
    try { Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue } catch {}
}

Write-Host "[harness] ---- log: $LogPath ----"
if (Test-Path $LogPath) {
    Get-Content $LogPath | Select-String -Pattern "\[FocusLog\]|\[VisualQA\]"
} else {
    Write-Host "[harness] 로그 파일이 생성되지 않았습니다."
}
