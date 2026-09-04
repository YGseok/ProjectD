# Setting/sync-from-repo.ps1
#
# 새 PC에서 이 저장소를 클론(또는 pull)한 직후 실행한다.
# 저장소의 Setting/ 폴더 내용을 이 PC의 Claude Code 경로로 복사해서,
# 이 프로젝트에 대한 Claude 메모리/전역 설정을 최신 상태로 맞춘다.
#
# .credentials.json은 건드리지 않는다 — 로그인은 각 PC에서 `claude` 실행 후
# 별도로 진행해야 한다.

$ErrorActionPreference = "Stop"
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

$repoRoot = Split-Path -Parent $PSScriptRoot
$slug = ($repoRoot -replace '[:\\/]', '-')

$claudeMemoryDir = Join-Path $HOME ".claude\projects\$slug\memory"
$srcMemoryDir    = Join-Path $PSScriptRoot "memory"

$claudeSettings  = Join-Path $HOME ".claude\settings.json"
$srcSettings     = Join-Path $PSScriptRoot "global-settings.json"

if (Test-Path $srcMemoryDir) {
    New-Item -ItemType Directory -Force -Path $claudeMemoryDir | Out-Null
    Copy-Item "$srcMemoryDir\*" $claudeMemoryDir -Recurse -Force
    Write-Output "이 PC의 Claude 메모리를 저장소 내용으로 최신화: $claudeMemoryDir"
} else {
    Write-Output "저장소에 Setting/memory가 없습니다. 건너뜁니다."
}

if (Test-Path $srcSettings) {
    $settingsDir = Split-Path -Parent $claudeSettings
    New-Item -ItemType Directory -Force -Path $settingsDir | Out-Null
    Copy-Item $srcSettings $claudeSettings -Force
    Write-Output "전역 설정을 저장소 내용으로 최신화: $claudeSettings"
}

Write-Output "완료. 이 PC에서 이 프로젝트를 열면 동일한 Claude 메모리/설정을 사용합니다."
