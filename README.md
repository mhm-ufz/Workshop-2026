# mHM QGIS Workshop

This repository sets up the software for the workshop:

- a self-contained software environment with QGIS, mHM and all Python packages,
- the mHM QGIS plugin, set up in a separate QGIS profile,
- a small test domain for a first mHM run and viewing its output.

The workshop exercise data and projects will be distributed separately.
The environment and QGIS profile are installed **inside the installation folder**.
Your system Python and any QGIS you already have installed are not changed.

> **Please complete the installation before the workshop** and let us know if
> anything goes wrong. Installation downloads several GB and can take a while
> on conference Wi-Fi.

---

## Requirements

- **Ubuntu** (22.04 or newer, other Linux distributions usually work as well), **macOS** (Apple Silicon or Intel) or **Windows** 10/11 (64-bit, Intel or AMD)
- About **10 GB of free disk space**
- An internet connection during installation
- A terminal (on Windows: PowerShell)

Windows on ARM (e.g. laptops with a Snapdragon processor) is not supported. If
you only have such a machine, please contact us in advance.

---

## Installation

### 1. Put the folder in a suitable place

Unpack or clone `mhm-workshop` to a location that

- has **no spaces** in its path (e.g. `~/mhm-workshop` or `C:\mhm-workshop`, not `~/My Files/mhm-workshop`),
- is **not synchronised** by a cloud client (Nextcloud, Dropbox, iCloud, OneDrive, …),
- is on a **local disk**, not a network drive.

On Windows, `C:\mhm-workshop` is a good choice: the path is short, and Desktop
and Documents are often synchronised by OneDrive.

### 2. Run the setup script

**Ubuntu and macOS:** open a terminal in the folder and run:

```bash
cd ~/mhm-workshop
bash setup.sh
```

**Windows:** open *Windows PowerShell* from the Start menu and run:

```powershell
cd C:\mhm-workshop
powershell -ExecutionPolicy Bypass -File setup.ps1
```

`-ExecutionPolicy Bypass` allows this one script to run. It does not change
your system settings.

The installation folder defaults to `.` (the current working directory).
It is where the environment is installed and where you start QGIS from.
Installing into the workshop folder itself, as above, is simplest. You can
also choose a separate new folder with `--install-dir ~/mhm-workshop-env`
(Windows: `-InstallDir C:\mhm-workshop-env`): the script then copies the few files it
needs there and leaves the workshop folder unchanged. The installation folder
must be new, empty or a previous installation, and its path must not contain
"Nextcloud".

The script

1. installs [pixi](https://pixi.sh) (a package manager) into `~/.pixi` (Windows: `%USERPROFILE%\.pixi`), if it is not installed yet,
2. tries to install [Pixi GUI](https://github.com/prefix-dev/pixi-gui) globally through pixi,
3. installs the workshop environment into `.pixi/` inside the installation folder,
4. installs the mHM plugin into the workshop QGIS profile there and enables it,
5. checks that the QGIS executable is available in the environment.

If Pixi GUI cannot be installed, setup warns and continues. This can happen on
older Linux systems with an incompatible glibc. You can still use all workshop
tasks from the terminal.

At the end you should see `Setup complete`.

Optional: create a launcher so you can start QGIS without a terminal:

```
# Ubuntu, macOS
bash setup.sh --launcher
# Windows
powershell -ExecutionPolicy Bypass -File setup.ps1 -Launcher
```

- **Ubuntu:** an entry *QGIS mHM Workshop* appears in the application menu.
- **macOS:** an app *QGIS mHM Workshop* appears in `~/Applications`.
- **Windows:** an entry *QGIS mHM Workshop* appears in the Start menu. Next to QGIS it opens a minimised console window; leave it open, it closes together with QGIS.

### 3. Open Pixi GUI

Start [Pixi GUI](https://github.com/prefix-dev/pixi-gui) from your operating
system's application menu or run `pixi-gui` in a terminal. Open the
**installation folder** as a workspace. Its tasks are:

| Task | Purpose |
|------|---------|
| `qgis` | Open QGIS with the workshop profile and mHM plugin. |
| `test-mhm` | Run the bundled test domain, or pass another domain directory. |
| `view` | Open the test domain's mRM output in ncv, or pass another NetCDF file. |

Run `test-mhm` before `view` to generate the default output file.
If Pixi GUI is unavailable, use the terminal commands below.

### 4. Start QGIS from the terminal

In the installation folder, run:

```
cd ~/mhm-workshop        # Windows: cd C:\mhm-workshop
pixi run qgis
```

or use the launcher. QGIS opens with the workshop profile and the mHM plugin
already enabled. Under *Help → About* you can check that QGIS runs from the
`.pixi/` folder in the installation folder.

> **Important:** use the workspace's `qgis` task in Pixi GUI, `pixi run qgis`,
> or the *QGIS mHM Workshop* launcher. A separate system QGIS installation
> does not use the workshop profile and environment.

### Inspect NetCDF files with ncv

In the installation folder, run `pixi run view` to open the test domain's
mRM output (`test_domain/output_b1/mRM_Fluxes_States.nc`) after running
`pixi run test-mhm`. To open another file, run `pixi run view path/to/file.nc`
(quote paths containing spaces). The task calls `python -m ncv` with that file.

Run `pixi run ncv` to open the viewer without a file.
QGIS 4 and ncv share the conda-forge PyQt6
installation. PyQt6 and netCDF4 are explicit conda dependencies so these
binary libraries are managed together with QGIS.

### Test mHM

In the installation folder, run `pixi run test-mhm` to simulate the bundled
test domain. Simulation outputs are written to `test_domain/output_b1/`.
To run a different domain, use `pixi run test-mhm path/to/domain`
(quote paths containing spaces). The task passes this directory to `python -m mhm`.
The bundled test domain's usage terms and attribution are in
[test_domain/NOTICE.md](test_domain/NOTICE.md).

---

## Updating an installation

Close QGIS and any running workshop tasks. Get the updated repository first:
for a Git clone, run `git pull --ff-only` in the repository folder; otherwise
download and extract the new archive.

From the updated repository folder, run the setup script in update mode:

**Ubuntu and macOS:**

```bash
bash setup.sh --update
```

**Windows:**

```powershell
powershell -ExecutionPolicy Bypass -File setup.ps1 -Update
```

These commands use the current directory as the installation folder. If you
installed elsewhere, or extracted the updated archive into a new folder,
point the updated script at the existing installation:

```bash
bash setup.sh --update --install-dir ~/mhm-workshop-env
```

```powershell
powershell -ExecutionPolicy Bypass -File setup.ps1 -Update -InstallDir C:\mhm-workshop-env
```

Update mode refreshes the environment files, synchronizes installed packages
with the current manifest and refreshes the lock file if needed. It reinstalls
the bundled mHM plugin while keeping the QGIS profile settings and existing
`test_domain/` files, including local namelist changes and simulation outputs.
Workshop exercise data and projects distributed separately are left in place.
Pixi GUI installation is retried; a failure still only produces a warning.

When you see `Update complete`, reopen the workspace in Pixi GUI or run
`pixi run qgis` in the installation folder.

---

## Folder structure

```
mhm-workshop/
├── README.md          this file
├── setup.sh           installation script (Ubuntu, macOS)
├── setup.ps1          installation script (Windows)
├── pixi.toml          environment definition
├── pixi.lock          exact package versions
├── tools/             bundled packages and the QGIS start helper for Windows
│   ├── mhm_qgis.zip   the mHM QGIS plugin, installed by the setup script
│   ├── mhm_tools-0.3.2-py3-none-any.whl  mhm-tools (not yet on PyPI)
│   └── start_qgis.py  QGIS start helper for Windows
├── test_domain/       bundled domain for a first test run, including NOTICE.md
├── qgis-profiles/     QGIS profile with the mHM plugin (created by the setup script)
└── .pixi/             the installed environment (created by the setup script)
```

`qgis-profiles/` and `.pixi/` are created in the installation folder. With a
separate installation folder, it also gets copies of `pixi.toml`, `pixi.lock`,
`tools/` and `test_domain/`. Update mode keeps an existing `test_domain/`.
The test run writes its results to `test_domain/output_b1/`.

---

## Troubleshooting

`pixi: command not found` **after installation**
(Windows: *The term 'pixi' is not recognized*)
Open a new terminal window. Or run `export PATH="$HOME/.pixi/bin:$PATH"`, on
Windows `$env:PATH = "$env:USERPROFILE\.pixi\bin;$env:PATH"`.

**Windows: "running scripts is disabled on this system"**
Start the script with `powershell -ExecutionPolicy Bypass -File setup.ps1 -InstallDir C:\mhm-workshop`,
as shown above, not with `.\setup.ps1`.

**Windows: "path too long" errors, or a warning about long path support**
Move the folder to a short path such as `C:\mhm-workshop` and run the setup
again. If that does not help, enable long paths once in a PowerShell window
opened with *Run as administrator*, restart Windows and run the setup again:

```powershell
New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name LongPathsEnabled -Value 1 -PropertyType DWORD -Force
```

**The plugin asks to install Python packages with** `pip --user`
Click **Cancel**. All packages are already part of the environment, so this
usually means QGIS was not started with `pixi run qgis`. If it happens
anyway, please contact us.

**Error** `_ARRAY_API not found` **or** `numpy.core.multiarray failed to import`
You are most likely running your system QGIS instead of the workshop QGIS.
Close all QGIS windows and start it again with `pixi run qgis`.

**Messages about** `libpdal_plugin_reader_tiledb.so` **in the terminal**
Harmless. They concern a point cloud format that is not used in the workshop.

**Ubuntu: "Wayland session detected" warning in QGIS**
The environment already starts QGIS in compatibility mode (XWayland). If the
warning still appears, please let us know.

**macOS: the launcher cannot be opened ("unidentified developer")**
Right-click the app in `~/Applications`, choose *Open* and confirm once.

**macOS on Apple Silicon: setup reports Rosetta**
Your terminal runs in Intel emulation. The script handles this, but if
problems occur, open the terminal without *Open using Rosetta* (Finder → Get Info).

---

## Uninstalling

Delete the `mhm-workshop` folder, and the installation folder if you chose a
separate one. To also remove pixi itself:

```
rm -rf ~/.pixi                                         # Ubuntu, macOS
Remove-Item -Recurse -Force "$env:USERPROFILE\.pixi"   # Windows PowerShell
```

On Windows, also remove `%USERPROFILE%\.pixi\bin` from your `PATH`: search the
Start menu for *Edit environment variables for your account*.

pixi keeps the downloaded packages in a cache of several GB, which you can
delete as well: `~/.cache/rattler` (Ubuntu), `~/Library/Caches/rattler`
(macOS) or `%LOCALAPPDATA%\rattler` (Windows).

If you used the launcher, also delete
`~/.local/share/applications/mhm-workshop-qgis.desktop` (Ubuntu),
`~/Applications/QGIS mHM Workshop.app` (macOS) or
`%APPDATA%\Microsoft\Windows\Start Menu\Programs\QGIS mHM Workshop.lnk` (Windows).

---

## Installation checks

GitHub Actions checks fresh installations and updates on Linux, Windows, and
macOS (Apple Silicon and Intel) for pushes and pull requests. You can also
start the **Installation** workflow manually from the repository's Actions tab.

The checks run the setup scripts, simulate the bundled mHM test domain, read
its NetCDF output, and launch QGIS with the enabled mHM plugin. They also check
that ncv's GUI code imports alongside QGIS and that updates preserve local
test-domain files and QGIS settings. Linux uses an Xvfb virtual display;
Windows and macOS use their native Qt backends. Pixi GUI installation remains
optional, as it is for participants.

---

## Contact

<!-- name, e-mail, workshop date and place -->

mHM: <https://mhm-ufz.org>
