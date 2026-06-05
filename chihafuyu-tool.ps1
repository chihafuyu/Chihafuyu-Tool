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
    Write-Host "Cannot determine script root directory. Please run directly." -ForegroundColor Red
    exit 1
}

# ==============================================================================
# RECOMMENDED APP VERSIONS
# ==============================================================================
$cfg_youtube_stable       = @("20.51.39", "20.47.62", "20.31.42", "20.21.37")
$cfg_youtube_music_stable = @("8.51.51", "8.47.56", "7.29.52")
$cfg_reddit_stable        = @("2026.14.0", "2026.10.0", "2026.04.0")

# Broken down into multiple lines for readability
$cfg_x_stable             = @(
    "11.95.1-release-ripped.0", 
    "11.80.0-alpha.1", 
    "11.82.0-beta.1", 
    "11.81.0-release.0", 
    "11.69.0-release.0"
)

$cfg_ig_stable            = @("430.0.0.53.80")
$cfg_adguard_stable       = @("4.12.81")
$cfg_ibispaint_stable     = @("14.0.1")
$cfg_wps_stable           = @("18.24")
$cfg_camscanner_stable    = @("7.15.5.2604080000")
$cfg_sleep_stable         = @("20260526")
$cfg_photos_stable        = @("Any")
$cfg_rar_stable           = @("Any")
# ==============================================================================

# Ensure JDK 21 or higher is installed as required by Morphe CLI
try {
    $javaVerOutput = (& java -version 2>&1) -join "`n"
    if ($LASTEXITCODE -ne 0) { throw "Java missing" }
    
    $regex = '"(?:1\.)?(\d+)'
    if ($javaVerOutput -match $regex) {
        $version = [int]$matches[1]
        if ($version -lt 21) {
            Clear-Host
            Write-Host "[!] Java Development Kit (JDK) 21 or higher is required!" -ForegroundColor Red
            Write-Host "    You currently have Java $version installed." -ForegroundColor Yellow
            Write-Host "    Please upgrade to Azul Zulu or Eclipse Temurin JDK 21 (LTS) and add it to PATH." -ForegroundColor Gray
            Write-Host "`nPress Enter to exit..." -ForegroundColor DarkGray
            $null = Read-Host
            exit 1
        }
    } else {
        throw "Cannot parse Java version"
    }
} catch {
    Clear-Host
    Write-Host "Java Development Kit (JDK) 21 is missing or misconfigured." -ForegroundColor Red
    Write-Host "Please install Azul Zulu or Eclipse Temurin JDK 21 (LTS) and add it to PATH." -ForegroundColor Gray
    Write-Host "`nPress Enter to exit..." -ForegroundColor DarkGray
    $null = Read-Host
    exit 1
}

function Get-ApkVersion {
    param([string]$FileName, [string]$AppKeyword)
    
    if ($FileName -notmatch '\.(apk|apkm|xapk|apks)$') { return $null }
    
    $baseName = $FileName -replace '\.(apk|apkm|xapk|apks)$', ''
    
    # Regex logic: Prioritize 7+ digit date codes (e.g., 20260526). 
    # For standard dot/dash formats, restrict suffixes to prevent swallowing architectures (like -arm64).
    $vPat = "(\b\d{7,}\b|\d+\.\d+(?:\.\d+)*(?:-(?:release|alpha|beta|rc|ripped|release-ripped)(?:\.\d+)+)?|\d+(?:-\d+)+(?:-(?:release|alpha|beta|rc|ripped|release-ripped)(?:\.\d+)+)?)"
    
    $patterns = @(
        @{ P = "$AppKeyword.*?[-_]$vPat\b"; W = 10 }
        @{ P = "$vPat[_-]?(?:\d+[_-])?(?:universal|arm64|v8a|x86_64|v7a|armeabi)"; W = 9 }
        @{ P = "v$vPat\b"; W = 7 }
        @{ P = "(?<!\d)$vPat\b"; W = 5 }
    )
    
    $foundVersions = @()
    foreach ($regex in $patterns) {
        if ($baseName -match $regex.P) {
            # Note: $Matches is the automatic PS variable populated by the -match operator
            $ext = $Matches[1]
            $ext = [regex]::Replace($ext, '(?<=\d)-(?=\d)', '.')
            
            # Using PSCustomObject fixes PowerShell's Hashtable sorting bug
            $foundVersions += [PSCustomObject]@{ Ver = $ext; Weight = $regex.W }
        }
    }
    
    if ($foundVersions.Count -eq 0) { return $null }
    
    # Fallback weight system to pick the most accurate version string if multiple matches occur
    $best = $foundVersions | Sort-Object Weight -Descending | Select-Object -First 1
    return $best.Ver
}

function Test-IsUniversalApk {
    param([string]$ApkPath)
    $zip = $null
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction Stop
        if ([System.IO.Path]::GetExtension($ApkPath) -ne ".apk") { return $false }
        
        # Basic validation to ensure the file is a valid Android package
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
        # Appended the back instruction dynamically to all Y/N prompts
        $input = (Read-Host "$Prompt (Y/N or 'B' to go back)").Trim()
        
        if ($input -match '^[bB]$') { throw "BACK_TO_MAIN" }
        if ($input -match '^[yYnN]$') { return ($input -match '^[yY]$') }
        
        Write-Host "  Invalid input. Please enter Y, N, or B." -ForegroundColor Red
    }
}

function Read-ValidatedInput {
    param([string]$Prompt, [string]$RegexPattern, [string]$ErrorMessage)
    while ($true) {
        # Appended the back instruction dynamically to all structured prompts
        $input = (Read-Host "$Prompt (or 'B' to go back)").Trim()
        
        if ($input -match '^[bB]$') { throw "BACK_TO_MAIN" }
        if ($input -match $RegexPattern) { return $input }
        
        Write-Host "  $ErrorMessage" -ForegroundColor Red
    }
}

function Resolve-Ecosystem {
    Write-Host "`n[SELECT] Target Ecosystem:" -ForegroundColor Yellow
    Write-Host "1. Morphe (YouTube, YT Music, Reddit)"
    Write-Host "2. Piko (X/Twitter, Instagram)"
    Write-Host "3. hoo-dles (AdGuard, IbisPaint X, WPS Office, CamScanner, Sleep as Android)"
    Write-Host "4. De-ReVanced (Google Photos, RAR)"
    Write-Host "5. Go back to Main Menu"
    $ecoChoice = Read-ValidatedInput -Prompt "Enter choice (1-5)" -RegexPattern "^[1-5]$" -ErrorMessage "Invalid input. Please enter 1-5."

    if ($ecoChoice -eq "5") {
        return $null
    }

    $projectName = switch ($ecoChoice) {
        "1" { "Morphe" }
        "2" { "Piko" }
        "3" { "hoo-dles" }
        "4" { "De-ReVanced" }
    }
    
    $workspace = Join-Path $PSScriptRoot $projectName

    # Create the directory structure if it does not exist
    if (-not (Test-Path -LiteralPath $workspace)) {
        New-Item -ItemType Directory -Path $workspace -Force | Out-Null
        Write-Host "  -> Created new workspace: .\$projectName" -ForegroundColor Green
    }
    
    foreach ($dir in @("Input", "Output")) {
        $dirPath = Join-Path $workspace $dir
        if (-not (Test-Path -LiteralPath $dirPath)) { New-Item -ItemType Directory -Path $dirPath -Force | Out-Null }
    }
    
    return @{ Name = $projectName; Workspace = $workspace }
}

function Resolve-EnvironmentArtifacts {
    param([string]$Workspace, [string]$ProjectName, [bool]$RequirePatches)
    
    Set-Location -LiteralPath $Workspace -ErrorAction Stop

    # Scan root and workspace directories for CLI engine jars
    $cliStableSearch = Get-ChildItem -Path "..\morphe-cli-*-all.jar", ".\morphe-cli-*-all.jar" -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch "-dev" } | Sort-Object Name -Descending | Select-Object -First 1
    $cliDevSearch = Get-ChildItem -Path "..\morphe-cli-*-dev.*-all.jar", ".\morphe-cli-*-dev.*-all.jar" -File -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1

    $cliStableDisplay = if ($cliStableSearch) { "[$($cliStableSearch.Name)]" } else { "[Not Found]" }
    $cliDevDisplay = if ($cliDevSearch) { "[$($cliDevSearch.Name)]" } else { "[Not Found]" }

    Write-Host "`n[SELECT] Patcher CLI Environment:" -ForegroundColor Yellow
    Write-Host -NoNewline "1. Latest Stable CLI "
    if ($cliStableDisplay -eq "[Not Found]") { Write-Host $cliStableDisplay -ForegroundColor Red } else { Write-Host $cliStableDisplay -ForegroundColor Green }
    Write-Host -NoNewline "2. Latest Pre-release CLI "
    if ($cliDevDisplay -eq "[Not Found]") { Write-Host $cliDevDisplay -ForegroundColor Red } else { Write-Host $cliDevDisplay -ForegroundColor Green }
    
    $cliChoice = Read-ValidatedInput -Prompt "Enter choice (1 or 2)" -RegexPattern "^[12]$" -ErrorMessage "Invalid input."

    $patchesChoice = "1"
    if ($RequirePatches) {
        # Scan workspace for .mpp patch bundles
        $patchStableSearch = Get-ChildItem -Path ".\patches-*.mpp" -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch "-dev" } | Sort-Object Name -Descending | Select-Object -First 1
        $patchDevSearch = Get-ChildItem -Path ".\patches-*-dev.*.mpp" -File -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1

        $patchStableDisplay = if ($patchStableSearch) { "[$($patchStableSearch.Name)]" } else { "[Not Found]" }
        $patchDevDisplay = if ($patchDevSearch) { "[$($patchDevSearch.Name)]" } else { "[Not Found]" }

        Write-Host "`n[SELECT] Patches Environment:" -ForegroundColor Yellow
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
    }

    # Pause execution and monitor directory if required files are missing
    if (-not $cliJar -or ($RequirePatches -and -not $patchesFile)) {
        Write-Host "`n[!] Required environment artifacts are missing!" -ForegroundColor Red
        if (-not $cliJar) { Write-Host "  - Missing Morphe CLI (.jar) in Root or .\$ProjectName folder." -ForegroundColor Yellow }
        if ($RequirePatches -and -not $patchesFile) { Write-Host "  - Missing Patches (.mpp) in .\$ProjectName folder." -ForegroundColor Yellow }
        
        Write-Host "`nWaiting for the missing files to be placed... (Press CTRL+C to abort)" -ForegroundColor Cyan
        
        $cliPrefix = if ($cliChoice -eq "1") { "morphe-cli-*-all.jar" } else { "morphe-cli-*-dev.*-all.jar" }
        $patchPrefix = if ($patchesChoice -eq "1") { "patches-*.mpp" } else { "patches-*-dev.*.mpp" }

        while (-not $cliJar -or ($RequirePatches -and -not $patchesFile)) {
            Start-Sleep -Seconds 2
            $cliJar = Get-ChildItem -Path "..\$cliPrefix", ".\$cliPrefix" -File -ErrorAction SilentlyContinue | Where-Object { ($cliChoice -eq "2") -or ($_.Name -notmatch "-dev") } | Sort-Object Name -Descending | Select-Object -First 1
            if ($RequirePatches) {
                $patchesFile = Get-ChildItem -Path ".\$patchPrefix" -File -ErrorAction SilentlyContinue | Where-Object { ($patchesChoice -eq "2") -or ($_.Name -notmatch "-dev") } | Sort-Object Name -Descending | Select-Object -First 1
            }
        }
        Write-Host "  [✓] Required artifacts found! Resuming process..." -ForegroundColor Green
    }

    $patchTrack = if ($patchesChoice -eq "1") { "stable" } else { "dev" }

    if ($cliChoice -eq "2" -or ($RequirePatches -and $patchesChoice -eq "2")) {
        Write-Host "`n[WARNING] Pre-Release Environment Detected" -ForegroundColor Yellow
        if (-not (Get-YesNoPrompt "Proceed with pre-release track?")) { return $null }
    }
    
    return @{ Cli = $cliJar; Patches = $patchesFile; Track = $patchTrack }
}

function Invoke-PatchingWorkflow {
    Clear-Host
    Write-Host "==============================================" -ForegroundColor Cyan
    Write-Host "          CHIHAFUYU TOOL - PATCHING           " -ForegroundColor Cyan
    Write-Host "==============================================" -ForegroundColor Cyan
    
    $eco = Resolve-Ecosystem
    if (-not $eco) { return }
    $projectName = $eco.Name; $workspace = $eco.Workspace
    
    $envArt = Resolve-EnvironmentArtifacts -Workspace $workspace -ProjectName $projectName -RequirePatches $true
    if (-not $envArt) { return }
    $cliJar = $envArt.Cli; $patchesFile = $envArt.Patches; $patchTrack = $envArt.Track

    Write-Host "`n[STEP 4] Select Target Application(s):" -ForegroundColor Yellow
    
    # Map ecosystem choices to their respective targets
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
        Write-Host "1. AdGuard`n2. IbisPaint X`n3. WPS Office`n4. CamScanner`n5. Sleep as Android`n6. All Applications"
        $appSelection = Read-ValidatedInput -Prompt "Enter choice(s) [e.g., 1, 2, or 6]" -RegexPattern "^[1-6](,[1-6])*$" -ErrorMessage "Invalid input. Enter numbers 1-6 separated by commas."
        
        $masterApps = @(
            @{ id = "1"; name = "AdGuard"; package = "com.adguard.android"; keys = @("adguard"); exclude = @(); strip = $true; stable = $cfg_adguard_stable },
            @{ id = "2"; name = "IbisPaint_X"; package = "jp.ne.ibis.ibispaintx.app"; keys = @("ibispaint", "ibis", "ibis-paint"); exclude = @(); strip = $true; stable = $cfg_ibispaint_stable },
            @{ id = "3"; name = "WPS_Office"; package = "cn.wps.moffice_eng"; keys = @("wps", "moffice"); exclude = @(); strip = $true; stable = $cfg_wps_stable },
            @{ id = "4"; name = "CamScanner"; package = "com.intsig.camscanner"; keys = @("camscanner"); exclude = @(); strip = $true; stable = $cfg_camscanner_stable },
            @{ id = "5"; name = "Sleep_as_Android"; package = "com.urbandroid.sleep"; keys = @("sleep", "urbandroid"); exclude = @(); strip = $true; stable = $cfg_sleep_stable }
        )
    } elseif ($projectName -eq "De-ReVanced") {
        Write-Host "1. Google Photos`n2. RAR`n3. All Applications"
        $appSelection = Read-ValidatedInput -Prompt "Enter choice(s) [e.g., 1, 2, or 3]" -RegexPattern "^[1-3](,[1-3])*$" -ErrorMessage "Invalid input. Enter numbers 1-3 separated by commas."
        
        $masterApps = @(
            @{ id = "1"; name = "Google_Photos"; package = "com.google.android.apps.photos"; keys = @("photos"); exclude = @(); strip = $true; stable = $cfg_photos_stable },
            @{ id = "2"; name = "RAR"; package = "com.rarlab.rar"; keys = @("rar"); exclude = @(); strip = $true; stable = $cfg_rar_stable }
        )
    }

    # Cast to ensure it's always an array even if a single item is selected
    $choices = $appSelection.Split(',')
    $selectAllId = switch ($projectName) { "Morphe" {"4"} "Piko" {"3"} "hoo-dles" {"6"} "De-ReVanced" {"3"} }
    $selectedApps = @(if ($selectAllId -in $choices) { $masterApps } else { $masterApps | Where-Object { $_.id -in $choices } })

    Write-Host "`n[INFO] Place original .apk, .apkm, .xapk, or .apks files in '.\$projectName\Input'." -ForegroundColor DarkGray
    Write-Host "Note: Universal .apk is highly recommended, but bundle formats are natively supported." -ForegroundColor Green

    # Safely scan the array of objects to trigger custom app-specific warnings
    if ($selectedApps | Where-Object { $_.name -eq "Reddit" }) {
        Write-Host "Note for Reddit: You can drop bundles directly if you don't have a Universal APK!" -ForegroundColor Magenta
    }
    if ($selectedApps | Where-Object { $_.name -eq "X_Twitter" }) {
        Write-Host "Note for X (Twitter): Versions 11.82.0+ have 'pairiplib.so' protection. Standard APKs WILL CRASH!" -ForegroundColor Red
        Write-Host "You MUST use the custom '11.95.1-release-ripped.0' APK from the Piko Telegram group: https://t.me/pikopatches" -ForegroundColor Magenta
        Write-Host "(For older versions, v11.69.0-release.0 is required if you enable 'Disunify xchat system')" -ForegroundColor DarkGray
    }
    if ($selectedApps | Where-Object { $_.name -eq "Instagram" }) {
        Write-Host "Note for Instagram: Piko officially tested v$($cfg_ig_stable[0]) specifically on build codes 383611190 and 383611231. Make sure to pick 'arm64-v8a'!" -ForegroundColor Magenta
    }
    if ($selectedApps | Where-Object { $_.name -eq "IbisPaint_X" }) {
        Write-Host "Note for IbisPaint X: Make sure to select 'arm64-v8a' in the next step, as it's the only supported architecture!" -ForegroundColor Magenta
    }

    Write-Host "`n[STEP 5] Validating Dependencies..." -ForegroundColor Yellow
    
    $allApks = Get-ChildItem -Path ".\Input\*" -Include *.apk, *.apkm, *.xapk, *.apks -File -ErrorAction SilentlyContinue
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
            $v = Get-ApkVersion -FileName $matched[0].Name -AppKeyword $app.keys[0]
            $tag = if ("Any" -in $app.stable) { " [SUPPORTED]" } elseif ($v -in $app.stable) { " [RECOMMENDED]" } else { " [MISMATCH]" }
            $color = if ($tag -match "MISMATCH") { "Yellow" } else { "Green" }
            Write-Host "  [✓] $($app.name) -> $($matched[0].Name)$tag" -ForegroundColor $color
            $matched[0] 
        } else {
            Write-Host "`nMultiple files detected for $($app.name):" -ForegroundColor Cyan
            for ($i = 0; $i -lt $matched.Count; $i++) {
                $v = Get-ApkVersion -FileName $matched[$i].Name -AppKeyword $app.keys[0]
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
            Write-Host "     Please use a fully merged or standalone Universal .apk, or a supported bundle (.apkm/.xapk/.apks)." -ForegroundColor Yellow
            if (-not (Get-YesNoPrompt "  Force continue anyway?")) { return }
        }

        $ver = Get-ApkVersion -FileName $chosenApk.Name -AppKeyword $app.keys[0]
        
        # Fallback to manual entry if our regex fails to catch the version
        if (-not $ver) {
            $ver = Read-ValidatedInput -Prompt "Enter version manually for $($chosenApk.Name)" -RegexPattern "^(\d+(?:[\.-]\d+)*(?:-[a-zA-Z0-9\-\.]+)?|\d{7,})$" -ErrorMessage "Use format x.x.x, x-x-x, or a build number (e.g., 20260526)"
        }

        $app.TargetApk = $chosenApk.FullName
        $app.TargetVersion = $ver
        
        if ("Any" -notin $app.stable -and $ver -notin $app.stable) { 
            $hasMismatch = $true; $app.RequiresForce = $true 
        }
    }

    if ($missingApps -gt 0) { return }
    if ($hasMismatch -and -not (Get-YesNoPrompt "`nVersion mismatches detected. Force patch?")) { return }

    Write-Host "`n[STEP 6] Select Target Architecture:" -ForegroundColor Yellow
    Write-Host "  [i] Heads up! Make sure you pick the architecture that matches your device." -ForegroundColor DarkGray
    Write-Host "      Picking the wrong one could mean a sluggish app, or worse, crashes/broken functionality." -ForegroundColor DarkGray
    Write-Host "      Not sure? Grab an app like AIDA64 or CPU-Z and check the 'CPU ABI' or 'System Architecture' info." -ForegroundColor DarkGray
    Write-Host "1. arm64-v8a`n2. armeabi-v7a`n3. x86_64`n4. x86`n5. Universal"
    $archChoice = Read-ValidatedInput -Prompt "Choice (1-5)" -RegexPattern "^[1-5]$" -ErrorMessage "Invalid input."
    
    $targetArch = switch ($archChoice) {
        "1" { "arm64-v8a" } "2" { "armeabi-v7a" } "3" { "x86_64" } "4" { "x86" } "5" { "universal" }
    }

    Write-Host "`n[STEP 7] Configuration:" -ForegroundColor Yellow
    $useCustomKeystore = Get-YesNoPrompt "Use custom keystore?"
    
    $keystoreFile = $null; $keystoreAlias = $null; $securePass = $null; $secureEntryPass = $null; $customSigner = $null
    
    if ($useCustomKeystore) {
        Write-Host "  1. Enter credentials manually"
        Write-Host "  2. Load from 'custom-keystore.txt'"
        $ksMethod = Read-ValidatedInput -Prompt "Choice (1-2)" -RegexPattern "^[12]$" -ErrorMessage "Invalid input."

        if ($ksMethod -eq "2") {
            $ksConfigFile = Join-Path $PSScriptRoot "custom-keystore.txt"
            
            if (-not (Test-Path -LiteralPath $ksConfigFile)) {
                $template = "# Keystore configuration file`n" +
                            "# KeystorePath: Enter the filename (if placed in the same folder as this script) OR the full path (e.g., C:\Keys\my-release-key.keystore)`n" +
                            "KeystorePath=my-release-key.keystore`n" +
                            "KeystoreAlias=MyAlias`n" +
                            "KeystorePassword=my_password`n" +
                            "KeystoreEntryPassword=my_entry_password`n" +
                            "# Note: SignerName must be max 8 chars, NO SPACES (Android META-INF limitation)`n" +
                            "SignerName=MySigner"
                Set-Content -LiteralPath $ksConfigFile -Value $template -Encoding UTF8
                Write-Host "  [!] 'custom-keystore.txt' not found. A template has been created in the root folder." -ForegroundColor Yellow
                Write-Host "      Please fill in your details, save the file, and run the script again." -ForegroundColor Yellow
                Write-Host "`nPress Enter to restart session..." -ForegroundColor DarkGray
                $null = Read-Host
                return
            }
            
            Write-Host "  [i] Reading 'custom-keystore.txt'..." -ForegroundColor DarkGray
            
            $ksConfig = @{}
            Get-Content -LiteralPath $ksConfigFile | Where-Object { $_ -match '=' -and $_ -notmatch '^\s*#' } | ForEach-Object {
                $split = $_ -split '=', 2
                $ksConfig[$split[0].Trim()] = $split[1].Trim()
            }
            
            $ks = $ksConfig['KeystorePath']
            if (-not [string]::IsNullOrWhiteSpace($ks)) {
                if (-not [System.IO.Path]::IsPathRooted($ks)) { $ks = Join-Path $PSScriptRoot $ks }
                if (Test-Path -LiteralPath $ks -PathType Leaf) { 
                    $keystoreFile = $ks 
                } else {
                    Write-Host "  [!] Keystore file not found at: $ks" -ForegroundColor Red
                    Write-Host "`nPress Enter to restart session..." -ForegroundColor DarkGray
                    $null = Read-Host
                    return
                }
            } else {
                Write-Host "  [!] KeystorePath is empty or missing in config." -ForegroundColor Red
                Write-Host "`nPress Enter to restart session..." -ForegroundColor DarkGray
                $null = Read-Host
                return
            }
            
            $rawAlias = $ksConfig['KeystoreAlias']
            if (-not [string]::IsNullOrWhiteSpace($rawAlias)) {
                $keystoreAlias = $rawAlias
            } else {
                $keystoreAlias = "Morphe"
            }
            
            $rawPass = if ($null -ne $ksConfig['KeystorePassword']) { $ksConfig['KeystorePassword'] } else { "" }
            $securePass = ConvertTo-SecureString $rawPass -AsPlainText -Force
            $rawPass = $null
            
            $rawEntryPass = if ($null -ne $ksConfig['KeystoreEntryPassword']) { $ksConfig['KeystoreEntryPassword'] } else { "" }
            $secureEntryPass = ConvertTo-SecureString $rawEntryPass -AsPlainText -Force
            $rawEntryPass = $null
            
            $rawSigner = $ksConfig['SignerName']
            if (-not [string]::IsNullOrWhiteSpace($rawSigner)) {
                $sanitizedSigner = $rawSigner -replace '[^a-zA-Z0-9_\-]', ''
                if ($sanitizedSigner.Length -gt 8) {
                    $sanitizedSigner = $sanitizedSigner.Substring(0, 8)
                }
                
                if ($rawSigner -ne $sanitizedSigner) {
                    Write-Host "  [i] SignerName '$rawSigner' auto-formatted to '$sanitizedSigner' to comply with Android 8-char limit." -ForegroundColor Yellow
                }
                $customSigner = $sanitizedSigner
            } else {
                $customSigner = $null
            }
            
            Write-Host "  [✓] Keystore configuration loaded successfully." -ForegroundColor Green
            
        } else {
            while ($true) {
                # Add 'B' handling specifically for manual path entry
                $ks = (Read-Host "Keystore filename/path (or 'B' to go back)").Trim().Trim('"').Trim("'")
                if ($ks -match '^[bB]$') { throw "BACK_TO_MAIN" }
                if (-not [System.IO.Path]::IsPathRooted($ks)) { $ks = Join-Path $PSScriptRoot $ks }
                if (Test-Path -LiteralPath $ks -PathType Leaf) { $keystoreFile = $ks; break }
                Write-Host "  File not found: $ks" -ForegroundColor Red
            }
            $keystoreAlias = Read-ValidatedInput -Prompt "Alias" -RegexPattern "^[a-zA-Z0-9_\-\s]+$" -ErrorMessage "Alphanumeric, spaces, underscores, and dashes only."
            $securePass = Read-Host "Password" -AsSecureString
            $secureEntryPass = Read-Host "Entry Password" -AsSecureString
            
            $useCustomSigner = Get-YesNoPrompt "Use custom signer?"
            if ($useCustomSigner) { 
                Write-Host "  [i] Android limits META-INF signatures (SignerName) to max 8 characters, NO spaces." -ForegroundColor DarkGray
                $customSigner = Read-ValidatedInput -Prompt "Signer name" -RegexPattern "^[a-zA-Z0-9_\-]{1,8}$" -ErrorMessage "Max 8 chars, no spaces. Use alphanumeric or dashes." 
            }
        }
    }

    Write-Host "`n[STEP 8] Exporting Available Patches List..." -ForegroundColor Yellow
    $patchesListFile = Join-Path $workspace "list-patches-$patchTrack.txt"
    
    # Remove existing files first to prevent Morphe CLI from throwing a silent exit code 1 on overwrite
    if (Test-Path -LiteralPath $patchesListFile) { Remove-Item -LiteralPath $patchesListFile -Force -ErrorAction SilentlyContinue }
    
    $cliAbsPath = $cliJar.FullName
    $patchAbsPath = $patchesFile.FullName
    
    $listArgs = @(
        "-jar", 
        $cliAbsPath, 
        "list-patches", 
        "--with-packages", 
        "--with-versions", 
        "--with-options", 
        "--out=$patchesListFile", 
        "--patches=$patchAbsPath"
    )
    
    $null = & java $listArgs 2>&1
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $patchesListFile)) {
        Write-Host "  Failed to create patches reference file." -ForegroundColor Red
    } else {
        $headerText  = "========================================================================`n"
        $headerText += " Generated via Chihafuyu Tool`n"
        $headerText += " This tool utilizes patches and code from $projectName.`n"
        if ($projectName -eq "Morphe") {
            $headerText += " To learn more, visit https://morphe.software`n"
        } elseif ($projectName -eq "Piko") {
            $headerText += " To learn more, visit https://github.com/crimera/piko`n"
        } elseif ($projectName -eq "hoo-dles") {
            $headerText += " To learn more, visit https://github.com/hoo-dles/morphe-patches`n"
        } elseif ($projectName -eq "De-ReVanced") {
            $headerText += " To learn more, visit https://github.com/RookieEnough/De-ReVanced`n"
        }
        $headerText += "========================================================================`n`n"
        
        $originalContent = Get-Content -LiteralPath $patchesListFile -Raw
        Set-Content -LiteralPath $patchesListFile -Value ($headerText + $originalContent) -Encoding UTF8
        
        Write-Host "  Reference file created: $(Split-Path $patchesListFile -Leaf)" -ForegroundColor Green
    }

    Write-Host "`n[STEP 9] Generating Option Files..." -ForegroundColor Yellow

    foreach ($app in $selectedApps) {
        if (-not $app.TargetApk) { continue }
        
        $jsonFileName = Join-Path $workspace "$($app.name.ToLower().Replace('_','-'))-options-$patchTrack.json"
        
        # Remove existing files first to prevent Morphe CLI from throwing a silent exit code 1 on overwrite
        if (Test-Path -LiteralPath $jsonFileName) { Remove-Item -LiteralPath $jsonFileName -Force -ErrorAction SilentlyContinue }
        
        $optArgs = @(
            "-jar", 
            $cliAbsPath, 
            "options-create", 
            "--patches=$patchAbsPath", 
            "--out=$jsonFileName", 
            "--filter-package-name=$($app.package)"
        )
        
        $null = & java $optArgs 2>&1
        
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $jsonFileName)) {
            Write-Host "  [!] Options generation failed for $($app.name). Aborting." -ForegroundColor Red
            return
        }
        Write-Host "  [✓] Options generated for $($app.name)" -ForegroundColor Green
    }

    Write-Host "`n[STEP 10] Options Generated Successfully." -ForegroundColor Cyan
    if (Get-YesNoPrompt "Modify JSON files before patching?") {
        Write-Host "  [TIP] Confused on what to edit? Check the '$(Split-Path $patchesListFile -Leaf)' file generated in Step 8 for reference." -ForegroundColor DarkGray
        Write-Host "Awaiting manual modifications. Press any key to resume..." -ForegroundColor Magenta
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }

    $constraintError = $false
    foreach ($app in $selectedApps) {
        if ($app.name -eq "X_Twitter" -and $app.TargetVersion -ne "11.69.0-release.0") {
            $jsonFileName = Join-Path $workspace "$($app.name.ToLower().Replace('_','-'))-options-$patchTrack.json"
            if (Test-Path -LiteralPath $jsonFileName) {
                try {
                    # Safety check: Prevent a known Twitter bootloop if the xchat patch is forced on an incompatible version
                    $jsonContent = Get-Content -LiteralPath $jsonFileName -Raw | ConvertFrom-Json
                    if ($null -ne $jsonContent."Disunify xchat system" -and $jsonContent."Disunify xchat system".enabled -eq $true) {
                        Write-Host "`n[!] CRITICAL WARNING FOR X (TWITTER):" -ForegroundColor Red
                        Write-Host "    You enabled the 'Disunify xchat system' patch, but your APK is v$($app.TargetVersion)." -ForegroundColor Red
                        Write-Host "    This specific patch ONLY supports v11.69.0-release.0." -ForegroundColor Red
                        $constraintError = $true
                    }
                } catch { }
            }
        }
    }
    
    if ($constraintError) {
        if (-not (Get-YesNoPrompt "    Force continue anyway? (Highly likely to fail/crash)")) {
            return
        }
    }

    Write-Host "`n[STEP 11] Bytecode Mode Configuration..." -ForegroundColor Yellow
    $bytecodeMode = $null
    
    $isWindowsOS = ($env:OS -eq 'Windows_NT')
    
    if ($isWindowsOS) {
        Write-Host "  [i] Skipped. Morphe CLI currently forces 'FULL' bytecode mode on Windows." -ForegroundColor DarkGray
    } else {
        if (Get-YesNoPrompt "Configure custom bytecode mode? (--bytecode-mode)") {
            Write-Host "1. FULL       (Legacy: rebuilds all dex, slow, highest memory)"
            Write-Host "2. STRIP_FAST (CLI Default: fastest, least memory, bigger APK)"
            Write-Host "3. STRIP_SAFE (Manager Default: balanced speed, memory, and APK size)"
            $bcChoice = Read-ValidatedInput -Prompt "Choice (1-3)" -RegexPattern "^[1-3]$" -ErrorMessage "Invalid input."
            $bytecodeMode = switch ($bcChoice) {
                "1" { "FULL" }
                "2" { "STRIP_FAST" }
                "3" { "STRIP_SAFE" }
            }
        }
    }

    Write-Host "`n[STEP 12] Signing Configuration..." -ForegroundColor Yellow
    $disableSigning = Get-YesNoPrompt "Disable signing of the final apk? (--unsigned)"

    Write-Host "`n[STEP 13] Verification Configuration..." -ForegroundColor Yellow
    $verifyWithSdk = Get-YesNoPrompt "Verify the patched app with a local Android SDK? (--verify-with-sdk)"
    if ($verifyWithSdk) {
        Write-Host "  [i] Just a heads up: You'll need a proper Android SDK installed on your machine for this to work," -ForegroundColor DarkGray
        Write-Host "      specifically the 'build-tools' and 'platforms' packages." -ForegroundColor DarkGray
        Write-Host "      If Morphe CLI can't find them, the patching process will throw an error and abort." -ForegroundColor DarkGray
    }

    Write-Host "`n[STEP 14] Patching & Cleanup Sequence..." -ForegroundColor Yellow
    $continueOnError = Get-YesNoPrompt "Skip failed patches and continue? (--continue-on-error)"
    
    # JVM Heap Allocation: Calculate physical RAM and set a safe -Xmx limit to prevent OutOfMemory crashes
    $heapSize = "2G"
    try {
        $ramInfo = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
        if ($ramInfo) {
            $sysRamGB = [math]::Round($ramInfo.TotalPhysicalMemory / 1GB)
            if ($sysRamGB -ge 8) { 
                $heapSize = "4G" 
            } elseif ($sysRamGB -ge 6) { 
                $heapSize = "3G" 
            }
            Write-Host "  [i] Detected System RAM: ${sysRamGB}GB. Auto-adjusting Java Heap Space to: -$heapSize" -ForegroundColor DarkGray
        }
    } catch {
        Write-Host "  [i] Could not detect RAM. Using safe fallback Java Heap Space: -$heapSize" -ForegroundColor DarkGray
    }
    
    $tempLogFile = Join-Path $workspace "Output\temp_patch_log.txt"
    if (Test-Path -LiteralPath $tempLogFile) { Remove-Item -LiteralPath $tempLogFile -Force -ErrorAction Ignore }
    
    # Rely on Morphe 1.9.0+ native morphe-data/tmp/ handling and instruct it to self-purge
    try {
        $plainPass = $null; $plainEntryPass = $null
        $bstr1 = [IntPtr]::Zero; $bstr2 = [IntPtr]::Zero
        
        if ($useCustomKeystore) {
            $bstr1 = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePass)
            $plainPass = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr1)
            $bstr2 = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureEntryPass)
            $plainEntryPass = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr2)
        }

        foreach ($app in $selectedApps) {
            if (-not $app.TargetApk) { continue }
            
            $jsonFileName = Join-Path $workspace "$($app.name.ToLower().Replace('_','-'))-options-$patchTrack.json"
            $outputApkAbs = Join-Path $workspace "Output\$($app.name)_$($projectName)_$($app.TargetVersion)-$targetArch.apk"
            
            $tempResultFile = Join-Path $workspace "Output\temp_result_$($app.name).json"
            if (Test-Path -LiteralPath $tempResultFile) { Remove-Item -LiteralPath $tempResultFile -Force -ErrorAction Ignore }
            
            Write-Host "`n>>> PATCHING: $($app.name) (v$($app.TargetVersion)) <<<" -ForegroundColor Magenta
            
            $logHeader = "`n" + ("=" * 60) + "`n>>> LOG FOR: $($app.name) (v$($app.TargetVersion)) <<<`n" + ("=" * 60) + "`n"
            Add-Content -LiteralPath $tempLogFile -Value $logHeader -Encoding UTF8
            
            $baseArgs = @(
                "-Xmx$heapSize",
                "-jar", 
                $cliAbsPath, 
                "patch", 
                "--patches=$patchAbsPath", 
                "--options-file=$jsonFileName", 
                $app.TargetApk, 
                "--out=$outputApkAbs", 
                "--result-file=$tempResultFile",
                "--purge"
            )
            
            if ($bytecodeMode) { $baseArgs += "--bytecode-mode=$bytecodeMode" }
            if ($patchTrack -eq "dev" -or $app.RequiresForce) { $baseArgs += "--force" }
            if ($verifyWithSdk) { $baseArgs += "--verify-with-sdk" }
            
            if ($disableSigning) {
                $baseArgs += "--unsigned"
            } elseif ($useCustomKeystore) { 
                # If custom keystore is NOT enabled, Morphe natively defaults to morphe-data/morphe.keystore
                $baseArgs += "--keystore=$keystoreFile", "--keystore-entry-alias=$keystoreAlias", "--keystore-password=$plainPass", "--keystore-entry-password=$plainEntryPass" 
                if ($customSigner) { $baseArgs += "--signer=$customSigner" }
            }
            
            # Enforce stripping of unnecessary native libraries if a specific architecture is selected
            if ($app.strip -and ($targetArch -ne "universal")) { 
                $baseArgs += "--striplibs=$targetArch" 
            }

            if ($continueOnError) { $baseArgs += "--continue-on-error" }

            Write-Host "  Executing Patcher CLI..." -ForegroundColor DarkGray
            
            # Stream the Java output to the console and temp log file simultaneously
            & java $baseArgs 2>&1 | Tee-Object -FilePath $tempLogFile -Append | ForEach-Object { Write-Host $_ }
            
            # Workaround for Windows memory-mapped file lock issue
            if ($isWindowsOS) {
                Write-Host "  [i] Sweeping Morphe CLI native temp files (Windows workaround)..." -ForegroundColor DarkGray
                Start-Sleep -Seconds 2
                
                $morpheTmpDirs = @(
                    Join-Path $cliJar.Directory.FullName "morphe-data\tmp",
                    Join-Path $env:USERPROFILE "morphe\tmp"
                )
                foreach ($tmpDir in $morpheTmpDirs) {
                    if (Test-Path -LiteralPath $tmpDir) {
                        Remove-Item -Path "$tmpDir\*" -Recurse -Force -ErrorAction SilentlyContinue
                    }
                }
            }

            if ($LASTEXITCODE -ne 0) {
                Write-Host "  [!] Patching FAILED (Exit Code: $LASTEXITCODE)" -ForegroundColor Red
                if (-not $continueOnError) { break }
            } else {
                Write-Host "  [✓] Patching SUCCEEDED" -ForegroundColor Green
            }
        }
    } finally {
        # Free unmanaged memory pointers to prevent password leaks
        if ($bstr1 -ne [IntPtr]::Zero) { [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr1) }
        if ($bstr2 -ne [IntPtr]::Zero) { [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr2) }
        
        # Trigger explicit Garbage Collection to flush out the standard string representations
        if ($plainPass) { 
            $plainPass = $null; Clear-Variable plainPass -ErrorAction Ignore
            [System.GC]::Collect(); [System.GC]::WaitForPendingFinalizers() 
        }
        if ($plainEntryPass) { 
            $plainEntryPass = $null; Clear-Variable plainEntryPass -ErrorAction Ignore
            [System.GC]::Collect(); [System.GC]::WaitForPendingFinalizers() 
        }
        
        if ($securePass) { $securePass.Dispose() }
        if ($secureEntryPass) { $secureEntryPass.Dispose() }
    }

    Write-Host "`n[SUCCESS] Operations concluded." -ForegroundColor Green

    if (Get-YesNoPrompt "`nExport patching logs?") {
        $logPath = Join-Path $workspace "Output\Patch_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
        if (Test-Path -LiteralPath $tempLogFile) { 
            Rename-Item -LiteralPath $tempLogFile -NewName (Split-Path $logPath -Leaf) 
            Write-Host "  -> Log exported successfully to: .\Output\$(Split-Path $logPath -Leaf)" -ForegroundColor Green
        }
    } else {
        if (Test-Path -LiteralPath $tempLogFile) { Remove-Item -LiteralPath $tempLogFile -ErrorAction Ignore }
    }

    if (Get-YesNoPrompt "Export patching result JSON? (--result-file)") {
        foreach ($app in $selectedApps) {
            $tempResultFile = Join-Path $workspace "Output\temp_result_$($app.name).json"
            if (Test-Path -LiteralPath $tempResultFile) {
                $finalResultName = "Result_$($app.name)_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
                Rename-Item -LiteralPath $tempResultFile -NewName $finalResultName
                Write-Host "  -> JSON result exported to: .\Output\$finalResultName" -ForegroundColor Green
            }
        }
    } else {
        foreach ($app in $selectedApps) {
            $tempResultFile = Join-Path $workspace "Output\temp_result_$($app.name).json"
            if (Test-Path -LiteralPath $tempResultFile) { Remove-Item -LiteralPath $tempResultFile -ErrorAction Ignore }
        }
    }

    if (Get-YesNoPrompt "Open output directory?") { Invoke-Item ".\Output" }
    
    Write-Host "`nPress Enter to return to Main Menu..." -ForegroundColor Magenta
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
    Write-Host "6. Go back to Main Menu"
    Write-Host "X. Close Tool"
    
    $utilChoice = Read-ValidatedInput -Prompt "Enter choice" -RegexPattern "^[1-6xX]$" -ErrorMessage "Invalid input. Please enter 1-6, or X."
    
    if ($utilChoice -match '^[xX]$') { exit 0 }
    if ($utilChoice -eq '6') { return }
    
    if ($utilChoice -in @('1', '2')) {
        Write-Host "`n  [i] HEADS UP: This feature relies on ADB. Make sure you have Android 'platform-tools' installed and added to your system PATH!" -ForegroundColor Cyan
        
        $eco = Resolve-Ecosystem
        if (-not $eco) { return }
        $envArt = Resolve-EnvironmentArtifacts -Workspace $eco.Workspace -ProjectName $eco.Name -RequirePatches $false
        if (-not $envArt) { return }
        $cliAbsPath = $envArt.Cli.FullName
        
        if ($utilChoice -eq '1') {
            Write-Host "`n[INSTALL] Select Install Mode:" -ForegroundColor Yellow
            Write-Host "1. Non-Root (Standard Install via --apk)"
            Write-Host "2. Root (Mount Install via --mount)"
            $installMode = Read-ValidatedInput -Prompt "Enter choice (1 or 2)" -RegexPattern "^[12]$" -ErrorMessage "Invalid input."
            
            # Explicit back instruction added for manual file drop
            $apkPath = Read-Host "Drag and drop the APK file here, or enter the full path (or 'B' to go back)"
            $apkPath = $apkPath.Trim().Trim('"').Trim("'")
            if ($apkPath -match '^[bB]$') { throw "BACK_TO_MAIN" }
            
            if (-not (Test-Path -LiteralPath $apkPath -PathType Leaf)) {
                Write-Host "  [!] APK file not found at: $apkPath" -ForegroundColor Red
            } else {
                Write-Host "  [i] Ensure your device is connected via USB and ADB debugging is authorized." -ForegroundColor DarkGray
                
                # Enforce safe RAM limits here too just to be consistent
                $baseArgs = @("-Xmx2G", "-jar", $cliAbsPath, "utility", "install", "-a", $apkPath)
                if ($installMode -eq '2') {
                    $pkg = Read-ValidatedInput -Prompt "Target Package Name (e.g., com.google.android.youtube)" -RegexPattern "^[a-zA-Z0-9_\.]+$" -ErrorMessage "Invalid package name."
                    $baseArgs += "-m"
                    $baseArgs += $pkg
                }
                
                Write-Host "`nExecuting Morphe Utility..." -ForegroundColor Magenta
                & java $baseArgs
            }
        } 
        elseif ($utilChoice -eq '2') {
            Write-Host "`n[UNINSTALL] Select Uninstall Mode:" -ForegroundColor Yellow
            Write-Host "1. Non-Root (Standard Uninstall via --package-name)"
            Write-Host "2. Root (Unmount via --unmount)"
            $uninstallMode = Read-ValidatedInput -Prompt "Enter choice (1 or 2)" -RegexPattern "^[12]$" -ErrorMessage "Invalid input."
            
            $pkg = Read-ValidatedInput -Prompt "Target Package Name (e.g., com.google.android.youtube)" -RegexPattern "^[a-zA-Z0-9_\.]+$" -ErrorMessage "Invalid package name format."
            
            Write-Host "  [i] Ensure your device is connected via USB and ADB debugging is authorized." -ForegroundColor DarkGray
            
            $baseArgs = @("-Xmx2G", "-jar", $cliAbsPath, "utility", "uninstall", "-p", $pkg)
            if ($uninstallMode -eq '2') {
                $baseArgs += "--unmount"
            }
            
            Write-Host "`nExecuting Morphe Utility..." -ForegroundColor Magenta
            & java $baseArgs
        }
    }
    elseif ($utilChoice -in @('3', '4')) {
        $eco = Resolve-Ecosystem
        if (-not $eco) { return }
        $envArt = Resolve-EnvironmentArtifacts -Workspace $eco.Workspace -ProjectName $eco.Name -RequirePatches $true
        if (-not $envArt) { return }
        
        $cliAbsPath = $envArt.Cli.FullName
        $patchAbsPath = $envArt.Patches.FullName
        
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
                  @{pkg="com.urbandroid.sleep"; name="sleep-as-android"})
            } elseif ($eco.Name -eq "De-ReVanced") {
                @(@{pkg="com.google.android.apps.photos"; name="google-photos"},
                  @{pkg="com.rarlab.rar"; name="rar"})
            }
            
            foreach ($app in $apps) {
                $jsonFileName = Join-Path $eco.Workspace "$($app.name)-options-$($envArt.Track).json"
                
                # Remove existing files first to prevent Morphe CLI from throwing a silent exit code 1 on overwrite
                if (Test-Path -LiteralPath $jsonFileName) { Remove-Item -LiteralPath $jsonFileName -Force -ErrorAction SilentlyContinue }
                
                $optArgs = @(
                    "-Xmx2G",
                    "-jar", 
                    $cliAbsPath,
                    "options-create", 
                    "--patches=$patchAbsPath", 
                    "--out=$jsonFileName", 
                    "--filter-package-name=$($app.pkg)"
                )
                
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
            
            # Remove existing files first to prevent Morphe CLI from throwing a silent exit code 1 on overwrite
            if (Test-Path -LiteralPath $patchesListFile) { Remove-Item -LiteralPath $patchesListFile -Force -ErrorAction SilentlyContinue }
            
            $listArgs = @("-Xmx2G", "-jar", $cliAbsPath, "list-patches", "--with-packages", "--with-versions", "--with-options", "--out=$patchesListFile", "--patches=$patchAbsPath")
            
            & java $listArgs
            
            if ($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath $patchesListFile)) {
                Write-Host "  [✓] Reference file created successfully in .\$($eco.Name)\" -ForegroundColor Green
            } else {
                Write-Host "  [!] Failed to create patches reference file." -ForegroundColor Red
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
    
    Write-Host "`nPress Enter to return to Main Menu..." -ForegroundColor Magenta
    $null = Read-Host
}

function Invoke-MainMenu {
    Clear-Host
    Write-Host "==============================================" -ForegroundColor Cyan
    Write-Host "                CHIHAFUYU TOOL                " -ForegroundColor Cyan
    Write-Host "==============================================" -ForegroundColor Cyan
    
    Write-Host "`nWhat do you want to do?" -ForegroundColor Yellow
    Write-Host "1. Patching apps"
    Write-Host "2. Using utility"
    Write-Host "X. Close"

    while ($true) {
        $choice = (Read-Host "Enter choice (1, 2, or X)").Trim()
        
        if ($choice -match '^[xX]$') { 
            return $false 
        }
        elseif ($choice -eq '1') {
            try {
                Invoke-PatchingWorkflow
            } catch {
                if ($_.Exception.Message -eq "BACK_TO_MAIN") {
                    Write-Host "`n[i] Operation aborted. Returning to Main Menu..." -ForegroundColor Yellow
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
                    Write-Host "`n[i] Operation aborted. Returning to Main Menu..." -ForegroundColor Yellow
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
        else {
            Write-Host "  Invalid input. Please enter 1, 2, or X." -ForegroundColor Red
        }
    }
}

while (Invoke-MainMenu) { 
}

Write-Host "`nSession ended. Have a great day!" -ForegroundColor Cyan
Start-Sleep -Seconds 2

# Forces a clean exit code so the terminal doesn't flash previous Java errors
exit 0