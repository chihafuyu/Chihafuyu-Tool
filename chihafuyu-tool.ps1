<#
.SYNOPSIS
    Chihafuyu Tool
    A comprehensive utility to automate Android app patching and manage ADB installations 
    using standard CLI patchers.

.DESCRIPTION
    Simplifies the Android application patching workflow and ADB utility operations. 
    Automates artifact discovery, enforces version validation, manages secure credentials, 
    optimizes APK size via architecture stripping, and acts as an ADB frontend for 
    both root and non-root device installations.

.AUTHOR
    chihafuyu

.LICENSE
    MIT License

    Copyright (c) 2026 chihafuyu

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
#>

#Requires -Version 5.1

if ([string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    Write-Host "Cannot determine the script root directory. Please run the script directly." -ForegroundColor Red
    exit 1
}

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

# De-Vanced
$cfg_photos_stable          = @("Any")

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

# hxreborn
$cfg_projectivy_stable      = @("Any")
$cfg_protonmail_stable      = @("7.10.4")
$cfg_symfonium_stable       = @("14.1.0")

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
$cfg_x_stable               = @("12.17.0-release.0")
$cfg_ig_stable              = @("439.0.0.37.89")

# rushiranpise
$cfg_1dot1dot1dot1_stable   = @("6.38.8")
$cfg_accubattery_stable     = @("2.1.8")
$cfg_accuweather_stable     = @("21.1.14-5-rc")
$cfg_adobescan_stable       = @("26.08.01")
$cfg_aida64_stable          = @("2.21")
$cfg_amoledpix_stable       = @("7.3")
$cfg_ampere_stable          = @("v4.37.0")
$cfg_animedepth_stable      = @("1.0.4")
$cfg_apkmirror_stable       = @("2.0.3 (41-d04e542)")
$cfg_calm_stable            = @("6.101.1")
$cfg_canva_stable           = @("5.2.1")
$cfg_colornote_stable       = @("4.8.6")
$cfg_cpuz_stable            = @("1.60")
$cfg_electron_stable        = @("3.0.3")
$cfg_holavpn_stable         = @("AARCH64_1.248.400")
$cfg_httpsniffer_stable     = @("2.11.7-ad_mob")
$cfg_inure_stable           = @("build107.2.0")
$cfg_kahoot_stable          = @("6.6.7")
$cfg_kinemaster_stable      = @("8.1.13.36552.GP")
$cfg_larkplayer_stable      = @("2026.12.5")
$cfg_life360_stable         = @("26.29.0")
$cfg_mlmanager_stable       = @("5.0")
$cfg_mobioffice_stable      = @("16.5.60515")
$cfg_netguard_stable        = @("2.337")
$cfg_networkguru_stable     = @("2.0")
$cfg_ninjavpn_stable        = @("1.4.7")
$cfg_protonvpn_stable       = @("5.19.78.0")
$cfg_proxyman_stable        = @("1.21.0")
$cfg_psiphon_stable         = @("479")
$cfg_rar_stable             = @("7.23.build134")
$cfg_sdmaid_stable          = @("1.7.5-rc0")
$cfg_stargazing_stable      = @("3.3.3")
$cfg_stickerly_stable       = @("3.36.1")
$cfg_strava_stable          = @("474.14")
$cfg_terabox_stable         = @("4.22.6")
$cfg_turboscan_stable       = @("1.7.3")
$cfg_uptodown_stable        = @("7.37")
$cfg_wallverse_stable       = @("4.2")
$cfg_waze_stable            = @("5.22.0.3")
$cfg_windscribe_stable      = @("4.2.2328")
$cfg_wolfram_stable         = @("1.0.8.20260601651")
# ==============================================================================

# Validate Java environment compliance. Morphe requires Java 25 or higher due to a Windows file lock bug.
try {
    $javaVerOutput = (& java -version 2>&1) -join "`n"
    if ($LASTEXITCODE -ne 0) { throw "Java is missing or not recognized." }
    
    $regex = '"(?:1\.)?(\d+)'
    if ($javaVerOutput -match $regex) {
        $version = [int]$Matches[1]
        if ($version -lt 25) {
            Clear-Host
            Write-Host "[!] Java Development Kit (JDK) 25 or higher is required!" -ForegroundColor Red
            Write-Host "    You currently have Java $version installed." -ForegroundColor Yellow
            Write-Host "    Please upgrade to Azul Zulu or Eclipse Temurin JDK 25 (LTS) and add it to PATH." -ForegroundColor Gray
            Write-Host "`nPress Enter to exit..." -ForegroundColor DarkGray
            $null = Read-Host
            exit 1
        }
    } else {
        throw "Cannot parse the Java version output."
    }
} catch {
    Clear-Host
    Write-Host "Java Development Kit (JDK) 25 is missing or misconfigured." -ForegroundColor Red
    Write-Host "Please install Azul Zulu or Eclipse Temurin JDK 25 (LTS) and add it to PATH." -ForegroundColor Gray
    Write-Host "`nPress Enter to exit..." -ForegroundColor DarkGray
    $null = Read-Host
    exit 1
}

function Get-ApkVersion {
    param([string]$FileName, [string[]]$AppKeywords)
    
    if ($FileName -notmatch '\.(apk|apkm|xapk|apks)$') { return $null }
    $baseName = $FileName -replace '\.(apk|apkm|xapk|apks)$', ''
    
    # Match standard versioning and 7+ digit date codes using lookarounds to bypass trailing underscores.
    $vPat = "((?<!\d)\d{7,}(?!\d)|\d+\.\d+(?:\.\d+)*(?:-(?:release|alpha|beta|rc|ripped|release-ripped)(?:\.\d+)+)?|\d+(?:[-_]\d+)+(?:-(?:release|alpha|beta|rc|ripped|release-ripped)(?:\.\d+)+)?)"
    
    $foundVersions = @()
    
    # Evaluate all keywords to ensure the highest weighted match is not skipped
    foreach ($AppKeyword in $AppKeywords) {
        # Weight-based pattern matching to isolate version strings from architecture tags.
        $patterns = @(
            @{ P = "$AppKeyword.*?[-_]$vPat(?=[-_]|$)"; W = 10 }
            @{ P = "$vPat[_-]?(?:\d+[_-])?(?:universal|arm64|v8a|x86_64|v7a|armeabi)"; W = 9 }
            @{ P = "v$vPat(?=[-_]|$)"; W = 7 }
            @{ P = "(?<!\d)$vPat(?=[-_]|$)"; W = 5 }
        )
        
        foreach ($regex in $patterns) {
            if ($baseName -match $regex.P) {
                $ext = $Matches[1]
                
                # Normalize version delimiter string from hyphens or underscores to periods.
                $ext = [regex]::Replace($ext, '(?<=\d)[-_](?=\d)', '.')
                
                $foundVersions += [PSCustomObject]@{ Ver = $ext; Weight = $regex.W }
            }
        }
    }
    
    if ($foundVersions.Count -eq 0) { return $null }
    
    # Select the absolute highest weighted regex match across all evaluated keywords.
    $best = $foundVersions | Sort-Object Weight -Descending | Select-Object -First 1
    return $best.Ver
}

function Test-IsUniversalApk {
    param([string]$ApkPath)
    $zip = $null
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction Stop
        if ([System.IO.Path]::GetExtension($ApkPath) -ne ".apk") { return $false }
        
        # Validate minimum Android package requirements directly via ZipFile header parsing.
        # This approach is significantly faster than using Expand-Archive for simple existence checks.
        $zip = [System.IO.Compression.ZipFile]::OpenRead($ApkPath)
        $hasDex = $null -ne ($zip.Entries | Where-Object Name -eq "classes.dex")
        $hasManifest = $null -ne ($zip.Entries | Where-Object FullName -eq "AndroidManifest.xml")
        
        return ($hasDex -and $hasManifest)
    } catch {
        return $true
    } finally {
        if ($null -ne $zip) { $zip.Dispose() }
    }
}

function Get-YesNoPrompt {
    param([string]$Prompt)
    while ($true) {
        # Global abort trigger allows the user to navigate back safely.
        $input = (Read-Host "$Prompt (Y/N or 'B' to go back)").Trim()
        
        if ($input -match '^[bB]$') { throw "BACK_TO_MAIN" }
        if ($input -match '^[yYnN]$') { return ($input -match '^[yY]$') }
        
        Write-Host "  Invalid input. Please enter Y, N, or B." -ForegroundColor Red
    }
}

function Read-ValidatedInput {
    param([string]$Prompt, [string]$RegexPattern, [string]$ErrorMessage)
    while ($true) {
        $input = (Read-Host "$Prompt (or 'B' to go back)").Trim()
        
        if ($input -match '^[bB]$') { throw "BACK_TO_MAIN" }
        if ($input -match $RegexPattern) { return $input }
        
        Write-Host "  $ErrorMessage" -ForegroundColor Red
    }
}

function Resolve-Ecosystem {
    Write-Host "`n[SELECT] Target Ecosystem(s):" -ForegroundColor Yellow
    Write-Host "1. ajstrick81 (Disney+, Prime Video, Netflix, HBO Max, Peacock, Tubi, ViX, Pluto TV, Paramount+)"
    Write-Host "2. arandomhooman (ADM, Alpha Progression, BandLab, Battery Guru, Cronometer, DirectChat, Finch, Flightradar24, FolderSync, InShot, Liquid Gallery, Poweramp, Smart AudioBook Player, Symfonium, Tumblr, Video Converter, WEBTOON)"
    Write-Host "3. BholeyKaBhakt (Speedtest, Stellarium, PROTO, vpnify, Backdrops, Solid Explorer)"
    Write-Host "4. browzomje (Pinterest, Easy Sudoku)"
    Write-Host "5. De-Vanced (Google Photos)"
    Write-Host "6. hoo-dles (AdGuard, IbisPaint X, WPS Office, Duolingo, Merriam-Webster, Windy, Mimo, XRecorder, CamScanner, Sleep as Android, Xodo)"
    Write-Host "7. hxreborn (Projectivy Launcher, Proton Mail, Symfonium)"
    Write-Host "8. icysymmetra (TikTok Global)"
    Write-Host "9. kiraio-moe (Atomic, AudioRelay, Boorusama, Epic!, Fake GPS, Hermit, Hidden Settings, iLovePDF, Key Mapper, Keymate, Manga Plus, Nekopoi, PixelLab, Timestamp Camera)"
    Write-Host "10. Morphe (YouTube, YT Music, Reddit)"
    Write-Host "11. PathxmOp (Chess.com)"
    Write-Host "12. Piko (X/Twitter, Instagram)"
    Write-Host "13. rushiranpise (1.1.1.1, AccuBattery, AccuWeather, Adobe Scan, AIDA64, AmoledPix, Ampere, Anime Depth Wallpapers, APKMirror Installer, Calm: Sleep & Meditation, Canva, ColorNote, CPU-Z, Electron, Hola VPN Proxy Plus, HTTP Sniffer, Inure App Manager, Kahoot!, KineMaster, Lark Player, Life360, ML Manager, MobiOffice, NetGuard, Network Guru, Ninja VPN, Proton VPN, Proxyman, Psiphon Pro, RAR, SD Maid SE, Stargazing Hub, Sticker.ly, Strava, TeraBox, TurboScan, Uptodown App Store, Wallverse, Waze, Windscribe VPN, WolframAlpha)"
    
    $ecoChoice = Read-ValidatedInput -Prompt "Enter choice(s) [e.g., 1, 2, or 1,2,13]" -RegexPattern "^(1[0-3]|[1-9])(,(1[0-3]|[1-9]))*$" -ErrorMessage "Invalid input. Enter numbers 1-13 separated by commas."

    $choices = $ecoChoice.Split(',') | Select-Object -Unique
    $ecosystems = @()

    foreach ($c in $choices) {
        $projectName = switch ($c) {
            "1"  { "ajstrick81" }
            "2"  { "arandomhooman" }
            "3"  { "BholeyKaBhakt" }
            "4"  { "browzomje" }
            "5"  { "De-Vanced" }
            "6"  { "hoo-dles" }
            "7"  { "hxreborn" }
            "8"  { "icysymmetra" }
            "9"  { "kiraio-moe" }
            "10" { "Morphe" }
            "11" { "PathxmOp" }
            "12" { "Piko" }
            "13" { "rushiranpise" }
        }
        
        $workspace = Join-Path $PSScriptRoot $projectName

        # Scaffold workspace directories if they do not exist.
        if (-not (Test-Path -LiteralPath $workspace)) {
            New-Item -ItemType Directory -Path $workspace -Force | Out-Null
            Write-Host "  -> Created new workspace: .\$projectName" -ForegroundColor Green
        }
        
        foreach ($dir in @("Input", "Output")) {
            $dirPath = Join-Path $workspace $dir
            if (-not (Test-Path -LiteralPath $dirPath)) { New-Item -ItemType Directory -Path $dirPath -Force | Out-Null }
        }
        
        $ecosystems += @{ Name = $projectName; Workspace = $workspace }
    }

    return $ecosystems
}

function Resolve-EnvironmentArtifacts {
    param([string]$Workspace, [string]$ProjectName, [bool]$RequirePatches)
    
    # Push-Location preserves the original root path to prevent terminal drift.
    Push-Location -LiteralPath $Workspace -ErrorAction Stop

    try {
        # Scan for `morphe-desktop` executables.
        # PadLeft regex injection prevents semantic versioning sorting flaws (e.g., v10 resolving before v9).
        $cliStableSearch = Get-ChildItem -Path "..\morphe-desktop-*-all.jar", ".\morphe-desktop-*-all.jar" -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch "-dev" } | Sort-Object { [regex]::Replace($_.Name, '\d+', { $args[0].Value.PadLeft(4, '0') }) } -Descending | Select-Object -First 1
        $cliDevSearch = Get-ChildItem -Path "..\morphe-desktop-*-dev.*-all.jar", ".\morphe-desktop-*-dev.*-all.jar" -File -ErrorAction SilentlyContinue | Sort-Object { [regex]::Replace($_.Name, '\d+', { $args[0].Value.PadLeft(4, '0') }) } -Descending | Select-Object -First 1

        $cliStableDisplay = if ($cliStableSearch) { "[$($cliStableSearch.Name)]" } else { "[Not Found]" }
        $cliDevDisplay = if ($cliDevSearch) { "[$($cliDevSearch.Name)]" } else { "[Not Found]" }

        Write-Host "`n[SELECT] Morphe Desktop Environment ($ProjectName):" -ForegroundColor Yellow
        Write-Host -NoNewline "1. Latest Stable Release "
        if ($cliStableDisplay -eq "[Not Found]") { Write-Host $cliStableDisplay -ForegroundColor Red } else { Write-Host $cliStableDisplay -ForegroundColor Green }
        Write-Host -NoNewline "2. Latest Pre-release "
        if ($cliDevDisplay -eq "[Not Found]") { Write-Host $cliDevDisplay -ForegroundColor Red } else { Write-Host $cliDevDisplay -ForegroundColor Green }
        
        $cliChoice = Read-ValidatedInput -Prompt "Enter choice (1 or 2)" -RegexPattern "^[12]$" -ErrorMessage "Invalid input."

        $patchesChoice = "1"
        $extraPatches = @()
        if ($RequirePatches) {
            $patchStableSearch = Get-ChildItem -Path ".\patches-*.mpp" -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch "-dev" } | Sort-Object { [regex]::Replace($_.Name, '\d+', { $args[0].Value.PadLeft(4, '0') }) } -Descending | Select-Object -First 1
            $patchDevSearch = Get-ChildItem -Path ".\patches-*-dev.*.mpp" -File -ErrorAction SilentlyContinue | Sort-Object { [regex]::Replace($_.Name, '\d+', { $args[0].Value.PadLeft(4, '0') }) } -Descending | Select-Object -First 1

            $patchStableDisplay = if ($patchStableSearch) { "[$($patchStableSearch.Name)]" } else { "[Not Found]" }
            $patchDevDisplay = if ($patchDevSearch) { "[$($patchDevSearch.Name)]" } else { "[Not Found]" }

            Write-Host "`n[SELECT] Patches Environment ($ProjectName):" -ForegroundColor Yellow
            Write-Host -NoNewline "1. Latest Stable Patches "
            if ($patchStableDisplay -eq "[Not Found]") { Write-Host $patchStableDisplay -ForegroundColor Red } else { Write-Host $patchStableDisplay -ForegroundColor Green }
            Write-Host -NoNewline "2. Latest Pre-release Patches "
            if ($patchDevDisplay -eq "[Not Found]") { Write-Host $patchDevDisplay -ForegroundColor Red } else { Write-Host $patchDevDisplay -ForegroundColor Green }
            
            $patchesChoice = Read-ValidatedInput -Prompt "Enter choice (1 or 2)" -RegexPattern "^[12]$" -ErrorMessage "Invalid input."
        }

        $cliJar = if ($cliChoice -eq "1") { $cliStableSearch } else { $cliDevSearch }
        $patchesFile = $null
        
        if ($RequirePatches) {
            $patchesFile = if ($patchesChoice -eq "1") { $patchStableSearch } else { $patchDevSearch }
            
            # Discover secondary/shim companion patches implicitly based on nomenclature.
            if ($patchesFile) {
                $extraPatches = Get-ChildItem -Path ".\*.mpp" -File -ErrorAction SilentlyContinue | Where-Object { $_.FullName -ne $patchesFile.FullName -and $_.Name -match "shim" }
            }
        }

        # Execute polling loop with a 5-minute timeout if required files are absent.
        if (-not $cliJar -or ($RequirePatches -and -not $patchesFile)) {
            Write-Host "`n[!] Required environment artifacts are missing!" -ForegroundColor Red
            if (-not $cliJar) { Write-Host "  - Missing Morphe Desktop (.jar) in the Root or .\$ProjectName directory." -ForegroundColor Yellow }
            if ($RequirePatches -and -not $patchesFile) { Write-Host "  - Missing Patches (.mpp) in the .\$ProjectName directory." -ForegroundColor Yellow }
            
            Write-Host "`nWaiting for the missing files to be placed... (Press CTRL+C to abort)" -ForegroundColor Cyan
            
            $cliPrefix = if ($cliChoice -eq "1") { "morphe-desktop-*-all.jar" } else { "morphe-desktop-*-dev.*-all.jar" }
            $patchPrefix = if ($patchesChoice -eq "1") { "patches-*.mpp" } else { "patches-*-dev.*.mpp" }

            $timeout = (Get-Date).AddMinutes(5)
            while (-not $cliJar -or ($RequirePatches -and -not $patchesFile)) {
                if ((Get-Date) -gt $timeout) { throw "Timeout reached. Aborting wait for environment artifacts." }
                Start-Sleep -Seconds 2
                
                $cliJar = Get-ChildItem -Path "..\$cliPrefix", ".\$cliPrefix" -File -ErrorAction SilentlyContinue | Where-Object { ($cliChoice -eq "2") -or ($_.Name -notmatch "-dev") } | Sort-Object { [regex]::Replace($_.Name, '\d+', { $args[0].Value.PadLeft(4, '0') }) } -Descending | Select-Object -First 1
                if ($RequirePatches) {
                    $patchesFile = Get-ChildItem -Path ".\$patchPrefix" -File -ErrorAction SilentlyContinue | Where-Object { ($patchesChoice -eq "2") -or ($_.Name -notmatch "-dev") } | Sort-Object { [regex]::Replace($_.Name, '\d+', { $args[0].Value.PadLeft(4, '0') }) } -Descending | Select-Object -First 1
                    if ($patchesFile) {
                        $extraPatches = Get-ChildItem -Path ".\*.mpp" -File -ErrorAction SilentlyContinue | Where-Object { $_.FullName -ne $patchesFile.FullName -and $_.Name -match "shim" }
                    }
                }
            }
            Write-Host "  [✓] Required artifacts found! Resuming process..." -ForegroundColor Green
        }

        $patchTrack = if ($patchesChoice -eq "1") { "stable" } else { "dev" }

        if ($cliChoice -eq "2" -or ($RequirePatches -and $patchesChoice -eq "2")) {
            Write-Host "`n[WARNING] Pre-Release Environment Detected for $ProjectName" -ForegroundColor Yellow
            if (-not (Get-YesNoPrompt "Proceed with the pre-release track?")) { return $null }
        }
        
        return @{ Cli = $cliJar; Patches = $patchesFile; ExtraPatches = $extraPatches; Track = $patchTrack }
    } finally {
        Pop-Location
    }
}

function Invoke-PatchingWorkflow {
    Clear-Host
    Write-Host "==============================================" -ForegroundColor Cyan
    Write-Host "          CHIHAFUYU TOOL - PATCHING           " -ForegroundColor Cyan
    Write-Host "==============================================" -ForegroundColor Cyan
    
    $ecosystems = Resolve-Ecosystem
    if (-not $ecosystems) { return }

    $batchJobs = @()

    # PHASE 1: Build the execution queue per ecosystem.
    foreach ($eco in $ecosystems) {
        $projectName = $eco.Name; $workspace = $eco.Workspace
        
        Write-Host "`n==============================================" -ForegroundColor Magenta
        Write-Host "       PREPARING ECOSYSTEM: $($projectName.ToUpper())" -ForegroundColor Magenta
        Write-Host "==============================================" -ForegroundColor Magenta

        $envArt = Resolve-EnvironmentArtifacts -Workspace $workspace -ProjectName $projectName -RequirePatches $true
        if (-not $envArt) { 
            Write-Host "  [!] Skipping $projectName due to aborted artifact selection." -ForegroundColor Red
            continue 
        }

        Write-Host "`n[+] Select Target Application(s):" -ForegroundColor Yellow
        
        if ($projectName -eq "ajstrick81") {
            Write-Host "1. Disney+"
            Write-Host "2. Prime Video"
            Write-Host "3. Netflix"
            Write-Host "4. HBO Max"
            Write-Host "5. Peacock"
            Write-Host "6. Tubi"
            Write-Host "7. ViX"
            Write-Host "8. Pluto TV"
            Write-Host "9. Paramount+"
            Write-Host "10. All Applications"
            $appSelection = Read-ValidatedInput -Prompt "Enter choice(s) [e.g., 1, 3, or 10]" -RegexPattern "^(10|[1-9])(,(10|[1-9]))*$" -ErrorMessage "Invalid input. Enter numbers 1-10 separated by commas."
            
            $masterApps = @(
                @{ id = "1"; name = "DisneyPlus"; package = "com.disney.disneyplus"; keys = @("disney", "disneyplus"); exclude = @(); strip = $true; stable = $cfg_disneyplus_stable },
                @{ id = "2"; name = "Prime_Video"; package = "com.amazon.amazonvideo.livingroom"; keys = @("prime", "amazonvideo", "livingroom"); exclude = @(); strip = $true; stable = $cfg_primevideo_stable },
                @{ id = "3"; name = "Netflix"; package = "com.netflix.ninja"; keys = @("netflix", "ninja"); exclude = @(); strip = $true; stable = $cfg_netflix_stable },
                @{ id = "4"; name = "HBO_Max"; package = "com.wbd.hbomax"; keys = @("hbo", "max", "hbomax"); exclude = @(); strip = $true; stable = $cfg_hbomax_stable },
                @{ id = "5"; name = "Peacock"; package = "com.peacocktv.peacockandroid"; keys = @("peacock"); exclude = @(); strip = $true; stable = $cfg_peacock_stable },
                @{ id = "6"; name = "Tubi"; package = "com.tubitv"; keys = @("tubi"); exclude = @(); strip = $true; stable = $cfg_tubi_stable },
                @{ id = "7"; name = "ViX"; package = "com.univision.prendetv"; keys = @("vix", "univision", "prendetv"); exclude = @(); strip = $true; stable = $cfg_vix_stable },
                @{ id = "8"; name = "Pluto_TV"; package = "tv.pluto.android"; keys = @("pluto"); exclude = @(); strip = $true; stable = $cfg_plutotv_stable },
                @{ id = "9"; name = "ParamountPlus"; package = "com.cbs.ott"; keys = @("paramount", "cbs", "ott"); exclude = @(); strip = $true; stable = $cfg_paramount_stable }
            )
        } elseif ($projectName -eq "arandomhooman") {
            Write-Host "1. Advanced Download Manager"
            Write-Host "2. Alpha Progression"
            Write-Host "3. BandLab"
            Write-Host "4. Battery Guru"
            Write-Host "5. Cronometer"
            Write-Host "6. DirectChat"
            Write-Host "7. Finch"
            Write-Host "8. Flightradar24"
            Write-Host "9. FolderSync"
            Write-Host "10. InShot"
            Write-Host "11. Liquid Gallery"
            Write-Host "12. Poweramp"
            Write-Host "13. Smart AudioBook Player"
            Write-Host "14. Symfonium"
            Write-Host "15. Tumblr"
            Write-Host "16. Video Converter [arm64-v8a only]"
            Write-Host "17. WEBTOON"
            Write-Host "18. All Applications"
            $appSelection = Read-ValidatedInput -Prompt "Enter choice(s) [e.g., 1, 16, or 18]" -RegexPattern "^(1[0-8]|[1-9])(,(1[0-8]|[1-9]))*$" -ErrorMessage "Invalid input. Enter numbers 1-18 separated by commas."
            
            $masterApps = @(
                @{ id = "1"; name = "Advanced_Download_Manager"; package = "com.dv.adm"; keys = @("adm", "advanced_download_manager"); exclude = @(); strip = $true; stable = $cfg_adm_stable },
                @{ id = "2"; name = "Alpha_Progression"; package = "com.alphaprogression.alphaprogression"; keys = @("alphaprogression"); exclude = @(); strip = $true; stable = $cfg_alphaprog_stable },
                @{ id = "3"; name = "BandLab"; package = "com.bandlab.bandlab"; keys = @("bandlab"); exclude = @(); strip = $true; stable = $cfg_bandlab_stable },
                @{ id = "4"; name = "Battery_Guru"; package = "com.paget96.batteryguru"; keys = @("batteryguru", "battery_guru"); exclude = @(); strip = $true; stable = $cfg_batteryguru_stable },
                @{ id = "5"; name = "Cronometer"; package = "com.cronometer.android.gold"; keys = @("cronometer"); exclude = @(); strip = $true; stable = $cfg_cronometer_stable },
                @{ id = "6"; name = "DirectChat"; package = "net.uniquegem.directchat"; keys = @("directchat"); exclude = @(); strip = $true; stable = $cfg_directchat_stable },
                @{ id = "7"; name = "Finch"; package = "com.finch.finch"; keys = @("finch"); exclude = @(); strip = $true; stable = $cfg_finch_stable },
                @{ id = "8"; name = "Flightradar24"; package = "com.flightradar24free"; keys = @("flightradar24"); exclude = @(); strip = $true; stable = $cfg_flightradar_stable },
                @{ id = "9"; name = "FolderSync"; package = "dk.tacit.android.foldersync.lite"; keys = @("foldersync"); exclude = @(); strip = $true; stable = $cfg_foldersync_stable },
                @{ id = "10"; name = "InShot"; package = "com.camerasideas.instashot"; keys = @("inshot"); exclude = @(); strip = $true; stable = $cfg_inshot_stable },
                @{ id = "11"; name = "Liquid_Gallery"; package = "com.soepic.photogallery.release"; keys = @("liquidgallery", "liquid_gallery"); exclude = @(); strip = $true; stable = $cfg_liquidgallery_stable },
                @{ id = "12"; name = "Poweramp"; package = "com.maxmpz.audioplayer"; keys = @("poweramp"); exclude = @(); strip = $true; stable = $cfg_poweramp_stable },
                @{ id = "13"; name = "Smart_AudioBook_Player"; package = "ak.alizandro.smartaudiobookplayer"; keys = @("smartaudiobookplayer", "smart_audiobook_player"); exclude = @(); strip = $true; stable = $cfg_smartaudiobook_stable },
                @{ id = "14"; name = "Symfonium"; package = "app.symfonik.music.player"; keys = @("symfonium"); exclude = @(); strip = $true; stable = $cfg_symfonium_stable },
                @{ id = "15"; name = "Tumblr"; package = "com.tumblr"; keys = @("tumblr"); exclude = @(); strip = $true; stable = $cfg_tumblr_stable },
                @{ id = "16"; name = "Video_Converter"; package = "app.remux.video.converter"; keys = @("videoconverter", "video_converter", "remux"); exclude = @(); strip = $true; stable = $cfg_videoconverter_stable },
                @{ id = "17"; name = "WEBTOON"; package = "com.naver.linewebtoon"; keys = @("webtoon", "linewebtoon"); exclude = @(); strip = $true; stable = $cfg_webtoon_stable }
            )
        } elseif ($projectName -eq "BholeyKaBhakt") {
            Write-Host "1. Speedtest"
            Write-Host "2. Stellarium"
            Write-Host "3. PROTO"
            Write-Host "4. vpnify"
            Write-Host "5. Backdrops"
            Write-Host "6. Solid Explorer"
            Write-Host "7. All Applications"
            $appSelection = Read-ValidatedInput -Prompt "Enter choice(s) [e.g., 1, 2, or 7]" -RegexPattern "^[1-7](,[1-7])*$" -ErrorMessage "Invalid input. Enter numbers 1-7 separated by commas."
            
            $masterApps = @(
                @{ id = "1"; name = "Speedtest"; package = "org.zwanoo.android.speedtest"; keys = @("speedtest"); exclude = @(); strip = $true; stable = $cfg_speedtest_stable },
                @{ id = "2"; name = "Stellarium"; package = "com.noctuasoftware.stellarium_free"; keys = @("stellarium"); exclude = @(); strip = $true; stable = $cfg_stellarium_stable },
                @{ id = "3"; name = "PROTO"; package = "com.proto.circuitsimulator"; keys = @("proto", "circuit", "simulator"); exclude = @(); strip = $true; stable = $cfg_proto_stable },
                @{ id = "4"; name = "vpnify"; package = "com.vpn.free.hotspot.secure.vpnify"; keys = @("vpnify"); exclude = @(); strip = $true; stable = $cfg_vpnify_stable },
                @{ id = "5"; name = "Backdrops"; package = "com.backdrops.wallpapers"; keys = @("backdrops"); exclude = @(); strip = $true; stable = $cfg_backdrops_stable },
                @{ id = "6"; name = "Solid_Explorer"; package = "pl.solidexplorer2"; keys = @("solid", "explorer"); exclude = @(); strip = $true; stable = $cfg_solidexplorer_stable }
            )
        } elseif ($projectName -eq "browzomje") {
            Write-Host "1. Pinterest"
            Write-Host "2. Easy Sudoku"
            Write-Host "3. All Applications"
            $appSelection = Read-ValidatedInput -Prompt "Enter choice(s) [e.g., 1, 2, or 3]" -RegexPattern "^[1-3](,[1-3])*$" -ErrorMessage "Invalid input. Enter numbers 1-3 separated by commas."
            
            $masterApps = @(
                @{ id = "1"; name = "Pinterest"; package = "com.pinterest"; keys = @("pinterest"); exclude = @(); strip = $true; stable = $cfg_pinterest_stable },
                @{ id = "2"; name = "Easy_Sudoku"; package = "easy.sudoku.puzzle.solver.free"; keys = @("easysudoku", "sudoku"); exclude = @(); strip = $true; stable = $cfg_easysudoku_stable }
            )
        } elseif ($projectName -eq "De-Vanced") {
            Write-Host "1. Google Photos"
            Write-Host "2. All Applications"
            $appSelection = Read-ValidatedInput -Prompt "Enter choice(s) [e.g., 1 or 2]" -RegexPattern "^[1-2](,[1-2])*$" -ErrorMessage "Invalid input. Enter numbers 1-2 separated by commas."
            
            $masterApps = @(
                @{ id = "1"; name = "Google_Photos"; package = "com.google.android.apps.photos"; keys = @("photos"); exclude = @(); strip = $true; stable = $cfg_photos_stable }
            )
        } elseif ($projectName -eq "hoo-dles") {
            Write-Host "1. AdGuard"
            Write-Host "2. IbisPaint X"
            Write-Host "3. WPS Office"
            Write-Host "4. CamScanner"
            Write-Host "5. Sleep as Android"
            Write-Host "6. Duolingo"
            Write-Host "7. Merriam-Webster"
            Write-Host "8. Mimo"
            Write-Host "9. Windy"
            Write-Host "10. XRecorder"
            Write-Host "11. Xodo"
            Write-Host "12. All Applications"
            $appSelection = Read-ValidatedInput -Prompt "Enter choice(s) [e.g., 1, 2, or 12]" -RegexPattern "^(1[0-2]|[1-9])(,(1[0-2]|[1-9]))*$" -ErrorMessage "Invalid input. Enter numbers 1-12 separated by commas."
            
            $masterApps = @(
                @{ id = "1"; name = "AdGuard"; package = "com.adguard.android"; keys = @("adguard"); exclude = @(); strip = $true; stable = $cfg_adguard_stable },
                @{ id = "2"; name = "IbisPaint_X"; package = "jp.ne.ibis.ibispaintx.app"; keys = @("ibispaint", "ibis", "ibis-paint"); exclude = @(); strip = $true; stable = $cfg_ibispaint_stable },
                @{ id = "3"; name = "WPS_Office"; package = "cn.wps.moffice_eng"; keys = @("wps", "moffice"); exclude = @(); strip = $true; stable = $cfg_wps_stable },
                @{ id = "4"; name = "CamScanner"; package = "com.intsig.camscanner"; keys = @("camscanner"); exclude = @(); strip = $true; stable = $cfg_camscanner_stable },
                @{ id = "5"; name = "Sleep_as_Android"; package = "com.urbandroid.sleep"; keys = @("sleep", "urbandroid"); exclude = @(); strip = $true; stable = $cfg_sleep_stable },
                @{ id = "6"; name = "Duolingo"; package = "com.duolingo"; keys = @("duolingo"); exclude = @(); strip = $true; stable = $cfg_duolingo_stable },
                @{ id = "7"; name = "Merriam_Webster"; package = "com.merriamwebster"; keys = @("merriam", "webster", "merriamwebster"); exclude = @(); strip = $true; stable = $cfg_merriamwebster_stable },
                @{ id = "8"; name = "Mimo"; package = "com.getmimo"; keys = @("mimo"); exclude = @(); strip = $true; stable = $cfg_mimo_stable },
                @{ id = "9"; name = "Windy"; package = "com.windyty.android"; keys = @("windy", "windyty"); exclude = @(); strip = $true; stable = $cfg_windy_stable },
                @{ id = "10"; name = "XRecorder"; package = "videoeditor.videorecorder.screenrecorder"; keys = @("xrecorder", "screenrecorder"); exclude = @(); strip = $true; stable = $cfg_xrecorder_stable },
                @{ id = "11"; name = "Xodo"; package = "com.xodo.pdf.reader"; keys = @("xodo"); exclude = @(); strip = $true; stable = $cfg_xodo_stable }
            )
        } elseif ($projectName -eq "hxreborn") {
            Write-Host "1. Projectivy Launcher"
            Write-Host "2. Proton Mail"
            Write-Host "3. Symfonium"
            Write-Host "4. All Applications"
            $appSelection = Read-ValidatedInput -Prompt "Enter choice(s) [e.g., 1, 2, or 4]" -RegexPattern "^[1-4](,[1-4])*$" -ErrorMessage "Invalid input. Enter numbers 1-4 separated by commas."
            
            $masterApps = @(
                @{ id = "1"; name = "Projectivy_Launcher"; package = "com.spocky.projengmenu"; keys = @("projectivy", "projengmenu"); exclude = @(); strip = $true; stable = $cfg_projectivy_stable },
                @{ id = "2"; name = "Proton_Mail"; package = "ch.protonmail.android"; keys = @("proton", "protonmail"); exclude = @("vpn"); strip = $true; stable = $cfg_protonmail_stable },
                @{ id = "3"; name = "Symfonium"; package = "app.symfonik.music.player"; keys = @("symfonium"); exclude = @(); strip = $true; stable = $cfg_symfonium_stable }
            )
        } elseif ($projectName -eq "icysymmetra") {
            Write-Host "1. TikTok Global"
            Write-Host "2. All Applications"
            $appSelection = Read-ValidatedInput -Prompt "Enter choice(s) [e.g., 1 or 2]" -RegexPattern "^[1-2](,[1-2])*$" -ErrorMessage "Invalid input. Enter numbers 1-2 separated by commas."
            
            $masterApps = @(
                @{ id = "1"; name = "TikTok"; package = "com.zhiliaoapp.musically"; keys = @("tiktok", "musically"); exclude = @(); strip = $true; stable = $cfg_tiktok_stable }
            )
        } elseif ($projectName -eq "kiraio-moe") {
            Write-Host "1. Atomic"
            Write-Host "2. AudioRelay"
            Write-Host "3. Boorusama"
            Write-Host "4. Epic!"
            Write-Host "5. Fake GPS Location"
            Write-Host "6. Hermit"
            Write-Host "7. Hidden Settings"
            Write-Host "8. iLovePDF"
            Write-Host "9. Key Mapper"
            Write-Host "10. Keymate"
            Write-Host "11. Manga Plus"
            Write-Host "12. Nekopoi [21+]"
            Write-Host "13. PixelLab"
            Write-Host "14. Timestamp Camera Free"
            Write-Host "15. All Applications"
            $appSelection = Read-ValidatedInput -Prompt "Enter choice(s) [e.g., 1, 12, or 15]" -RegexPattern "^(1[0-5]|[1-9])(,(1[0-5]|[1-9]))*$" -ErrorMessage "Invalid input. Enter numbers 1-15 separated by commas."
            
            $masterApps = @(
                @{ id = "1"; name = "Atomic"; package = "com.jlindemann.science"; keys = @("atomic", "science"); exclude = @(); strip = $true; stable = $cfg_atomic_stable },
                @{ id = "2"; name = "AudioRelay"; package = "com.azefsw.audioconnect"; keys = @("audiorelay"); exclude = @(); strip = $true; stable = $cfg_audiorelay_stable },
                @{ id = "3"; name = "Boorusama"; package = "com.degenk.boorusama"; keys = @("boorusama"); exclude = @(); strip = $true; stable = $cfg_boorusama_stable },
                @{ id = "4"; name = "Epic"; package = "com.getepic.Epic"; keys = @("epic"); exclude = @(); strip = $true; stable = $cfg_epic_stable },
                @{ id = "5"; name = "Fake_GPS_Location"; package = "com.hopefactory2021.fakegpslocation"; keys = @("fakegps", "fake-gps"); exclude = @(); strip = $true; stable = $cfg_fakegps_stable },
                @{ id = "6"; name = "Hermit"; package = "com.chimbori.hermitcrab"; keys = @("hermit"); exclude = @(); strip = $true; stable = $cfg_hermit_stable },
                @{ id = "7"; name = "Hidden_Settings"; package = "com.ceyhan.sets"; keys = @("hidden", "sets"); exclude = @(); strip = $true; stable = $cfg_hiddensets_stable },
                @{ id = "8"; name = "iLovePDF"; package = "com.ilovepdf.www"; keys = @("ilovepdf"); exclude = @(); strip = $true; stable = $cfg_ilovepdf_stable },
                @{ id = "9"; name = "Key_Mapper"; package = "io.github.sds100.keymapper"; keys = @("keymapper", "key-mapper"); exclude = @(); strip = $true; stable = $cfg_keymapper_stable },
                @{ id = "10"; name = "Keymate"; package = "net.nemostudio.keymate"; keys = @("keymate"); exclude = @(); strip = $true; stable = $cfg_keymate_stable },
                @{ id = "11"; name = "Manga_Plus"; package = "jp.co.shueisha.mangaplus"; keys = @("mangaplus", "manga-plus"); exclude = @(); strip = $true; stable = $cfg_mangaplus_stable },
                @{ id = "12"; name = "Nekopoi"; package = "com.kcstream.cing"; keys = @("nekopoi", "cing", "^app\d{5}"); exclude = @(); strip = $true; stable = $cfg_nekopoi_stable },
                @{ id = "13"; name = "PixelLab"; package = "com.imaginstudio.imagetools.pixellab"; keys = @("pixellab"); exclude = @(); strip = $true; stable = $cfg_pixellab_stable },
                @{ id = "14"; name = "Timestamp_Camera"; package = "com.jeyluta.timestampcamerafree"; keys = @("timestamp"); exclude = @(); strip = $true; stable = $cfg_timestampcam_stable }
            )
        } elseif ($projectName -eq "Morphe") {
            Write-Host "1. YouTube`n2. YouTube Music`n3. Reddit`n4. All Applications"
            $appSelection = Read-ValidatedInput -Prompt "Enter choice(s) [e.g., 1, 2, or 4]" -RegexPattern "^[1-4](,[1-4])*$" -ErrorMessage "Invalid input. Enter numbers 1-4 separated by commas."
            
            $masterApps = @(
                @{ id = "1"; name = "YouTube"; package = "com.google.android.youtube"; keys = @("youtube"); exclude = @("music"); strip = $true; stable = $cfg_youtube_stable },
                @{ id = "2"; name = "YouTube_Music"; package = "com.google.android.apps.youtube.music"; keys = @("music", "ytmusic"); exclude = @(); strip = $true; stable = $cfg_youtube_music_stable },
                @{ id = "3"; name = "Reddit"; package = "com.reddit.frontpage"; keys = @("reddit"); exclude = @(); strip = $true; stable = $cfg_reddit_stable }
            )
        } elseif ($projectName -eq "PathxmOp") {
            Write-Host "1. Chess.com"
            Write-Host "2. All Applications"
            $appSelection = Read-ValidatedInput -Prompt "Enter choice(s) [e.g., 1 or 2]" -RegexPattern "^[1-2](,[1-2])*$" -ErrorMessage "Invalid input. Enter numbers 1-2 separated by commas."
            
            $masterApps = @(
                @{ id = "1"; name = "Chess"; package = "com.chess"; keys = @("chess", "^\d{6,8}(?=_)"); exclude = @(); strip = $true; stable = $cfg_chess_stable }
            )
        } elseif ($projectName -eq "Piko") {
            Write-Host "1. X (Twitter)`n2. Instagram`n3. All Applications"
            $appSelection = Read-ValidatedInput -Prompt "Enter choice(s) [e.g., 1, 2, or 3]" -RegexPattern "^[1-3](,[1-3])*$" -ErrorMessage "Invalid input. Enter numbers 1-3 separated by commas."
            
            $masterApps = @(
                @{ id = "1"; name = "X_Twitter"; package = "com.twitter.android"; keys = @("twitter", "x"); exclude = @(); strip = $true; stable = $cfg_x_stable },
                @{ id = "2"; name = "Instagram"; package = "com.instagram.android"; keys = @("instagram", "ig"); exclude = @(); strip = $true; stable = $cfg_ig_stable }
            )
        } elseif ($projectName -eq "rushiranpise") {
            Write-Host "1. 1.1.1.1"
            Write-Host "2. AccuBattery"
            Write-Host "3. AccuWeather"
            Write-Host "4. Adobe Scan"
            Write-Host "5. AIDA64"
            Write-Host "6. AmoledPix"
            Write-Host "7. Ampere"
            Write-Host "8. Anime Depth Wallpapers"
            Write-Host "9. APKMirror Installer"
            Write-Host "10. Calm: Sleep & Meditation"
            Write-Host "11. Canva"
            Write-Host "12. ColorNote"
            Write-Host "13. CPU-Z"
            Write-Host "14. Electron"
            Write-Host "15. Hola VPN Proxy Plus"
            Write-Host "16. HTTP Sniffer"
            Write-Host "17. Inure App Manager"
            Write-Host "18. Kahoot!"
            Write-Host "19. KineMaster"
            Write-Host "20. Lark Player"
            Write-Host "21. Life360"
            Write-Host "22. ML Manager"
            Write-Host "23. MobiOffice"
            Write-Host "24. NetGuard"
            Write-Host "25. Network Guru"
            Write-Host "26. Ninja VPN"
            Write-Host "27. Proton VPN"
            Write-Host "28. Proxyman"
            Write-Host "29. Psiphon Pro"
            Write-Host "30. RAR"
            Write-Host "31. SD Maid SE"
            Write-Host "32. Stargazing Hub"
            Write-Host "33. Sticker.ly"
            Write-Host "34. Strava"
            Write-Host "35. TeraBox"
            Write-Host "36. TurboScan"
            Write-Host "37. Uptodown App Store"
            Write-Host "38. Wallverse"
            Write-Host "39. Waze"
            Write-Host "40. Windscribe VPN"
            Write-Host "41. WolframAlpha"
            Write-Host "42. All Applications"
            $appSelection = Read-ValidatedInput -Prompt "Enter choice(s) [e.g., 1, 30, or 42]" -RegexPattern "^(4[0-2]|[1-3][0-9]|[1-9])(,(4[0-2]|[1-3][0-9]|[1-9]))*$" -ErrorMessage "Invalid input. Enter numbers 1-42 separated by commas."
            
            $masterApps = @(
                @{ id = "1"; name = "1dot1dot1dot1"; package = "com.cloudflare.onedotonedotonedotone"; keys = @("1.1.1.1", "cloudflare", "onedot"); exclude = @(); strip = $true; stable = $cfg_1dot1dot1dot1_stable },
                @{ id = "2"; name = "AccuBattery"; package = "com.digibites.accubattery"; keys = @("accubattery"); exclude = @(); strip = $true; stable = $cfg_accubattery_stable },
                @{ id = "3"; name = "AccuWeather"; package = "com.accuweather.android"; keys = @("accuweather"); exclude = @(); strip = $true; stable = $cfg_accuweather_stable },
                @{ id = "4"; name = "Adobe_Scan"; package = "com.adobe.scan.android"; keys = @("adobe", "scan"); exclude = @(); strip = $true; stable = $cfg_adobescan_stable },
                @{ id = "5"; name = "AIDA64"; package = "com.finalwire.aida64"; keys = @("aida64"); exclude = @(); strip = $true; stable = $cfg_aida64_stable },
                @{ id = "6"; name = "AmoledPix"; package = "com.androholic.amoledpix"; keys = @("amoledpix"); exclude = @(); strip = $true; stable = $cfg_amoledpix_stable },
                @{ id = "7"; name = "Ampere"; package = "com.gombosdev.ampere"; keys = @("ampere"); exclude = @(); strip = $true; stable = $cfg_ampere_stable },
                @{ id = "8"; name = "Anime_Depth_Wallpapers"; package = "com.jndapp.anime.depth.live.wallpaper"; keys = @("anime", "depth", "wallpaper"); exclude = @(); strip = $true; stable = $cfg_animedepth_stable },
                @{ id = "9"; name = "APKMirror_Installer"; package = "com.apkmirror.helper.prod"; keys = @("apkmirror", "installer", "helper"); exclude = @(); strip = $true; stable = $cfg_apkmirror_stable },
                @{ id = "10"; name = "Calm"; package = "com.calm.android"; keys = @("calm"); exclude = @(); strip = $true; stable = $cfg_calm_stable },
                @{ id = "11"; name = "Canva"; package = "com.canva.editor"; keys = @("canva"); exclude = @(); strip = $true; stable = $cfg_canva_stable },
                @{ id = "12"; name = "ColorNote"; package = "com.socialnmobile.dictapps.notepad.color.note"; keys = @("colornote", "color_note", "color.note"); exclude = @(); strip = $true; stable = $cfg_colornote_stable },
                @{ id = "13"; name = "CPU_Z"; package = "com.cpuid.cpu_z"; keys = @("cpu-z", "cpuz", "cpu_z"); exclude = @(); strip = $true; stable = $cfg_cpuz_stable },
                @{ id = "14"; name = "Electron"; package = "com.mahersafadi.electron"; keys = @("electron"); exclude = @(); strip = $true; stable = $cfg_electron_stable },
                @{ id = "15"; name = "Hola_VPN"; package = "org.hola.play"; keys = @("hola", "holavpn"); exclude = @(); strip = $true; stable = $cfg_holavpn_stable },
                @{ id = "16"; name = "HTTP_Sniffer"; package = "com.anetcapture.mock"; keys = @("http", "sniffer", "anetcapture"); exclude = @(); strip = $true; stable = $cfg_httpsniffer_stable },
                @{ id = "17"; name = "Inure"; package = "app.simple.inure.play"; keys = @("inure"); exclude = @(); strip = $true; stable = $cfg_inure_stable },
                @{ id = "18"; name = "Kahoot"; package = "no.mobitroll.kahoot.android"; keys = @("kahoot"); exclude = @(); strip = $true; stable = $cfg_kahoot_stable },
                @{ id = "19"; name = "KineMaster"; package = "com.nexstreaming.app.kinemasterfree"; keys = @("kinemaster"); exclude = @(); strip = $true; stable = $cfg_kinemaster_stable },
                @{ id = "20"; name = "Lark_Player"; package = "com.dywx.larkplayer"; keys = @("lark", "larkplayer"); exclude = @(); strip = $true; stable = $cfg_larkplayer_stable },
                @{ id = "21"; name = "Life360"; package = "com.life360.android.safetymapd"; keys = @("life360"); exclude = @(); strip = $true; stable = $cfg_life360_stable },
                @{ id = "22"; name = "ML_Manager"; package = "com.javiersantos.mlmanager"; keys = @("ml_manager", "mlmanager"); exclude = @(); strip = $true; stable = $cfg_mlmanager_stable },
                @{ id = "23"; name = "MobiOffice"; package = "com.mobisystems.office"; keys = @("mobioffice", "mobi", "office"); exclude = @("wps"); strip = $true; stable = $cfg_mobioffice_stable },
                @{ id = "24"; name = "NetGuard"; package = "eu.faircode.netguard"; keys = @("netguard"); exclude = @(); strip = $true; stable = $cfg_netguard_stable },
                @{ id = "25"; name = "Network_Guru"; package = "com.paget96.netspeedindicator"; keys = @("networkguru", "network_guru", "netspeedindicator"); exclude = @(); strip = $true; stable = $cfg_networkguru_stable },
                @{ id = "26"; name = "Ninja_VPN"; package = "app.ninjavpn.android"; keys = @("ninjavpn", "ninja_vpn"); exclude = @(); strip = $true; stable = $cfg_ninjavpn_stable },
                @{ id = "27"; name = "Proton_VPN"; package = "ch.protonvpn.android"; keys = @("proton", "protonvpn"); exclude = @(); strip = $true; stable = $cfg_protonvpn_stable },
                @{ id = "28"; name = "Proxyman"; package = "com.proxyman.proxymanandroid"; keys = @("proxyman"); exclude = @(); strip = $true; stable = $cfg_proxyman_stable },
                @{ id = "29"; name = "Psiphon_Pro"; package = "com.psiphon3.subscription"; keys = @("psiphon"); exclude = @(); strip = $true; stable = $cfg_psiphon_stable },
                @{ id = "30"; name = "RAR"; package = "com.rarlab.rar"; keys = @("rar"); exclude = @(); strip = $true; stable = $cfg_rar_stable },
                @{ id = "31"; name = "SD_Maid_SE"; package = "eu.darken.sdmse"; keys = @("sd_maid", "sdmaid", "sdmse"); exclude = @(); strip = $true; stable = $cfg_sdmaid_stable },
                @{ id = "32"; name = "Stargazing_Hub"; package = "com.twtapp"; keys = @("stargazing", "stargazinghub"); exclude = @(); strip = $true; stable = $cfg_stargazing_stable },
                @{ id = "33"; name = "Stickerly"; package = "com.snowcorp.stickerly.android"; keys = @("stickerly", "sticker.ly"); exclude = @(); strip = $true; stable = $cfg_stickerly_stable },
                @{ id = "34"; name = "Strava"; package = "com.strava"; keys = @("strava"); exclude = @(); strip = $true; stable = $cfg_strava_stable },
                @{ id = "35"; name = "TeraBox"; package = "com.dubox.drive"; keys = @("terabox", "dubox"); exclude = @(); strip = $true; stable = $cfg_terabox_stable },
                @{ id = "36"; name = "TurboScan"; package = "com.piksoft.turboscan.free"; keys = @("turboscan"); exclude = @(); strip = $true; stable = $cfg_turboscan_stable },
                @{ id = "37"; name = "Uptodown_App_Store"; package = "com.uptodown"; keys = @("uptodown"); exclude = @(); strip = $true; stable = $cfg_uptodown_stable },
                @{ id = "38"; name = "Wallverse"; package = "com.wallverse.wallpapers"; keys = @("wallverse"); exclude = @(); strip = $true; stable = $cfg_wallverse_stable },
                @{ id = "39"; name = "Waze"; package = "com.waze"; keys = @("waze"); exclude = @(); strip = $true; stable = $cfg_waze_stable },
                @{ id = "40"; name = "Windscribe_VPN"; package = "com.windscribe.vpn"; keys = @("windscribe"); exclude = @(); strip = $true; stable = $cfg_windscribe_stable },
                @{ id = "41"; name = "WolframAlpha"; package = "com.wolfram.android.alphapro"; keys = @("wolfram", "wolframalpha", "alphapro"); exclude = @(); strip = $true; stable = $cfg_wolfram_stable }
            )
        }

        $choices = $appSelection.Split(',')
        $selectAllId = switch ($projectName) { 
            "ajstrick81" {"10"}
            "arandomhooman" {"18"} 
            "BholeyKaBhakt" {"7"} 
            "browzomje" {"3"} 
            "De-Vanced" {"2"} 
            "hoo-dles" {"12"} 
            "hxreborn" {"4"}
            "icysymmetra" {"2"} 
            "kiraio-moe" {"15"} 
            "Morphe" {"4"} 
            "PathxmOp" {"2"} 
            "Piko" {"3"} 
            "rushiranpise" {"42"}
        }
        $selectedApps = @(if ($selectAllId -in $choices) { $masterApps } else { $masterApps | Where-Object { $_.id -in $choices } })

        Write-Host "`n[INFO] Place original .apk, .apkm, .xapk, or .apks files in '.\$projectName\Input'." -ForegroundColor DarkGray

        # Display application-specific notices.
        if ($selectedApps | Where-Object { $_.name -eq "Instagram" }) {
            Write-Host "Note for Instagram: Piko officially tested v$($cfg_ig_stable[0]) specifically on build code 384510827. Make sure to pick 'arm64-v8a'!" -ForegroundColor Magenta
        }
        if ($selectedApps | Where-Object { $_.name -eq "IbisPaint_X" }) {
            Write-Host "Note for IbisPaint X: Select 'arm64-v8a' in the next step, as it's the only supported architecture!" -ForegroundColor Magenta
        }
        if ($selectedApps | Where-Object { $_.name -eq "Video_Converter" }) {
            Write-Host "Note for Video Converter: This application only supports 64-bit devices. Make sure to select 'arm64-v8a' in the next step!" -ForegroundColor Magenta
        }

        Write-Host "`n[+] Validating Dependencies..." -ForegroundColor Yellow
        
        # Bypass PowerShell's buggy -Include wildcard resolution by using LiteralPath and Regex filtering.
        $inputDir = Join-Path $workspace "Input"
        $allApks = Get-ChildItem -LiteralPath $inputDir -File -ErrorAction SilentlyContinue | Where-Object { 
            $_.Extension -match '(?i)^\.(apk|apkm|xapk|apks)$' -and 
            -not ($_.Attributes -band [System.IO.FileAttributes]::ReparsePoint) 
        }
        $hasMismatch = $false
        $missingApps = 0

        foreach ($app in $selectedApps) {
            $app.TargetApk = $null

            # NSFW Safety Check for Nekopoi patching pipeline
            if ($app.name -eq "Nekopoi") {
                Write-Host "`n[!] WARNING: MATURE CONTENT DETECTED (21+)" -ForegroundColor Red
                if (-not (Get-YesNoPrompt "You are about to patch an NSFW (21+) application. Are you sure you want to proceed?")) {
                    Write-Host "  -> Skipping Nekopoi deployment by user request." -ForegroundColor DarkGray
                    continue
                }
                
                Write-Host "`n[!] RED GATES: INDEMNITY & LIABILITY DISCLAIMER" -ForegroundColor Red
                Write-Host "I assume absolutely no responsibility or liability for any psychological issues, addiction, dependencies, or potential legal violations arising from the use of this un-censored software." -ForegroundColor Yellow
                if (-not (Get-YesNoPrompt "Do you explicitly understand the risks and wish to continue anyway?")) {
                    Write-Host "  -> Skipping Nekopoi deployment by user request." -ForegroundColor DarkGray
                    continue
                }
            }
            
            $matched = @($allApks | Where-Object { 
                $n = $_.Name.ToLower()
                $matchKey = $false
                foreach ($k in $app.keys) { if ($n -match $k) { $matchKey = $true; break } }
                foreach ($e in $app.exclude) { if ($n -match $e) { $matchKey = $false; break } }
                $matchKey
            })

            if (-not $matched -or $matched.Count -eq 0) {
                Write-Host "[-] $($app.name) - No App file detected." -ForegroundColor Red
                $missingApps++
                continue
            }

            $chosenApk = if ($matched.Count -eq 1) { 
                $v = Get-ApkVersion -FileName $matched[0].Name -AppKeywords $app.keys
                
                $tag = if ("Any" -in $app.stable) { " [SUPPORTED]" } elseif ($v -in $app.stable) { " [RECOMMENDED]" } else { " [MISMATCH]" }
                $color = if ($tag -match "MISMATCH") { "Yellow" } else { "Green" }
                Write-Host "  [✓] $($app.name) -> $($matched[0].Name)$tag" -ForegroundColor $color
                $matched[0] 
            } else {
                Write-Host "`nMultiple files detected for $($app.name):" -ForegroundColor Cyan
                for ($i = 0; $i -lt $matched.Count; $i++) {
                    $v = Get-ApkVersion -FileName $matched[$i].Name -AppKeywords $app.keys
                    
                    $tag = if ("Any" -in $app.stable) { " [SUPPORTED]" } elseif ($v -in $app.stable) { " [RECOMMENDED]" } else { " [MISMATCH]" }
                    $color = if ($tag -match "MISMATCH") { "Yellow" } else { "Green" }
                    Write-Host "  $($i + 1). $($matched[$i].Name)$tag" -ForegroundColor $color
                }
                $idx = Read-ValidatedInput -Prompt "Select File (1-$($matched.Count))" -RegexPattern "^[1-$($matched.Count)]$" -ErrorMessage "Invalid selection."
                $matched[[int]$idx - 1]
            }

            $isBundle = [System.IO.Path]::GetExtension($chosenApk.FullName) -match "\.(apkm|xapk|apks)$"
            if (-not $isBundle -and -not (Test-IsUniversalApk $chosenApk.FullName)) {
                Write-Host "`n  [!] WARNING: This .apk is missing required core files (Split/Corrupt)!" -ForegroundColor Yellow
                if (-not (Get-YesNoPrompt "  Force continue anyway?")) { continue }
            }

            $ver = Get-ApkVersion -FileName $chosenApk.Name -AppKeywords $app.keys
            
            # Prompt for manual entry if version extraction fails.
            if (-not $ver) {
                $ver = Read-ValidatedInput -Prompt "Enter version manually for $($chosenApk.Name)" -RegexPattern "^[a-zA-Z0-9\-\.\+ _\(\)]+$" -ErrorMessage "Use format x.x.x, or a build tag (e.g., build-1025-uni, 2.0.3 (41-d04e542))"
            }

            $app.TargetApk = $chosenApk.FullName
            $app.TargetVersion = $ver
            
            if ("Any" -notin $app.stable -and $ver -notin $app.stable) { 
                $hasMismatch = $true; $app.RequiresForce = $true 
            }
        }

        $validAppsCount = ($selectedApps | Where-Object { $null -ne $_.TargetApk }).Count
        if ($validAppsCount -eq 0) {
            Write-Host "`n[!] No matching app files found in the Input folder. Skipping ecosystem $projectName." -ForegroundColor Red
            Start-Sleep -Seconds 2
            continue
        }
        
        if ($missingApps -gt 0) {
            if (-not (Get-YesNoPrompt "`nSome selected apps are missing in $projectName. Continue patching the available ones?")) { continue }
        }
        
        if ($hasMismatch -and -not (Get-YesNoPrompt "`nVersion mismatches detected in $projectName. Force patch?")) { continue }

        $validApps = $selectedApps | Where-Object { $null -ne $_.TargetApk }
        $batchJobs += [PSCustomObject]@{
            Eco = $eco
            Env = $envArt
            Apps = $validApps
        }
    }

    if ($batchJobs.Count -eq 0) {
        Write-Host "`n[!] No valid jobs queued across all selected ecosystems. Aborting workflow." -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }

    # PHASE 2: Collect Global Configurations (Applies to all jobs in the queue).
    Write-Host "`n==============================================" -ForegroundColor Cyan
    Write-Host "           GLOBAL CONFIGURATIONS              " -ForegroundColor Cyan
    Write-Host "==============================================" -ForegroundColor Cyan

    Write-Host "`n[+] Select Global Target Architecture:" -ForegroundColor Yellow
    Write-Host "1. arm64-v8a`n2. armeabi-v7a`n3. x86_64`n4. x86`n5. Universal"
    $archChoice = Read-ValidatedInput -Prompt "Choice (1-5)" -RegexPattern "^[1-5]$" -ErrorMessage "Invalid input."
    $targetArch = switch ($archChoice) { "1" { "arm64-v8a" } "2" { "armeabi-v7a" } "3" { "x86_64" } "4" { "x86" } "5" { "universal" } }

    Write-Host "`n[+] Global Keystore Configuration:" -ForegroundColor Yellow
    $useCustomKeystore = Get-YesNoPrompt "Use custom keystore?"
    $keystoreFile = $null; $keystoreAlias = $null; $securePass = $null; $secureEntryPass = $null; $customSigner = $null
    
    if ($useCustomKeystore) {
        Write-Host "  1. Enter credentials manually"
        Write-Host "  2. Load from 'custom-keystore.txt'"
        $ksMethod = Read-ValidatedInput -Prompt "Choice (1-2)" -RegexPattern "^[12]$" -ErrorMessage "Invalid input."

        if ($ksMethod -eq "2") {
            $ksConfigFile = Join-Path $PSScriptRoot "custom-keystore.txt"
            if (-not (Test-Path -LiteralPath $ksConfigFile)) {
                $template = "# Keystore configuration file`nKeystorePath=my-release-key.keystore`nKeystoreAlias=MyAlias`nKeystorePassword=my_password`nKeystoreEntryPassword=my_entry_password`nSignerName=MySigner"
                Set-Content -LiteralPath $ksConfigFile -Value $template -Encoding UTF8
                Write-Host "  [!] 'custom-keystore.txt' not found. A template has been created in the root folder." -ForegroundColor Yellow
                Write-Host "`nPress Enter to restart the session..." -ForegroundColor DarkGray
                $null = Read-Host
                return
            }
            
            $ksConfig = @{}
            Get-Content -LiteralPath $ksConfigFile | Where-Object { $_ -match '=' -and $_ -notmatch '^\s*#' } | ForEach-Object {
                $split = $_ -split '=', 2
                $ksConfig[$split[0].Trim()] = $split[1].Trim()
            }
            
            $ks = $ksConfig['KeystorePath']
            if (-not [string]::IsNullOrWhiteSpace($ks)) {
                if (-not [System.IO.Path]::IsPathRooted($ks)) { $ks = Join-Path $PSScriptRoot $ks }
                if (Test-Path -LiteralPath $ks -PathType Leaf) { $keystoreFile = $ks } else { return }
            } else { return }
            
            $rawAlias = $ksConfig['KeystoreAlias']
            $keystoreAlias = if (-not [string]::IsNullOrWhiteSpace($rawAlias)) { $rawAlias } else { "Morphe" }
            
            $rawPass = if ($null -ne $ksConfig['KeystorePassword']) { $ksConfig['KeystorePassword'] } else { "" }
            $securePass = ConvertTo-SecureString $rawPass -AsPlainText -Force
            $rawPass = $null
            
            $rawEntryPass = if ($null -ne $ksConfig['KeystoreEntryPassword']) { $ksConfig['KeystoreEntryPassword'] } else { "" }
            $secureEntryPass = ConvertTo-SecureString $rawEntryPass -AsPlainText -Force
            $rawEntryPass = $null
            
            $rawSigner = $ksConfig['SignerName']
            if (-not [string]::IsNullOrWhiteSpace($rawSigner)) {
                $customSigner = ($rawSigner -replace '[^a-zA-Z0-9_\-]', '').Substring(0, [math]::Min($rawSigner.Length, 8))
            }
            Write-Host "  [✓] Keystore configuration loaded successfully." -ForegroundColor Green
        } else {
            while ($true) {
                $ks = (Read-Host "Keystore filename/path (or 'B' to go back)").Trim().Trim('"').Trim("'")
                if ($ks -match '^[bB]$') { throw "BACK_TO_MAIN" }
                if (-not [System.IO.Path]::IsPathRooted($ks)) { $ks = Join-Path $PSScriptRoot $ks }
                if (Test-Path -LiteralPath $ks -PathType Leaf) { $keystoreFile = $ks; break }
                Write-Host "  File not found: $ks" -ForegroundColor Red
            }
            $keystoreAlias = Read-ValidatedInput -Prompt "Alias" -RegexPattern "^[a-zA-Z0-9_\-\s]+$" -ErrorMessage "Alphanumeric, spaces, underscores, and dashes only."
            $securePass = Read-Host "Password" -AsSecureString
            $secureEntryPass = Read-Host "Entry Password" -AsSecureString
            
            if (Get-YesNoPrompt "Use custom signer?") { 
                $customSigner = Read-ValidatedInput -Prompt "Signer name" -RegexPattern "^[a-zA-Z0-9_\-]{1,8}$" -ErrorMessage "Max 8 chars, no spaces. Use alphanumeric or dashes." 
            }
        }
    }

    $isWindowsOS = ($env:OS -eq 'Windows_NT')
    $bytecodeMode = $null
    
    Write-Host "`n[+] Global Execution Preferences:" -ForegroundColor Yellow
    if ($isWindowsOS) {
        Write-Host "  [i] Bytecode Mode: Forced FULL (Windows compatibility requirement)." -ForegroundColor DarkGray
        $bytecodeMode = "FULL"
    } else {
        if (Get-YesNoPrompt "Configure custom bytecode mode? (--bytecode-mode)") {
            Write-Host "1. FULL`n2. STRIP_FAST`n3. STRIP_SAFE"
            $bcChoice = Read-ValidatedInput -Prompt "Choice (1-3)" -RegexPattern "^[1-3]$" -ErrorMessage "Invalid input."
            $bytecodeMode = switch ($bcChoice) { "1" { "FULL" } "2" { "STRIP_FAST" } "3" { "STRIP_SAFE" } }
        }
    }
    
    # Prompt the user to include experimental versions in the output generation (e.g. options JSON & list patches).
    $includeExperimental = Get-YesNoPrompt "Include experimental app versions in the patch lists? (--include-experimental)"

    $disableSigning = Get-YesNoPrompt "Disable signing of the final apk? (--unsigned)"
    
    # SDK Verification Gate
    $verifyWithSdk = Get-YesNoPrompt "Verify the patched apps with a local Android SDK? (--verify-with-sdk) [DEV ONLY]"
    if ($verifyWithSdk) {
        Write-Host "`n  [!] THIS REQUIRES A PROPER ANDROID SDK (BUILD-TOOLS & PLATFORMS)" -ForegroundColor Red
        Write-Host "      Many apps attempt to try/catch imports of classes that may or may not be available at runtime." -ForegroundColor Yellow
        Write-Host "      This causes 'missing class' FALSE NEGATIVES during verification, which is intentional and expected." -ForegroundColor Yellow
        Write-Host "      End users should NOT use this unless requested as part of a bug report.`n" -ForegroundColor Yellow
        
        $confirmVerify = Get-YesNoPrompt "  Are you sure you want to proceed with verification? (For Developers Only)"
        if (-not $confirmVerify) {
            $verifyWithSdk = $false
            Write-Host "  [i] SDK verification cancelled. Continuing with standard patching..." -ForegroundColor DarkGray
        } else {
            Write-Host "  [i] SDK verification enabled. Prepare for potential false negatives." -ForegroundColor DarkGray
        }
    }
    
    $continueOnError = Get-YesNoPrompt "Skip failed patches and continue? (--continue-on-error)"

    # PHASE 3: Generate reference lists and JSON option files for all queued jobs.
    Write-Host "`n==============================================" -ForegroundColor Cyan
    Write-Host "          GENERATING OPTION FILES             " -ForegroundColor Cyan
    Write-Host "==============================================" -ForegroundColor Cyan

    foreach ($job in $batchJobs) {
        $workspace = $job.Eco.Workspace
        $cliAbsPath = $job.Env.Cli.FullName
        $patchAbsPath = $job.Env.Patches.FullName
        $extraPatches = $job.Env.ExtraPatches
        $patchTrack = $job.Env.Track

        $patchesListFile = Join-Path $workspace "list-patches-$patchTrack.txt"
        if (Test-Path -LiteralPath $patchesListFile) { Remove-Item -LiteralPath $patchesListFile -Force -ErrorAction SilentlyContinue }
        
        # Build array dynamically by appending string elements sequentially to safely bind CLI args.
        $listArgs = @("-jar", $cliAbsPath, "list-patches", "--with-packages", "--with-versions", "--with-options", "--out", $patchesListFile, "--patches", $patchAbsPath)
        if ($includeExperimental) { $listArgs += "--include-experimental" }
        if ($extraPatches) { foreach ($ep in $extraPatches) { $listArgs += "--patches"; $listArgs += $ep.FullName } }
        
        $null = & java $listArgs 2>&1
        if ($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath $patchesListFile)) {
            Write-Host "  [✓] Reference list created: $(Split-Path $patchesListFile -Leaf) ($($job.Eco.Name))" -ForegroundColor Green
        }

        foreach ($app in $job.Apps) {
            $jsonFileName = Join-Path $workspace "$($app.name.ToLower().Replace('_','-'))-options-$patchTrack.json"
            if (Test-Path -LiteralPath $jsonFileName) { Remove-Item -LiteralPath $jsonFileName -Force -ErrorAction SilentlyContinue }
            
            $optArgs = @("-jar", $cliAbsPath, "options-create", "--patches", $patchAbsPath)
            if ($extraPatches) { foreach ($ep in $extraPatches) { $optArgs += "--patches"; $optArgs += $ep.FullName } }
            $optArgs += @("--out", $jsonFileName, "--filter-package-name", $app.package)
            
            $null = & java $optArgs 2>&1
            if ($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath $jsonFileName)) {
                Write-Host "  [✓] Options generated for $($app.name) ($($job.Eco.Name))" -ForegroundColor Green
            } else {
                Write-Host "  [!] Options generation failed for $($app.name)." -ForegroundColor Red
            }
        }
    }

    # PHASE 4: Global Pause & JSON Constraint Evaluation.
    Write-Host "`n[OPTIONS READY] All configuration files have been generated." -ForegroundColor Cyan
    if (Get-YesNoPrompt "Modify JSON files before patching?") {
        Write-Host "  [TIP] Check the 'list-patches-xxx.txt' files in each workspace for reference." -ForegroundColor DarkGray
        Write-Host "Awaiting manual modifications. Setup your workspaces, then press any key to initiate the Batch Sequence..." -ForegroundColor Magenta
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }

    $abortBatch = $false
    foreach ($job in $batchJobs) {
        foreach ($app in $job.Apps) {
            if ($app.name -eq "X_Twitter") {
                $jsonFileName = Join-Path $job.Eco.Workspace "$($app.name.ToLower().Replace('_','-'))-options-$($job.Env.Track).json"
                if (Test-Path -LiteralPath $jsonFileName) {
                    try {
                        $jsonContent = Get-Content -LiteralPath $jsonFileName -Raw | ConvertFrom-Json
                        
                        # Constraint 1: Block redirecting to X Lite
                        $verMatch = [regex]::Match($app.TargetVersion, "^(\d+)\.(\d+)")
                        if ($verMatch.Success) {
                            $major = [int]$verMatch.Groups[1].Value
                            $minor = [int]$verMatch.Groups[2].Value
                            if ($major -lt 11 -or ($major -eq 11 -and $minor -lt 98)) {
                                if ($null -ne $jsonContent."Block redirecting to X Lite" -and $jsonContent."Block redirecting to X Lite".enabled -eq $true) {
                                    Write-Host "`n[!] CRITICAL WARNING FOR X (TWITTER):" -ForegroundColor Red
                                    Write-Host "    You enabled the 'Block redirecting to X Lite' patch, but your APK is v$($app.TargetVersion)." -ForegroundColor Red
                                    Write-Host "    This specific patch requires v11.98.0-release.0 or higher." -ForegroundColor Red
                                    if (-not (Get-YesNoPrompt "    Force continue anyway? (Highly likely to crash)")) { $abortBatch = $true }
                                }
                            }
                        }
                    } catch { }
                }
            }
        }
    }
    if ($abortBatch) { Write-Host "`n[i] Operations aborted due to constraint violation." -ForegroundColor Yellow; Start-Sleep -Seconds 2; return }

    # PHASE 5: Unattended Batch Execution.
    Write-Host "`n==============================================" -ForegroundColor Cyan
    Write-Host "           BATCH PATCHING EXECUTION           " -ForegroundColor Cyan
    Write-Host "==============================================" -ForegroundColor Cyan

    $heapSize = "2G"
    try {
        $ramInfo = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
        if ($ramInfo) {
            $sysRamGB = [math]::Round($ramInfo.TotalPhysicalMemory / 1GB)
            if ($sysRamGB -ge 8) { $heapSize = "4G" } elseif ($sysRamGB -ge 6) { $heapSize = "3G" }
            Write-Host "  [i] Detected System RAM: ${sysRamGB}GB. Auto-adjusting Java Heap Space to: -$heapSize" -ForegroundColor DarkGray
        }
    } catch { }
    
    try {
        $plainPass = $null; $plainEntryPass = $null
        $bstr1 = [IntPtr]::Zero; $bstr2 = [IntPtr]::Zero
        
        if ($useCustomKeystore) {
            $bstr1 = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePass)
            $plainPass = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr1)
            $bstr2 = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureEntryPass)
            $plainEntryPass = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr2)
        }

        foreach ($job in $batchJobs) {
            $workspace = $job.Eco.Workspace
            $projectName = $job.Eco.Name
            $cliAbsPath = $job.Env.Cli.FullName
            $patchAbsPath = $job.Env.Patches.FullName
            $extraPatches = $job.Env.ExtraPatches
            $patchTrack = $job.Env.Track

            $tempLogFile = Join-Path $workspace "Output\temp_patch_log.txt"
            if (Test-Path -LiteralPath $tempLogFile) { Remove-Item -LiteralPath $tempLogFile -Force -ErrorAction Ignore }

            foreach ($app in $job.Apps) {
                
                $jsonFileName = Join-Path $workspace "$($app.name.ToLower().Replace('_','-'))-options-$patchTrack.json"
                $outputApkAbs = Join-Path $workspace "Output\$($app.name)_$($projectName)_$($app.TargetVersion)-$targetArch.apk"
                
                $tempResultFile = Join-Path $workspace "Output\temp_result_$($app.name).json"
                if (Test-Path -LiteralPath $tempResultFile) { Remove-Item -LiteralPath $tempResultFile -Force -ErrorAction Ignore }
                
                Write-Host "`n>>> PATCHING: $($app.name) (v$($app.TargetVersion)) [$projectName] <<<" -ForegroundColor Magenta
                
                $logHeader = "`n" + ("=" * 60) + "`n>>> LOG FOR: $($app.name) (v$($app.TargetVersion)) <<<`n" + ("=" * 60) + "`n"
                Add-Content -LiteralPath $tempLogFile -Value $logHeader -Encoding UTF8
                
                # Append discrete array components to prevent flag concatenation failures in the upstream JVM parser.
                $baseArgs = @("-Xmx$heapSize", "-jar", $cliAbsPath, "patch", "--patches", $patchAbsPath)
                if ($extraPatches) { foreach ($ep in $extraPatches) { $baseArgs += "--patches"; $baseArgs += $ep.FullName } }
                
                # The --options-update flag is omitted here because options-create generates a fresh JSON file during Phase 3.
                # The deprecated --purge flag is also omitted as the CLI purges temp files by default.
                $baseArgs += @("--options-file", $jsonFileName, "--out", $outputApkAbs, "--result-file", $tempResultFile)
                
                if ($bytecodeMode) { $baseArgs += "--bytecode-mode"; $baseArgs += $bytecodeMode }
                if ($patchTrack -eq "dev" -or $app.RequiresForce) { $baseArgs += "--force" }
                if ($verifyWithSdk) { $baseArgs += "--verify-with-sdk" }
                
                if ($disableSigning) {
                    $baseArgs += "--unsigned"
                } elseif ($useCustomKeystore) { 
                    $baseArgs += "--keystore", $keystoreFile, "--keystore-entry-alias", $keystoreAlias, "--keystore-password", $plainPass, "--keystore-entry-password", $plainEntryPass 
                    if ($customSigner) { $baseArgs += "--signer"; $baseArgs += $customSigner }
                }
                
                if ($app.strip -and ($targetArch -ne "universal")) { $baseArgs += "--striplibs"; $baseArgs += $targetArch }
                if ($continueOnError) { $baseArgs += "--continue-on-error" }

                # Append positional argument (APK file) at the very end of the command array.
                $baseArgs += $app.TargetApk

                & java $baseArgs 2>&1 | Tee-Object -FilePath $tempLogFile -Append | ForEach-Object { Write-Host $_ }

                if ($LASTEXITCODE -ne 0) {
                    Write-Host "  [!] Patching FAILED (Exit Code: $LASTEXITCODE)" -ForegroundColor Red
                    if (-not $continueOnError) { break }
                } else {
                    Write-Host "  [✓] Patching SUCCEEDED" -ForegroundColor Green
                }
            }
        }
    } finally {
        # Secure string memory flush.
        if ($bstr1 -ne [IntPtr]::Zero) { [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr1) }
        if ($bstr2 -ne [IntPtr]::Zero) { [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr2) }
        if ($plainPass) { $plainPass = $null; Clear-Variable plainPass -ErrorAction Ignore; [System.GC]::Collect(); [System.GC]::WaitForPendingFinalizers() }
        if ($plainEntryPass) { $plainEntryPass = $null; Clear-Variable plainEntryPass -ErrorAction Ignore; [System.GC]::Collect(); [System.GC]::WaitForPendingFinalizers() }
        if ($securePass) { $securePass.Dispose() }
        if ($secureEntryPass) { $secureEntryPass.Dispose() }
    }

    # PHASE 6: Post-Execution Exports.
    Write-Host "`n[SUCCESS] Batch operations concluded." -ForegroundColor Green

    if (Get-YesNoPrompt "`nExport patching logs?") {
        foreach ($job in $batchJobs) {
            $logPath = Join-Path $job.Eco.Workspace "Output\Patch_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
            $tempLogFile = Join-Path $job.Eco.Workspace "Output\temp_patch_log.txt"
            if (Test-Path -LiteralPath $tempLogFile) { 
                Rename-Item -LiteralPath $tempLogFile -NewName (Split-Path $logPath -Leaf) 
                Write-Host "  -> Log exported: .\$($job.Eco.Name)\Output\$(Split-Path $logPath -Leaf)" -ForegroundColor Green
            }
        }
    } else {
        foreach ($job in $batchJobs) {
            $tempLogFile = Join-Path $job.Eco.Workspace "Output\temp_patch_log.txt"
            if (Test-Path -LiteralPath $tempLogFile) { Remove-Item -LiteralPath $tempLogFile -ErrorAction Ignore }
        }
    }

    if (Get-YesNoPrompt "Export patching result JSONs? (--result-file)") {
        foreach ($job in $batchJobs) {
            foreach ($app in $job.Apps) {
                $tempResultFile = Join-Path $job.Eco.Workspace "Output\temp_result_$($app.name).json"
                if (Test-Path -LiteralPath $tempResultFile) {
                    $finalResultName = "Result_$($app.name)_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
                    Rename-Item -LiteralPath $tempResultFile -NewName $finalResultName
                    Write-Host "  -> JSON result exported: .\$($job.Eco.Name)\Output\$finalResultName" -ForegroundColor Green
                }
            }
        }
    } else {
        foreach ($job in $batchJobs) {
            foreach ($app in $job.Apps) {
                $tempResultFile = Join-Path $job.Eco.Workspace "Output\temp_result_$($app.name).json"
                if (Test-Path -LiteralPath $tempResultFile) { Remove-Item -LiteralPath $tempResultFile -ErrorAction Ignore }
            }
        }
    }

    if (Get-YesNoPrompt "Open output directories?") { 
        foreach ($job in $batchJobs) { Invoke-Item "$($job.Eco.Workspace)\Output" } 
    }
    
    Write-Host "`nPress Enter to return to the Main Menu..." -ForegroundColor Magenta
    $null = Read-Host
}

function Invoke-UtilityWorkflow {
    Clear-Host
    Write-Host "==============================================" -ForegroundColor Cyan
    Write-Host "           CHIHAFUYU TOOL - UTILITY           " -ForegroundColor Cyan
    Write-Host "==============================================" -ForegroundColor Cyan
    
    Write-Host "`nSelect Utility Action:" -ForegroundColor Yellow
    Write-Host "1. Install app to device (adb)"
    Write-Host "2. Uninstall app from device (adb)"
    Write-Host "3. Generate Options only"
    Write-Host "4. Generate list-patches only"
    Write-Host "5. Generate Custom Keystore (PKCS12)"
    Write-Host "6. Clear Morphe Cache (Downloaded patches, logs, temp)"
    Write-Host "X. Close Tool"
    
    $utilChoice = Read-ValidatedInput -Prompt "Enter choice" -RegexPattern "^[1-6xX]$" -ErrorMessage "Invalid input. Please enter 1-6, or X."
    
    if ($utilChoice -match '^[xX]$') { exit 0 }
    
    if ($utilChoice -in @('1', '2')) {
        Write-Host "`n  [i] HEADS UP: This feature relies on ADB. Make sure you have Android 'platform-tools' installed and added to your system PATH!" -ForegroundColor Cyan
        
        $ecosystems = Resolve-Ecosystem
        if (-not $ecosystems) { return }
        $eco = $ecosystems[0] # ADB utilities only require a single valid CLI environment.
        
        $envArt = Resolve-EnvironmentArtifacts -Workspace $eco.Workspace -ProjectName $eco.Name -RequirePatches $false
        if (-not $envArt) { return }
        $cliAbsPath = $envArt.Cli.FullName
        
        if ($utilChoice -eq '1') {
            Write-Host "`n[INSTALL] Select Install Mode:" -ForegroundColor Yellow
            Write-Host "1. Non-Root (Standard Install via --apk)"
            Write-Host "2. Root (Mount Install via --mount)"
            $installMode = Read-ValidatedInput -Prompt "Enter choice (1 or 2)" -RegexPattern "^[12]$" -ErrorMessage "Invalid input."
            
            $apkPath = Read-Host "Drag and drop the APK file here, or enter the full path (or 'B' to go back)"
            $apkPath = $apkPath.Trim().Trim('"').Trim("'")
            if ($apkPath -match '^[bB]$') { throw "BACK_TO_MAIN" }
            
            $apkItem = Get-Item -LiteralPath $apkPath -Force -ErrorAction SilentlyContinue
            if ($apkItem -and ($apkItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
                Write-Host "  [!] Symlinks or ReparsePoints are not allowed for security reasons." -ForegroundColor Red
                Start-Sleep -Seconds 2
                return
            }
            
            if (-not (Test-Path -LiteralPath $apkPath -PathType Leaf)) {
                Write-Host "  [!] APK file not found at: $apkPath" -ForegroundColor Red
            } else {
                # Setup Link Handling features dynamically.
                $routeLinks = Get-YesNoPrompt "Route supported web links to the patched app? (--route-links)"
                $disableStock = $false
                if ($routeLinks) {
                    $disableStock = Get-YesNoPrompt "Also stop the stock app from opening these links? (--disable-stock)"
                }

                Write-Host "  [i] Ensure your device is connected via USB and ADB debugging is authorized." -ForegroundColor DarkGray
                
                $baseArgs = @("-Xmx2G", "-jar", $cliAbsPath, "utility", "install", "-a", $apkPath)
                if ($installMode -eq '2') {
                    $pkg = Read-ValidatedInput -Prompt "Target Package Name (e.g., com.google.android.youtube)" -RegexPattern "^(?:[a-zA-Z][a-zA-Z0-9_]*)(?:\.[a-zA-Z][a-zA-Z0-9_]*)+$" -ErrorMessage "Invalid Android package name format."
                    $baseArgs += "-m"
                    $baseArgs += $pkg
                }

                # Link handling flag injections.
                if ($routeLinks) { $baseArgs += "--route-links" }
                if ($disableStock) {
                    $stockPkg = Read-ValidatedInput -Prompt "Stock Package Name to disable" -RegexPattern "^(?:[a-zA-Z][a-zA-Z0-9_]*)(?:\.[a-zA-Z][a-zA-Z0-9_]*)+$" -ErrorMessage "Invalid Android package name format."
                    $baseArgs += "--disable-stock"
                    $baseArgs += $stockPkg
                }
                
                Write-Host "`nExecuting Morphe Utility..." -ForegroundColor Magenta
                & java $baseArgs
                if ($LASTEXITCODE -ne 0) {
                    Write-Host "  [!] Command FAILED (Exit Code: $LASTEXITCODE)" -ForegroundColor Red
                } else {
                    Write-Host "  [✓] Command SUCCEEDED" -ForegroundColor Green
                }
            }
        } 
        elseif ($utilChoice -eq '2') {
            Write-Host "`n[UNINSTALL] Select Uninstall Mode:" -ForegroundColor Yellow
            Write-Host "1. Non-Root (Standard Uninstall via --package-name)"
            Write-Host "2. Root (Unmount via --unmount)"
            $uninstallMode = Read-ValidatedInput -Prompt "Enter choice (1 or 2)" -RegexPattern "^[12]$" -ErrorMessage "Invalid input."
            
            $pkg = Read-ValidatedInput -Prompt "Target Package Name (e.g., com.google.android.youtube)" -RegexPattern "^(?:[a-zA-Z][a-zA-Z0-9_]*)(?:\.[a-zA-Z][a-zA-Z0-9_]*)+$" -ErrorMessage "Invalid Android package name format."
            
            Write-Host "  [i] Ensure your device is connected via USB and ADB debugging is authorized." -ForegroundColor DarkGray
            
            $baseArgs = @("-Xmx2G", "-jar", $cliAbsPath, "utility", "uninstall", "-p", $pkg)
            if ($uninstallMode -eq '2') {
                $baseArgs += "--unmount"
            }
            
            Write-Host "`nExecuting Morphe Utility..." -ForegroundColor Magenta
            & java $baseArgs
            if ($LASTEXITCODE -ne 0) {
                Write-Host "  [!] Command FAILED (Exit Code: $LASTEXITCODE)" -ForegroundColor Red
            } else {
                Write-Host "  [✓] Command SUCCEEDED" -ForegroundColor Green
            }
        }
    }
    elseif ($utilChoice -in @('3', '4')) {
        $ecosystems = Resolve-Ecosystem
        if (-not $ecosystems) { return }
        
        foreach ($eco in $ecosystems) {
            Write-Host "`n>>> PROCESSING ECOSYSTEM: $($eco.Name.ToUpper()) <<<" -ForegroundColor Cyan
            
            $envArt = Resolve-EnvironmentArtifacts -Workspace $eco.Workspace -ProjectName $eco.Name -RequirePatches $true
            if (-not $envArt) { continue }
            
            $cliAbsPath = $envArt.Cli.FullName
            $patchAbsPath = $envArt.Patches.FullName
            $extraPatches = $envArt.ExtraPatches
            
            if ($utilChoice -eq '3') {
                Write-Host "`n[GENERATE OPTIONS] Running for all supported apps in $($eco.Name)..." -ForegroundColor Yellow
                
                $apps = if ($eco.Name -eq "ajstrick81") {
                    @(@{pkg="com.disney.disneyplus"; name="disneyplus"},
                      @{pkg="com.amazon.amazonvideo.livingroom"; name="prime-video"},
                      @{pkg="com.netflix.ninja"; name="netflix"},
                      @{pkg="com.wbd.hbomax"; name="hbo-max"},
                      @{pkg="com.peacocktv.peacockandroid"; name="peacock"},
                      @{pkg="com.tubitv"; name="tubi"},
                      @{pkg="com.univision.prendetv"; name="vix"},
                      @{pkg="tv.pluto.android"; name="pluto-tv"},
                      @{pkg="com.cbs.ott"; name="paramountplus"})
                } elseif ($eco.Name -eq "arandomhooman") {
                    @(@{pkg="com.dv.adm"; name="advanced-download-manager"},
                      @{pkg="com.alphaprogression.alphaprogression"; name="alpha-progression"},
                      @{pkg="com.bandlab.bandlab"; name="bandlab"},
                      @{pkg="com.paget96.batteryguru"; name="battery-guru"},
                      @{pkg="com.cronometer.android.gold"; name="cronometer"},
                      @{pkg="net.uniquegem.directchat"; name="directchat"},
                      @{pkg="com.finch.finch"; name="finch"},
                      @{pkg="com.flightradar24free"; name="flightradar24"},
                      @{pkg="dk.tacit.android.foldersync.lite"; name="foldersync"},
                      @{pkg="com.camerasideas.instashot"; name="inshot"},
                      @{pkg="com.soepic.photogallery.release"; name="liquid-gallery"},
                      @{pkg="com.maxmpz.audioplayer"; name="poweramp"},
                      @{pkg="ak.alizandro.smartaudiobookplayer"; name="smart-audiobook-player"},
                      @{pkg="app.symfonik.music.player"; name="symfonium"},
                      @{pkg="com.tumblr"; name="tumblr"},
                      @{pkg="app.remux.video.converter"; name="video-converter"},
                      @{pkg="com.naver.linewebtoon"; name="webtoon"})
                } elseif ($eco.Name -eq "BholeyKaBhakt") {
                    @(@{pkg="org.zwanoo.android.speedtest"; name="speedtest"},
                      @{pkg="com.noctuasoftware.stellarium_free"; name="stellarium"},
                      @{pkg="com.proto.circuitsimulator"; name="proto"},
                      @{pkg="com.vpn.free.hotspot.secure.vpnify"; name="vpnify"},
                      @{pkg="com.backdrops.wallpapers"; name="backdrops"},
                      @{pkg="pl.solidexplorer2"; name="solid-explorer"})
                } elseif ($eco.Name -eq "browzomje") {
                    @(@{pkg="com.pinterest"; name="pinterest"},
                      @{pkg="easy.sudoku.puzzle.solver.free"; name="easy-sudoku"})
                } elseif ($eco.Name -eq "De-Vanced") {
                    @(@{pkg="com.google.android.apps.photos"; name="google-photos"})
                } elseif ($eco.Name -eq "hoo-dles") {
                    @(@{pkg="com.adguard.android"; name="adguard"},
                      @{pkg="jp.ne.ibis.ibispaintx.app"; name="ibispaint-x"},
                      @{pkg="cn.wps.moffice_eng"; name="wps-office"},
                      @{pkg="com.intsig.camscanner"; name="camscanner"},
                      @{pkg="com.urbandroid.sleep"; name="sleep-as-android"},
                      @{pkg="com.duolingo"; name="duolingo"},
                      @{pkg="com.merriamwebster"; name="merriam-webster"},
                      @{pkg="com.getmimo"; name="mimo"},
                      @{pkg="com.windyty.android"; name="windy"},
                      @{pkg="videoeditor.videorecorder.screenrecorder"; name="xrecorder"},
                      @{pkg="com.xodo.pdf.reader"; name="xodo"})
                } elseif ($eco.Name -eq "hxreborn") {
                    @(@{pkg="com.spocky.projengmenu"; name="projectivy-launcher"},
                      @{pkg="ch.protonmail.android"; name="proton-mail"},
                      @{pkg="app.symfonik.music.player"; name="symfonium"})
                } elseif ($eco.Name -eq "icysymmetra") {
                    @(@{pkg="com.zhiliaoapp.musically"; name="tiktok"})
                } elseif ($eco.Name -eq "kiraio-moe") {
                    @(@{pkg="com.jlindemann.science"; name="atomic"},
                      @{pkg="com.azefsw.audioconnect"; name="audiorelay"},
                      @{pkg="com.degenk.boorusama"; name="boorusama"},
                      @{pkg="com.getepic.Epic"; name="epic"},
                      @{pkg="com.hopefactory2021.fakegpslocation"; name="fake-gps-location"},
                      @{pkg="com.chimbori.hermitcrab"; name="hermit"},
                      @{pkg="com.ceyhan.sets"; name="hidden-settings"},
                      @{pkg="com.ilovepdf.www"; name="ilovepdf"},
                      @{pkg="io.github.sds100.keymapper"; name="key-mapper"},
                      @{pkg="net.nemostudio.keymate"; name="keymate"},
                      @{pkg="jp.co.shueisha.mangaplus"; name="manga-plus"},
                      @{pkg="com.kcstream.cing"; name="nekopoi"},
                      @{pkg="com.imaginstudio.imagetools.pixellab"; name="pixellab"},
                      @{pkg="com.jeyluta.timestampcamerafree"; name="timestamp-camera"})
                } elseif ($eco.Name -eq "Morphe") {
                    @(@{pkg="com.google.android.youtube"; name="youtube"}, 
                      @{pkg="com.google.android.apps.youtube.music"; name="youtube-music"}, 
                      @{pkg="com.reddit.frontpage"; name="reddit"})
                } elseif ($eco.Name -eq "PathxmOp") {
                    @(@{pkg="com.chess"; name="chess"})
                } elseif ($eco.Name -eq "Piko") {
                    @(@{pkg="com.twitter.android"; name="x-twitter"}, 
                      @{pkg="com.instagram.android"; name="instagram"}) 
                } elseif ($eco.Name -eq "rushiranpise") {
                    @(@{pkg="com.cloudflare.onedotonedotonedotone"; name="1dot1dot1dot1"},
                      @{pkg="com.digibites.accubattery"; name="accubattery"},
                      @{pkg="com.accuweather.android"; name="accuweather"},
                      @{pkg="com.adobe.scan.android"; name="adobe-scan"},
                      @{pkg="com.finalwire.aida64"; name="aida64"},
                      @{pkg="com.androholic.amoledpix"; name="amoledpix"},
                      @{pkg="com.gombosdev.ampere"; name="ampere"},
                      @{pkg="com.jndapp.anime.depth.live.wallpaper"; name="anime-depth"},
                      @{pkg="com.apkmirror.helper.prod"; name="apkmirror"},
                      @{pkg="com.calm.android"; name="calm"},
                      @{pkg="com.canva.editor"; name="canva"},
                      @{pkg="com.socialnmobile.dictapps.notepad.color.note"; name="colornote"},
                      @{pkg="com.cpuid.cpu_z"; name="cpuz"},
                      @{pkg="com.mahersafadi.electron"; name="electron"},
                      @{pkg="org.hola.play"; name="holavpn"},
                      @{pkg="com.anetcapture.mock"; name="httpsniffer"},
                      @{pkg="app.simple.inure.play"; name="inure"},
                      @{pkg="no.mobitroll.kahoot.android"; name="kahoot"},
                      @{pkg="com.nexstreaming.app.kinemasterfree"; name="kinemaster"},
                      @{pkg="com.dywx.larkplayer"; name="lark-player"},
                      @{pkg="com.life360.android.safetymapd"; name="life360"},
                      @{pkg="com.javiersantos.mlmanager"; name="ml-manager"},
                      @{pkg="com.mobisystems.office"; name="mobioffice"},
                      @{pkg="eu.faircode.netguard"; name="netguard"},
                      @{pkg="com.paget96.netspeedindicator"; name="network-guru"},
                      @{pkg="app.ninjavpn.android"; name="ninjavpn"},
                      @{pkg="ch.protonvpn.android"; name="protonvpn"},
                      @{pkg="com.proxyman.proxymanandroid"; name="proxyman"},
                      @{pkg="com.psiphon3.subscription"; name="psiphon-pro"},
                      @{pkg="com.rarlab.rar"; name="rar"},
                      @{pkg="eu.darken.sdmse"; name="sd-maid-se"},
                      @{pkg="com.twtapp"; name="stargazing-hub"},
                      @{pkg="com.snowcorp.stickerly.android"; name="stickerly"},
                      @{pkg="com.strava"; name="strava"},
                      @{pkg="com.dubox.drive"; name="terabox"},
                      @{pkg="com.piksoft.turboscan.free"; name="turboscan"},
                      @{pkg="com.uptodown"; name="uptodown"},
                      @{pkg="com.wallverse.wallpapers"; name="wallverse"},
                      @{pkg="com.waze"; name="waze"},
                      @{pkg="com.windscribe.vpn"; name="windscribe-vpn"},
                      @{pkg="com.wolfram.android.alphapro"; name="wolframalpha"})
                }
                
                foreach ($app in $apps) {
                    $jsonFileName = Join-Path $eco.Workspace "$($app.name)-options-$($envArt.Track).json"
                    
                    if (Test-Path -LiteralPath $jsonFileName) {
                        try { Remove-Item -LiteralPath $jsonFileName -Force -ErrorAction Stop }
                        catch { Write-Host "  [!] Warning: Could not remove existing options JSON. It may be locked." -ForegroundColor Yellow }
                    }
                    
                    $optArgs = @("-Xmx2G", "-jar", $cliAbsPath, "options-create", "--patches", $patchAbsPath)
                    if ($extraPatches) { foreach ($ep in $extraPatches) { $optArgs += "--patches"; $optArgs += $ep.FullName } }
                    $optArgs += @("--out", $jsonFileName, "--filter-package-name", $app.pkg)
                    
                    Write-Host "  Generating for $($app.pkg)..." -ForegroundColor DarkGray
                    & java $optArgs
                    
                    if ($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath $jsonFileName)) {
                        Write-Host "  [✓] Saved to $(Split-Path $jsonFileName -Leaf)" -ForegroundColor Green
                    } else {
                        Write-Host "  [!] Failed to generate for $($app.pkg)" -ForegroundColor Red
                    }
                }
            }
            elseif ($utilChoice -eq '4') {
                $patchesListFile = Join-Path $eco.Workspace "list-patches-$($envArt.Track).txt"
                Write-Host "`n[GENERATE LIST] Exporting patches reference to $(Split-Path $patchesListFile -Leaf)..." -ForegroundColor Yellow
                
                if (Test-Path -LiteralPath $patchesListFile) {
                    try { Remove-Item -LiteralPath $patchesListFile -Force -ErrorAction Stop }
                    catch { Write-Host "  [!] Warning: Could not remove existing patches list. It may be locked." -ForegroundColor Yellow }
                }

                $incExp = Get-YesNoPrompt "Include experimental app versions in the output? (--include-experimental)"
                
                $listArgs = @("-Xmx2G", "-jar", $cliAbsPath, "list-patches", "--with-packages", "--with-versions", "--with-options", "--out", $patchesListFile, "--patches", $patchAbsPath)
                if ($incExp) { $listArgs += "--include-experimental" }
                if ($extraPatches) { foreach ($ep in $extraPatches) { $listArgs += "--patches"; $listArgs += $ep.FullName } }
                
                & java $listArgs
                
                if ($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath $patchesListFile)) {
                    Write-Host "  [✓] Reference file created successfully in .\$($eco.Name)\" -ForegroundColor Green
                } else {
                    Write-Host "  [!] Failed to create patches reference file." -ForegroundColor Red
                }
            }
        }
    }
    elseif ($utilChoice -eq '5') {
        Write-Host "`n[GENERATE KEYSTORE] Creating a new PKCS12 Keystore..." -ForegroundColor Yellow
        $ksName = Read-ValidatedInput -Prompt "Enter filename (e.g., my-key.keystore)" -RegexPattern "^[\w\-\.]+$" -ErrorMessage "Alphanumeric, dashes, and dots only."
        
        if ($ksName -notmatch '\.[a-zA-Z0-9]+$') {
            if ($env:OS -eq 'Windows_NT') {
                $ksName += ".keystore"
                Write-Host "  [i] Windows OS detected. Auto-appending '.keystore' -> $ksName" -ForegroundColor DarkGray
            } else {
                Write-Host "  [i] Unix/macOS detected. Keeping extensionless filename -> $ksName" -ForegroundColor DarkGray
            }
        }

        $ksAlias = Read-ValidatedInput -Prompt "Enter Alias" -RegexPattern "^[\w\-\s]+$" -ErrorMessage "Alphanumeric, spaces, and dashes only."
        $ksPass = Read-ValidatedInput -Prompt "Enter Password (min 6 chars)" -RegexPattern "^.{6,}$" -ErrorMessage "Password must be at least 6 characters."
        
        Write-Host "  [i] Android limits META-INF signatures (SignerName) to max 8 characters, NO spaces." -ForegroundColor DarkGray
        $ksSigner = Read-ValidatedInput -Prompt "Enter Signer Name (CN)" -RegexPattern "^[a-zA-Z0-9_\-]{1,8}$" -ErrorMessage "Max 8 chars, no spaces."
        
        $ksOU = Read-ValidatedInput -Prompt "Enter Organizational Unit (OU) [e.g., IT, Modder]" -RegexPattern "^[\w\-\.\s]+$" -ErrorMessage "Alphanumeric, spaces, dots, and dashes only."
        $ksOrg = Read-ValidatedInput -Prompt "Enter Organization (O) [e.g., MyCompany]" -RegexPattern "^[\w\-\.\s]+$" -ErrorMessage "Alphanumeric, spaces, dots, and dashes only."
        $ksCountry = Read-ValidatedInput -Prompt "Enter 2-letter Country Code (C) [e.g., ID, US]" -RegexPattern "^[a-zA-Z]{2}$" -ErrorMessage "Must be exactly 2 letters."

        $ksPath = Join-Path $PSScriptRoot $ksName
        if (Test-Path -LiteralPath $ksPath) {
            Write-Host "  [!] File '$ksName' already exists in the root folder!" -ForegroundColor Red
        } else {
            Write-Host "  Generating keystore using Java keytool..." -ForegroundColor DarkGray
            
            $keytoolArgs = @(
                "-genkeypair",
                "-v",
                "-keystore", $ksPath,
                "-alias", $ksAlias,
                "-keyalg", "RSA",
                "-keysize", "4096",
                "-validity", "10000",
                "-storepass", $ksPass,
                "-keypass", $ksPass,
                "-dname", "CN=$ksSigner, OU=$ksOU, O=$ksOrg, C=$($ksCountry.ToUpper())",
                "-storetype", "PKCS12"
            )
            
            & keytool @keytoolArgs 2>&1 | Out-Null
            
            if ($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath $ksPath)) {
                Write-Host "  [✓] Keystore generated successfully at: $ksPath" -ForegroundColor Green
            } else {
                Write-Host "  [!] Failed to generate keystore." -ForegroundColor Red
            }
        }
    }
    elseif ($utilChoice -eq '6') {
        Write-Host "`n[CLEAR CACHE] Clearing Morphe temporary files and cache..." -ForegroundColor Yellow
        
        $ecosystems = Resolve-Ecosystem
        if (-not $ecosystems) { return }
        $eco = $ecosystems[0]
        
        $envArt = Resolve-EnvironmentArtifacts -Workspace $eco.Workspace -ProjectName $eco.Name -RequirePatches $false
        if (-not $envArt) { return }
        
        $cliAbsPath = $envArt.Cli.FullName
        $baseArgs = @("-jar", $cliAbsPath, "utility", "clear-cache", "--info")
        
        Write-Host "`nExecuting Morphe Utility..." -ForegroundColor Magenta
        
        # Capture the standard output of a Java process
        $javaOutput = & java $baseArgs 2>&1
        $exitStatus = $LASTEXITCODE
        
        # Print the output (including the byte count) to the screen
        $javaOutput | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
        
        if ($exitStatus -eq 0) {
            Write-Host "  [✓] Cache cleared successfully." -ForegroundColor Green
        } else {
            Write-Host "  [!] Failed to clear cache." -ForegroundColor Red
        }
    }
    
    Write-Host "`nPress Enter to return to the Main Menu..." -ForegroundColor Magenta
    $null = Read-Host
}

function Invoke-MainMenu {
    Clear-Host
    Write-Host "==============================================" -ForegroundColor Cyan
    Write-Host "                CHIHAFUYU TOOL                " -ForegroundColor Cyan
    Write-Host "==============================================" -ForegroundColor Cyan
    
    Write-Host "`nWhat do you want to do?" -ForegroundColor Yellow
    Write-Host "1. Patch apps"
    Write-Host "2. Use utilities"
    Write-Host "X. Close"

    while ($true) {
        $choice = Read-ValidatedInput -Prompt "Enter choice" -RegexPattern "^[12xX]$" -ErrorMessage "Invalid input. Please enter 1, 2, or X."
        
        if ($choice -match '^[xX]$') { 
            return $false 
        }
        elseif ($choice -eq '1') {
            try {
                Invoke-PatchingWorkflow
            } catch {
                if ($_.Exception.Message -eq "BACK_TO_MAIN") {
                    Write-Host "`n[i] Operation aborted. Returning to the Main Menu..." -ForegroundColor Yellow
                    Start-Sleep -Seconds 1
                } else {
                    Write-Host "`n[FATAL ERROR] $($_.Exception.Message)" -ForegroundColor Red
                    Write-Host "Press Enter to exit..."
                    $null = Read-Host
                    exit 1
                }
            }
            return $true
        }
        elseif ($choice -eq '2') {
            try {
                Invoke-UtilityWorkflow
            } catch {
                if ($_.Exception.Message -eq "BACK_TO_MAIN") {
                    Write-Host "`n[i] Operation aborted. Returning to the Main Menu..." -ForegroundColor Yellow
                    Start-Sleep -Seconds 1
                } else {
                    Write-Host "`n[FATAL ERROR] $($_.Exception.Message)" -ForegroundColor Red
                    Write-Host "Press Enter to exit......"
                    $null = Read-Host
                    exit 1
                }
            }
            return $true
        }
    }
}

while (Invoke-MainMenu) { 
}

Write-Host "`nSession ended. Have a great day!" -ForegroundColor Cyan
Start-Sleep -Seconds 2

# Forces a clean exit code so the terminal does not flash previous Java errors.
exit 0
