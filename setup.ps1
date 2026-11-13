<#
.SYNOPSIS
    Setup script for the mHM QGIS workshop environment (Windows).

.DESCRIPTION
    Installs pixi (if needed) and the workshop environment with QGIS into an
    installation folder, installs the mHM QGIS plugin into the workshop profile
    there and checks that the QGIS executable is available.
    Also installs Pixi GUI if possible; a failure only produces a warning.

    The environment goes to <InstallDir>\.pixi, the QGIS profile with the mHM
    plugin to <InstallDir>\qgis-profiles, and the pixi tool to
    %USERPROFILE%\.pixi. The system Python and any system QGIS are not touched.

    Run it from a PowerShell or Command Prompt window in this folder:
        powershell -ExecutionPolicy Bypass -File setup.ps1 [-InstallDir <folder>] [options]

    Start QGIS later with:
        cd <InstallDir>
        pixi run qgis

.PARAMETER InstallDir
    Folder to install into (default: current directory, "."). Its path must not contain "Nextcloud",
    and it must be new, empty or a previous installation. It may be this
    folder. Otherwise pixi.toml, the lock file, tools\ and test_domain\ are
    copied there and this folder is left unchanged.

.PARAMETER Launcher
    Additionally create a launcher: an entry "QGIS mHM Workshop" in the
    Start menu. -Desktop does the same.

.PARAMETER Update
    Refresh an existing installation from this checkout, keeping its
    test_domain\ and QGIS profile settings. Update the checkout first.

.PARAMETER Start
    Start QGIS after setup.

.PARAMETER Help
    Show this help.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File setup.ps1 -InstallDir C:\mhm-workshop

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File setup.ps1 -InstallDir C:\mhm-workshop -Launcher -Start

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File setup.ps1 -Update
#>
[CmdletBinding(PositionalBinding = $false)]
param(
    [string]$InstallDir = '.',
    [switch]$Update,
    [Alias('Desktop')]
    [switch]$Launcher,
    [switch]$Start,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$ProgressPreference = 'SilentlyContinue'   # the progress bar makes Expand-Archive very slow

$ProjectDir = $PSScriptRoot
# Lock file with the package versions to install. pixi only reads pixi.lock,
# so the setup copies this file there. Change it to switch to another one.
$LockFile = 'pixi.lock'

function Info($Message) { Write-Host '==> ' -ForegroundColor Cyan -NoNewline; Write-Host $Message }
function Warn($Message) { Write-Host 'Warning: ' -ForegroundColor Yellow -NoNewline; Write-Host $Message }
function Fail($Message) { Write-Host 'Error: ' -ForegroundColor Red -NoNewline; Write-Host $Message; exit 1 }

if ($Help) { Get-Help $PSCommandPath -Detailed; exit 0 }

# --- installation folder ------------------------------------------------------
if (-not $InstallDir) {
    Fail 'Please choose an installation folder, e.g.:  powershell -ExecutionPolicy Bypass -File setup.ps1 -InstallDir C:\mhm-workshop'
}
# A relative path is taken from the folder the script is called from
$InstallDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($InstallDir)
$InstallDir = [IO.Path]::GetFullPath((Join-Path $InstallDir '.'))   # without a trailing \
if ($InstallDir -match 'nextcloud') {
    Fail "The installation folder must not be inside Nextcloud (got: $InstallDir). Choose a local folder, e.g. C:\mhm-workshop"
}
if (Test-Path -LiteralPath $InstallDir -PathType Leaf) { Fail "$InstallDir is a file, not a folder" }
$Previous = $false
if (Test-Path -LiteralPath $InstallDir) {
    # never write into a folder with other content, unless it is a previous installation
    $Manifest = Join-Path $InstallDir 'pixi.toml'
    $Previous = (Test-Path -LiteralPath $Manifest) -and
                (Select-String -LiteralPath $Manifest -SimpleMatch 'name = "mhm-workshop"' -Quiet)
    if (-not $Previous -and @(Get-ChildItem -LiteralPath $InstallDir -Force).Count -gt 0) {
        Fail "$InstallDir is not empty and holds no previous workshop installation. Choose a new or empty folder."
    }
}
if ($Update -and -not $Previous) {
    Fail "No workshop installation found in $InstallDir. Run setup without -Update first, or choose the existing installation with -InstallDir."
}

# Work in this folder, and return to the caller's folder when done
Push-Location -LiteralPath $ProjectDir
try {
    if (-not (Test-Path -LiteralPath pixi.toml)) { Fail "pixi.toml not found in $ProjectDir" }

    # --- 0. detect platform ---------------------------------------------------
    # A 32-bit PowerShell on 64-bit Windows reports x86, the real one is in PROCESSOR_ARCHITEW6432
    $Arch = if ($env:PROCESSOR_ARCHITEW6432) { $env:PROCESSOR_ARCHITEW6432 } else { $env:PROCESSOR_ARCHITECTURE }
    if ($Arch -ne 'AMD64') { Fail "Unsupported system: Windows/$Arch" }
    $Platform = 'win-64'
    Info "Platform: $Platform"

    if (-not (Select-String -LiteralPath pixi.toml -SimpleMatch "`"$Platform`"" -Quiet)) {
        Fail "Platform $Platform is not listed under 'platforms' in pixi.toml. Please contact the workshop team."
    }

    # Some files in the environment have long paths, which Windows only allows
    # with long path support enabled
    try {
        $LongPaths = Get-ItemPropertyValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name LongPathsEnabled
    } catch {
        $LongPaths = 0
    }
    if ($LongPaths -ne 1) {
        Warn ("Long path support is disabled in Windows, so the installation may fail with 'path too long' errors. " +
              "Keep the installation folder close to the drive root (e.g. C:\mhm-workshop), or enable long paths once in a " +
              "PowerShell run as administrator:`n    New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' " +
              "-Name LongPathsEnabled -Value 1 -PropertyType DWORD -Force")
    }

    # --- 1. pixi --------------------------------------------------------------
    $PixiInstalled = $false
    if (-not (Get-Command pixi -ErrorAction SilentlyContinue)) {
        $PixiHome = if ($env:PIXI_HOME) { $env:PIXI_HOME } else { Join-Path $env:USERPROFILE '.pixi' }
        $PixiBinDir = Join-Path $PixiHome 'bin'
        if (-not (Test-Path -LiteralPath (Join-Path $PixiBinDir 'pixi.exe'))) {
            Info "Installing pixi into $PixiHome ..."
            # in a separate PowerShell, so the installer cannot change this script's state
            & powershell.exe -NoProfile -ExecutionPolicy Bypass -Command 'irm -useb https://pixi.sh/install.ps1 | iex'
            if ($LASTEXITCODE -ne 0) { Fail 'Could not install pixi. Please check your internet connection.' }
            $PixiInstalled = $true
        }
        $env:PATH = "$PixiBinDir;$env:PATH"
    }
    Info "Using $(& pixi --version)"

    # --- optional Pixi GUI (failure must not stop workshop setup) -------------
    Info 'Installing Pixi GUI ...'
    try {
        & pixi global install pixi-gui --channel https://prefix.dev/pixi-gui --channel https://prefix.dev/conda-forge
        if ($LASTEXITCODE -eq 0) {
            Info 'Pixi GUI installed. Start it with: pixi-gui'
        } else {
            Warn 'Pixi GUI could not be installed. Check the errors above. Continuing with workshop setup; use pixi run qgis to start QGIS.'
        }
    } catch {
        Warn "Pixi GUI could not be installed: $($_.Exception.Message). Continuing with workshop setup; use pixi run qgis to start QGIS."
    }

    # --- 2. environment -------------------------------------------------------
    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
    if ($InstallDir -ne $ProjectDir) {
        Info "Copying the environment files to $InstallDir ..."
        Copy-Item -LiteralPath pixi.toml -Destination $InstallDir -Force
        foreach ($Folder in @('tools', 'test_domain')) {
            if ($Update -and $Folder -eq 'test_domain' -and
                (Test-Path -LiteralPath (Join-Path $InstallDir 'test_domain') -PathType Container)) {
                continue
            }
            if (Test-Path -LiteralPath $Folder -PathType Container) {
                $Destination = Join-Path $InstallDir $Folder
                New-Item -ItemType Directory -Force -Path $Destination | Out-Null
                Get-ChildItem -LiteralPath $Folder -Force | Copy-Item -Destination $Destination -Recurse -Force
            }
        }
    }
    $LockSource = Join-Path $ProjectDir $LockFile
    $PluginZip = Join-Path $InstallDir 'tools\mhm_qgis.zip'
    # From here on, everything happens in the installation folder
    Set-Location -LiteralPath $InstallDir

    if ($Update) {
        Info "Updating the workshop environment in $InstallDir\.pixi ..."
    } else {
        Info "Installing the workshop environment into $InstallDir\.pixi (this can take a few minutes) ..."
    }
    if (Test-Path -LiteralPath $LockSource) {
        Info "Using the package versions from $LockFile"
        $LockTarget = Join-Path $InstallDir 'pixi.lock'
        if ($LockSource -ne $LockTarget) { Copy-Item -LiteralPath $LockSource -Destination $LockTarget -Force }
    } else {
        Warn "$LockFile not found, resolving the newest versions"
    }
    if ((Test-Path -LiteralPath $LockSource) -and -not $Update) {
        & pixi install --locked     # exactly the supplied versions
    } else {
        # Update mode allows a stale lock file to be refreshed for the new manifest.
        & pixi install
    }
    if ($LASTEXITCODE -ne 0) { Fail 'Installing the environment failed. Please send the output above to the workshop team.' }

    # --- 3. mHM QGIS plugin ---------------------------------------------------
    $ProfileDir = 'qgis-profiles\profiles\workshop'
    $PluginsDir = "$ProfileDir\python\plugins"
    if (Test-Path -LiteralPath $PluginZip) {
        Info "Installing the mHM plugin into $InstallDir\$PluginsDir ..."
        New-Item -ItemType Directory -Force -Path $PluginsDir | Out-Null
        if (Test-Path -LiteralPath "$PluginsDir\mhm_qgis") {
            Remove-Item -LiteralPath "$PluginsDir\mhm_qgis" -Recurse -Force   # replace any older version
        }
        Expand-Archive -LiteralPath $PluginZip -DestinationPath $PluginsDir -Force
        if (-not (Test-Path -LiteralPath "$PluginsDir\mhm_qgis\metadata.txt")) {
            Fail "Plugin not found after unpacking $PluginZip"
        }

        # enable the plugin in the workshop profile
        $Ini = Join-Path $InstallDir "$ProfileDir\QGIS\QGIS4.ini"
        New-Item -ItemType Directory -Force -Path (Split-Path $Ini) | Out-Null
        $Lines = @()
        if (Test-Path -LiteralPath $Ini) { $Lines = [IO.File]::ReadAllLines($Ini) }
        if ($Lines -cmatch '^mhm_qgis=') {
            $Lines = $Lines -creplace '^mhm_qgis=.*', 'mhm_qgis=true'
        } elseif ($Lines -ccontains '[PythonPlugins]') {
            $Lines = $Lines | ForEach-Object { $_; if ($_ -ceq '[PythonPlugins]') { 'mhm_qgis=true' } }
        } else {
            $Lines += '', '[PythonPlugins]', 'mhm_qgis=true'
        }
        [IO.File]::WriteAllLines($Ini, [string[]]$Lines)   # UTF-8 without BOM
    } else {
        Warn "$PluginZip not found, skipping plugin installation"
    }

    # --- 4. clean stale bytecode in the QGIS profile --------------------------
    if (Test-Path -LiteralPath qgis-profiles) {
        # list all first, so the search does not walk into folders already removed
        @(Get-ChildItem -LiteralPath qgis-profiles -Directory -Recurse -Force -Filter __pycache__) |
            Remove-Item -Recurse -Force
    }

    # --- 5. checks ------------------------------------------------------------
    $QgisBin = & pixi run where.exe qgis | Where-Object { $_ -match '^[A-Za-z]:\\' } | Select-Object -First 1
    $EnvDir = (Join-Path $InstallDir '.pixi') + '\'
    if ($QgisBin -and $QgisBin.StartsWith($EnvDir, [StringComparison]::OrdinalIgnoreCase)) {
        Info "QGIS found in environment: $QgisBin"
    } else {
        Fail "QGIS from the environment not found (got: '$(if ($QgisBin) { $QgisBin } else { 'nothing' })')"
    }

    # --- 6. optional launcher -------------------------------------------------
    if ($Launcher) {
        $PixiBin = (Get-Command pixi).Source
        $AppName = 'QGIS mHM Workshop'
        $LinkPath = Join-Path ([Environment]::GetFolderPath('Programs')) "$AppName.lnk"
        # A Start menu shortcut that runs "pixi run qgis" in the installation folder.
        # Its console window starts minimized and closes together with QGIS.
        $Link = (New-Object -ComObject WScript.Shell).CreateShortcut($LinkPath)
        $Link.TargetPath = $PixiBin
        $Link.Arguments = 'run qgis'
        $Link.WorkingDirectory = $InstallDir
        $Link.WindowStyle = 7   # minimized
        $Link.Description = 'QGIS with the mHM plugin from the workshop environment'
        if ($QgisBin -like '*.exe') { $Link.IconLocation = "$QgisBin,0" }
        $Link.Save()
        Info "Launcher created: '$AppName' in the Start menu"
    }

    if ($Update) {
        Info "Update complete. Start QGIS with:  cd `"$InstallDir`"; pixi run qgis"
    } else {
        Info "Setup complete. Start QGIS with:  cd `"$InstallDir`"; pixi run qgis"
    }
    if ($PixiInstalled) { Warn "pixi was just installed. Open a new terminal window before running 'pixi' yourself." }

    if ($Start) {
        & pixi run qgis
        exit $LASTEXITCODE
    }
} finally {
    Pop-Location
}
