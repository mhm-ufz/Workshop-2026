<#
.SYNOPSIS
    Update this workshop folder to the latest version on GitHub (Windows).

.DESCRIPTION
    Run it with:  pixi run update

    Downloads the main branch ZIP and runs its setup.ps1 -Update on this folder,
    which keeps test_domain\ and the QGIS profile settings. A Git clone is
    updated with git pull --ff-only instead.
#>
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'   # the progress bar makes downloads very slow

$Url = if ($env:WORKSHOP_ZIP_URL) { $env:WORKSHOP_ZIP_URL } else { 'https://github.com/mhm-ufz/Workshop-2026/archive/refs/heads/main.zip' }
$Root = Split-Path -Parent $PSScriptRoot

function Info($Message) { Write-Host '==> ' -ForegroundColor Cyan -NoNewline; Write-Host $Message }
function Fail($Message) { Write-Host 'Error: ' -ForegroundColor Red -NoNewline; Write-Host $Message; exit 1 }

# Windows cannot replace files of running programs, so stop before changing anything.
$EnvDir = Join-Path $Root '.pixi\'
$Running = @(Get-Process | Where-Object { $_.Path -and $_.Path.StartsWith($EnvDir, [StringComparison]::OrdinalIgnoreCase) })
if ($Running.Count -gt 0) {
    Fail "Please close these workshop programs first, then run update again: $(@($Running.ProcessName | Sort-Object -Unique) -join ', ')"
}

if (Test-Path -LiteralPath (Join-Path $Root '.git')) {
    Info 'Git clone found, pulling the latest changes ...'
    & git -C $Root pull --ff-only
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Root 'setup.ps1') -Update -InstallDir $Root
    exit $LASTEXITCODE
}

# Windows PowerShell 5.1 may not offer TLS 1.2 by default, which GitHub requires
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$Tmp = Join-Path ([IO.Path]::GetTempPath()) "mhm-workshop-update-$([Guid]::NewGuid().ToString('N'))"
$Code = 1
try {
    New-Item -ItemType Directory -Path $Tmp | Out-Null
    $Zip = Join-Path $Tmp 'workshop.zip'
    Info "Downloading $Url ..."
    try {
        Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $Zip
    } catch {
        Fail "Download failed: $($_.Exception.Message). Please check your internet connection."
    }
    Expand-Archive -LiteralPath $Zip -DestinationPath (Join-Path $Tmp 'src')

    $Top = Get-ChildItem -LiteralPath (Join-Path $Tmp 'src') -Directory | Select-Object -First 1   # the ZIP holds a single top folder
    if (-not $Top -or -not (Test-Path -LiteralPath (Join-Path $Top.FullName 'setup.ps1')) -or
        -not (Test-Path -LiteralPath (Join-Path $Top.FullName 'pixi.toml'))) {
        Fail 'The downloaded ZIP has no workshop files. Please contact the workshop team.'
    }
    $Src = $Top.FullName

    # A separate PowerShell, since setup.ps1 ends with exit
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Src 'setup.ps1') -Update -InstallDir $Root
    $Code = $LASTEXITCODE
} finally {
    Remove-Item -LiteralPath $Tmp -Recurse -Force -ErrorAction SilentlyContinue
}
exit $Code
