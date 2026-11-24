# mHM Workshop 2026

Welcome! This folder contains the software for our hands-on hydrological
modelling workshop: mHM, QGIS with the mHM plugin, and tools for exploring results.

## Quickstart

Please set things up **before the workshop**. The installation downloads the
software and may take a while. If you get stuck, let us know—we are happy to help.

### 1. Download the workshop folder

[Download the ZIP](https://github.com/mhm-ufz/Workshop-2026/archive/refs/heads/main.zip),
extract it, and rename the extracted folder to `mhm-workshop`.
On Windows, right-click the ZIP in **File Explorer** and choose **Extract All…**.

If you prefer Git, clone it instead:

```bash
git clone https://github.com/mhm-ufz/Workshop-2026.git mhm-workshop
```

We **strongly recommend using the paths below**: put `mhm-workshop` at the
root of your Windows drive (`C:\mhm-workshop`) or directly in your home folder
on Linux/macOS (`~/mhm-workshop`).

### 2. Run setup once

Copy and paste each command below, pressing **Enter** after each line.
The `cd` command switches to the workshop folder at the recommended location.

**Windows:** open the **Start menu**, search for **Windows PowerShell**, and
select **Open**. Microsoft has a short guide to
[starting Windows PowerShell](https://learn.microsoft.com/en-us/powershell/scripting/windows-powershell/starting-windows-powershell).

```powershell
cd C:\mhm-workshop
powershell -ExecutionPolicy Bypass -File setup.ps1
```

**Linux and macOS:** open **Terminal** and run:

```bash
cd ~/mhm-workshop
bash setup.sh
```

Wait until you see **Setup complete**. Setup installs the workshop software and
tries to install Pixi GUI, which lets you run the tools with a click.

### 3. Open Pixi GUI

**Windows:** open the **Start menu**, search for **Pixi GUI**, and launch it.
**Linux/macOS:** open **Pixi GUI** from your applications menu.
You can also type `pixi-gui` in a new PowerShell or Terminal window.
In Pixi GUI, open the workshop folder (`C:\mhm-workshop` on Windows or
`~/mhm-workshop` on Linux/macOS)—the one containing `pixi.toml`.

![Pixi GUI showing the mHM Workshop 2026 workspace and its tasks](tools/GUI.png)

Click the **play button next to `mhm`** for a first test run. When it finishes,
run **`view`** to explore the results. The default settings are ready to use.
You can return to Pixi GUI throughout the workshop to launch the tools.

## Your workshop tools

| Task | What it does |
|------|--------------|
| `mhm` | Run mHM; starts with the included test domain. |
| `ncdump` | Print a NetCDF file's header to inspect its variables and dimensions. |
| `qgis` | Open QGIS with the workshop's mHM plugin enabled. |
| `shell` | Open a terminal with the workshop tools available. |
| `update` | Update the workshop software to the latest version (see [Updating](#updating)). |
| `view` | Open a NetCDF file in the graphical viewer. |

The pencil button lets you change a task's inputs. Run `mhm` first to create
the default output used by `view` and `ncdump`. Results are saved in
`test_domain/output_b1/`. The exercise data for the workshop will be provided
separately.

Please start QGIS through this workspace's **`qgis` task**, so it uses the
workshop environment and plugin.

## Editing files

We recommend installing [Visual Studio Code](https://code.visualstudio.com/download)
for editing model configuration files and scripts. It integrates with Pixi GUI:
use **Open in Editor…** and select VS Code to open the workshop folder.

## If something doesn't work

Send us the error message and tell us which step you were running. If setup
warns that Pixi GUI could not be installed, the workshop tools can still work.
Open a new **Windows PowerShell** or **Terminal** window and switch to the
workshop folder with `cd C:\mhm-workshop` (Linux/macOS: `cd ~/mhm-workshop`).
Then run a task by name, for example:

```text
pixi run mhm
pixi run view
pixi run qgis
```

## Updating

If we ask you to update, close QGIS, the viewer and any workshop terminal.
Then click the **play button next to `update`** in Pixi GUI (or run
`pixi run update` in the workshop folder). Wait until you see
**Update complete**. If Pixi GUI does not show the new tasks afterwards,
close and reopen the workshop folder in Pixi GUI.

The update downloads the latest workshop version and replaces `pixi.toml`,
`README.md` and the `tools` folder, then updates the software and the mHM
plugin. Your `test_domain` folder, results and QGIS settings are kept.
A Git clone is updated with `git pull --ff-only` instead.

### Updating by hand

Use this if your workshop folder has no `update` task yet, or if the `update`
task fails. Close the workshop tools first. For a Git clone, run
`git pull --ff-only` in the workshop folder, then rerun the setup command above
with `--update` (Windows: `-Update`).

Otherwise, download the new ZIP.
Extract it into a separate folder. From that new folder, run the setup script
with update mode and the path to your existing workshop folder:

**Windows:**

```powershell
powershell -ExecutionPolicy Bypass -File setup.ps1 -Update -InstallDir C:\mhm-workshop
```

**Linux and macOS** (adjust the path if needed):

```bash
bash setup.sh --update --install-dir ~/mhm-workshop
```

This updates the software and plugin while keeping your test-domain files,
results and QGIS settings.

Learn more about [mHM](https://mhm-ufz.org).
The included test domain's usage terms are in [test_domain/NOTICE.md](test_domain/NOTICE.md).
