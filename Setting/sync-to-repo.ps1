# Setting/sync-to-repo.ps1
#
# 이 PC에 실제로 쌓인 Claude Code 메모리/전역 설정을 이 저장소의 Setting/ 폴더로
# 복사한다. GitHub에 올리기 직전에 실행해서 커밋에 최신 상태가 담기게 한다.
#
# 절대 .credentials.json(로그인 인증 정보)은 다루지 않는다 — 그 파일은 항상
# 각 PC의 로컬 로그인 상태로 남아야 하며 저장소에 들어가서는 안 된다.

$ErrorActionPreference = "Stop"
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

$repoRoot = Split-Path -Parent $PSScriptRoot
$slug = ($repoRoot -replace '[:\\/]', '-')

$claudeMemoryDir = Join-Path $HOME ".claude\projects\$slug\memory"
$destMemoryDir   = Join-Path $PSScriptRoot "memory"

$claudeSettings  = Join-Path $HOME ".claude\settings.json"
$destSettings    = Join-Path $PSScriptRoot "global-settings.json"

if (Test-Path $claudeMemoryDir) {
    New-Item -ItemType Directory -Force -Path $destMemoryDir | Out-Null
    Get-ChildItem $destMemoryDir -File -ErrorAction SilentlyContinue | Remove-Item -Force
    Copy-Item "$claudeMemoryDir\*" $destMemoryDir -Recurse -Force
    Write-Output "메모리 동기화: $claudeMemoryDir -> $destMemoryDir"
} else {
    Write-Output "이 PC에는 이 프로젝트($repoRoot)의 Claude 메모리가 아직 없습니다: $claudeMemoryDir"
}

if (Test-Path $claudeSettings) {
    Copy-Item $claudeSettings $destSettings -Force
    Write-Output "전역 설정 동기화: $claudeSettings -> $destSettings"
}

Write-Output "완료. 이제 Setting/ 변경분을 커밋하면 됩니다."
