# mHM QGIS Workshop

This folder contains everything you need for the workshop:

- a self-contained software environment with QGIS, mHM and all Python packages,
- the mHM QGIS plugin, set up in a separate QGIS profile,
- the input data and a prepared mHM QGIS project for the exercises.

Everything is installed **inside this folder**. Your system Python and any QGIS
you already have installed are not changed.

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
2. installs the workshop environment into `.pixi/` inside the installation folder,
3. installs the mHM plugin into the workshop QGIS profile there and enables it,
4. checks that the QGIS executable is available in the environment.

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

### 3. Start QGIS

In the installation folder, run:

```
cd ~/mhm-workshop        # Windows: cd C:\mhm-workshop
pixi run qgis
```

or use the launcher. QGIS opens with the workshop profile and the mHM plugin
already enabled. Under *Help → About* you can check that QGIS runs from the
`.pixi/` folder in the installation folder.

> **Important:** always start QGIS this way. If you open QGIS from your normal
> application menu, you get your system QGIS, which does not have the plugin
> and its dependencies.

### Inspect NetCDF files with ncv

In the installation folder, run `pixi run ncv` or
`pixi run ncv path/to/file.nc`. QGIS 4 and ncv share the conda-forge PyQt6
installation. PyQt6 and netCDF4 are explicit conda dependencies so these
binary libraries are managed together with QGIS.

### Test mHM

In the installation folder, run `pixi run mhm-test` to simulate the bundled
test domain. Simulation outputs are written to `test_domain/output_b1/`.

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
├── test_domain/       input data and namelists for the mHM test run
├── project-init/      the prepared mHM QGIS project for the exercises
│   ├── input-data/    mHM input data
│   └── mhm-qgis/      the project (Test-v5)
├── qgis-profiles/     QGIS profile with the mHM plugin (created by the setup script)
└── .pixi/             the installed environment (created by the setup script)
```

`qgis-profiles/` and `.pixi/` are created in the installation folder. With a
separate installation folder, it also gets copies of `pixi.toml`, `pixi.lock`,
`tools/` and `test_domain/`, and `project-init/` stays in the workshop folder.

Each model run writes its output to `runs/<run name>/output/` in the project
folder `project-init/mhm-qgis/Test-v5/`.

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

## Data sources and licences

The bundled Mosel test domain comes from the [mHM repository](https://git.ufz.de/mhm/mhm).
Its upstream example-data notice limits use to **non-commercial research and
non-commercial education** and requires consideration of the original data
providers' licences for use and redistribution.

[test_domain/NOTICE.md](test_domain/NOTICE.md) preserves that notice, its provider
acknowledgments and the upstream revision used to verify the bundled files.
It includes references for E-OBS, the Harmonized World Soil Database, SRTM and
the European Soil Database. The original providers' terms also apply.

---

## Contact

<!-- name, e-mail, workshop date and place -->

mHM: <https://mhm-ufz.org>
