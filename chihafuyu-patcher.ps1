<#
.SYNOPSIS
    Chihafuyu Patcher
    A straightforward tool to automate Android app patching using standard CLI patchers.

.DESCRIPTION
    Simplifies the Android application patching workflow. Automates artifact 
    discovery, enforces version validation, manages secure credentials, 
    and optimizes APK size via architecture stripping. Natively supports 
    standard APKs and app bundles (.apkm, .xapk, .apks).

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

# Enforce minimum PowerShell version required to run this script safely
#Requires -Version 5.1

if ([string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    Write-Host "Cannot determine script root directory. Please run directly." -ForegroundColor Red
    exit 1
}

# ==============================================================================
# RECOMMENDED APP VERSIONS
# ==============================================================================
# Morphe
$cfg_youtube_stable       = "20.47.62"
$cfg_youtube_music_stable = "8.47.56"
$cfg_reddit_stable        = "2026.04.0"

# Piko
$cfg_x_stable             = "Any"
$cfg_ig_stable            = "423.0.0.47.66"
# ==============================================================================

# Check for JDK 17
try {
    $null = & java -version 2>&1
    if ($LASTEXITCODE -ne 0) { throw "Java returned non-zero" }
} catch {
    Clear-Host
    Write-Host "Java Development Kit (JDK) 17 is missing or misconfigured." -ForegroundColor Red
    Write-Host "Please install Azul Zulu or Eclipse Temurin JDK 17 and add it to PATH." -ForegroundColor Gray
    exit 1
}

# --- Helpers ---

function Get-ApkVersion {
    param([string]$FileName, [string]$AppKeyword)
    
    if ($FileName -notmatch '\.(apk|apkm|xapk|apks)$') { return $null }
    
    $baseName = $FileName -replace '\.(apk|apkm|xapk|apks)$', ''
    
    $patterns = @(
        @{ P = "$AppKeyword(?:[\._-]android)?[-_](\d+\.\d+\.\d+(?:\.\d{1,6})*(-release\.\d+)?)\b"; W = 10 }
        @{ P = "(\d+\.\d+\.\d+(?:\.\d{1,6})*(-release\.\d+)?)[_-]?(?:\d+[_-])?(?:universal|arm64|v8a|x86_64|v7a)"; W = 9 }
        @{ P = "v(\d+\.\d+\.\d+(?:\.\d{1,6})*(-release\.\d+)?)\b"; W = 7 }
        @{ P = "(\d+\.\d+\.\d+(?:\.\d{1,6})*(-release\.\d+)?)\b"; W = 5 }
    )
    
    $matches = @()
    foreach ($regex in $patterns) {
        if ($baseName -match $regex.P) {
            $matches += @{ Ver = $Matches[1]; Weight = $regex.W }
        }
    }
    
    if ($matches.Count -eq 0) { return $null }
    $best = $matches | Sort-Object Weight -Descending | Select-Object -First 1
    return $best.Ver
}

function Test-IsUniversalApk {
    param([string]$ApkPath)
    $zip = $null
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction Stop
        if ([System.IO.Path]::GetExtension($ApkPath) -ne ".apk") { return $false }
        
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
        $input = (Read-Host "$Prompt (Y/N)").Trim()
        if ($input -match '^[yYnN]$') { return ($input -match '^[yY]$') }
        Write-Host "  Invalid input. Please enter Y or N." -ForegroundColor Red
    }
}

function Read-ValidatedInput {
    param([string]$Prompt, [string]$RegexPattern, [string]$ErrorMessage)
    while ($true) {
        $input = (Read-Host $Prompt).Trim()
        if ($input -match $RegexPattern) { return $input }
        Write-Host "  $ErrorMessage" -ForegroundColor Red
    }
}

# --- Core Logic ---

function Invoke-PatchingSession {
    Set-Location -Path $PSScriptRoot -ErrorAction Stop

    Clear-Host
    Write-Host "==============================================" -ForegroundColor Cyan
    Write-Host "              CHIHAFUYU PATCHER               " -ForegroundColor Cyan
    Write-Host "==============================================" -ForegroundColor Cyan

    Write-Host "`n[STEP 1] Select Target Ecosystem:" -ForegroundColor Yellow
    Write-Host "1. Morphe (YouTube, YT Music, Reddit)"
    Write-Host "2. Piko (X/Twitter, Instagram)"
    $ecoChoice = Read-ValidatedInput -Prompt "Enter choice (1 or 2)" -RegexPattern "^[12]$" -ErrorMessage "Invalid input."

    $projectName = if ($ecoChoice -eq "1") { "Morphe" } else { "Piko" }
    $workspace = Join-Path $PSScriptRoot $projectName

    if (-not (Test-Path $workspace)) {
        New-Item -ItemType Directory -Path $workspace -Force | Out-Null
        Write-Host "  -> Created new workspace: .\$projectName" -ForegroundColor Green
    }
    
    Set-Location -Path $workspace -ErrorAction Stop

    foreach ($dir in @("Input", "Output")) {
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    }

    Write-Host "`n[STEP 2] Select Patcher CLI Environment:" -ForegroundColor Yellow
    Write-Host "1. Latest Stable CLI`n2. Latest Pre-release CLI"
    $cliChoice = Read-ValidatedInput -Prompt "Enter choice (1 or 2)" -RegexPattern "^[12]$" -ErrorMessage "Invalid input."

    Write-Host "`n[STEP 3] Select Patches Environment:" -ForegroundColor Yellow
    Write-Host "1. Latest Stable Patches`n2. Latest Pre-release Patches"
    $patchesChoice = Read-ValidatedInput -Prompt "Enter choice (1 or 2)" -RegexPattern "^[12]$" -ErrorMessage "Invalid input."

    $cliPrefix = if ($cliChoice -eq "1") { "morphe-cli-*-all.jar" } else { "morphe-cli-*-dev.*-all.jar" }
    $patchPrefix = if ($patchesChoice -eq "1") { "patches-*.mpp" } else { "patches-*-dev.*.mpp" }
    
    $cliJar = Get-ChildItem -Path $PSScriptRoot, $workspace -Filter $cliPrefix -File -ErrorAction SilentlyContinue | Where-Object { ($cliChoice -eq "2") -or ($_.Name -notmatch "-dev") } | Sort-Object Name -Descending | Select-Object -First 1
    $patchesFile = Get-ChildItem -Path $workspace -Filter $patchPrefix -File -ErrorAction SilentlyContinue | Where-Object { ($patchesChoice -eq "2") -or ($_.Name -notmatch "-dev") } | Sort-Object Name -Descending | Select-Object -First 1

    if (-not $cliJar -or -not $patchesFile) {
        Write-Host "`n[!] Required environment artifacts are missing!" -ForegroundColor Red
        if (-not $cliJar) { Write-Host "  - Missing Morphe CLI (.jar) in Root or .\$projectName folder." -ForegroundColor Yellow }
        if (-not $patchesFile) { Write-Host "  - Missing Patches (.mpp) in .\$projectName folder." -ForegroundColor Yellow }
        Write-Host "`nPlace the required files and try again." -ForegroundColor Gray
        return $false 
    }

    $patchTrack = if ($patchesChoice -eq "1") { "stable" } else { "dev" }

    if ($cliChoice -eq "2" -or $patchesChoice -eq "2") {
        Write-Host "`n[WARNING] Pre-Release Environment Detected" -ForegroundColor Yellow
        if (-not (Get-YesNoPrompt "Proceed with pre-release track?")) { return $false }
    }

    Write-Host "`n[STEP 4] Select Target Application(s):" -ForegroundColor Yellow
    if ($projectName -eq "Morphe") {
        Write-Host "1. YouTube`n2. YouTube Music`n3. Reddit`n4. All Applications"
        $appSelection = Read-ValidatedInput -Prompt "Enter choice(s) [e.g., 1, 2, or 4]" -RegexPattern "^[1-4](,[1-4])*$" -ErrorMessage "Invalid input. Enter numbers 1-4 separated by commas."
        
        $masterApps = @(
            @{ id = "1"; name = "YouTube"; package = "com.google.android.youtube"; keys = @("youtube"); exclude = @("music"); strip = $true; stable = $cfg_youtube_stable },
            @{ id = "2"; name = "YouTube_Music"; package = "com.google.android.apps.youtube.music"; keys = @("music", "ytmusic"); exclude = @(); strip = $true; stable = $cfg_youtube_music_stable },
            @{ id = "3"; name = "Reddit"; package = "com.reddit.frontpage"; keys = @("reddit"); exclude = @(); strip = $true; stable = $cfg_reddit_stable }
        )
    } else {
        Write-Host "1. X (Twitter)`n2. Instagram`n3. All Applications"
        $appSelection = Read-ValidatedInput -Prompt "Enter choice(s) [e.g., 1, 2, or 3]" -RegexPattern "^[1-3](,[1-3])*$" -ErrorMessage "Invalid input. Enter numbers 1-3 separated by commas."
        
        $masterApps = @(
            @{ id = "1"; name = "X_Twitter"; package = "com.twitter.android"; keys = @("twitter", "x"); exclude = @(); strip = $true; stable = $cfg_x_stable },
            @{ id = "2"; name = "Instagram"; package = "com.instagram.android"; keys = @("instagram", "ig"); exclude = @(); strip = $true; stable = $cfg_ig_stable }
        )
    }

    $choices = $appSelection.Split(',')
    $selectAllId = if ($projectName -eq "Morphe") { "4" } else { "3" }
    $selectedApps = @(if ($selectAllId -in $choices) { $masterApps } else { $masterApps | Where-Object { $_.id -in $choices } })

    Write-Host "`n[INFO] Place original .apk, .apkm, .xapk, or .apks files in '.\$projectName\Input'." -ForegroundColor DarkGray
    Write-Host "Note: Universal .apk is highly recommended, but bundle formats are natively supported." -ForegroundColor Green

    if ($selectedApps.name -contains "Reddit") {
        Write-Host "Note for Reddit: You can drop bundles directly if you don't have a Universal APK!" -ForegroundColor Magenta
    }
    if ($selectedApps.name -contains "X_Twitter") {
        Write-Host "Note for X (Twitter): Supports latest versions. However, if you manually enable the 'Disunify xchat system' patch, you MUST use v11.69.0-release.0!" -ForegroundColor Magenta
    }

    Write-Host "`n[STEP 5] Validating Dependencies..." -ForegroundColor Yellow
    
    $allApks = Get-ChildItem "Input\*" -Include *.apk, *.apkm, *.xapk, *.apks -File -ErrorAction SilentlyContinue
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
            $tag = if ($app.stable -eq "Any") { " [SUPPORTED]" } elseif ($v -eq $app.stable) { " [RECOMMENDED]" } else { " [MISMATCH]" }
            $color = if ($tag -match "MISMATCH") { "Yellow" } else { "Green" }
            Write-Host "  [✓] $($app.name) -> $($matched[0].Name)$tag" -ForegroundColor $color
            $matched[0] 
        } else {
            Write-Host "`nMultiple files detected for $($app.name):" -ForegroundColor Cyan
            for ($i = 0; $i -lt $matched.Count; $i++) {
                $v = Get-ApkVersion -FileName $matched[$i].Name -AppKeyword $app.keys[0]
                $tag = if ($app.stable -eq "Any") { " [SUPPORTED]" } elseif ($v -eq $app.stable) { " [RECOMMENDED]" } else { " [MISMATCH]" }
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
            if (-not (Get-YesNoPrompt "  Force continue anyway?")) { return $false }
        }

        $ver = Get-ApkVersion -FileName $chosenApk.Name -AppKeyword $app.keys[0]
        if (-not $ver) {
            $ver = Read-ValidatedInput -Prompt "Enter version manually for $($chosenApk.Name)" -RegexPattern "^\d+\.\d+\.\d+(?:\.\d+)*(-release\.\d+)?$" -ErrorMessage "Use format x.x.x or x.x.x-release.x"
        }

        $app.TargetApk = $chosenApk.FullName
        $app.TargetVersion = $ver
        
        if ($app.stable -ne "Any" -and $ver -ne $app.stable) { 
            $hasMismatch = $true; $app.RequiresForce = $true 
        }
    }

    if ($missingApps -gt 0) { return $false }
    if ($hasMismatch -and -not (Get-YesNoPrompt "`nVersion mismatches detected. Force patch?")) { return $false }

    Write-Host "`n[STEP 6] Select Target Architecture:" -ForegroundColor Yellow
    Write-Host "1. arm64-v8a`n2. armeabi-v7a`n3. x86_64`n4. x86`n5. Universal"
    $archChoice = Read-ValidatedInput -Prompt "Choice (1-5)" -RegexPattern "^[1-5]$" -ErrorMessage "Invalid input."
    
    $targetArch = switch ($archChoice) {
        "1" { "arm64-v8a" } "2" { "armeabi-v7a" } "3" { "x86_64" } "4" { "x86" } "5" { "universal" }
    }

    Write-Host "`n[STEP 7] Configuration:" -ForegroundColor Yellow
    $useCustomKeystore = Get-YesNoPrompt "Use custom keystore?"
    
    $keystoreFile = $null; $keystoreAlias = $null; $securePass = $null; $secureEntryPass = $null
    
    if ($useCustomKeystore) {
        while ($true) {
            $ks = (Read-Host "Keystore filename/path").Trim()
            if (-not [System.IO.Path]::IsPathRooted($ks)) { $ks = Join-Path $PSScriptRoot $ks }
            if (Test-Path -LiteralPath $ks -PathType Leaf) { $keystoreFile = $ks; break }
            Write-Host "  File not found: $ks" -ForegroundColor Red
        }
        $keystoreAlias = Read-ValidatedInput -Prompt "Alias" -RegexPattern "^[a-zA-Z0-9_\-]+$" -ErrorMessage "Alphanumeric, underscores, and dashes only."
        $securePass = Read-Host "Password" -AsSecureString
        $secureEntryPass = Read-Host "Entry Password" -AsSecureString
    }
    
    $useCustomSigner = Get-YesNoPrompt "Use custom signer?"
    $customSigner = if ($useCustomSigner) { Read-ValidatedInput -Prompt "Signer name" -RegexPattern "^[a-zA-Z0-9_\-\s]+$" -ErrorMessage "Invalid characters." } else { $null }

    Write-Host "`n[STEP 8] Exporting Available Patches List..." -ForegroundColor Yellow
    $patchesListFile = "list-patches-$patchTrack.txt"
    
    $cliRelPath = if ($cliJar.DirectoryName -eq $workspace) { ".\$($cliJar.Name)" } else { "..\$($cliJar.Name)" }
    $patchRelPath = ".\$($patchesFile.Name)"
    
    $listArgs = @("-jar", $cliRelPath, "list-patches", "--with-packages", "--with-versions", "--with-options", "--out=$patchesListFile", "--patches=$patchRelPath")
    
    $null = & java $listArgs 2>&1
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $patchesListFile)) {
        Write-Host "  Failed to create patches reference file." -ForegroundColor Red
    } else {
        $headerText  = "========================================================================`n"
        $headerText += " Generated via Chihafuyu Patcher`n"
        $headerText += " This tool utilizes patches and code from $projectName.`n"
        if ($projectName -eq "Morphe") {
            $headerText += " To learn more, visit https://morphe.software`n"
        } elseif ($projectName -eq "Piko") {
            $headerText += " To learn more, visit https://github.com/crimera/piko`n"
        }
        $headerText += "========================================================================`n`n"
        
        $originalContent = Get-Content -Path $patchesListFile -Raw
        Set-Content -Path $patchesListFile -Value ($headerText + $originalContent) -Encoding UTF8
        
        Write-Host "  Reference file created: $patchesListFile" -ForegroundColor Green
    }

    Write-Host "`n[STEP 9] Generating Option Files..." -ForegroundColor Yellow

    foreach ($app in $selectedApps) {
        if (-not $app.TargetApk) { continue }
        
        $jsonFileName = "$($app.name.ToLower().Replace('_','-'))-options-$patchTrack.json"
        if (Test-Path $jsonFileName) { Remove-Item $jsonFileName -Force }
        
        $optArgs = @("-jar", $cliRelPath, "options-create", "--patches=$patchRelPath", "--out=$jsonFileName", "--filter-package-name=$($app.package)")
        
        $null = & java $optArgs 2>&1
        
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path $jsonFileName)) {
            Write-Host "  [!] Options generation failed for $($app.name). Aborting." -ForegroundColor Red
            return $false
        }
        Write-Host "  [✓] Options generated for $($app.name)" -ForegroundColor Green
    }

    Write-Host "`n[STEP 10] Options Generated Successfully." -ForegroundColor Cyan
    if (Get-YesNoPrompt "Modify JSON files before patching?") {
        Write-Host "  [TIP] Confused on what to edit? Check the '$patchesListFile' file generated in Step 8 for reference." -ForegroundColor DarkGray
        Write-Host "Awaiting manual modifications. Press any key to resume..." -ForegroundColor Magenta
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }

    Write-Host "`n[STEP 11] Bytecode Mode Configuration..." -ForegroundColor Yellow
    $bytecodeMode = $null
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

    Write-Host "`n[STEP 12] Signing Configuration..." -ForegroundColor Yellow
    $disableSigning = Get-YesNoPrompt "Disable signing of the final apk? (--unsigned)"

    Write-Host "`n[STEP 13] Patching Sequence..." -ForegroundColor Yellow
    $continueOnError = Get-YesNoPrompt "Skip failed patches and continue? (--continue-on-error)"
    
    $tempLogFile = "Output\temp_patch_log.txt"
    if (Test-Path $tempLogFile) { Remove-Item $tempLogFile -Force -ErrorAction Ignore }

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
            
            $jsonFileName = "$($app.name.ToLower().Replace('_','-'))-options-$patchTrack.json"
            $outputApkRelative = ".\Output\$($app.name)_$($projectName)_$($app.TargetVersion)-$targetArch.apk"
            
            Write-Host "`n>>> PATCHING: $($app.name) (v$($app.TargetVersion)) <<<" -ForegroundColor Magenta
            
            $logHeader = "`n" + ("=" * 60) + "`n>>> LOG FOR: $($app.name) (v$($app.TargetVersion)) <<<`n" + ("=" * 60) + "`n"
            Add-Content -Path $tempLogFile -Value $logHeader -Encoding UTF8
            
            $baseArgs = @("-jar", $cliRelPath, "patch", "--patches=$patchRelPath", "--options-file=$jsonFileName", $app.TargetApk, "--out=$outputApkRelative", "--purge")
            
            if ($bytecodeMode) { $baseArgs += "--bytecode-mode=$bytecodeMode" }
            if ($patchTrack -eq "dev" -or $app.RequiresForce) { $baseArgs += "--force" }
            
            if ($disableSigning) {
                $baseArgs += "--unsigned"
            } else {
                if ($useCustomKeystore) { 
                    $baseArgs += "--keystore=$keystoreFile", "--keystore-entry-alias=$keystoreAlias", "--keystore-password=$plainPass", "--keystore-entry-password=$plainEntryPass" 
                }
                if ($customSigner) { $baseArgs += "--signer=$customSigner" }
            }
            
            $isArchSpecific = (Split-Path $app.TargetApk -Leaf) -match "(?i)(arm64|armeabi|v7a|v8a|x86|x86_64|mips|mips64|riscv64)"
            if ($app.name -eq "Reddit") { $isArchSpecific = $false }
            if ($app.strip -and ($targetArch -ne "universal") -and -not $isArchSpecific) { $baseArgs += "--striplibs=$targetArch" }
            if ($continueOnError) { $baseArgs += "--continue-on-error" }

            Write-Host "  Executing Patcher CLI..." -ForegroundColor DarkGray
            
            & java $baseArgs 2>&1 | Tee-Object -FilePath $tempLogFile -Append | ForEach-Object { Write-Host $_ }
            
            if ($LASTEXITCODE -ne 0) {
                Write-Host "  [!] Patching FAILED (Exit Code: $LASTEXITCODE)" -ForegroundColor Red
                if (-not $continueOnError) { break }
            } else {
                Write-Host "  [✓] Patching SUCCEEDED" -ForegroundColor Green
            }
        }
    } finally {
        if ($bstr1 -ne [IntPtr]::Zero) { [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr1) }
        if ($bstr2 -ne [IntPtr]::Zero) { [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr2) }
        
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
        if (Test-Path $tempLogFile) { 
            Rename-Item $tempLogFile -NewName (Split-Path $logPath -Leaf) 
            Write-Host "  -> Log exported successfully to: .\Output\$(Split-Path $logPath -Leaf)" -ForegroundColor Green
        }
    } else {
        if (Test-Path $tempLogFile) { Remove-Item $tempLogFile -ErrorAction Ignore }
    }

    if (Get-YesNoPrompt "Open output directory?") { Invoke-Item ".\Output" }
    
    return (Get-YesNoPrompt "Initiate a new workflow session?")
}

# --- Runner ---

while (Invoke-PatchingSession) { Start-Sleep -Seconds 1 }

Write-Host "`nSession ended. Have a great day!" -ForegroundColor Cyan
Start-Sleep -Seconds 2
exit