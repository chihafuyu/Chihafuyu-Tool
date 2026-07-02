# 🚀 Chihafuyu Tool

A comprehensive, menu-driven PowerShell script to automate Android app patching and manage ADB installations utilizing the **Morphe**, **Piko**, **hoo-dles**, **De-ReVanced**, **BholeyKaBhakt**, and **browzomje** ecosystems via the **Morphe CLI**.

Whether you're patching `YouTube`, `Reddit`, `X (Twitter)`, `Instagram`, `AdGuard`, `IbisPaint X`, `Sleep as Android`, `Pinterest`, or simply managing your device via ADB, just sit back and let the script do the heavy lifting. It handles all the boring chores for you: environment checks, smart APK hunting, secure keystore handling, smart JVM heap allocation, JSON result generation, and proper memory cleanup.

> [!IMPORTANT]
> **📱 Root vs. Non-Root Devices**
>
> Just a quick heads-up: I built and tested the core patching process for **non-rooted** Android devices. While the actual patching on your PC will work flawlessly either way, installing the patched apps via root-specific methods (like system mounting) requires root privileges on your phone. Luckily, this tool's Utility menu explicitly supports both Root (`--mount`) and Non-Root (`--apk`) workflows!

---

## ✨ Features

- **🌐 Multi-Ecosystem Support**: Seamlessly switch between Morphe (`YouTube`, `YouTube Music`, `Reddit`), Piko (`X/Twitter`, `Instagram`), hoo-dles (`AdGuard`, `IbisPaint X`, `WPS Office`, `CamScanner`, `Sleep as Android`, `Duolingo`, `Windy`, `Xodo`, etc.), De-ReVanced (`Google Photos`, `RAR`), BholeyKaBhakt (`Speedtest`, `Stellarium`, `PROTO`, `vpnify`, `Backdrops`, `Solid Explorer`), and browzomje (`Pinterest`) workspaces in a single script. Select multiple ecosystems at once (e.g., `1,2,6`) to queue up batch patching across different platforms in a single run.
- **🛠️ Integrated Utility Menu**: Acts as a frontend for Morphe CLI's utility features. Install/Uninstall apps via ADB directly from the script (supports standard and root-mount modes), or quickly generate `options.json`/`list-patches.txt` files without running the entire patching loop.
- **📦 Native Bundle Support**: No need to manually merge Split APKs anymore! Natively processes standard `.apk`, `.apkm`, `.xapk`, and `.apks` files.
- **🛡️ Environment Validation**: Smartly checks for JDK 25+ and ensures your CLI (`.jar`) and Patches (`.mpp`) are ready for your chosen track (Stable or Pre-release).
- **🔄 Smart Multi-Patch Processing**: Need to apply third-party shim patches alongside your main patch bundle? No problem! The script automatically detects secondary patches (e.g., `*shim*.mpp`) and dynamically chains them into the patching sequence.
- **🔍 Smart APK Discovery & Multi-Version Support**: Scans your `Input` folder, extracts exact versions ignoring messy build numbers or weird version formats (like `x-y-z`), and validates them against an array of supported versions.
- **🧠 JSON Logic Constraints**: Safely inspects your customized `options.json` before patching to prevent fatal crashes (e.g., blocking the execution if the specific "Disunify xchat system" or "Block redirecting to X Lite" patch is forced on an incompatible Twitter APK).
- **⚙️ Auto Architecture & Memory Management**: Automatically detects if an APK is already architecture-specific and skips redundant library stripping. Dynamically scales JVM heap size (`-Xmx`) based on your system's physical RAM to prevent `OutOfMemory` crashes.
- **🔐 Memory-Safe Keystore Handling**: Uses `SecureString` and unmanaged memory pointers to aggressively prevent password leaks within the script's internal memory space.
- **📊 Stealth JSON Results**: Automatically captures the patching result output and offers to export it as a clean JSON file at the end of the session.
- **🔙 Global Abort / Back Navigation**: Made a mistake? Just type `B` at any prompt to safely cancel the operation and return to the main menu without breaking the script.

> [!WARNING]
> **🚨 Keystore Password Exposure Notice**
> 
> While this script uses advanced memory-handling to protect your passwords internally, the upstream `morphe-cli` Java engine currently requires passwords to be passed via standard command-line arguments (e.g., `--keystore-password`). 
> 
> This means your plaintext password **may be momentarily visible to system monitoring tools** (like Windows Task Manager or Process Explorer) while the patching process is actively running in the background. 
> 
> **Recommendation:** Never use high-value personal passwords (like your bank or primary email password) for your Android keystores, especially if you are running this tool on a shared or enterprise machine!

---

## 📋 Prerequisites

Before spinning up the tool, make sure you have these ready:

1. **OS**: Windows 10/11. PowerShell 5.1+ is required (PowerShell 7+ is highly recommended). Download [here](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell).
2. **Java Development Kit (JDK) 25**: The latest Morphe CLI utilizes FFM APIs to natively resolve file locking issues on Windows, which strictly requires JDK 25 or higher (a standard JRE or older JDK 21 won't cut it). Pick and install **JUST ONE** of these reliable builds:
   * [Azul Zulu JDK 25 (LTS)](https://www.azul.com/downloads/?version=java-25-lts&package=jdk)
   * **OR** [Eclipse Temurin JDK 25 (LTS)](https://adoptium.net/temurin/releases/?version=25)
   
   > **Important:** Make sure to check the **"Add to PATH"** option during installation.
3. **Android SDK Platform-Tools (For Utility Menu)**: If you want to use the script's install/uninstall features, you must have `adb` installed. Download [SDK Platform-Tools](https://developer.android.com/studio/releases/platform-tools) and add it to your system PATH.
4. **Android SDK (For Verification)**: If you intend to use the `--verify-with-sdk` feature during patching, you must have an Android SDK (specifically `build-tools` and `platforms`) installed on your machine and properly configured. Otherwise, the script will throw a fatal error.
5. **Patcher CLI & Patches**: You'll need the patching engine (Morphe CLI) and the patch bundles (`.mpp`) for your target ecosystem. Download the latest releases from the links below:
   * **Morphe CLI (Required for all)**: [morphe-cli releases](https://github.com/MorpheApp/morphe-cli/releases)
   * **Morphe Patches**: [morphe-patches releases](https://github.com/MorpheApp/morphe-patches/releases)
   * **Piko Patches**: [piko releases](https://github.com/crimera/piko/releases)
   * **hoo-dles Patches**: [hoo-dles releases](https://github.com/hoo-dles/morphe-patches/releases)
   * **De-ReVanced Patches**: [De-ReVanced releases](https://github.com/RookieEnough/De-ReVanced/releases)
   * **BholeyKaBhakt Patches**: [android-patches-xtra releases](https://github.com/BholeyKaBhakt/android-patches-xtra/releases)
   * **browzomje Patches**: [browzomje releases](https://github.com/browzomje/browzomje-patches/releases)
6. **App Files**: Have your raw, unpatched apps ready ([APKMirror](https://www.apkmirror.com/) is highly recommended for most apps). 
   * **For certain X (Twitter) versions**, standard APKs might crash due to 'pairiplib.so' protection. If they crash, use the ripped APKs (like `11.99.0-release-ripped.1`) from the [Piko Telegram](https://t.me/pikopatches).
   * **For X (Twitter) versions 12.0.0 and above**, you need an additional third-party patch from `inotia00`. Download `x-shim-xxx.mpp` from [inotia00's GitLab](https://gitlab.com/inotia00/x-shim/-/releases) and place it alongside the regular Piko `.mpp` patch. The script will automatically detect and apply both patches together!

> [!NOTE]
> **📱 File Format & Naming Support:**
>
> * While fully merged or standalone Universal `.apk` files are highly recommended for the cleanest patching process, the script also natively supports dropping `.apkm`, `.xapk`, or `.apks` bundles directly into the `Input` folder!
> * **Don't worry about messy file names!** If you download directly from APKMirror, your file might look something like this:
>     `com.google.android.youtube_20.51.39-1558707648_minAPI28(arm64-v8a,armeabi-v7a,x86,x86_64)(nodpi)_apkmirror.com.apk`
>     Just drop it as is. The script's regex engine is smart enough to ignore the garbage tags and extract the correct version natively. Alternatively, if you prefer keeping things clean and simple, you can easily rename it to something like `com.google.android.youtube-20.51.39-universal.apk` for `YouTube` or `com.google.android.apps.youtube.music-8.51.51-arm64-v8a.apkm` for `YT Music`. For other supported apps, you can just follow the same naming convention.

7. **MicroG-RE**: If you're patching `YouTube` and/or `YouTube Music` via `Morphe`, you'll need to install MicroG-RE on your device and then sign in to your `Google account`. Download it here: [MicroG-RE releases](https://github.com/MorpheApp/MicroG-RE/releases/latest).

---

## 🚀 How to Use

1. **Set the Stage**: Grab the script from the [Releases page](https://github.com/chihafuyu/Chihafuyu-Patcher/releases/latest) (Recommended) or download the [Main branch source code](https://github.com/chihafuyu/Chihafuyu-Patcher/archive/refs/heads/main.zip). Extract the ZIP and place `chihafuyu-tool.ps1` into an empty working directory. Next, place your downloaded `morphe-cli.jar` right next to the script, and drop the `.mpp` patch files into their respective folders.
2. **Folder Structure**: The script uses a smart multi-workspace architecture. When you run it, it will auto-create the necessary folders for you. Your root directory should look like this:
```text
📁 Your-Working-Directory/
 ├── 📄 chihafuyu-tool.ps1           (The main script)
 ├── ☕ morphe-cli-x.x.x-all.jar     (CLI - Place here or inside the ecosystem folder)
 ├── 📄 custom-keystore.txt          (Optional - Auto-generated for bulk credentials)
 ├── 🔑 my-custom-key.keystore       (Optional - Place your custom keystore here)
 ├── 📁 Morphe/                      (Morphe Workspace)
 │    ├── 📦 patches-x.x.x.mpp       
 │    ├── 📁 Input/                  
 │    └── 📁 Output/                 
 ├── 📁 Piko/                        (Piko Workspace)
 │    ├── 📦 patches-x.x.x.mpp       
 │    ├── 📦 x-shim-x.x.x.mpp         (Optional - For X v12+)
 │    ├── 📁 Input/                  
 │    └── 📁 Output/
 ├── 📁 hoo-dles/                    (hoo-dles Workspace)
 │    ├── 📦 patches-x.x.x.mpp       
 │    ├── 📁 Input/                  
 │    └── 📁 Output/
 ├── 📁 De-ReVanced/                 (De-ReVanced Workspace)
 │    ├── 📦 patches-x.x.x.mpp       
 │    ├── 📁 Input/                  
 │    └── 📁 Output/
 ├── 📁 BholeyKaBhakt/               (BholeyKaBhakt Workspace)
 │    ├── 📦 patches-x.x.x.mpp       
 │    ├── 📁 Input/                  
 │    └── 📁 Output/
 └── 📁 browzomje/                   (browzomje Workspace)
      ├── 📦 patches-x.x.x.mpp       
      ├── 📁 Input/                  
      └── 📁 Output/
```
3. **Load your Apps**: Move the target files (`.apk`, `.apkm`, etc.) into the `Input` folder of the ecosystem you want to patch.
4. **Run the script**:
   * Double click `chihafuyu-tool.ps1`, OR
   * Right-click `chihafuyu-tool.ps1` and select "Run with PowerShell", OR
   * Open a PowerShell terminal in the folder and type: `.\chihafuyu-tool.ps1`, then press `Enter`.
5. **Main Menu**: You will be greeted with the Main Menu. Select `1` for Patching apps or `2` for the ADB Utility features.
6. **Follow the Prompts**: The script will interactively guide you through selecting the ecosystem, environment track, target apps, architecture, and other configurations.
7. **Grab your patched apps**: Once you hit that `[SUCCESS]` message, just open the `Output` folder (and save the logs if you want). Your fresh patched APK(s) are ready to be installed!

> **💡 Pro Tip:** By default, the script applies the standard set of patches. Want to customize them? Hit `Y` when asked to modify the JSON files. Open the generated file (e.g., `youtube-options-stable.json`), set the patch values to `true` or `false` as needed, save your changes, and press any key in the terminal to resume patching!

> [!WARNING]
> **🚨 UNIVERSAL PATCHES LIMITATION 🚨**
>
> Inside your generated `options.json`, you might notice patches like `Override certificate pinning`, `Change package name`, and `Disable Play Store updates`. These are **Universal Patches** designed to work on *any* app.
> 
> Keep in mind: Each ecosystem (Morphe, Piko, hoo-dles, etc.) explicitly bundles its *own* specific set of universal patches inside their respective `.mpp` files. They are not globally shared across different patchers.
>
> Furthermore, they have a major weakness: **they do NOT support every app out there**. For example, applying them to random, unsupported apps (like banking apps or heavily secured games) will likely fail or cause crashes. Use them with caution!

---

## 🛠️ Configuration (Optional)

Whenever new stable patch bundles are released with updated app version targets, just open `chihafuyu-tool.ps1` in your favorite text editor ([Notepad++](https://notepad-plus-plus.org/downloads/) is highly recommended) and update the versions at the very top of the file:

```powershell
# ==============================================================================
# RECOMMENDED APP VERSIONS
# ==============================================================================
# Morphe
$cfg_youtube_stable       = @("20.51.39", "20.47.62", "20.31.42", "20.21.37")
$cfg_youtube_music_stable = @("9.15.51", "8.51.51", "7.29.52")
$cfg_reddit_stable        = @("2026.14.0", "2026.04.0")

# Piko
$cfg_x_stable             = @(
    "12.2.0-release.0",
    "12.0.0-release.0",
    "11.99.0-release-ripped.1", 
    "11.81.0-release.0", 
    "11.69.0-release.0"
)
$cfg_ig_stable            = @("435.0.0.37.76")

# hoo-dles
$cfg_adguard_stable       = @("4.12.81")
$cfg_ibispaint_stable     = @("14.0.4")
$cfg_wps_stable           = @("18.24")
$cfg_camscanner_stable    = @("7.15.5.2604080000")
$cfg_sleep_stable         = @("20260526")
$cfg_duolingo_stable      = @("6.85.7")
$cfg_merriamwebster_stable= @("Any")
$cfg_mimo_stable          = @("9.11")
$cfg_windy_stable         = @("50.1.1")
$cfg_xrecorder_stable     = @("2.5.1.1")
$cfg_xodo_stable          = @("10.15.0")

# De-ReVanced
$cfg_photos_stable        = @("Any")
$cfg_rar_stable           = @("Any")

# BholeyKaBhakt
$cfg_speedtest_stable     = @("7.0.4")
$cfg_stellarium_stable    = @("1.16.3", "1.16.2")
$cfg_proto_stable         = @("1.49.0", "1.48.0")
$cfg_vpnify_stable        = @("2.2.9")
$cfg_backdrops_stable     = @("6.1.2")
$cfg_solidexplorer_stable = @("3.4.10")

# browzomje
$cfg_pinterest_stable     = @("14.23.0", "14.24.0")
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

**Third-Party Code Attribution:**

> This tool utilizes patches and code from Morphe, Piko, hoo-dles, De-ReVanced, BholeyKaBhakt and inotia00. To learn more, visit [Morphe](https://morphe.software), [Piko](https://github.com/crimera/piko), [hoo-dles](https://github.com/hoo-dles/morphe-patches), [De-ReVanced](https://github.com/RookieEnough/De-ReVanced), [BholeyKaBhakt](https://github.com/BholeyKaBhakt/android-patches-xtra), [browzomje](https://github.com/browzomje/browzomje-patches), and [inotia00](https://gitlab.com/inotia00/x-shim/)