# 🚀 Chihafuyu Tool

A comprehensive, menu-driven PowerShell script to automate Android app patching and manage ADB installations utilizing the **De-Vanced**, **hoo-dles**, **hxreborn**, **jasonwu1994**, **kiraio-moe**, **kuchingneko28**, **kveld9**, **Morphe**, and **Piko** ecosystems via **Morphe Desktop**.

Whether you're patching `YouTube`, `YouTube Music`, `Reddit`, `TikTok Global`, `X (Twitter)`, `Instagram`, `Brave Browser`, `Google Photos`, `Gboard`, `Proton Mail`, `AdGuard`, `Lightroom Mobile`, `iPusnas`, `Nekopoi`, or simply managing your device via ADB, just sit back and let the script do the heavy lifting. It handles all the boring chores for you: environment checks, smart APK hunting, secure keystore handling, smart JVM heap allocation, JSON result generation, and proper memory cleanup.

> [!IMPORTANT]
> **📱 Root vs. Non-Root Devices**
>
> Just a quick heads-up: I built and tested the core patching process for **non-rooted** Android devices. While the actual patching on your PC will work flawlessly either way, installing the patched apps via root-specific methods (like system mounting) requires root privileges on your phone. Luckily, this tool's Utility menu explicitly supports both Root (`--mount`) and Non-Root (`--apk`) workflows!

---

## ✨ Features

- **🌐 Multi-Ecosystem Support**: Seamlessly switch between 9 curated ecosystems in a single script:
  - **De-Vanced**: `Google Photos`
  - **hoo-dles**: `AdGuard`, `CamScanner`, `Duolingo`, `IbisPaint X`, `Lightroom Mobile`, `Merriam-Webster`, `Mimo`, `MyFitnessPal`, `PyDroid3`, `Sleep as Android`, `Smart Launcher`, `Windy`, `WPS Office`, `Xodo`, `XRecorder`
  - **hxreborn**: `Projectivy Launcher`, `Proton Mail`, `Symfonium`
  - **jasonwu1994**: `Gboard`
  - **kiraio-moe**: `Atomic`, `Boorusama`, `Epic!`, `Fake GPS Location`, `Hermit`, `Hidden Settings`, `iLovePDF`, `Key Mapper`, `Keymate`, `Manga Plus`, `Nekopoi`, `PixelLab`, `Pixiv`, `Timestamp Camera Free`
  - **kuchingneko28**: `iPusnas`
  - **kveld9**: `Brave Browser`, `TikTok Global`
  - **Morphe**: `Reddit`, `YouTube`, `YouTube Music`
  - **Piko**: `Instagram`, `X (Twitter)`

  Select multiple ecosystems at once to queue up batch patching across different platforms in a single run.
- **🛠️ Integrated Utility Menu**: Acts as a frontend for Morphe Desktop's utility features:
  - Install/Uninstall apps via ADB directly from the script (supports standard `--apk`, root-mount `--mount`, and link routing `--route-links` / `--disable-stock`).
  - Generate `options.json` (with per-file or batch `[Y/N/A/X]` backup/overwrite prompts) or `list-patches.txt` without running the entire patching loop.
  - Generate custom PKCS12 Android keystores (`keytool`) with masked password confirmation and environment-passed credentials.
  - Clear Morphe cache (`clear-cache`) cleanly.
- **📦 Native Bundle Support**: No need to manually merge Split APKs anymore! Natively processes standard `.apk`, `.apkm`, `.xapk`, and `.apks` files, and validates `.apk` archives for required core entries (`classes.dex` & `AndroidManifest.xml`).
- **🛡️ Environment Validation**: Smartly checks for JDK 25+ and ensures your CLI (`.jar`) and Patches (`.mpp`) are ready for your chosen track (Stable or Pre-release).
- **🔄 Smart Multi-Patch Processing**: Need to apply third-party shim patches alongside your main patch bundle? The script automatically detects companion `*shim*.mpp` files in the ecosystem workspace and chains them into the patching sequence.
- **🔍 Smart APK Discovery & Multi-Version Support**: Scans your `Input` folder, matches package/app identifiers cleanly without cross-app false positives, extracts exact versions (including special tags like `4.7.0m`, `8.3_arm64`, `6.6 build 016`, `18.0.3.954559732-release-arm64-v8a`, `12.17.0-release.0`), and validates them against configured supported versions.
- **🧠 JSON Logic Constraints & Content Warnings**: Safely inspects customized `options.json` files before patching to warn on incompatible patch/version combinations (e.g., `Block redirecting to X Lite` on older X/Twitter APKs), and enforces mandatory indemnity disclaimers before processing NSFW/21+ targeted applications.
- **⚙️ Targeted Architecture Stripping & Memory Management**: Supports architecture-specific library stripping (`--striplibs` for `arm64-v8a`, `armeabi-v7a`, `x86_64`, `x86`, or `universal`) and dynamically scales JVM heap size (`-Xmx2G` to `-Xmx4G`) based on detected physical RAM.
- **🔐 Memory-Safe Keystore Handling**: Uses `SecureString`, immediate unmanaged `BSTR` zeroing, and cleanup in `finally` blocks on every exit path to prevent password leaks in script memory.
- **📊 Logs & Stealth JSON Results**: Streams UTF-8 execution logs and `--result-file` outputs cleanly and lets you export them at the end of the session (cleaning up temporary files automatically).
- **🔙 Global Abort / Back Navigation**: Made a mistake? Type `B` at any sub-prompt to safely cancel the operation and return to the main menu without leaking credentials or temporary files.

> [!WARNING]
> **🚨 Keystore Password Exposure Notice**
>
> While this script uses `SecureString` and immediate unmanaged memory zeroing to protect your passwords internally, the upstream `morphe-desktop` Java engine currently requires patching keystore passwords to be passed via command-line arguments (e.g., `--keystore-password`).
>
> This means your patching keystore password **may be momentarily visible to system monitoring tools** (like Windows Task Manager or Process Explorer) while the patching process is actively running in the background.
>
> **Recommendation:** Never use high-value personal passwords (like your bank or primary email password) for your Android keystores, especially if you are running this tool on a shared or enterprise machine!

---

## 📋 Prerequisites

Before spinning up the tool, make sure you have these ready:

1. **OS**: Windows 10/11. PowerShell 5.1+ is required (PowerShell 7+ is highly recommended). Download [here](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell).
2. **Java Development Kit (JDK) 25**: Morphe Desktop utilizes FFM APIs to natively resolve file locking issues on Windows, which strictly requires JDK 25 or higher (a standard JRE or older JDK won't cut it). Pick and install **JUST ONE** of these reliable builds:
   * [Azul Zulu JDK 25 (LTS)](https://www.azul.com/downloads/?version=java-25-lts&package=jdk)
   * **OR** [Eclipse Temurin JDK 25 (LTS)](https://adoptium.net/temurin/releases/?version=25)

   > **Important:** Make sure to check the **"Add to PATH"** option during installation.
3. **Android SDK Platform-Tools (For Utility Menu)**: If you want to use the script's ADB install/uninstall features, you must have `adb` installed. Download [SDK Platform-Tools](https://developer.android.com/studio/releases/platform-tools) and add it to your system PATH.
4. **Android SDK (For Verification)**: If you intend to use the `--verify-with-sdk` feature during patching, you must have an Android SDK (specifically `build-tools` and `platforms`) installed and properly configured.
5. **Patcher CLI & Patches**: You'll need the patching engine (Morphe Desktop) and the patch bundles (`.mpp`) for your target ecosystem:
   * **Morphe Desktop (Required for all)**: [morphe-desktop releases](https://github.com/MorpheApp/morphe-desktop/releases)
   * **De-Vanced Patches**: [De-Vanced releases](https://github.com/RookieEnough/De-Vanced/releases)
   * **hoo-dles Patches**: [morphe-patches releases](https://github.com/hoo-dles/morphe-patches/releases)
   * **hxreborn Patches**: [morphe-patches releases](https://github.com/hxreborn/morphe-patches/releases)
   * **jasonwu1994 Patches**: [Gboard-patches releases](https://github.com/jasonwu1994/Gboard-patches/releases)
   * **kiraio-moe Patches**: [Lain-Patches releases](https://github.com/kiraio-moe/Lain-Patches/releases)
   * **kuchingneko28 Patches**: [ipusnas-patches releases](https://github.com/kuchingneko28/ipusnas-patches/releases)
   * **kveld9 Patches**: [kveld-morphe-patches releases](https://github.com/kveld9/kveld-morphe-patches/releases)
   * **Morphe Patches**: [morphe-patches releases](https://github.com/MorpheApp/morphe-patches/releases)
   * **Piko Patches**: [piko releases](https://github.com/crimera/piko/releases)
6. **App Files**: Have your raw, unpatched apps ready ([APKMirror](https://www.apkmirror.com/) is recommended for most apps). **Note for Nekopoi:** Download the raw APK directly from their official source (`https://linkpoi.me/app`).

> [!NOTE]
> **📱 File Format & Naming Support:**
>
> * While fully merged or standalone Universal `.apk` files are highly recommended for the cleanest patching process, the script also natively supports dropping `.apkm`, `.xapk`, or `.apks` bundles directly into the `Input` folder!
> * **Don't worry about messy file names!** If you download directly from APKMirror or external CDNs, your file might look like:
>   `com.google.android.youtube_21.04.223-1559103232_minAPI28(arm64-v8a,armeabi-v7a,x86,x86_64)(nodpi)_apkmirror.com.apk`.
>   Just drop it as is — the regex engine extracts the version natively.
> * **Abstract File Names:** If you download a file with a completely abstract name (e.g., `app25301.apk`), **rename it** to include the app name (e.g., `nekopoi_2.5.3.apk`) so the script can identify which app it belongs to (note: `appNNNNN.apk` is also matched automatically for Nekopoi). If version extraction cannot determine a version from a custom name, the script falls back to prompting you manually!

7. **MicroG-RE**: If you're patching `YouTube` and/or `YouTube Music` via `Morphe`, you'll need to install MicroG-RE on your device and sign in to your Google account. Download it here: [MicroG-RE releases](https://github.com/MorpheApp/MicroG-RE/releases/latest).

---

## 🚀 How to Use

1. **Set the Stage**: Grab the script from the [Releases page](https://github.com/chihafuyu/Chihafuyu-Tool/releases) (Recommended) or download the [Main branch source code](https://github.com/chihafuyu/Chihafuyu-Tool/archive/refs/heads/main.zip). Extract the ZIP and place `chihafuyu-tool.ps1` into an empty working directory. Next, place your downloaded `morphe-desktop-*-all.jar` right next to the script (or inside an ecosystem folder), and drop the `.mpp` patch files into their respective folders.
2. **Folder Structure**: The script uses a multi-workspace architecture and auto-creates the folders for you as you select ecosystems:

```text
📁 Your-Working-Directory/
 ├── 📄 chihafuyu-tool.ps1           (The main script)
 ├── ☕ morphe-desktop-x.x.x-all.jar (CLI - Place here or inside an ecosystem folder)
 ├── 📄 custom-keystore.txt          (Optional - Auto-generated template for bulk credentials)
 ├── 🔑 my-custom-key.keystore       (Optional - Place or generate your custom keystore here)
 ├── 📁 De-Vanced/                   (De-Vanced Workspace)
 │    ├── 📦 patches-x.x.x.mpp
 │    ├── 📁 Input/
 │    └── 📁 Output/
 ├── 📁 hoo-dles/                    (hoo-dles Workspace)
 │    ├── 📦 patches-x.x.x.mpp
 │    ├── 📁 Input/
 │    └── 📁 Output/
 ├── 📁 hxreborn/                    (hxreborn Workspace)
 │    ├── 📦 patches-x.x.x.mpp
 │    ├── 📁 Input/
 │    └── 📁 Output/
 ├── 📁 jasonwu1994/                 (jasonwu1994 Workspace)
 │    ├── 📦 patches-x.x.x.mpp
 │    ├── 📁 Input/
 │    └── 📁 Output/
 ├── 📁 kiraio-moe/                  (kiraio-moe Workspace)
 │    ├── 📦 patches-x.x.x.mpp
 │    ├── 📁 Input/
 │    └── 📁 Output/
 ├── 📁 kuchingneko28/               (kuchingneko28 Workspace)
 │    ├── 📦 patches-x.x.x.mpp
 │    ├── 📁 Input/
 │    └── 📁 Output/
 ├── 📁 kveld9/                      (kveld9 Workspace)
 │    ├── 📦 patches-x.x.x.mpp
 │    ├── 📁 Input/
 │    └── 📁 Output/
 ├── 📁 Morphe/                      (Morphe Workspace)
 │    ├── 📦 patches-x.x.x.mpp
 │    ├── 📁 Input/
 │    └── 📁 Output/
 └── 📁 Piko/                        (Piko Workspace)
      ├── 📦 patches-x.x.x.mpp
      ├── 📁 Input/
      └── 📁 Output/
```

3. **Load your Apps**: Move the target files (`.apk`, `.apkm`, `.xapk`, `.apks`) into the `Input` folder of the ecosystem you want to patch.
4. **Run the script**:
   * Right-click `chihafuyu-tool.ps1` and select **"Run with PowerShell"**, OR
   * Open a PowerShell terminal in the folder and run: `.\chihafuyu-tool.ps1`.
5. **Main Menu**: Select `1` for Patching apps or `2` for the Utility menu.
6. **Follow the Prompts**: The script interactively guides you through selecting ecosystems, environment tracks, target apps, architecture, signing/keystore options, and flags.
7. **Grab your patched apps**: Once patching completes, export logs/JSON results if desired and open the `Output` folder. Your fresh patched APK(s) are ready to install!

> **💡 Pro Tip:** By default, the script generates fresh options files with standard defaults. Want to customize patches? Hit `Y` when asked to modify the JSON files, edit the generated file (e.g., `youtube-options-stable.json`), save your changes, and press any key in the terminal to resume patching!

> [!WARNING]
> **🚨 UNIVERSAL PATCHES LIMITATION 🚨**
>
> Inside your generated `options.json`, you might notice patches like `Override certificate pinning`, `Clone app`, `Change installer source`, and `Disable Play Store updates`. These are **Universal Patches** designed to work on *any* app.
>
> Keep in mind: Each ecosystem bundles its *own* set of universal patches inside its `.mpp` file — they are not globally shared across patchers, and **they do NOT support every app out there** (e.g., banking apps or heavily protected games will likely fail or crash). Use them with caution!

---

## 🛠️ Configuration (Optional)

Whenever new stable patch bundles are released with updated app version targets, open `chihafuyu-tool.ps1` in your text editor ([Notepad++](https://notepad-plus-plus.org/downloads/) or VS Code) and update the versions near the top of the file:

```powershell
# ==============================================================================
# RECOMMENDED APP VERSIONS (SORTED A-Z)
# ==============================================================================
# De-Vanced
$cfg_photos_stable          = @("Any")

# hoo-dles
$cfg_adguard_stable         = @("4.13.1")
$cfg_camscanner_stable      = @("7.20.0.2606230000")
$cfg_duolingo_stable        = @("6.92.5")
$cfg_ibispaint_stable       = @("14.0.6")
$cfg_lightroom_stable       = @("11.4.5")
$cfg_merriamwebster_stable  = @("Any")
$cfg_mimo_stable            = @("9.11")
$cfg_myfitnesspal_stable    = @("26.31.0")
$cfg_pydroid3_stable        = @("8.3_arm64")
$cfg_sleep_stable           = @("20260526")
$cfg_smartlauncher_stable   = @("6.6 build 016")
$cfg_windy_stable           = @("51.0.1")
$cfg_wps_stable             = @("18.24")
$cfg_xodo_stable            = @("10.15.0")
$cfg_xrecorder_stable       = @("2.5.1.1")

# hxreborn
$cfg_projectivy_stable      = @("Any")
$cfg_protonmail_stable      = @("7.10.4")
$cfg_symfonium_stable       = @("14.1.0")

# jasonwu1994
$cfg_gboard_stable          = @("18.0.3.954559732-release-arm64-v8a")

# kiraio-moe
$cfg_atomic_stable          = @("4.7.0m")
$cfg_boorusama_stable       = @("4.5.1")
$cfg_epic_stable            = @("3.141.43")
$cfg_fakegps_stable         = @("113.0")
$cfg_hermit_stable          = @("31.6.1")
$cfg_hiddensets_stable      = @("7.34")
$cfg_ilovepdf_stable        = @("4.0.1")
$cfg_keymapper_stable       = @("4.2.1")
$cfg_keymate_stable         = @("1.2.0")
$cfg_mangaplus_stable       = @("2.4.1")
$cfg_nekopoi_stable         = @("2.5.3-build01", "2.5.3")
$cfg_pixellab_stable        = @("2.1.9")
$cfg_pixiv_stable           = @("6.189.0")
$cfg_timestampcam_stable    = @("1.252")

# kuchingneko28
$cfg_ipusnas_stable         = @("2.1.4")

# kveld9
$cfg_brave_stable           = @("1.93.137")
$cfg_tiktok_kveld9_stable   = @("47.1.4")

# Morphe
$cfg_reddit_stable          = @("2026.14.0", "2026.04.0")
$cfg_youtube_stable         = @("21.04.223", "20.51.39", "20.31.42", "20.21.37")
$cfg_youtube_music_stable   = @("9.15.51")

# Piko
$cfg_ig_stable              = @("439.0.0.37.89")
$cfg_x_stable               = @("12.17.0-release.0")
# ==============================================================================
```

---

## ⚠️ Troubleshooting

**Script closing instantly or throwing execution policy errors on your first try? (Windows Only)**
That's usually Windows blocking unsigned local scripts via its default Execution Policy:

1. Open PowerShell as Administrator (or run for CurrentUser without admin).
2. Run:

   ```powershell
   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
   ```

3. Type `Y` and press Enter, then run `.\chihafuyu-tool.ps1` again.

---

## 📜 Legal & License

Distributed under the MIT License. See [LICENSE](LICENSE) for full details.

**Copyright (c) 2026 chihafuyu**

> You are free to use, modify, and distribute this tool for any purpose, as long as you keep the original copyright notice above. It is provided _"as is"_, without warranty of any kind. Use it at your own risk!

**Third-Party Code Attribution:**

> This tool utilizes patches and tooling from De-Vanced, hoo-dles, hxreborn, jasonwu1994, kiraio-moe, kuchingneko28, kveld9, Morphe, Piko, and inotia00. To learn more, visit [De-Vanced](https://github.com/RookieEnough/De-Vanced/releases), [hoo-dles](https://github.com/hoo-dles/morphe-patches/releases), [hxreborn](https://github.com/hxreborn/morphe-patches/releases), [jasonwu1994](https://github.com/jasonwu1994/Gboard-patches/releases), [kiraio-moe](https://github.com/kiraio-moe/Lain-Patches/releases), [kuchingneko28](https://github.com/kuchingneko28/ipusnas-patches/releases), [kveld9](https://github.com/kveld9/kveld-morphe-patches/releases), [Morphe](https://morphe.software), [Piko](https://github.com/crimera/piko/releases), and [inotia00](https://gitlab.com/inotia00/x-shim/).
