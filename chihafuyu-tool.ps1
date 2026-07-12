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
# Morphe
$cfg_youtube_stable       = @("20.51.39", "20.47.62", "20.31.42", "20.21.37")
$cfg_youtube_music_stable = @("9.15.51", "8.51.51", "7.29.52")
$cfg_reddit_stable        = @("2026.14.0", "2026.04.0")

# Piko
$cfg_x_stable             = @("12.7.1-release.0")
$cfg_ig_stable            = @("435.0.0.37.76")

# hoo-dles
$cfg_adguard_stable       = @("4.12.81")
$cfg_ibispaint_stable     = @("14.0.6")
$cfg_wps_stable           = @("18.24")
$cfg_camscanner_stable    = @("7.20.0.2606230000")
$cfg_sleep_stable         = @("20260526")
$cfg_duolingo_stable      = @("6.86.5")
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

# PathxmOp
$cfg_chess_stable         = @("4.10.0", "4.10.0-googleplay", "4.9.49", "4.9.49-googleplay")
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
    param([string]$FileName, [string]$AppKeyword)
    
    if ($FileName -notmatch '\.(apk|apkm|xapk|apks)$') { return $null }
    $baseName = $FileName -replace '\.(apk|apkm|xapk|apks)$', ''
    
    # Match standard versioning and 7+ digit date codes using lookarounds to bypass trailing underscores.
    # Properly uses [-_] character class without invalid escape sequences.
    $vPat = "((?<!\d)\d{7,}(?!\d)|\d+\.\d+(?:\.\d+)*(?:-(?:release|alpha|beta|rc|ripped|release-ripped)(?:\.\d+)+)?|\d+(?:[-_]\d+)+(?:-(?:release|alpha|beta|rc|ripped|release-ripped)(?:\.\d+)+)?)"
    
    # Weight-based pattern matching to isolate version strings from architecture tags.
    $patterns = @(
        @{ P = "$AppKeyword.*?[-_]$vPat(?=[-_]|$)"; W = 10 }
        @{ P = "$vPat[_-]?(?:\d+[_-])?(?:universal|arm64|v8a|x86_64|v7a|armeabi)"; W = 9 }
        @{ P = "v$vPat(?=[-_]|$)"; W = 7 }
        @{ P = "(?<!\d)$vPat(?=[-_]|$)"; W = 5 }
    )
    
    $foundVersions = @()
    foreach ($regex in $patterns) {
        if ($baseName -match $regex.P) {
            $ext = $Matches[1]
            
            # Normalize version delimiter string from hyphens or underscores to periods.
            $ext = [regex]::Replace($ext, '(?<=\d)[-_](?=\d)', '.')
            
            # Force PSCustomObject for reliable numerical sorting.
            $foundVersions += [PSCustomObject]@{ Ver = $ext; Weight = $regex.W }
        }
    }
    
    if ($foundVersions.Count -eq 0) { return $null }
    
    # Select the highest weighted regex match.
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
    Write-Host "1. Morphe (YouTube, YT Music, Reddit)"
    Write-Host "2. Piko (X/Twitter, Instagram)"
    Write-Host "3. hoo-dles (AdGuard, IbisPaint X, WPS Office, Duolingo, Merriam-Webster, Windy, Mimo, XRecorder, CamScanner, Sleep as Android, Xodo)"
    Write-Host "4. De-ReVanced (Google Photos, RAR)"
    Write-Host "5. BholeyKaBhakt (Speedtest, Stellarium, PROTO, vpnify, Backdrops, Solid Explorer)"
    Write-Host "6. browzomje (Pinterest)"
    Write-Host "7. PathxmOp (Chess.com)"
    
    $ecoChoice = Read-ValidatedInput -Prompt "Enter choice(s) [e.g., 1, 2, or 1,2,7]" -RegexPattern "^([1-7](,[1-7])*)$" -ErrorMessage "Invalid input. Enter numbers 1-7 separated by commas."

    $choices = $ecoChoice.Split(',') | Select-Object -Unique
    $ecosystems = @()

    foreach ($c in $choices) {
        $projectName = switch ($c) {
            "1" { "Morphe" }
            "2" { "Piko" }
            "3" { "hoo-dles" }
            "4" { "De-ReVanced" }
            "5" { "BholeyKaBhakt" }
            "6" { "browzomje" }
            "7" { "PathxmOp" }
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
        # Scan for both `morphe-desktop` and `morphe-cli` executables.
        # PadLeft regex injection prevents semantic versioning sorting flaws (e.g., v10 resolving before v9).
        $cliStableSearch = Get-ChildItem -Path "..\morphe-*-all.jar", ".\morphe-*-all.jar" -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "morphe-(cli|desktop)-" -and $_.Name -notmatch "-dev" } | Sort-Object { [regex]::Replace($_.Name, '\d+', { $args[0].Value.PadLeft(4, '0') }) } -Descending | Select-Object -First 1
        $cliDevSearch = Get-ChildItem -Path "..\morphe-*-dev.*-all.jar", ".\morphe-*-dev.*-all.jar" -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "morphe-(cli|desktop)-" } | Sort-Object { [regex]::Replace($_.Name, '\d+', { $args[0].Value.PadLeft(4, '0') }) } -Descending | Select-Object -First 1

        $cliStableDisplay = if ($cliStableSearch) { "[$($cliStableSearch.Name)]" } else { "[Not Found]" }
        $cliDevDisplay = if ($cliDevSearch) { "[$($cliDevSearch.Name)]" } else { "[Not Found]" }

        Write-Host "`n[SELECT] Patcher CLI Environment ($ProjectName):" -ForegroundColor Yellow
        Write-Host -NoNewline "1. Latest Stable CLI "
        if ($cliStableDisplay -eq "[Not Found]") { Write-Host $cliStableDisplay -ForegroundColor Red } else { Write-Host $cliStableDisplay -ForegroundColor Green }
        Write-Host -NoNewline "2. Latest Pre-release CLI "
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
            if (-not $cliJar) { Write-Host "  - Missing Morphe CLI (.jar) in the Root or .\$ProjectName directory." -ForegroundColor Yellow }
            if ($RequirePatches -and -not $patchesFile) { Write-Host "  - Missing Patches (.mpp) in the .\$ProjectName directory." -ForegroundColor Yellow }
            
            Write-Host "`nWaiting for the missing files to be placed... (Press CTRL+C to abort)" -ForegroundColor Cyan
            
            $cliPrefix = if ($cliChoice -eq "1") { "morphe-*-all.jar" } else { "morphe-*-dev.*-all.jar" }
            $patchPrefix = if ($patchesChoice -eq "1") { "patches-*.mpp" } else { "patches-*-dev.*.mpp" }

            $timeout = (Get-Date).AddMinutes(5)
            while (-not $cliJar -or ($RequirePatches -and -not $patchesFile)) {
                if ((Get-Date) -gt $timeout) { throw "Timeout reached. Aborting wait for environment artifacts." }
                Start-Sleep -Seconds 2
                
                $cliJar = Get-ChildItem -Path "..\$cliPrefix", ".\$cliPrefix" -File -ErrorAction SilentlyContinue | Where-Object { ($_.Name -match "morphe-(cli|desktop)-") -and (($cliChoice -eq "2") -or ($_.Name -notmatch "-dev")) } | Sort-Object { [regex]::Replace($_.Name, '\d+', { $args[0].Value.PadLeft(4, '0') }) } -Descending | Select-Object -First 1
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
        
        if ($projectName -eq "Morphe") {
            Write-Host "1. YouTube`n2. YouTube Music`n3. Reddit`n4. All Applications"
            $appSelection = Read-ValidatedInput -Prompt "Enter choice(s) [e.g., 1, 2, or 4]" -RegexPattern "^[1-4](,[1-4])*$" -ErrorMessage "Invalid input. Enter numbers 1-4 separated by commas."
            
            $masterApps = @(
                @{ id = "1"; name = "YouTube"; package = "com.google.android.youtube"; keys = @("youtube"); exclude = @("music"); strip = $true; stable = $cfg_youtube_stable },
                @{ id = "2"; name = "YouTube_Music"; package = "com.google.android.apps.youtube.music"; keys = @("music", "ytmusic"); exclude = @(); strip = $true; stable = $cfg_youtube_music_stable },
                @{ id = "3"; name = "Reddit"; package = "com.reddit.frontpage"; keys = @("reddit"); exclude = @(); strip = $true; stable = $cfg_reddit_stable }
            )
        } elseif ($projectName -eq "Piko") {
            Write-Host "1. X (Twitter)`n2. Instagram`n3. All Applications"
            $appSelection = Read-ValidatedInput -Prompt "Enter choice(s) [e.g., 1, 2, or 3]" -RegexPattern "^[1-3](,[1-3])*$" -ErrorMessage "Invalid input. Enter numbers 1-3 separated by commas."
            
            $masterApps = @(
                @{ id = "1"; name = "X_Twitter"; package = "com.twitter.android"; keys = @("twitter", "x"); exclude = @(); strip = $true; stable = $cfg_x_stable },
                @{ id = "2"; name = "Instagram"; package = "com.instagram.android"; keys = @("instagram", "ig"); exclude = @(); strip = $true; stable = $cfg_ig_stable }
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
        } elseif ($projectName -eq "De-ReVanced") {
            Write-Host "1. Google Photos`n2. RAR`n3. All Applications"
            $appSelection = Read-ValidatedInput -Prompt "Enter choice(s) [e.g., 1, 2, or 3]" -RegexPattern "^[1-3](,[1-3])*$" -ErrorMessage "Invalid input. Enter numbers 1-3 separated by commas."
            
            $masterApps = @(
                @{ id = "1"; name = "Google_Photos"; package = "com.google.android.apps.photos"; keys = @("photos"); exclude = @(); strip = $true; stable = $cfg_photos_stable },
                @{ id = "2"; name = "RAR"; package = "com.rarlab.rar"; keys = @("rar"); exclude = @(); strip = $true; stable = $cfg_rar_stable }
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
            Write-Host "2. All Applications"
            $appSelection = Read-ValidatedInput -Prompt "Enter choice(s) [e.g., 1 or 2]" -RegexPattern "^[1-2](,[1-2])*$" -ErrorMessage "Invalid input. Enter numbers 1-2 separated by commas."
            
            $masterApps = @(
                @{ id = "1"; name = "Pinterest"; package = "com.pinterest"; keys = @("pinterest"); exclude = @(); strip = $true; stable = $cfg_pinterest_stable }
            )
        } elseif ($projectName -eq "PathxmOp") {
            Write-Host "1. Chess.com"
            Write-Host "2. All Applications"
            $appSelection = Read-ValidatedInput -Prompt "Enter choice(s) [e.g., 1 or 2]" -RegexPattern "^[1-2](,[1-2])*$" -ErrorMessage "Invalid input. Enter numbers 1-2 separated by commas."
            
            $masterApps = @(
                @{ id = "1"; name = "Chess"; package = "com.chess"; keys = @("chess", "^\d{5,8}_"); exclude = @(); strip = $true; stable = $cfg_chess_stable }
            )
        }

        $choices = $appSelection.Split(',')
        $selectAllId = switch ($projectName) { "Morphe" {"4"} "Piko" {"3"} "hoo-dles" {"12"} "De-ReVanced" {"3"} "BholeyKaBhakt" {"7"} "browzomje" {"2"} "PathxmOp" {"2"} }
        $selectedApps = @(if ($selectAllId -in $choices) { $masterApps } else { $masterApps | Where-Object { $_.id -in $choices } })

        Write-Host "`n[INFO] Place original .apk, .apkm, .xapk, or .apks files in '.\$projectName\Input'." -ForegroundColor DarkGray

        # Display application-specific notices.
        if ($selectedApps | Where-Object { $_.name -eq "Instagram" }) {
            Write-Host "Note for Instagram: Piko officially tested v$($cfg_ig_stable[0]) specifically on build code 384109456. Make sure to pick 'arm64-v8a'!" -ForegroundColor Magenta
        }
        if ($selectedApps | Where-Object { $_.name -eq "IbisPaint_X" }) {
            Write-Host "Note for IbisPaint X: Select 'arm64-v8a' in the next step, as it's the only supported architecture!" -ForegroundColor Magenta
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
                $v = $null
                foreach ($k in $app.keys) { $v = Get-ApkVersion -FileName $matched[0].Name -AppKeyword $k; if ($v) { break } }
                
                $tag = if ("Any" -in $app.stable) { " [SUPPORTED]" } elseif ($v -in $app.stable) { " [RECOMMENDED]" } else { " [MISMATCH]" }
                $color = if ($tag -match "MISMATCH") { "Yellow" } else { "Green" }
                Write-Host "  [✓] $($app.name) -> $($matched[0].Name)$tag" -ForegroundColor $color
                $matched[0] 
            } else {
                Write-Host "`nMultiple files detected for $($app.name):" -ForegroundColor Cyan
                for ($i = 0; $i -lt $matched.Count; $i++) {
                    $v = $null
                    foreach ($k in $app.keys) { $v = Get-ApkVersion -FileName $matched[$i].Name -AppKeyword $k; if ($v) { break } }
                    
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

            $ver = $null
            foreach ($k in $app.keys) { $ver = Get-ApkVersion -FileName $chosenApk.Name -AppKeyword $k; if ($ver) { break } }
            
            # Prompt for manual entry if version extraction fails.
            if (-not $ver) {
                $ver = Read-ValidatedInput -Prompt "Enter version manually for $($chosenApk.Name)" -RegexPattern "^(\d+(?:[\.-]\d+)*(?:-[a-zA-Z0-9\-\.]+)?|\d{7,})$" -ErrorMessage "Use format x.x.x, x-x-x, or a build number (e.g., 20260526)"
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
                        
                        # Constraint 1: Disunify xchat system
                        if ($app.TargetVersion -ne "11.69.0-release.0") {
                            if ($null -ne $jsonContent."Disunify xchat system" -and $jsonContent."Disunify xchat system".enabled -eq $true) {
                                Write-Host "`n[!] CRITICAL WARNING FOR X (TWITTER):" -ForegroundColor Red
                                Write-Host "    You enabled the 'Disunify xchat system' patch, but your APK is v$($app.TargetVersion)." -ForegroundColor Red
                                Write-Host "    This specific patch ONLY supports v11.69.0-release.0." -ForegroundColor Red
                                if (-not (Get-YesNoPrompt "    Force continue anyway? (Highly likely to crash)")) { $abortBatch = $true }
                            }
                        }
                        
                        # Constraint 2: Block redirecting to X Lite
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
                
                $apps = if ($eco.Name -eq "Morphe") { 
                    @(@{pkg="com.google.android.youtube"; name="youtube"}, 
                      @{pkg="com.google.android.apps.youtube.music"; name="youtube-music"}, 
                      @{pkg="com.reddit.frontpage"; name="reddit"}) 
                } elseif ($eco.Name -eq "Piko") { 
                    @(@{pkg="com.twitter.android"; name="x-twitter"}, 
                      @{pkg="com.instagram.android"; name="instagram"}) 
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
                } elseif ($eco.Name -eq "De-ReVanced") {
                    @(@{pkg="com.google.android.apps.photos"; name="google-photos"},
                      @{pkg="com.rarlab.rar"; name="rar"})
                } elseif ($eco.Name -eq "BholeyKaBhakt") {
                    @(@{pkg="org.zwanoo.android.speedtest"; name="speedtest"},
                      @{pkg="com.noctuasoftware.stellarium_free"; name="stellarium"},
                      @{pkg="com.proto.circuitsimulator"; name="proto"},
                      @{pkg="com.vpn.free.hotspot.secure.vpnify"; name="vpnify"},
                      @{pkg="com.backdrops.wallpapers"; name="backdrops"},
                      @{pkg="pl.solidexplorer2"; name="solid-explorer"})
                } elseif ($eco.Name -eq "browzomje") {
                    @(@{pkg="com.pinterest"; name="pinterest"})
                } elseif ($eco.Name -eq "PathxmOp") {
                    @(@{pkg="com.chess"; name="chess"})
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