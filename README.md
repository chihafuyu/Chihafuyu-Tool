# 🚀 Chihafuyu Patcher

A straightforward PowerShell script to automate Android app patching utilizing the **Morphe** and **Piko** ecosystems via **Morphe CLI**. 

Whether you're patching `YouTube`, `YouTube Music`, `Reddit`, `X (Twitter)`, or `Instagram`, just sit back and let the script do the heavy lifting. It handles all the boring chores for you: environment checks, smart APK hunting, secure keystore handling, and proper memory cleanup.

> [!IMPORTANT]
> **📱 Root vs. Non-Root Devices**
>
> Just a quick heads-up: I built and tested this script exclusively for **non-rooted** Android devices. While the actual patching process on your PC will work flawlessly either way, I can't guarantee how the patched apps will behave if you try to install them via root-specific methods (like system mounting). If you're rocking a rooted phone, you might need to tweak things on your end. You've been warned! ✌️

---

## ✨ Features

- **🌐 Multi-Ecosystem Support**: Seamlessly switch between Morphe (`YouTube`, `YouTube Music`, `Reddit`) and Piko (`X/Twitter` and `Instagram`) workspaces in a single script.
- **📦 Native Bundle Support**: No need to manually merge Split APKs anymore! Natively processes standard `.apk`, `.apkm`, `.xapk`, and `.apks` files.
- **🛡️ Environment Validation**: Smartly checks for JDK 21+ and ensures your CLI (`.jar`) and Patches (`.mpp`) are ready for your chosen track (Stable or Pre-release).
- **🔍 Smart APK Discovery**: Scans your `Input` folder and uses robust regex to find the right files and extract exact versions, ignoring messy build numbers.
- **⚙️ Auto Architecture Detection**: Automatically detects if an APK is already architecture-specific (like `arm64-v8a`) and skips redundant library stripping.
- **🔐 Secure Keystore Handling**: Uses `SecureString` and unmanaged memory pointers to handle custom keystore passwords, instantly wiping them from RAM after use.
- **📝 Clean Logging**: Captures Java execution logs in the background and exports them to a clean, UTF-8 text file without cluttering your terminal.

---

## 📋 Prerequisites

Before spinning up the script, make sure you have these ready:

1. **OS**: Windows 10/11, macOS, or Linux. PowerShell 5.1+ is required for Windows (PowerShell 7+ is highly recommended). For macOS and Linux, you must install [PowerShell 7](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell).
2. **Java Development Kit (JDK) 21**: The latest Morphe CLI requires JDK 21 (a standard JRE or older JDK 17 won't cut it). Pick and install **JUST ONE** of these reliable builds:
   * [Azul Zulu JDK 21 (LTS)](https://www.azul.com/downloads/?version=java-21-lts&package=jdk)
   * **OR** [Eclipse Temurin JDK 21 (LTS)](https://adoptium.net/temurin/releases/?version=21)
   
   > **Important:** Make sure to check the **"Add to PATH"** option during installation.
3. **Patcher CLI & Patches**: You'll need the patching engine (Morphe CLI) and the patch bundles (`.mpp`) for your target ecosystem. Download the latest releases from the links below:
   * **Morphe CLI (Required for all)**: [morphe-cli releases](https://github.com/MorpheApp/morphe-cli/releases)
   * **Morphe Patches**: [morphe-patches releases](https://github.com/MorpheApp/morphe-patches/releases)
   * **Piko Patches**: [piko releases](https://github.com/crimera/piko/releases)
4. **App Files**: Have your raw, unpatched apps ready ([APKMirror](https://www.apkmirror.com/) is highly recommended). 

> [!NOTE]
> **📱 File Format Support:**
>
> While fully merged or standalone Universal `.apk` files are highly recommended for the cleanest patching process, the script also supports dropping `.apkm`, `.xapk`, or `.apks` bundles directly into the `Input` folder!

5. **MicroG-RE**: If you're patching `YouTube` and/or `YouTube Music` via `Morphe`, you'll need to install MicroG-RE on your device and then sign in to your `Google account`. Download it here: [MicroG-RE releases](https://github.com/MorpheApp/MicroG-RE/releases/latest).

---

## 🚀 How to Use

1. **Set the Stage**: Grab the script from the [Releases page](https://github.com/chihafuyu/Chihafuyu-Patcher/releases/latest) (Recommended) or download the [Main branch source code](https://github.com/chihafuyu/Chihafuyu-Patcher/archive/refs/heads/main.zip). Extract the ZIP and place `chihafuyu-patcher.ps1` into an empty working directory. Next, place your downloaded `morphe-cli.jar` right next to the script, and drop the `.mpp` patch files into their respective folders.
2. **Folder Structure**: The script uses a smart multi-workspace architecture. When you run it, it will auto-create the `Morphe` and `Piko` folders for you. Your root directory should look like this:

```text
📁 Your-Working-Directory/
 ├── 📄 chihafuyu-patcher.ps1        (The main script)
 ├── ☕ morphe-cli-x.x.x-all.jar     (CLI - Place here or inside the ecosystem folder)
 ├── 🔑 my-custom-key.keystore       (Optional - Place your custom keystore here)
 ├── 📁 Morphe/                      (Morphe Workspace)
 │    ├── 📦 patches-x.x.x.mpp       (Morphe Patches)
 │    ├── 📁 Input/                  (Drop Morphe supported apps here)
 │    └── 📁 Output/                 (Patched APKs and log land here)
 └── 📁 Piko/                        (Piko Workspace)
      ├── 📦 patches-x.x.x.mpp       (Piko Patches)
      ├── 📁 Input/                  (Drop Piko supported apps here)
      └── 📁 Output/                 (Patched APKs and log land here)
```

3. **Load your Apps**: Move the target files (`.apk`, `.apkm`, etc.) into the `Input` folder of the ecosystem you want to patch.
4. **Run the script**:
   * Double click `chihafuyu-patcher.ps1`, OR
   * Right-click `chihafuyu-patcher.ps1` and select "Run with PowerShell", OR
   * Open a PowerShell terminal in the folder and type: `.\chihafuyu-patcher.ps1`, then press `Enter`.
5. **Follow the Prompts**: The script will interactively guide you through selecting the ecosystem, environment track, target apps, architecture, and optional custom keystore.
6. **Grab your patched apps**: Once you hit that `[SUCCESS]` message, just open the `Output` folder (and save the logs if you want). Your fresh patched APK(s) are ready to be installed!

> **💡 Pro Tip:** By default, the script applies the standard set of patches. Want to customize them? Hit `Y` when asked to modify the JSON files. Open the generated file (e.g., `youtube-options-stable.json`), set the patch values to `true` or `false` as needed, save your changes, and press any key in the terminal to resume patching!

> [!WARNING]
> **🚨 UNIVERSAL PATCHES LIMITATION 🚨**
>
> Inside your generated `options.json`, you might notice patches like `Override certificate pinning`, `Change package name`, and `Disable Play Store updates`. These are **Universal Patches** designed to work on *any* app.
> 
> However, they have a major weakness: **they do NOT support every app out there**. For example, applying them to random, unsupported apps (like banking apps or heavily secured games) will likely fail or cause crashes. Use them with caution!

---

## 🛠️ Configuration (Optional)

Whenever new stable patch bundles are released with updated app version targets, just open `chihafuyu-patcher.ps1` in your favorite text editor ([Notepad++](https://notepad-plus-plus.org/downloads/) is highly recommended) and update the versions at the very top of the file:

```powershell
# ==============================================================================
# RECOMMENDED APP VERSIONS
# ==============================================================================
# Morphe
$cfg_youtube_stable       = "20.45.36"
$cfg_youtube_music_stable = "8.44.54"
$cfg_reddit_stable        = "2026.04.0"

# Piko
$cfg_x_stable             = "Any"
$cfg_ig_stable            = "423.0.0.47.66"
# ==============================================================================
```

## ⚠️ Troubleshooting

**Script closing instantly or throwing a bunch of red errors on your first try? (Windows Only)**
Don't panic. That's usually just Windows being overprotective with its default Execution Policy. Here's a quick fix:

1. Open PowerShell as Administrator.
2. Run this exact command:

	```powershell
	Set-ExecutionPolicy RemoteSigned
	```
	
3. Type `Y` and press Enter. You're good to go, run the patching script again!

## 📜 Legal & License

Distributed under the MIT License.

Copyright (c) 2026 chihafuyu

**Third-Party Code Attribution:** This tool utilizes patches and code from Morphe and Piko. To learn more, visit [Morphe](https://morphe.software) or [Piko](https://github.com/crimera/piko).