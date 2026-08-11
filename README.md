# 🚀 Chihafuyu Tool

A comprehensive, menu-driven PowerShell script to automate Android app patching and manage ADB installations utilizing the **ajstrick81**, **arandomhooman**, **BholeyKaBhakt**, **browzomje**, **De-ReVanced**, **hoo-dles**, **icysymmetra**, **kiraio-moe**, **Morphe**, **PathxmOp**, and **Piko** ecosystems via **Morphe Desktop**.

Whether you're patching `YouTube`, `TikTok`, `Disney+`, `Netflix`, `Advanced Download Manager`, `Reddit`, `X (Twitter)`, `Instagram`, `AdGuard`, `IbisPaint X`, `Pinterest`, `Easy Sudoku`, `Chess.com`, `Nekopoi`, or simply managing your device via ADB, just sit back and let the script do the heavy lifting. It handles all the boring chores for you: environment checks, smart APK hunting, secure keystore handling, smart JVM heap allocation, JSON result generation, and proper memory cleanup.

> [!IMPORTANT]
> **📱 Root vs. Non-Root Devices**
>
> Just a quick heads-up: I built and tested the core patching process for **non-rooted** Android devices. While the actual patching on your PC will work flawlessly either way, installing the patched apps via root-specific methods (like system mounting) requires root privileges on your phone. Luckily, this tool's Utility menu explicitly supports both Root (`--mount`) and Non-Root (`--apk`) workflows!

---

## ✨ Features

- **🌐 Multi-Ecosystem Support**: Seamlessly switch between ajstrick81 (`Disney+`, `Prime Video`, `Netflix`, `HBO Max`, `Peacock`, `Tubi`, `ViX`, `Pluto TV`, `Paramount+`), arandomhooman (`ADM`, `Alpha Progression`, `BandLab`, `Battery Guru`, `Cronometer`, `DirectChat`, `Finch`, `Flightradar24`, `FolderSync`, `InShot`, `Liquid Gallery`, `Poweramp`, `Smart AudioBook Player`, `Symfonium`, `Tumblr`, `Video Converter`, `WEBTOON`), BholeyKaBhakt (`Speedtest`, `Stellarium`, `PROTO`, `vpnify`, `Backdrops`, `Solid Explorer`), browzomje (`Pinterest`, `Easy Sudoku`), De-ReVanced (`Google Photos`, `RAR`), hoo-dles (`AdGuard`, `IbisPaint X`, `WPS Office`, `CamScanner`, `Sleep as Android`, `Duolingo`, `Windy`, `Xodo`, etc.), icysymmetra (`TikTok Global`), kiraio-moe (`Atomic`, `AudioRelay`, `Boorusama`, `Epic!`, `Fake GPS`, `Hermit`, `Hidden Settings`, `iLovePDF`, `Key Mapper`, `Keymate`, `Manga Plus`, `Nekopoi`, `PixelLab`, `Timestamp Camera`), Morphe (`YouTube`, `YouTube Music`, `Reddit`), PathxmOp (`Chess.com`), and Piko (`X/Twitter`, `Instagram`) workspaces in a single script. Select multiple ecosystems at once to queue up batch patching across different platforms in a single run.
- **🛠️ Integrated Utility Menu**: Acts as a frontend for Morphe Desktop's utility features. Install/Uninstall apps via ADB directly from the script (supports standard, root-mount modes, and automatic link routing), clear Morphe cache, or quickly generate `options.json`/`list-patches.txt` files without running the entire patching loop.
- **📦 Native Bundle Support**: No need to manually merge Split APKs anymore! Natively processes standard `.apk`, `.apkm`, `.xapk`, and `.apks` files.
- **🛡️ Environment Validation**: Smartly checks for JDK 25+ and ensures your CLI (`.jar`) and Patches (`.mpp`) are ready for your chosen track (Stable or Pre-release).
- **🔄 Smart Multi-Patch Processing**: Need to apply third-party shim patches alongside your main patch bundle? No problem! The script automatically detects secondary patches (e.g., `*shim*.mpp`) and dynamically chains them into the patching sequence.
- **🔍 Smart APK Discovery & Multi-Version Support**: Scans your `Input` folder, extracts exact versions ignoring messy build numbers or weird version formats (like `x-y-z`, `x_y_z`, or even abstract names like `app25301.apk`), and validates them against an array of supported versions.
- **🧠 JSON Logic Constraints & Content Warnings**: Safely inspects your customized `options.json` before patching to prevent fatal crashes (e.g., blocking the execution if specific Twitter patches are forced on incompatible versions). The script also enforces mandatory indemnity warnings before processing NSFW/21+ targeted applications.
- **⚙️ Auto Architecture & Memory Management**: Automatically detects if an APK is already architecture-specific and skips redundant library stripping. Dynamically scales JVM heap size (`-Xmx`) based on your system's physical RAM to prevent `OutOfMemory` crashes.
- **🔐 Memory-Safe Keystore Handling**: Uses `SecureString` and unmanaged memory pointers to aggressively prevent password leaks within the script's internal memory space.
- **📊 Stealth JSON Results**: Automatically captures the patching result output and offers to export it as a clean JSON file at the end of the session.
- **🔙 Global Abort / Back Navigation**: Made a mistake? Just type `B` at any prompt to safely cancel the operation and return to the main menu without breaking the script.

> [!WARNING]
> **🚨 Keystore Password Exposure Notice**
> 
> While this script uses advanced memory-handling to protect your passwords internally, the upstream `morphe-desktop` Java engine currently requires passwords to be passed via standard command-line arguments (e.g., `--keystore-password`). 
> 
> This means your plaintext password **may be momentarily visible to system monitoring tools** (like Windows Task Manager or Process Explorer) while the patching process is actively running in the background. 
> 
> **Recommendation:** Never use high-value personal passwords (like your bank or primary email password) for your Android keystores, especially if you are running this tool on a shared or enterprise machine!

---

## 📋 Prerequisites

Before spinning up the tool, make sure you have these ready:

1. **OS**: Windows 10/11. PowerShell 5.1+ is required (PowerShell 7+ is highly recommended). Download [here](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell).
2. **Java Development Kit (JDK) 25**: The latest Morphe Desktop utilizes FFM APIs to natively resolve file locking issues on Windows, which strictly requires JDK 25 or higher (a standard JRE or older JDK 21 won't cut it). Pick and install **JUST ONE** of these reliable builds:
   * [Azul Zulu JDK 25 (LTS)](https://www.azul.com/downloads/?version=java-25-lts&package=jdk)
   * **OR** [Eclipse Temurin JDK 25 (LTS)](https://adoptium.net/temurin/releases/?version=25)
   
   > **Important:** Make sure to check the **"Add to PATH"** option during installation.
3. **Android SDK Platform-Tools (For Utility Menu)**: If you want to use the script's install/uninstall features, you must have `adb` installed. Download [SDK Platform-Tools](https://developer.android.com/studio/releases/platform-tools) and add it to your system PATH.
4. **Android SDK (For Verification)**: If you intend to use the `--verify-with-sdk` feature during patching, you must have an Android SDK (specifically `build-tools` and `platforms`) installed on your machine and properly configured. Otherwise, the script will throw a fatal error.
5. **Patcher CLI & Patches**: You'll need the patching engine (Morphe Desktop) and the patch bundles (`.mpp`) for your target ecosystem. Download the latest releases from the links below:
   * **Morphe Desktop (Required for all)**: [morphe-desktop releases](https://github.com/MorpheApp/morphe-desktop/releases)
   * **ajstrick81 Patches**: [morphe-androidtv-patches releases](https://github.com/ajstrick81/morphe-androidtv-patches/releases)
   * **arandomhooman Patches**: [hoomans-morphe-patches releases](https://github.com/arandomhooman/hoomans-morphe-patches/releases)
   * **BholeyKaBhakt Patches**: [android-patches-xtra releases](https://github.com/BholeyKaBhakt/android-patches-xtra/releases)
   * **browzomje Patches**: [browzomje releases](https://github.com/browzomje/browzomje-patches/releases)
   * **De-ReVanced Patches**: [De-ReVanced releases](https://github.com/RookieEnough/De-ReVanced/releases)
   * **hoo-dles Patches**: [hoo-dles releases](https://github.com/hoo-dles/morphe-patches/releases)
   * **icysymmetra Patches**: [tiktok-patches-for-morphe releases](https://github.com/icysymmetra/tiktok-patches-for-morphe/releases)
   * **kiraio-moe Patches**: [kiraio-moe releases](https://github.com/kiraio-moe/Lain-Patches/releases)
   * **Morphe Patches**: [morphe-patches releases](https://github.com/MorpheApp/morphe-patches/releases)
   * **PathxmOp Patches**: [Prathxm-Patches releases](https://github.com/PrathxmOp/Prathxm-Patches/releases)
   * **Piko Patches**: [piko releases](https://github.com/crimera/piko/releases)
6. **App Files**: Have your raw, unpatched apps ready ([APKMirror](https://www.apkmirror.com/) is highly recommended for most apps). **Note for Nekopoi:** Please download the raw APK directly from their official source (`https://linkpoi.me/app`). There are many fake and scam sites out there impersonating them, so stay safe!

> [!NOTE]
> **📱 File Format & Naming Support:**
>
> * While fully merged or standalone Universal `.apk` files are highly recommended for the cleanest patching process, the script also natively supports dropping `.apkm`, `.xapk`, or `.apks` bundles directly into the `Input` folder!
> * **Don't worry about messy file names!** If you download directly from APKMirror or external CDNs, your file might look something like this:
>     `com.google.android.youtube_20.51.39-1558707648_minAPI28(arm64-v8a,armeabi-v7a,x86,x86_64)(nodpi)_apkmirror.com.apk`.
>     Just drop it as is. The script's regex engine is smart enough to ignore the garbage tags and extract the correct version natively. 
> * **Abstract File Names:** If you download a file with a completely abstract name (e.g., `app25301.apk`), **you must rename it** to include the app's name (e.g., `nekopoi_2.5.3.apk`) so the script can identify which app it belongs to. Once identified, if the regex engine still struggles to parse the version from your custom name, the script will gracefully fallback and ask you to enter the version manually!

7. **MicroG-RE**: If you're patching `YouTube` and/or `YouTube Music` via `Morphe`, you'll need to install MicroG-RE on your device and then sign in to your `Google account`. Download it here: [MicroG-RE releases](https://github.com/MorpheApp/MicroG-RE/releases/latest).

---

## 🚀 How to Use

1. **Set the Stage**: Grab the script from the [Releases page](https://github.com/chihafuyu/Chihafuyu-Tool/releases) (Recommended) or download the [Main branch source code](https://github.com/chihafuyu/Chihafuyu-Tool/archive/refs/heads/main.zip). Extract the ZIP and place `chihafuyu-tool.ps1` into an empty working directory. Next, place your downloaded `morphe-desktop-*.jar` right next to the script, and drop the `.mpp` patch files into their respective folders.
2. **Folder Structure**: The script uses a smart multi-workspace architecture. When you run it, it will auto-create the necessary folders for you. Your root directory should look like this:
```text
📁 Your-Working-Directory/
 ├── 📄 chihafuyu-tool.ps1           (The main script)
 ├── ☕ morphe-desktop-x.x.x-all.jar (CLI - Place here or inside the ecosystem folder)
 ├── 📄 custom-keystore.txt          (Optional - Auto-generated for bulk credentials)
 ├── 🔑 my-custom-key.keystore       (Optional - Place your custom keystore here)
 ├── 📁 ajstrick81/                  (ajstrick81 Workspace)
 │    ├── 📦 patches-x.x.x.mpp       
 │    ├── 📁 Input/                  
 │    └── 📁 Output/
 ├── 📁 arandomhooman/               (arandomhooman Workspace)
 │    ├── 📦 patches-x.x.x.mpp       
 │    ├── 📁 Input/                  
 │    └── 📁 Output/
 ├── 📁 BholeyKaBhakt/               (BholeyKaBhakt Workspace)
 │    ├── 📦 patches-x.x.x.mpp       
 │    ├── 📁 Input/                  
 │    └── 📁 Output/
 ├── 📁 browzomje/                   (browzomje Workspace)
 │    ├── 📦 patches-x.x.x.mpp       
 │    ├── 📁 Input/                  
 │    └── 📁 Output/
 ├── 📁 De-ReVanced/                 (De-ReVanced Workspace)
 │    ├── 📦 patches-x.x.x.mpp       
 │    ├── 📁 Input/                  
 │    └── 📁 Output/
 ├── 📁 hoo-dles/                    (hoo-dles Workspace)
 │    ├── 📦 patches-x.x.x.mpp       
 │    ├── 📁 Input/                  
 │    └── 📁 Output/
 ├── 📁 icysymmetra/                 (icysymmetra Workspace)
 │    ├── 📦 patches-x.x.x.mpp       
 │    ├── 📁 Input/                  
 │    └── 📁 Output/
 ├── 📁 kiraio-moe/                  (kiraio-moe Workspace)
 │    ├── 📦 patches-x.x.x.mpp       
 │    ├── 📁 Input/                  
 │    └── 📁 Output/
 ├── 📁 Morphe/                      (Morphe Workspace)
 │    ├── 📦 patches-x.x.x.mpp       
 │    ├── 📁 Input/                  
 │    └── 📁 Output/
 ├── 📁 PathxmOp/                    (PathxmOp Workspace)
 │    ├── 📦 patches-x.x.x.mpp       
 │    ├── 📁 Input/                  
 │    └── 📁 Output/
 └── 📁 Piko/                        (Piko Workspace)
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
> Inside your generated `options.json`, you might notice patches like `Override certificate pinning`, `Clone app`, `Change installer source` and `Disable Play Store updates`. These are **Universal Patches** designed to work on *any* app.
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
# ajstrick81
$cfg_disneyplus_stable      = @("26.12.1+rc1-2026.07.15")
$cfg_primevideo_stable      = @("6.23.23+v15.5.0.70-armv7a")
$cfg_netflix_stable         = @("13.0.1 build 25028")
$cfg_hbomax_stable          = @("7.7.0.78", "7.5.0.73")
$cfg_peacock_stable         = @("7.6.100")
$cfg_tubi_stable            = @("10.28.5000")
$cfg_vix_stable             = @("4.47.2_tv")
$cfg_plutotv_stable         = @("5.66.0-leanback")
$cfg_paramount_stable       = @("16.17.0", "16.8.0")

# arandomhooman
$cfg_adm_stable             = @("14.0.39")
$cfg_alphaprog_stable       = @("7.1.1")
$cfg_bandlab_stable         = @("11.25.3")
$cfg_batteryguru_stable     = @("2.4.8.1", "2.5.0.2-beta1")
$cfg_cronometer_stable      = @("4.56.0")
$cfg_directchat_stable      = @("1.9.8")
$cfg_finch_stable           = @("3.73.179")
$cfg_flightradar_stable     = @("11.6.1")
$cfg_foldersync_stable      = @("4.9.3")
$cfg_inshot_stable          = @("2.214.1539")
$cfg_liquidgallery_stable   = @("2.1.11")
$cfg_poweramp_stable        = @("build-1025-bundle-play", "build-1025-uni")
$cfg_smartaudiobook_stable  = @("11.7.8")
$cfg_symfonium_stable       = @("14.1.0")
$cfg_tumblr_stable          = @("45.0.0.109")
$cfg_videoconverter_stable  = @("3.2.2")
$cfg_webtoon_stable         = @("3.9.5")

# BholeyKaBhakt
$cfg_speedtest_stable       = @("7.0.4")
$cfg_stellarium_stable      = @("1.16.3", "1.16.2")
$cfg_proto_stable           = @("1.49.0", "1.48.0")
$cfg_vpnify_stable          = @("2.2.9")
$cfg_backdrops_stable       = @("6.1.2")
$cfg_solidexplorer_stable   = @("3.4.10")

# browzomje
$cfg_pinterest_stable       = @("14.23.0", "14.28.0")
$cfg_easysudoku_stable      = @("5.70.0")

# De-ReVanced
$cfg_photos_stable          = @("Any")
$cfg_rar_stable             = @("Any")

# hoo-dles
$cfg_adguard_stable         = @("4.13.1")
$cfg_ibispaint_stable       = @("14.0.6")
$cfg_wps_stable             = @("18.24")
$cfg_camscanner_stable      = @("7.20.0.2606230000")
$cfg_sleep_stable           = @("20260526")
$cfg_duolingo_stable        = @("6.86.5")
$cfg_merriamwebster_stable  = @("Any")
$cfg_mimo_stable            = @("9.11")
$cfg_windy_stable           = @("50.1.1")
$cfg_xrecorder_stable       = @("2.5.1.1")
$cfg_xodo_stable            = @("10.15.0")

# icysymmetra
$cfg_tiktok_stable          = @("46.2.3")

# kiraio-moe
$cfg_atomic_stable          = @("4.7.0m")
$cfg_audiorelay_stable      = @("0.26.1")
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
$cfg_timestampcam_stable    = @("1.252")

# Morphe
$cfg_youtube_stable         = @("21.04.223", "20.51.39", "20.31.42", "20.21.37")
$cfg_youtube_music_stable   = @("9.15.51")
$cfg_reddit_stable          = @("2026.14.0", "2026.04.0")

# PathxmOp
$cfg_chess_stable           = @("4.10.0", "4.10.0-googleplay", "4.9.49", "4.9.49-googleplay")

# Piko
$cfg_x_stable               = @("12.11.0-release.0")
$cfg_ig_stable              = @("439.0.0.37.89")
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

**Copyright (c) 2026 chihafuyu**

Basically: you are free to use, modify, and distribute this tool for any purpose, as long as you keep the original copyright notice above. It is provided _"as is"_, without warranty of any kind. Use it at your own risk!

**Third-Party Code Attribution:**

> This tool utilizes patches and code from ajstrick81, arandomhooman, BholeyKaBhakt, browzomje, De-ReVanced, hoo-dles, icysymmetra, kiraio-moe, Morphe, PathxmOp, Piko, and inotia00. To learn more, visit [ajstrick81](https://github.com/ajstrick81/morphe-androidtv-patches/releases), [arandomhooman](https://github.com/arandomhooman/hoomans-morphe-patches/releases), [BholeyKaBhakt](https://github.com/BholeyKaBhakt/android-patches-xtra), [browzomje](https://github.com/browzomje/browzomje-patches), [De-ReVanced](https://github.com/RookieEnough/De-ReVanced), [hoo-dles](https://github.com/hoo-dles/morphe-patches), [icysymmetra](https://github.com/icysymmetra/tiktok-patches-for-morphe/releases), [kiraio-moe](https://github.com/kiraio-moe/Lain-Patches), [Morphe](https://morphe.software), [PathxmOp](https://github.com/PrathxmOp/Prathxm-Patches), [Piko](https://github.com/crimera/piko) and [inotia00](https://gitlab.com/inotia00/x-shim/).
