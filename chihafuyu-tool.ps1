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
Set-StrictMode -Version 3.0

if ([string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    Write-Error "Cannot determine the script root directory. Please run the script directly."
    exit 1
}

# Script-scoped state for options backup decision:
#   $null  = ask per file
#   $true  = always backup
#   $false = always overwrite
$script:OptionsBackupMode = $null

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

function Write-Ui {
    <#
    .SYNOPSIS
        Writes colored console UI lines without polluting pipeline return values.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSAvoidUsingWriteHost',
        '',
        Justification = 'Interactive console UI requires host-colored output without polluting function return pipelines.'
    )]
    param(
        [Parameter(Position = 0)]
        [AllowEmptyString()]
        [string]$Message = "",

        [Parameter()]
        [ConsoleColor]$ForegroundColor,

        [Parameter()]
        [switch]$NoNewline
    )

    $params = @{
        Object    = $Message
        NoNewline = $NoNewline
    }
    if ($PSBoundParameters.ContainsKey('ForegroundColor')) {
        $params['ForegroundColor'] = $ForegroundColor
    }
    Write-Host @params
}

function Clear-UiScreen {
    try {
        if (-not [System.Console]::IsOutputRedirected) {
            Clear-Host
        }
    } catch {
        Write-Verbose $_.Exception.Message
    }
}

function Read-SafeLine {
    param(
        [string]$Prompt,
        [switch]$NoPrompt
    )

    $raw = if ($NoPrompt -or [string]::IsNullOrEmpty($Prompt)) {
        Read-Host
    } else {
        Read-Host -Prompt $Prompt
    }
    if ($null -eq $raw) {
        return ""
    }
    return $raw.Trim()
}

function Wait-KeyOrEnter {
    param([string]$Message)

    if (-not [string]::IsNullOrEmpty($Message)) {
        Write-Ui $Message -ForegroundColor Magenta
    }

    if ([System.Console]::IsInputRedirected) {
        $null = Read-SafeLine -NoPrompt
        return
    }

    try {
        $null = [System.Console]::ReadKey($true)
    } catch {
        $null = Read-SafeLine -NoPrompt
    }
}

function Invoke-NativeTool {
    <#
    .SYNOPSIS
        Executes an external CLI process safely across PS 5.1 and PS 7, preserving exit codes
        even when the caller session sets $ErrorActionPreference = 'Stop'.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Executable,

        [Parameter(Mandatory)]
        [string[]]$Arguments,

        [Parameter()]
        [string]$LogFilePath,

        [Parameter()]
        [switch]$StreamToConsole,

        [Parameter()]
        [ConsoleColor]$StreamColor
    )

    $prevEap = $ErrorActionPreference
    $writer = $null
    $capturedLines = [System.Collections.Generic.List[string]]::new()
    $exitCode = 1

    try {
        # Prevent Windows PowerShell 5.1 from converting redirected stderr (2>&1) into terminating errors.
        $ErrorActionPreference = 'Continue'

        if (-not [string]::IsNullOrWhiteSpace($LogFilePath)) {
            $writer = [System.IO.StreamWriter]::new($LogFilePath, $true, [System.Text.UTF8Encoding]::new($false))
        }

        & $Executable @Arguments 2>&1 | ForEach-Object {
            $line = if ($_ -is [System.Management.Automation.ErrorRecord]) {
                $_.ToString()
            } else {
                "$_"
            }

            if ($null -ne $writer) {
                $writer.WriteLine($line)
            }
            if ($StreamToConsole) {
                if ($PSBoundParameters.ContainsKey('StreamColor')) {
                    Write-Ui $line -ForegroundColor $StreamColor
                } else {
                    Write-Ui $line
                }
            } else {
                $capturedLines.Add($line)
            }
        }

        $exitCode = if ($null -ne $LASTEXITCODE) { [int]$LASTEXITCODE } else { 0 }
    } finally {
        $ErrorActionPreference = $prevEap
        if ($null -ne $writer) {
            $writer.Dispose()
        }
    }

    return [PSCustomObject]@{
        ExitCode = $exitCode
        Output   = $capturedLines.ToArray()
    }
}

function ConvertTo-SecureStringValue {
    <#
    .SYNOPSIS
        Builds a read-only SecureString from a string via character array clearing,
        avoiding ConvertTo-SecureString -AsPlainText and PS 5.1 empty-string crashes.
    #>
    param(
        [AllowEmptyString()]
        [string]$Text
    )

    $secure = [System.Security.SecureString]::new()
    if (-not [string]::IsNullOrEmpty($Text)) {
        $chars = $Text.ToCharArray()
        try {
            foreach ($ch in $chars) {
                $secure.AppendChar($ch)
            }
        } finally {
            [Array]::Clear($chars, 0, $chars.Length)
        }
    }
    $secure.MakeReadOnly()
    return $secure
}

function ConvertFrom-SecureStringToBstrValue {
    <#
    .SYNOPSIS
        Extracts the plaintext string from a SecureString while immediately freeing
        and zeroing the intermediate unmanaged BSTR allocation.
    #>
    param(
        [Parameter(Mandatory)]
        [System.Security.SecureString]$SecureValue
    )

    $bstr = [IntPtr]::Zero
    try {
        $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureValue)
        return [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    } finally {
        if ($bstr -ne [IntPtr]::Zero) {
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
        }
    }
}

function Test-JavaEnvironment {
    <#
    .SYNOPSIS
        Validates that Java Development Kit 25 or higher is installed and available on PATH.
        Morphe Desktop requires JDK 25+ due to a Windows file lock bug in older runtimes.
    #>
    try {
        if (-not (Get-Command -Name 'java' -ErrorAction SilentlyContinue)) {
            throw "Java executable not found in PATH."
        }

        $res = Invoke-NativeTool -Executable 'java' -Arguments @('-version')
        if ($res.ExitCode -ne 0) {
            throw "Java exited with code $($res.ExitCode)."
        }

        $javaVerOutput = $res.Output -join "`n"
        # Target the version string that appears after the "version" keyword, not just any number in quotes.
        if ($javaVerOutput -match 'version\s+"(?:1\.)?(\d+)') {
            $version = [int]$Matches[1]
            if ($version -lt 25) {
                Clear-UiScreen
                Write-Ui "[!] Java Development Kit (JDK) 25 or higher is required!" -ForegroundColor Red
                Write-Ui "    You currently have Java $version installed." -ForegroundColor Yellow
                Write-Ui "    Please upgrade to Azul Zulu or Eclipse Temurin JDK 25 (LTS) and add it to PATH." -ForegroundColor Gray
                Write-Ui "`nPress Enter to exit..." -ForegroundColor DarkGray
                $null = Read-SafeLine -NoPrompt
                return $false
            }
            return $true
        }

        throw "Cannot parse the Java version output."
    } catch {
        Clear-UiScreen
        Write-Ui "Java Development Kit (JDK) 25 is missing or misconfigured." -ForegroundColor Red
        Write-Ui "Please install Azul Zulu or Eclipse Temurin JDK 25 (LTS) and add it to PATH." -ForegroundColor Gray
        Write-Ui "`nPress Enter to exit..." -ForegroundColor DarkGray
        $null = Read-SafeLine -NoPrompt
        return $false
    }
}

function Get-EcosystemCatalog {
    <#
    .SYNOPSIS
        Single source of truth for supported ecosystems, menu labels, and application metadata.
    #>
    return @(
        @{
            Id          = "1"
            Name        = "De-Vanced"
            Summary     = "Google Photos"
            Apps        = @(
                @{ id = "1"; label = "Google Photos"; name = "Google_Photos"; package = "com.google.android.apps.photos"; keys = @("photos"); exclude = @(); strip = $true; stable = $cfg_photos_stable }
            )
        },
        @{
            Id          = "2"
            Name        = "hoo-dles"
            Summary     = "AdGuard, CamScanner, Duolingo, IbisPaint X, Lightroom Mobile, Merriam-Webster, Mimo, MyFitnessPal, PyDroid3, Sleep as Android, Smart Launcher, Windy, WPS Office, Xodo, XRecorder"
            Apps        = @(
                @{ id = "1";  label = "AdGuard";          name = "AdGuard";          package = "com.adguard.android";                   keys = @("adguard");                                         exclude = @(); strip = $true; stable = $cfg_adguard_stable },
                @{ id = "2";  label = "CamScanner";       name = "CamScanner";       package = "com.intsig.camscanner";                 keys = @("camscanner");                                      exclude = @(); strip = $true; stable = $cfg_camscanner_stable },
                @{ id = "3";  label = "Duolingo";         name = "Duolingo";         package = "com.duolingo";                          keys = @("duolingo");                                        exclude = @(); strip = $true; stable = $cfg_duolingo_stable },
                @{ id = "4";  label = "IbisPaint X";      name = "IbisPaint_X";      package = "jp.ne.ibis.ibispaintx.app";             keys = @("ibispaint", "ibis", "ibis-paint");                 exclude = @(); strip = $true; stable = $cfg_ibispaint_stable },
                @{ id = "5";  label = "Lightroom Mobile"; name = "Lightroom_Mobile"; package = "com.adobe.lrmobile";                    keys = @("lightroom", "lrmobile");                           exclude = @(); strip = $true; stable = $cfg_lightroom_stable },
                @{ id = "6";  label = "Merriam-Webster";  name = "Merriam_Webster";  package = "com.merriamwebster";                    keys = @("merriam", "webster", "merriamwebster");            exclude = @(); strip = $true; stable = $cfg_merriamwebster_stable },
                @{ id = "7";  label = "Mimo";             name = "Mimo";             package = "com.getmimo";                           keys = @("mimo");                                            exclude = @(); strip = $true; stable = $cfg_mimo_stable },
                @{ id = "8";  label = "MyFitnessPal";     name = "MyFitnessPal";     package = "com.myfitnesspal.android";              keys = @("myfitnesspal");                                    exclude = @(); strip = $true; stable = $cfg_myfitnesspal_stable },
                @{ id = "9";  label = "PyDroid3";         name = "PyDroid3";         package = "ru.iiec.pydroid3";                      keys = @("pydroid", "pydroid3");                             exclude = @(); strip = $true; stable = $cfg_pydroid3_stable },
                @{ id = "10"; label = "Sleep as Android"; name = "Sleep_as_Android"; package = "com.urbandroid.sleep";                  keys = @("sleep", "urbandroid");                             exclude = @(); strip = $true; stable = $cfg_sleep_stable },
                @{ id = "11"; label = "Smart Launcher";   name = "Smart_Launcher";   package = "ginlemon.flowerfree";                   keys = @("smartlauncher", "smart[-_\s]?launcher", "flowerfree"); exclude = @(); strip = $true; stable = $cfg_smartlauncher_stable },
                @{ id = "12"; label = "Windy";            name = "Windy";            package = "com.windyty.android";                   keys = @("windy", "windyty");                                exclude = @(); strip = $true; stable = $cfg_windy_stable },
                @{ id = "13"; label = "WPS Office";       name = "WPS_Office";       package = "cn.wps.moffice_eng";                    keys = @("wps", "moffice");                                  exclude = @(); strip = $true; stable = $cfg_wps_stable },
                @{ id = "14"; label = "Xodo";             name = "Xodo";             package = "com.xodo.pdf.reader";                   keys = @("xodo");                                            exclude = @(); strip = $true; stable = $cfg_xodo_stable },
                @{ id = "15"; label = "XRecorder";        name = "XRecorder";        package = "videoeditor.videorecorder.screenrecorder"; keys = @("xrecorder", "screenrecorder", "videorecorder");   exclude = @(); strip = $true; stable = $cfg_xrecorder_stable }
            )
        },
        @{
            Id          = "3"
            Name        = "hxreborn"
            Summary     = "Projectivy Launcher, Proton Mail, Symfonium"
            Apps        = @(
                @{ id = "1"; label = "Projectivy Launcher"; name = "Projectivy_Launcher"; package = "com.spocky.projengmenu";    keys = @("projectivy", "projengmenu"); exclude = @();        strip = $true; stable = $cfg_projectivy_stable },
                @{ id = "2"; label = "Proton Mail";         name = "Proton_Mail";         package = "ch.protonmail.android";     keys = @("proton", "protonmail");      exclude = @("vpn");   strip = $true; stable = $cfg_protonmail_stable },
                @{ id = "3"; label = "Symfonium";           name = "Symfonium";           package = "app.symfonik.music.player"; keys = @("symfonium", "symfonik");     exclude = @();        strip = $true; stable = $cfg_symfonium_stable }
            )
        },
        @{
            Id          = "4"
            Name        = "jasonwu1994"
            Summary     = "Gboard"
            Apps        = @(
                @{ id = "1"; label = "Gboard"; name = "Gboard"; package = "com.google.android.inputmethod.latin"; keys = @("gboard", "inputmethod"); exclude = @(); strip = $true; stable = $cfg_gboard_stable }
            )
        },
        @{
            Id          = "5"
            Name        = "kiraio-moe"
            Summary     = "Atomic, Boorusama, Epic!, Fake GPS, Hermit, Hidden Settings, iLovePDF, Key Mapper, Keymate, Manga Plus, Nekopoi, PixelLab, Pixiv, Timestamp Camera"
            Apps        = @(
                @{ id = "1";  label = "Atomic";                name = "Atomic";            package = "com.jlindemann.science";             keys = @("atomic", "science");                                          exclude = @(); strip = $true; stable = $cfg_atomic_stable },
                @{ id = "2";  label = "Boorusama";             name = "Boorusama";         package = "com.degenk.boorusama";                 keys = @("boorusama");                                                  exclude = @(); strip = $true; stable = $cfg_boorusama_stable },
                @{ id = "3";  label = "Epic!";                 name = "Epic";              package = "com.getepic.Epic";                     keys = @("epic");                                                       exclude = @(); strip = $true; stable = $cfg_epic_stable },
                @{ id = "4";  label = "Fake GPS Location";     name = "Fake_GPS_Location"; package = "com.hopefactory2021.fakegpslocation";  keys = @("fakegps", "fake-gps");                                        exclude = @(); strip = $true; stable = $cfg_fakegps_stable },
                @{ id = "5";  label = "Hermit";                name = "Hermit";            package = "com.chimbori.hermitcrab";              keys = @("hermit");                                                     exclude = @(); strip = $true; stable = $cfg_hermit_stable },
                @{ id = "6";  label = "Hidden Settings";       name = "Hidden_Settings";   package = "com.ceyhan.sets";                      keys = @("hidden", "(?<![a-z0-9])sets(?![a-z0-9])");                  exclude = @(); strip = $true; stable = $cfg_hiddensets_stable },
                @{ id = "7";  label = "iLovePDF";              name = "iLovePDF";          package = "com.ilovepdf.www";                     keys = @("ilovepdf");                                                   exclude = @(); strip = $true; stable = $cfg_ilovepdf_stable },
                @{ id = "8";  label = "Key Mapper";            name = "Key_Mapper";        package = "io.github.sds100.keymapper";           keys = @("keymapper", "key-mapper");                                    exclude = @(); strip = $true; stable = $cfg_keymapper_stable },
                @{ id = "9";  label = "Keymate";               name = "Keymate";           package = "net.nemostudio.keymate";               keys = @("keymate");                                                    exclude = @(); strip = $true; stable = $cfg_keymate_stable },
                @{ id = "10"; label = "Manga Plus";            name = "Manga_Plus";        package = "jp.co.shueisha.mangaplus";             keys = @("mangaplus", "manga-plus");                                    exclude = @(); strip = $true; stable = $cfg_mangaplus_stable },
                @{ id = "11"; label = "Nekopoi [21+]";         name = "Nekopoi";           package = "com.kcstream.cing";                    keys = @("nekopoi", "(?<![a-z0-9])cing(?![a-z0-9])", "^app\d{5}");    exclude = @(); strip = $true; stable = $cfg_nekopoi_stable },
                @{ id = "12"; label = "PixelLab";              name = "PixelLab";          package = "com.imaginstudio.imagetools.pixellab"; keys = @("pixellab");                                                   exclude = @(); strip = $true; stable = $cfg_pixellab_stable },
                @{ id = "13"; label = "Pixiv";                 name = "Pixiv";             package = "jp.pxv.android";                       keys = @("pixiv", "(?<![a-z0-9])pxv(?![a-z0-9])");                    exclude = @(); strip = $true; stable = $cfg_pixiv_stable },
                @{ id = "14"; label = "Timestamp Camera Free"; name = "Timestamp_Camera";  package = "com.jeyluta.timestampcamerafree";      keys = @("timestamp");                                                  exclude = @(); strip = $true; stable = $cfg_timestampcam_stable }
            )
        },
        @{
            Id          = "6"
            Name        = "kuchingneko28"
            Summary     = "iPusnas"
            Apps        = @(
                @{ id = "1"; label = "iPusnas"; name = "iPusnas"; package = "mam.reader.ipusnas"; keys = @("ipusnas"); exclude = @(); strip = $true; stable = $cfg_ipusnas_stable }
            )
        },
        @{
            Id          = "7"
            Name        = "kveld9"
            Summary     = "Brave Browser, TikTok Global"
            Apps        = @(
                @{ id = "1"; label = "Brave Browser"; name = "Brave_Browser"; package = "com.brave.browser";        keys = @("brave");                exclude = @(); strip = $true; stable = $cfg_brave_stable },
                @{ id = "2"; label = "TikTok Global"; name = "TikTok";        package = "com.zhiliaoapp.musically"; keys = @("tiktok", "musically");  exclude = @(); strip = $true; stable = $cfg_tiktok_kveld9_stable }
            )
        },
        @{
            Id          = "8"
            Name        = "Morphe"
            Summary     = "Reddit, YouTube, YT Music"
            Apps        = @(
                @{ id = "1"; label = "Reddit";        name = "Reddit";        package = "com.reddit.frontpage";                  keys = @("reddit");              exclude = @();          strip = $true; stable = $cfg_reddit_stable },
                @{ id = "2"; label = "YouTube";       name = "YouTube";       package = "com.google.android.youtube";            keys = @("youtube");             exclude = @("music");   strip = $true; stable = $cfg_youtube_stable },
                @{ id = "3"; label = "YouTube Music"; name = "YouTube_Music"; package = "com.google.android.apps.youtube.music"; keys = @("music", "ytmusic");    exclude = @();          strip = $true; stable = $cfg_youtube_music_stable }
            )
        },
        @{
            Id          = "9"
            Name        = "Piko"
            Summary     = "Instagram, X (Twitter)"
            Apps        = @(
                @{ id = "1"; label = "Instagram";   name = "Instagram"; package = "com.instagram.android"; keys = @("instagram", "(?<![a-z0-9])ig(?![a-z0-9])"); exclude = @(); strip = $true; stable = $cfg_ig_stable },
                @{ id = "2"; label = "X (Twitter)"; name = "X_Twitter"; package = "com.twitter.android";   keys = @("twitter", "(?<![a-z0-9])x(?![a-z0-9])");    exclude = @(); strip = $true; stable = $cfg_x_stable }
            )
        }
    )
}

function Get-ApkVersion {
    param(
        [string]$FileName,
        [string[]]$AppKeywords,
        [string[]]$StableVersions = @()
    )

    if ($FileName -notmatch '\.(apk|apkm|xapk|apks)$') { return $null }
    $baseName = $FileName -replace '\.(apk|apkm|xapk|apks)$', ''

    # Match standard versioning, optional single-letter build tag (e.g. 4.7.0m), and 7+ digit date codes.
    $vPat = "(?<ver>(?<!\d)\d{7,}(?!\d)|\d+\.\d+(?:\.\d+)*(?:[a-zA-Z](?=[-_.\s]|$))?(?:-(?:release|alpha|beta|rc|ripped|release-ripped)(?:\.\d+)+)?|\d+(?:[-_]\d+)+(?:-(?:release|alpha|beta|rc|ripped|release-ripped)(?:\.\d+)+)?)"

    $foundVersions = [System.Collections.Generic.List[PSCustomObject]]::new()

    # Exact delimited check against configured version strings handles specialized formats
    # such as '6.6 build 016', '8.3_arm64', or '18.0.3.954559732-release-arm64-v8a'.
    foreach ($stableVer in $StableVersions) {
        if ([string]::IsNullOrWhiteSpace($stableVer) -or $stableVer -eq 'Any') { continue }
        $escapedParts = ($stableVer -split '[\s_]+' | ForEach-Object { [regex]::Escape($_) }) -join '[-_\s]+'
        if ($baseName -match "(?<![0-9]\.|[a-zA-Z0-9])$escapedParts(?![0-9a-zA-Z]|\.[0-9])") {
            $foundVersions.Add([PSCustomObject]@{ Ver = $stableVer; Weight = 15 })
        }
    }

    # Evaluate all keywords to ensure the highest weighted match is not skipped.
    foreach ($AppKeyword in $AppKeywords) {
        # Weight-based pattern matching to isolate version strings from architecture tags.
        $patterns = @(
            @{ P = "(?:$AppKeyword).*?[-_]$vPat(?=[-_]|$)"; W = 10 }
            @{ P = "$vPat[_-]?(?:\d+[_-])?(?:universal|arm64|v8a|x86_64|v7a|armeabi)"; W = 9 }
            @{ P = "v$vPat(?=[-_]|$)"; W = 7 }
            @{ P = "(?<!\d)$vPat(?=[-_]|$)"; W = 5 }
        )

        foreach ($regex in $patterns) {
            if ($baseName -match $regex.P) {
                $ext = $Matches['ver']

                # Normalize version delimiter string from hyphens or underscores to periods.
                $ext = [regex]::Replace($ext, '(?<=\d)[-_](?=\d)', '.')

                $foundVersions.Add([PSCustomObject]@{ Ver = $ext; Weight = $regex.W })
            }
        }
    }

    if ($foundVersions.Count -eq 0) { return $null }

    # Select the absolute highest weighted regex match across all evaluated keywords.
    $best = $foundVersions | Sort-Object -Property Weight -Descending | Select-Object -First 1
    return $best.Ver
}

function Test-IsUniversalApk {
    param([string]$ApkPath)

    $zip = $null
    try {
        if (-not (Test-Path -LiteralPath $ApkPath -PathType Leaf)) { return $false }
        if ([System.IO.Path]::GetExtension($ApkPath) -ne ".apk") { return $false }

        if (-not ('System.IO.Compression.ZipFile' -as [type])) {
            Add-Type -AssemblyName System.IO.Compression -ErrorAction Stop
            Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction Stop
        }

        # Validate minimum Android package requirements directly via O(1) ZipFile entry lookup.
        $zip = [System.IO.Compression.ZipFile]::OpenRead($ApkPath)
        $hasDex = $null -ne $zip.GetEntry("classes.dex")
        $hasManifest = $null -ne $zip.GetEntry("AndroidManifest.xml")

        return ($hasDex -and $hasManifest)
    } catch {
        # If we can't open the archive, treat it as NOT a valid universal APK so caller warns the user.
        return $false
    } finally {
        if ($null -ne $zip) { $zip.Dispose() }
    }
}

function Get-YesNoPrompt {
    param([string]$Prompt)

    while ($true) {
        # Global abort trigger allows the user to navigate back safely.
        $userInput = Read-SafeLine -Prompt "$Prompt (Y/N or 'B' to go back)"

        if ($userInput -match '^[bB]$') { throw "BACK_TO_MAIN" }
        if ($userInput -match '^[yYnN]$') { return ($userInput -match '^[yY]$') }

        Write-Ui "  Invalid input. Please enter Y, N, or B." -ForegroundColor Red
    }
}

function Read-ValidatedInput {
    param(
        [string]$Prompt,
        [string]$RegexPattern,
        [string]$ErrorMessage,
        [switch]$NoBack
    )

    $promptText = if ($NoBack) { $Prompt } else { "$Prompt (or 'B' to go back)" }

    while ($true) {
        $userInput = Read-SafeLine -Prompt $promptText

        if (-not $NoBack -and $userInput -match '^[bB]$') { throw "BACK_TO_MAIN" }
        if ($userInput -match $RegexPattern) { return $userInput }

        Write-Ui "  $ErrorMessage" -ForegroundColor Red
    }
}

function Read-ValidatedIndex {
    <#
    .SYNOPSIS
        Safe numeric-range prompt that supports arbitrary positive ranges including >= 10.
    #>
    param([int]$Min, [int]$Max)

    while ($true) {
        $raw = Read-SafeLine -Prompt "Select File ($Min-$Max) (or 'B' to go back)"
        if ($raw -match '^[bB]$') { throw "BACK_TO_MAIN" }

        $parsed = 0
        if ([int]::TryParse($raw, [ref]$parsed) -and $parsed -ge $Min -and $parsed -le $Max) {
            return $parsed
        }

        Write-Ui "  Invalid selection. Enter a number between $Min and $Max." -ForegroundColor Red
    }
}

function Read-SelectionList {
    <#
    .SYNOPSIS
        Reads comma-separated integer selections within [Min, Max], allowing optional spaces.
    #>
    param(
        [string]$Prompt,
        [int]$Min,
        [int]$Max
    )

    while ($true) {
        $raw = Read-SafeLine -Prompt "$Prompt (or 'B' to go back)"
        if ($raw -match '^[bB]$') { throw "BACK_TO_MAIN" }

        if ([string]::IsNullOrWhiteSpace($raw)) {
            Write-Ui "  Invalid input. Enter numbers $Min-$Max separated by commas." -ForegroundColor Red
            continue
        }

        $tokens = $raw.Split(',')
        $valid = $true
        $seen = [System.Collections.Generic.HashSet[string]]::new()
        $results = [System.Collections.Generic.List[string]]::new()

        foreach ($tok in $tokens) {
            $trimmed = $tok.Trim()
            $parsed = 0
            if (-not [int]::TryParse($trimmed, [ref]$parsed) -or $parsed -lt $Min -or $parsed -gt $Max) {
                $valid = $false
                break
            }
            $normalized = [string]$parsed
            if ($seen.Add($normalized)) {
                $results.Add($normalized)
            }
        }

        if ($valid -and $results.Count -gt 0) {
            return $results.ToArray()
        }

        Write-Ui "  Invalid input. Enter numbers $Min-$Max separated by commas." -ForegroundColor Red
    }
}

function Get-UniqueChildPath {
    param(
        [string]$Directory,
        [string]$BaseName,
        [string]$Extension
    )

    $candidate = Join-Path $Directory "$BaseName$Extension"
    $counter = 1
    while (Test-Path -LiteralPath $candidate) {
        $candidate = Join-Path $Directory "${BaseName}_$counter$Extension"
        $counter++
    }
    return $candidate
}

function Resolve-OptionsFileBackup {
    param([string]$FilePath, [string]$Label)

    # Returns $true if caller may proceed to write the file, $false if the caller should skip this app.
    if (-not (Test-Path -LiteralPath $FilePath)) { return $true }

    $doBackup = $script:OptionsBackupMode
    if ($null -eq $doBackup) {
        Write-Ui "`n[!] Existing options file found: $(Split-Path -Path $FilePath -Leaf) ($Label)" -ForegroundColor Yellow
        while ($true) {
            $ans = Read-SafeLine -Prompt "  Backup? [Y=backup this, N=overwrite this, A=backup all, X=overwrite all, B=back]"
            if ($ans -match '^[bB]$') { throw "BACK_TO_MAIN" }
            switch -Regex ($ans) {
                '^[yY]$' { $doBackup = $true; break }
                '^[nN]$' { $doBackup = $false; break }
                '^[aA]$' { $doBackup = $true; $script:OptionsBackupMode = $true; break }
                '^[xX]$' { $doBackup = $false; $script:OptionsBackupMode = $false; break }
                default { Write-Ui "  Invalid input. Please enter Y, N, A, X, or B." -ForegroundColor Red }
            }
            if ($null -ne $doBackup) { break }
        }
    }

    if ($doBackup) {
        $dir = Split-Path -Path $FilePath -Parent
        $base = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
        $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        $backupPath = Get-UniqueChildPath -Directory $dir -BaseName "$base.$stamp" -Extension '.bak.json'
        $backupName = Split-Path -Path $backupPath -Leaf
        try {
            Move-Item -LiteralPath $FilePath -Destination $backupPath -Force -ErrorAction Stop
            Write-Ui "  [✓] Backed up: $backupName" -ForegroundColor Green
            return $true
        } catch {
            Write-Ui "  [!] Backup failed: $($_.Exception.Message)" -ForegroundColor Red
            Write-Ui "      Skipping this app to avoid data loss." -ForegroundColor Red
            return $false
        }
    } else {
        try {
            Remove-Item -LiteralPath $FilePath -Force -ErrorAction Stop
            return $true
        } catch {
            Write-Ui "  [!] Failed to remove existing file: $($_.Exception.Message). Skipping this app." -ForegroundColor Red
            return $false
        }
    }
}

function Get-LatestVersionedFile {
    param(
        [string[]]$SearchPaths,
        [switch]$ExcludeDev
    )

    $candidates = Get-ChildItem -Path $SearchPaths -File -ErrorAction SilentlyContinue |
        Where-Object { -not ($_.Attributes -band [System.IO.FileAttributes]::ReparsePoint) }

    if ($ExcludeDev) {
        $candidates = $candidates | Where-Object { $_.Name -notmatch '-dev' }
    }

    return $candidates |
        Sort-Object -Property { [regex]::Replace($_.Name, '\d+', { $args[0].Value.PadLeft(10, '0') }) } -Descending |
        Select-Object -First 1
}

function Resolve-Ecosystem {
    $catalog = Get-EcosystemCatalog

    Write-Ui "`n[SELECT] Target Ecosystem(s):" -ForegroundColor Yellow
    foreach ($entry in $catalog) {
        Write-Ui "$($entry.Id). $($entry.Name) ($($entry.Summary))"
    }

    $choices = Read-SelectionList -Prompt "Enter choice(s) [e.g., 1, 2, or 1,2,$($catalog.Count)]" -Min 1 -Max $catalog.Count
    $ecosystems = [System.Collections.Generic.List[hashtable]]::new()

    foreach ($c in $choices) {
        $ecoDef = $catalog | Where-Object { $_.Id -eq $c } | Select-Object -First 1
        if (-not $ecoDef) { continue }

        $projectName = $ecoDef.Name
        $workspace = Join-Path $PSScriptRoot $projectName

        # Scaffold workspace directories if they do not exist.
        if (-not (Test-Path -LiteralPath $workspace)) {
            New-Item -ItemType Directory -Path $workspace -Force | Out-Null
            Write-Ui "  -> Created new workspace: .\$projectName" -ForegroundColor Green
        }

        foreach ($dir in @("Input", "Output")) {
            $dirPath = Join-Path $workspace $dir
            if (-not (Test-Path -LiteralPath $dirPath)) {
                New-Item -ItemType Directory -Path $dirPath -Force | Out-Null
            }
        }

        $ecosystems.Add(@{
            Name      = $projectName
            Workspace = $workspace
            Apps      = $ecoDef.Apps
        })
    }

    return ,$ecosystems.ToArray()
}

function Resolve-EnvironmentArtifact {
    param(
        [string]$Workspace,
        [string]$ProjectName,
        [bool]$RequirePatches
    )

    # Push-Location preserves the original root path to prevent terminal drift.
    Push-Location -LiteralPath $Workspace -ErrorAction Stop

    try {
        # Scan for `morphe-desktop` executables.
        $cliStableSearch = Get-LatestVersionedFile -SearchPaths @("..\morphe-desktop-*-all.jar", ".\morphe-desktop-*-all.jar") -ExcludeDev
        $cliDevSearch = Get-LatestVersionedFile -SearchPaths @("..\morphe-desktop-*-dev.*-all.jar", ".\morphe-desktop-*-dev.*-all.jar")

        $cliStableDisplay = if ($cliStableSearch) { "[$($cliStableSearch.Name)]" } else { "[Not Found]" }
        $cliDevDisplay = if ($cliDevSearch) { "[$($cliDevSearch.Name)]" } else { "[Not Found]" }

        Write-Ui "`n[SELECT] Morphe Desktop Environment ($ProjectName):" -ForegroundColor Yellow
        Write-Ui -NoNewline "1. Latest Stable Release "
        if ($cliStableDisplay -eq "[Not Found]") { Write-Ui $cliStableDisplay -ForegroundColor Red } else { Write-Ui $cliStableDisplay -ForegroundColor Green }
        Write-Ui -NoNewline "2. Latest Pre-release "
        if ($cliDevDisplay -eq "[Not Found]") { Write-Ui $cliDevDisplay -ForegroundColor Red } else { Write-Ui $cliDevDisplay -ForegroundColor Green }

        $cliChoice = Read-ValidatedInput -Prompt "Enter choice (1 or 2)" -RegexPattern "^[12]$" -ErrorMessage "Invalid input."

        $patchesChoice = "1"
        $extraPatches = @()
        $patchStableSearch = $null
        $patchDevSearch = $null

        if ($RequirePatches) {
            $patchStableSearch = Get-LatestVersionedFile -SearchPaths @(".\patches-*.mpp") -ExcludeDev
            $patchDevSearch = Get-LatestVersionedFile -SearchPaths @(".\patches-*-dev.*.mpp")

            $patchStableDisplay = if ($patchStableSearch) { "[$($patchStableSearch.Name)]" } else { "[Not Found]" }
            $patchDevDisplay = if ($patchDevSearch) { "[$($patchDevSearch.Name)]" } else { "[Not Found]" }

            Write-Ui "`n[SELECT] Patches Environment ($ProjectName):" -ForegroundColor Yellow
            Write-Ui -NoNewline "1. Latest Stable Patches "
            if ($patchStableDisplay -eq "[Not Found]") { Write-Ui $patchStableDisplay -ForegroundColor Red } else { Write-Ui $patchStableDisplay -ForegroundColor Green }
            Write-Ui -NoNewline "2. Latest Pre-release Patches "
            if ($patchDevDisplay -eq "[Not Found]") { Write-Ui $patchDevDisplay -ForegroundColor Red } else { Write-Ui $patchDevDisplay -ForegroundColor Green }

            $patchesChoice = Read-ValidatedInput -Prompt "Enter choice (1 or 2)" -RegexPattern "^[12]$" -ErrorMessage "Invalid input."
        }

        $cliJar = if ($cliChoice -eq "1") { $cliStableSearch } else { $cliDevSearch }
        $patchesFile = $null

        if ($RequirePatches) {
            $patchesFile = if ($patchesChoice -eq "1") { $patchStableSearch } else { $patchDevSearch }

            # Discover secondary/shim companion patches implicitly based on nomenclature.
            if ($patchesFile) {
                $extraPatches = @(Get-ChildItem -Path ".\*.mpp" -File -ErrorAction SilentlyContinue |
                    Where-Object {
                        $_.FullName -ne $patchesFile.FullName -and
                        $_.Name -match "shim" -and
                        -not ($_.Attributes -band [System.IO.FileAttributes]::ReparsePoint)
                    })
            }
        }

        # Execute polling loop with a 5-minute timeout if required files are absent.
        if (-not $cliJar -or ($RequirePatches -and -not $patchesFile)) {
            Write-Ui "`n[!] Required environment artifacts are missing!" -ForegroundColor Red
            if (-not $cliJar) { Write-Ui "  - Missing Morphe Desktop (.jar) in the Root or .\$ProjectName directory." -ForegroundColor Yellow }
            if ($RequirePatches -and -not $patchesFile) { Write-Ui "  - Missing Patches (.mpp) in the .\$ProjectName directory." -ForegroundColor Yellow }

            Write-Ui "`nWaiting for the missing files to be placed... (Press CTRL+C to abort)" -ForegroundColor Cyan

            $cliPrefix = if ($cliChoice -eq "1") { "morphe-desktop-*-all.jar" } else { "morphe-desktop-*-dev.*-all.jar" }
            $patchPrefix = if ($patchesChoice -eq "1") { "patches-*.mpp" } else { "patches-*-dev.*.mpp" }

            $timeout = (Get-Date).AddMinutes(5)
            while (-not $cliJar -or ($RequirePatches -and -not $patchesFile)) {
                if ((Get-Date) -gt $timeout) { throw "Timeout reached. Aborting wait for environment artifacts." }
                Start-Sleep -Seconds 2

                $cliJar = Get-LatestVersionedFile -SearchPaths @("..\$cliPrefix", ".\$cliPrefix") -ExcludeDev:($cliChoice -eq "1")
                if ($RequirePatches) {
                    $patchesFile = Get-LatestVersionedFile -SearchPaths @(".\$patchPrefix") -ExcludeDev:($patchesChoice -eq "1")
                    if ($patchesFile) {
                        $extraPatches = @(Get-ChildItem -Path ".\*.mpp" -File -ErrorAction SilentlyContinue |
                            Where-Object {
                                $_.FullName -ne $patchesFile.FullName -and
                                $_.Name -match "shim" -and
                                -not ($_.Attributes -band [System.IO.FileAttributes]::ReparsePoint)
                            })
                    }
                }
            }
            Write-Ui "  [✓] Required artifacts found! Resuming process..." -ForegroundColor Green
        }

        $patchTrack = if ($patchesChoice -eq "1") { "stable" } else { "dev" }

        if ($cliChoice -eq "2" -or ($RequirePatches -and $patchesChoice -eq "2")) {
            Write-Ui "`n[WARNING] Pre-Release Environment Detected for $ProjectName" -ForegroundColor Yellow
            if (-not (Get-YesNoPrompt -Prompt "Proceed with the pre-release track?")) { return $null }
        }

        return @{ Cli = $cliJar; Patches = $patchesFile; ExtraPatches = $extraPatches; Track = $patchTrack }
    } finally {
        Pop-Location
    }
}

function Find-StandaloneCliJar {
    <#
    .SYNOPSIS
        Locates a morphe-desktop CLI jar from the script root (and immediate ecosystem folders if absent).
    #>
    param([string]$SearchRoot)

    $stablePaths = @(
        (Join-Path $SearchRoot "morphe-desktop-*-all.jar"),
        (Join-Path $SearchRoot "*\morphe-desktop-*-all.jar")
    )
    $devPaths = @(
        (Join-Path $SearchRoot "morphe-desktop-*-dev.*-all.jar"),
        (Join-Path $SearchRoot "*\morphe-desktop-*-dev.*-all.jar")
    )

    # Prefer jars in the script root before scanning ecosystem subfolders.
    $cliStable = Get-LatestVersionedFile -SearchPaths @($stablePaths[0]) -ExcludeDev
    if (-not $cliStable) {
        $cliStable = Get-LatestVersionedFile -SearchPaths @($stablePaths[1]) -ExcludeDev
    }

    $cliDev = Get-LatestVersionedFile -SearchPaths @($devPaths[0])
    if (-not $cliDev) {
        $cliDev = Get-LatestVersionedFile -SearchPaths @($devPaths[1])
    }

    return @{ Stable = $cliStable; Dev = $cliDev }
}

function Read-StandaloneCliJar {
    param([string]$SearchRoot)

    $cliBundle = Find-StandaloneCliJar -SearchRoot $SearchRoot

    Write-Ui "`n[SELECT] Morphe Desktop Environment:" -ForegroundColor Yellow
    Write-Ui -NoNewline "1. Latest Stable Release "
    if ($cliBundle.Stable) { Write-Ui "[$($cliBundle.Stable.Name)]" -ForegroundColor Green } else { Write-Ui "[Not Found]" -ForegroundColor Red }
    Write-Ui -NoNewline "2. Latest Pre-release "
    if ($cliBundle.Dev) { Write-Ui "[$($cliBundle.Dev.Name)]" -ForegroundColor Green } else { Write-Ui "[Not Found]" -ForegroundColor Red }

    $cliChoice = Read-ValidatedInput -Prompt "Enter choice (1 or 2)" -RegexPattern "^[12]$" -ErrorMessage "Invalid input."
    $cliJar = if ($cliChoice -eq "1") { $cliBundle.Stable } else { $cliBundle.Dev }
    if (-not $cliJar) {
        Write-Ui "  [!] Selected CLI not found. Place 'morphe-desktop-*-all.jar' in $SearchRoot." -ForegroundColor Red
        Start-Sleep -Seconds 2
        return $null
    }

    return $cliJar
}

function Read-CustomKeystoreConfig {
    <#
    .SYNOPSIS
        Collects custom keystore parameters either manually or from custom-keystore.txt.
    #>
    Write-Ui "  1. Enter credentials manually"
    Write-Ui "  2. Load from 'custom-keystore.txt'"
    $ksMethod = Read-ValidatedInput -Prompt "Choice (1-2)" -RegexPattern "^[12]$" -ErrorMessage "Invalid input."

    if ($ksMethod -eq "2") {
        $ksConfigFile = Join-Path $PSScriptRoot "custom-keystore.txt"
        if (-not (Test-Path -LiteralPath $ksConfigFile)) {
            $template = "# Keystore configuration file`nKeystorePath=my-release-key.keystore`nKeystoreAlias=MyAlias`nKeystorePassword=my_password`nKeystoreEntryPassword=my_entry_password`nSignerName=MySigner"
            Set-Content -LiteralPath $ksConfigFile -Value $template -Encoding UTF8
            Write-Ui "  [!] 'custom-keystore.txt' not found. A template has been created in the root folder." -ForegroundColor Yellow
            Write-Ui "`nPress Enter to return to the Main Menu..." -ForegroundColor DarkGray
            $null = Read-SafeLine -NoPrompt
            return $null
        }

        $ksConfig = @{}
        Get-Content -LiteralPath $ksConfigFile | Where-Object { $_ -match '=' -and $_ -notmatch '^\s*#' } | ForEach-Object {
            $split = $_ -split '=', 2
            $ksConfig[$split[0].Trim()] = $split[1].Trim()
        }

        $keystoreFile = $null
        $securePass = $null
        $secureEntryPass = $null

        try {
            $ks = $ksConfig['KeystorePath']
            if (-not [string]::IsNullOrWhiteSpace($ks)) {
                $ks = $ks.Trim('"').Trim("'")
                if (-not [System.IO.Path]::IsPathRooted($ks)) { $ks = Join-Path $PSScriptRoot $ks }
                if (Test-Path -LiteralPath $ks -PathType Leaf) {
                    $keystoreFile = $ks
                } else {
                    Write-Ui "  [!] Keystore file not found: $ks" -ForegroundColor Red
                    Write-Ui "`nPress Enter to return to the Main Menu..." -ForegroundColor DarkGray
                    $null = Read-SafeLine -NoPrompt
                    return $null
                }
            } else {
                Write-Ui "  [!] KeystorePath is missing or empty in 'custom-keystore.txt'." -ForegroundColor Red
                Write-Ui "`nPress Enter to return to the Main Menu..." -ForegroundColor DarkGray
                $null = Read-SafeLine -NoPrompt
                return $null
            }

            $rawAlias = $ksConfig['KeystoreAlias']
            $keystoreAlias = if (-not [string]::IsNullOrWhiteSpace($rawAlias)) { $rawAlias } else { "Morphe" }

            $rawPass = $ksConfig['KeystorePassword']
            $rawEntryPass = $ksConfig['KeystoreEntryPassword']
            if ([string]::IsNullOrEmpty($rawPass) -or [string]::IsNullOrEmpty($rawEntryPass)) {
                Write-Ui "  [!] KeystorePassword or KeystoreEntryPassword is empty in 'custom-keystore.txt'." -ForegroundColor Red
                Write-Ui "`nPress Enter to return to the Main Menu..." -ForegroundColor DarkGray
                $null = Read-SafeLine -NoPrompt
                return $null
            }

            $securePass = ConvertTo-SecureStringValue -Text $rawPass
            $secureEntryPass = ConvertTo-SecureStringValue -Text $rawEntryPass
            $rawPass = $null
            $rawEntryPass = $null

            $customSigner = $null
            $rawSigner = $ksConfig['SignerName']
            if (-not [string]::IsNullOrWhiteSpace($rawSigner)) {
                $cleanedSigner = $rawSigner -replace '[^a-zA-Z0-9_\-]', ''
                if (-not [string]::IsNullOrEmpty($cleanedSigner)) {
                    if ($cleanedSigner.Length -gt 8) {
                        $cleanedSigner = $cleanedSigner.Substring(0, 8)
                        Write-Ui "  [i] SignerName truncated to 8 characters: $cleanedSigner" -ForegroundColor DarkGray
                    }
                    $customSigner = $cleanedSigner
                }
            }

            Write-Ui "  [✓] Keystore configuration loaded successfully." -ForegroundColor Green
            return [PSCustomObject]@{
                File      = $keystoreFile
                Alias     = $keystoreAlias
                Pass      = $securePass
                EntryPass = $secureEntryPass
                Signer    = $customSigner
            }
        } catch {
            if ($null -ne $securePass) { $securePass.Dispose() }
            if ($null -ne $secureEntryPass) { $secureEntryPass.Dispose() }
            throw
        } finally {
            # Clear sensitive hashtable contents from memory.
            $ksConfig.Clear()
            $ksConfig = $null
        }
    }

    while ($true) {
        $ks = (Read-SafeLine -Prompt "Keystore filename/path (or 'B' to go back)").Trim('"').Trim("'")
        if ($ks -match '^[bB]$') { throw "BACK_TO_MAIN" }
        if ([string]::IsNullOrWhiteSpace($ks)) {
            Write-Ui "  Please enter a valid keystore path." -ForegroundColor Red
            continue
        }
        if (-not [System.IO.Path]::IsPathRooted($ks)) { $ks = Join-Path $PSScriptRoot $ks }
        if (Test-Path -LiteralPath $ks -PathType Leaf) { $keystoreFile = $ks; break }
        Write-Ui "  File not found: $ks" -ForegroundColor Red
    }

    $keystoreAlias = Read-ValidatedInput -Prompt "Alias" -RegexPattern "^[a-zA-Z0-9_\-\s]+$" -ErrorMessage "Alphanumeric, spaces, underscores, and dashes only."
    $securePass = $null
    $secureEntryPass = $null

    try {
        $securePass = Read-Host -Prompt "Password" -AsSecureString
        $secureEntryPass = Read-Host -Prompt "Entry Password" -AsSecureString

        $customSigner = $null
        if (Get-YesNoPrompt -Prompt "Use custom signer?") {
            $customSigner = Read-ValidatedInput -Prompt "Signer name" -RegexPattern "^[a-zA-Z0-9_\-]{1,8}$" -ErrorMessage "Max 8 chars, no spaces. Use alphanumeric or dashes."
        }

        return [PSCustomObject]@{
            File      = $keystoreFile
            Alias     = $keystoreAlias
            Pass      = $securePass
            EntryPass = $secureEntryPass
            Signer    = $customSigner
        }
    } catch {
        if ($null -ne $securePass) { $securePass.Dispose() }
        if ($null -ne $secureEntryPass) { $secureEntryPass.Dispose() }
        throw
    }
}

function Test-XLiteConstraint {
    param([object]$JsonContent)

    if ($null -eq $JsonContent) { return $false }

    # Iterate @($JsonContent) so single-item JSON arrays unwrapped by ConvertFrom-Json still evaluate properly.
    foreach ($entry in @($JsonContent)) {
        if ($null -eq $entry) { continue }

        # Schema A: object map { "Block redirecting to X Lite": { "enabled": true } }
        $patchProp = $entry.PSObject.Properties['Block redirecting to X Lite']
        if ($null -ne $patchProp -and $null -ne $patchProp.Value) {
            $enabledProp = $patchProp.Value.PSObject.Properties['enabled']
            if ($null -ne $enabledProp -and $enabledProp.Value -eq $true) {
                return $true
            }
        }

        # Schema B: array of patch objects [{ "patchName": "Block redirecting to X Lite", "enabled": true }]
        $nameProp = $entry.PSObject.Properties['patchName']
        if ($null -eq $nameProp) { $nameProp = $entry.PSObject.Properties['name'] }
        $entryEnabled = $entry.PSObject.Properties['enabled']
        if ($null -ne $nameProp -and $nameProp.Value -eq "Block redirecting to X Lite" -and $null -ne $entryEnabled -and $entryEnabled.Value -eq $true) {
            return $true
        }
    }

    return $false
}

function Invoke-PatchingWorkflow {
    param()

    Clear-UiScreen
    Write-Ui "==============================================" -ForegroundColor Cyan
    Write-Ui "          CHIHAFUYU TOOL - PATCHING           " -ForegroundColor Cyan
    Write-Ui "==============================================" -ForegroundColor Cyan

    # Reset backup decision at workflow start.
    $script:OptionsBackupMode = $null

    $ecosystems = @(Resolve-Ecosystem)
    if ($ecosystems.Count -eq 0) { return }

    $batchJobs = [System.Collections.Generic.List[PSCustomObject]]::new()

    # PHASE 1: Build the execution queue per ecosystem.
    foreach ($eco in $ecosystems) {
        $projectName = $eco.Name
        $workspace = $eco.Workspace

        Write-Ui "`n==============================================" -ForegroundColor Magenta
        Write-Ui "       PREPARING ECOSYSTEM: $($projectName.ToUpper())" -ForegroundColor Magenta
        Write-Ui "==============================================" -ForegroundColor Magenta

        $envArt = Resolve-EnvironmentArtifact -Workspace $workspace -ProjectName $projectName -RequirePatches $true
        if (-not $envArt) {
            Write-Ui "  [!] Skipping $projectName due to aborted artifact selection." -ForegroundColor Red
            continue
        }

        Write-Ui "`n[+] Select Target Application(s):" -ForegroundColor Yellow

        # Clone app definitions per run so runtime state never mutates catalog entries.
        $masterApps = @(foreach ($appDef in $eco.Apps) { $appDef.Clone() })
        $allOptionId = $masterApps.Count + 1

        foreach ($appDef in $masterApps) {
            Write-Ui "$($appDef.id). $($appDef.label)"
        }
        Write-Ui "$allOptionId. All Applications"

        $exampleChoice = if ($allOptionId -ge 3) { "1, 2, or $allOptionId" } else { "1 or $allOptionId" }
        $selectedIds = Read-SelectionList -Prompt "Enter choice(s) [e.g., $exampleChoice]" -Min 1 -Max $allOptionId

        $selectedApps = @(if ([string]$allOptionId -in $selectedIds) {
            $masterApps
        } else {
            $masterApps | Where-Object { $_.id -in $selectedIds }
        })

        Write-Ui "`n[INFO] Place original .apk, .apkm, .xapk, or .apks files in '.\$projectName\Input'." -ForegroundColor DarkGray

        # Display application-specific notices.
        if ($selectedApps | Where-Object { $_.name -eq "Gboard" }) {
            Write-Ui "Note for Gboard: jasonwu1994 officially targets the arm64-v8a specific release. Make sure to pick 'arm64-v8a'!" -ForegroundColor Magenta
        }
        if ($selectedApps | Where-Object { $_.name -eq "Instagram" }) {
            Write-Ui "Note for Instagram: Piko officially tested v$($cfg_ig_stable[0]) specifically on build code 384510827. Make sure to pick 'arm64-v8a'!" -ForegroundColor Magenta
        }
        if ($selectedApps | Where-Object { $_.name -eq "IbisPaint_X" }) {
            Write-Ui "Note for IbisPaint X: Select 'arm64-v8a' in the next step, as it's the only supported architecture!" -ForegroundColor Magenta
        }

        Write-Ui "`n[+] Validating Dependencies..." -ForegroundColor Yellow

        # Bypass PowerShell's buggy -Include wildcard resolution by using LiteralPath and Regex filtering.
        $inputDir = Join-Path $workspace "Input"
        $allApks = @(Get-ChildItem -LiteralPath $inputDir -File -ErrorAction SilentlyContinue | Where-Object {
            $_.Extension -match '^\.(apk|apkm|xapk|apks)$' -and
            -not ($_.Attributes -band [System.IO.FileAttributes]::ReparsePoint)
        })
        $hasMismatch = $false
        $missingApps = 0

        foreach ($app in $selectedApps) {
            $app.TargetApk = $null
            $app.TargetVersion = $null
            $app.RequiresForce = $false

            $matched = @($allApks | Where-Object {
                $n = $_.Name.ToLower()
                $matchKey = $false
                foreach ($k in $app.keys) { if ($n -match $k) { $matchKey = $true; break } }
                if ($matchKey) {
                    foreach ($e in $app.exclude) { if ($n -match $e) { $matchKey = $false; break } }
                }
                $matchKey
            })

            if ($matched.Count -eq 0) {
                Write-Ui "[-] $($app.name) - No App file detected." -ForegroundColor Red
                $missingApps++
                continue
            }

            # NSFW Safety Check for Nekopoi patching pipeline (only when matching files exist).
            if ($app.name -eq "Nekopoi") {
                Write-Ui "`n[!] WARNING: MATURE CONTENT DETECTED (21+)" -ForegroundColor Red
                if (-not (Get-YesNoPrompt -Prompt "You are about to patch an NSFW (21+) application. Are you sure you want to proceed?")) {
                    Write-Ui "  -> Skipping Nekopoi deployment by user request." -ForegroundColor DarkGray
                    continue
                }

                Write-Ui "`n[!] RED GATES: INDEMNITY & LIABILITY DISCLAIMER" -ForegroundColor Red
                Write-Ui "I assume absolutely no responsibility or liability for any psychological issues, addiction, dependencies, or potential legal violations arising from the use of this un-censored software." -ForegroundColor Yellow
                if (-not (Get-YesNoPrompt -Prompt "Do you explicitly understand the risks and wish to continue anyway?")) {
                    Write-Ui "  -> Skipping Nekopoi deployment by user request." -ForegroundColor DarkGray
                    continue
                }
            }

            $chosenApk = if ($matched.Count -eq 1) {
                $v = Get-ApkVersion -FileName $matched[0].Name -AppKeywords $app.keys -StableVersions $app.stable

                $tag = if ("Any" -in $app.stable) { " [SUPPORTED]" } elseif ($v -in $app.stable) { " [RECOMMENDED]" } else { " [MISMATCH]" }
                $color = if ($tag -match "MISMATCH") { "Yellow" } else { "Green" }
                Write-Ui "  [✓] $($app.name) -> $($matched[0].Name)$tag" -ForegroundColor $color
                $matched[0]
            } else {
                Write-Ui "`nMultiple files detected for $($app.name):" -ForegroundColor Cyan
                for ($i = 0; $i -lt $matched.Count; $i++) {
                    $v = Get-ApkVersion -FileName $matched[$i].Name -AppKeywords $app.keys -StableVersions $app.stable

                    $tag = if ("Any" -in $app.stable) { " [SUPPORTED]" } elseif ($v -in $app.stable) { " [RECOMMENDED]" } else { " [MISMATCH]" }
                    $color = if ($tag -match "MISMATCH") { "Yellow" } else { "Green" }
                    Write-Ui "  $($i + 1). $($matched[$i].Name)$tag" -ForegroundColor $color
                }
                $idx = Read-ValidatedIndex -Min 1 -Max $matched.Count
                $matched[$idx - 1]
            }

            $isBundle = [System.IO.Path]::GetExtension($chosenApk.FullName) -match "\.(apkm|xapk|apks)$"
            if (-not $isBundle -and -not (Test-IsUniversalApk -ApkPath $chosenApk.FullName)) {
                Write-Ui "`n  [!] WARNING: This .apk is missing required core files (Split/Corrupt)!" -ForegroundColor Yellow
                if (-not (Get-YesNoPrompt -Prompt "  Force continue anyway?")) { continue }
            }

            $ver = Get-ApkVersion -FileName $chosenApk.Name -AppKeywords $app.keys -StableVersions $app.stable

            # Prompt for manual entry if version extraction fails.
            if (-not $ver) {
                $ver = Read-ValidatedInput -Prompt "Enter version manually for $($chosenApk.Name)" -RegexPattern "^[a-zA-Z0-9\-\.\+ _\(\)]+$" -ErrorMessage "Use format x.x.x, or a build tag (e.g., build-1025-uni, 2.0.3 (41-d04e542))"
            }

            $app.TargetApk = $chosenApk.FullName
            $app.TargetVersion = $ver

            if ("Any" -notin $app.stable -and $ver -notin $app.stable) {
                $hasMismatch = $true
                $app.RequiresForce = $true
            }
        }

        $validApps = @($selectedApps | Where-Object { $null -ne $_.TargetApk })
        if ($validApps.Count -eq 0) {
            Write-Ui "`n[!] No matching app files found in the Input folder. Skipping ecosystem $projectName." -ForegroundColor Red
            Start-Sleep -Seconds 2
            continue
        }

        if ($missingApps -gt 0) {
            if (-not (Get-YesNoPrompt -Prompt "`nSome selected apps are missing in $projectName. Continue patching the available ones?")) { continue }
        }

        if ($hasMismatch -and -not (Get-YesNoPrompt -Prompt "`nVersion mismatches detected in $projectName. Force patch?")) { continue }

        $batchJobs.Add([PSCustomObject]@{
            Eco  = $eco
            Env  = $envArt
            Apps = $validApps
        })
    }

    if ($batchJobs.Count -eq 0) {
        Write-Ui "`n[!] No valid jobs queued across all selected ecosystems. Aborting workflow." -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }

    # PHASE 2..6 wrapped in outer finally to guarantee SecureString/temp-file cleanup on any abort or error.
    $keystoreCfg = $null
    $plainPass = $null
    $plainEntryPass = $null
    $batchCompleted = $false

    try {
        # PHASE 2: Collect Global Configurations (Applies to all jobs in the queue).
        Write-Ui "`n==============================================" -ForegroundColor Cyan
        Write-Ui "           GLOBAL CONFIGURATIONS              " -ForegroundColor Cyan
        Write-Ui "==============================================" -ForegroundColor Cyan

        Write-Ui "`n[+] Select Global Target Architecture:" -ForegroundColor Yellow
        Write-Ui "1. arm64-v8a`n2. armeabi-v7a`n3. x86_64`n4. x86`n5. Universal"
        $archChoice = Read-ValidatedInput -Prompt "Choice (1-5)" -RegexPattern "^[1-5]$" -ErrorMessage "Invalid input."
        $targetArch = switch ($archChoice) { "1" { "arm64-v8a" } "2" { "armeabi-v7a" } "3" { "x86_64" } "4" { "x86" } "5" { "universal" } }

        $disableSigning = Get-YesNoPrompt -Prompt "`nDisable signing of the final apk? (--unsigned)"

        $useCustomKeystore = $false
        if (-not $disableSigning) {
            Write-Ui "`n[+] Global Keystore Configuration:" -ForegroundColor Yellow
            $useCustomKeystore = Get-YesNoPrompt -Prompt "Use custom keystore?"
            if ($useCustomKeystore) {
                $keystoreCfg = Read-CustomKeystoreConfig
                if ($null -eq $keystoreCfg) { return }
            }
        }

        $isWindowsOS = ($env:OS -eq 'Windows_NT')
        $bytecodeMode = $null

        Write-Ui "`n[+] Global Execution Preferences:" -ForegroundColor Yellow
        if ($isWindowsOS) {
            Write-Ui "  [i] Bytecode Mode: Forced FULL (Windows compatibility requirement)." -ForegroundColor DarkGray
            $bytecodeMode = "FULL"
        } else {
            if (Get-YesNoPrompt -Prompt "Configure custom bytecode mode? (--bytecode-mode)") {
                Write-Ui "1. FULL`n2. STRIP_FAST`n3. STRIP_SAFE"
                $bcChoice = Read-ValidatedInput -Prompt "Choice (1-3)" -RegexPattern "^[1-3]$" -ErrorMessage "Invalid input."
                $bytecodeMode = switch ($bcChoice) { "1" { "FULL" } "2" { "STRIP_FAST" } "3" { "STRIP_SAFE" } }
            }
        }

        # Prompt the user to include experimental versions in the output generation (e.g. options JSON & list patches).
        $includeExperimental = Get-YesNoPrompt -Prompt "Include experimental app versions in the patch lists? (--include-experimental)"

        # SDK Verification Gate
        $verifyWithSdk = Get-YesNoPrompt -Prompt "Verify the patched apps with a local Android SDK? (--verify-with-sdk) [DEV ONLY]"
        if ($verifyWithSdk) {
            Write-Ui "`n  [!] THIS REQUIRES A PROPER ANDROID SDK (BUILD-TOOLS & PLATFORMS)" -ForegroundColor Red
            Write-Ui "      Many apps attempt to try/catch imports of classes that may or may not be available at runtime." -ForegroundColor Yellow
            Write-Ui "      This causes 'missing class' FALSE NEGATIVES during verification, which is intentional and expected." -ForegroundColor Yellow
            Write-Ui "      End users should NOT use this unless requested as part of a bug report.`n" -ForegroundColor Yellow

            $confirmVerify = Get-YesNoPrompt -Prompt "  Are you sure you want to proceed with verification? (For Developers Only)"
            if (-not $confirmVerify) {
                $verifyWithSdk = $false
                Write-Ui "  [i] SDK verification cancelled. Continuing with standard patching..." -ForegroundColor DarkGray
            } else {
                Write-Ui "  [i] SDK verification enabled. Prepare for potential false negatives." -ForegroundColor DarkGray
            }
        }

        $continueOnError = Get-YesNoPrompt -Prompt "Skip failed patches and continue? (--continue-on-error)"

        # PHASE 3: Generate reference lists and JSON option files for all queued jobs.
        Write-Ui "`n==============================================" -ForegroundColor Cyan
        Write-Ui "          GENERATING OPTION FILES             " -ForegroundColor Cyan
        Write-Ui "==============================================" -ForegroundColor Cyan

        $activeJobs = [System.Collections.Generic.List[PSCustomObject]]::new()

        foreach ($job in $batchJobs) {
            $workspace = $job.Eco.Workspace
            $cliAbsPath = $job.Env.Cli.FullName
            $patchAbsPath = $job.Env.Patches.FullName
            $extraPatches = $job.Env.ExtraPatches
            $patchTrack = $job.Env.Track

            $patchesListFile = Join-Path $workspace "list-patches-$patchTrack.txt"
            if (Test-Path -LiteralPath $patchesListFile) {
                Remove-Item -LiteralPath $patchesListFile -Force -ErrorAction SilentlyContinue
            }

            $listArgs = [System.Collections.Generic.List[string]]::new()
            foreach ($arg in @("-jar", $cliAbsPath, "list-patches", "--with-packages", "--with-versions", "--with-options", "--out", $patchesListFile, "--patches", $patchAbsPath)) {
                $listArgs.Add($arg)
            }
            if ($includeExperimental) { $listArgs.Add("--include-experimental") }
            if ($extraPatches) {
                foreach ($ep in $extraPatches) {
                    $listArgs.Add("--patches")
                    $listArgs.Add($ep.FullName)
                }
            }

            $listResult = Invoke-NativeTool -Executable 'java' -Arguments $listArgs.ToArray()
            if ($listResult.ExitCode -eq 0 -and (Test-Path -LiteralPath $patchesListFile)) {
                Write-Ui "  [✓] Reference list created: $(Split-Path -Path $patchesListFile -Leaf) ($($job.Eco.Name))" -ForegroundColor Green
            } else {
                Write-Ui "  [!] Reference list generation failed ($($job.Eco.Name), Exit Code: $($listResult.ExitCode))." -ForegroundColor Yellow
            }

            $readyApps = [System.Collections.Generic.List[hashtable]]::new()
            foreach ($app in $job.Apps) {
                $jsonFileName = Join-Path $workspace "$($app.name.ToLower().Replace('_','-'))-options-$patchTrack.json"

                # Backup prompt for existing options file. If the caller can't safely proceed, skip this app.
                if (-not (Resolve-OptionsFileBackup -FilePath $jsonFileName -Label $app.name)) {
                    Write-Ui "  [!] Skipping $($app.name) due to file operation failure." -ForegroundColor Yellow
                    continue
                }

                $optArgs = [System.Collections.Generic.List[string]]::new()
                foreach ($arg in @("-jar", $cliAbsPath, "options-create", "--patches", $patchAbsPath)) {
                    $optArgs.Add($arg)
                }
                if ($extraPatches) {
                    foreach ($ep in $extraPatches) {
                        $optArgs.Add("--patches")
                        $optArgs.Add($ep.FullName)
                    }
                }
                foreach ($arg in @("--out", $jsonFileName, "--filter-package-name", $app.package)) {
                    $optArgs.Add($arg)
                }

                $optResult = Invoke-NativeTool -Executable 'java' -Arguments $optArgs.ToArray()
                if ($optResult.ExitCode -eq 0 -and (Test-Path -LiteralPath $jsonFileName)) {
                    Write-Ui "  [✓] Options generated for $($app.name) ($($job.Eco.Name))" -ForegroundColor Green
                    $readyApps.Add($app)
                } else {
                    Write-Ui "  [!] Options generation failed for $($app.name) (Exit Code: $($optResult.ExitCode)). Skipping." -ForegroundColor Red
                    foreach ($errLine in $optResult.Output) {
                        if (-not [string]::IsNullOrWhiteSpace($errLine)) {
                            Write-Ui "      $errLine" -ForegroundColor DarkGray
                        }
                    }
                }
            }

            if ($readyApps.Count -gt 0) {
                $activeJobs.Add([PSCustomObject]@{
                    Eco  = $job.Eco
                    Env  = $job.Env
                    Apps = $readyApps.ToArray()
                })
            }
        }

        $batchJobs = $activeJobs
        if ($batchJobs.Count -eq 0) {
            Write-Ui "`n[!] No applications remain in the batch queue after options generation. Aborting." -ForegroundColor Red
            Start-Sleep -Seconds 2
            return
        }

        # PHASE 4: Global Pause & JSON Constraint Evaluation.
        Write-Ui "`n[OPTIONS READY] All configuration files have been generated." -ForegroundColor Cyan
        if (Get-YesNoPrompt -Prompt "Modify JSON files before patching?") {
            Write-Ui "  [TIP] Check the 'list-patches-xxx.txt' files in each workspace for reference." -ForegroundColor DarkGray
            Wait-KeyOrEnter -Message "Awaiting manual modifications. Setup your workspaces, then press any key to initiate the Batch Sequence..."
        }

        $abortBatch = $false
        foreach ($job in $batchJobs) {
            if ($abortBatch) { break }
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
                                    if (Test-XLiteConstraint -JsonContent $jsonContent) {
                                        Write-Ui "`n[!] CRITICAL WARNING FOR X (TWITTER):" -ForegroundColor Red
                                        Write-Ui "    You enabled the 'Block redirecting to X Lite' patch, but your APK is v$($app.TargetVersion)." -ForegroundColor Red
                                        Write-Ui "    This specific patch requires v11.98.0-release.0 or higher." -ForegroundColor Red
                                        if (-not (Get-YesNoPrompt -Prompt "    Force continue anyway? (Highly likely to crash)")) {
                                            $abortBatch = $true
                                            break
                                        }
                                    }
                                }
                            }
                        } catch {
                            Write-Verbose $_.Exception.Message
                        }
                    }
                }
            }
        }
        if ($abortBatch) {
            Write-Ui "`n[i] Operations aborted due to constraint violation." -ForegroundColor Yellow
            Start-Sleep -Seconds 2
            return
        }

        # PHASE 5: Unattended Batch Execution.
        Write-Ui "`n==============================================" -ForegroundColor Cyan
        Write-Ui "           BATCH PATCHING EXECUTION           " -ForegroundColor Cyan
        Write-Ui "==============================================" -ForegroundColor Cyan

        $heapSize = "2G"
        if ($isWindowsOS) {
            try {
                $ramInfo = Get-CimInstance -ClassName Win32_ComputerSystem -Property TotalPhysicalMemory -ErrorAction SilentlyContinue
                if ($ramInfo) {
                    $sysRamGB = [math]::Round($ramInfo.TotalPhysicalMemory / 1GB)
                    if ($sysRamGB -ge 8) { $heapSize = "4G" } elseif ($sysRamGB -ge 6) { $heapSize = "3G" }
                    Write-Ui "  [i] Detected System RAM: ${sysRamGB}GB. Auto-adjusting Java Heap Space to: -$heapSize" -ForegroundColor DarkGray
                }
            } catch {
                Write-Verbose $_.Exception.Message
            }
        }

        if ($useCustomKeystore -and $null -ne $keystoreCfg) {
            $plainPass = ConvertFrom-SecureStringToBstrValue -SecureValue $keystoreCfg.Pass
            $plainEntryPass = ConvertFrom-SecureStringToBstrValue -SecureValue $keystoreCfg.EntryPass
        }

        $abortAll = $false
        $succeededCount = 0
        $failedCount = 0

        foreach ($job in $batchJobs) {
            if ($abortAll) { break }

            $workspace = $job.Eco.Workspace
            $projectName = $job.Eco.Name
            $cliAbsPath = $job.Env.Cli.FullName
            $patchAbsPath = $job.Env.Patches.FullName
            $extraPatches = $job.Env.ExtraPatches
            $patchTrack = $job.Env.Track

            $outputDir = Join-Path $workspace "Output"
            $tempLogFile = Join-Path $outputDir "temp_patch_log.txt"
            if (Test-Path -LiteralPath $tempLogFile) { Remove-Item -LiteralPath $tempLogFile -Force -ErrorAction Ignore }

            foreach ($app in $job.Apps) {
                if ($abortAll) { break }

                $jsonFileName = Join-Path $workspace "$($app.name.ToLower().Replace('_','-'))-options-$patchTrack.json"
                $outputApkAbs = Join-Path $outputDir "$($app.name)_${projectName}_$($app.TargetVersion)-$targetArch.apk"

                $tempResultFile = Join-Path $outputDir "temp_result_$($app.name).json"
                if (Test-Path -LiteralPath $tempResultFile) { Remove-Item -LiteralPath $tempResultFile -Force -ErrorAction Ignore }

                Write-Ui "`n>>> PATCHING: $($app.name) (v$($app.TargetVersion)) [$projectName] <<<" -ForegroundColor Magenta

                $logHeader = "`n" + ("=" * 60) + "`n>>> LOG FOR: $($app.name) (v$($app.TargetVersion)) <<<`n" + ("=" * 60) + "`n"
                $headerWriter = [System.IO.StreamWriter]::new($tempLogFile, $true, [System.Text.UTF8Encoding]::new($false))
                try {
                    $headerWriter.WriteLine($logHeader)
                } finally {
                    $headerWriter.Dispose()
                }

                # Build discrete argument list to prevent flag concatenation failures in the upstream JVM parser.
                $baseArgs = [System.Collections.Generic.List[string]]::new()
                foreach ($arg in @("-Xmx$heapSize", "-jar", $cliAbsPath, "patch", "--patches", $patchAbsPath)) {
                    $baseArgs.Add($arg)
                }
                if ($extraPatches) {
                    foreach ($ep in $extraPatches) {
                        $baseArgs.Add("--patches")
                        $baseArgs.Add($ep.FullName)
                    }
                }

                foreach ($arg in @("--options-file", $jsonFileName, "--out", $outputApkAbs, "--result-file", $tempResultFile)) {
                    $baseArgs.Add($arg)
                }

                if ($bytecodeMode) {
                    $baseArgs.Add("--bytecode-mode")
                    $baseArgs.Add($bytecodeMode)
                }
                if ($patchTrack -eq "dev" -or $app.RequiresForce) { $baseArgs.Add("--force") }
                if ($verifyWithSdk) { $baseArgs.Add("--verify-with-sdk") }

                if ($disableSigning) {
                    $baseArgs.Add("--unsigned")
                } elseif ($useCustomKeystore -and $null -ne $keystoreCfg) {
                    foreach ($arg in @("--keystore", $keystoreCfg.File, "--keystore-entry-alias", $keystoreCfg.Alias, "--keystore-password", $plainPass, "--keystore-entry-password", $plainEntryPass)) {
                        $baseArgs.Add($arg)
                    }
                    if ($keystoreCfg.Signer) {
                        $baseArgs.Add("--signer")
                        $baseArgs.Add($keystoreCfg.Signer)
                    }
                }

                if ($app.strip -and ($targetArch -ne "universal")) {
                    $baseArgs.Add("--striplibs")
                    $baseArgs.Add($targetArch)
                }
                if ($continueOnError) { $baseArgs.Add("--continue-on-error") }

                # Append positional argument (APK file) at the very end of the command array.
                $baseArgs.Add($app.TargetApk)

                try {
                    $patchResult = Invoke-NativeTool -Executable 'java' -Arguments $baseArgs.ToArray() -LogFilePath $tempLogFile -StreamToConsole
                } finally {
                    $baseArgs.Clear()
                }

                if ($patchResult.ExitCode -ne 0) {
                    $failedCount++
                    Write-Ui "  [!] Patching FAILED (Exit Code: $($patchResult.ExitCode))" -ForegroundColor Red
                    if (-not $continueOnError) { $abortAll = $true; break }
                } else {
                    $succeededCount++
                    Write-Ui "  [✓] Patching SUCCEEDED" -ForegroundColor Green
                }
            }
        }

        # PHASE 6: Post-Execution Exports.
        if ($failedCount -gt 0 -and $succeededCount -eq 0) {
            Write-Ui "`n[!] Batch operations finished with failures ($failedCount failed, 0 succeeded)." -ForegroundColor Red
        } elseif ($failedCount -gt 0) {
            Write-Ui "`n[!] Batch operations concluded with partial errors ($succeededCount succeeded, $failedCount failed)." -ForegroundColor Yellow
        } else {
            Write-Ui "`n[SUCCESS] Batch operations concluded ($succeededCount succeeded)." -ForegroundColor Green
        }

        if (Get-YesNoPrompt -Prompt "`nExport patching logs?") {
            foreach ($job in $batchJobs) {
                $outputDir = Join-Path $job.Eco.Workspace "Output"
                $tempLogFile = Join-Path $outputDir "temp_patch_log.txt"
                if (Test-Path -LiteralPath $tempLogFile) {
                    $targetLogPath = Get-UniqueChildPath -Directory $outputDir -BaseName "Patch_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss')" -Extension '.txt'
                    $targetLogName = Split-Path -Path $targetLogPath -Leaf
                    Rename-Item -LiteralPath $tempLogFile -NewName $targetLogName
                    Write-Ui "  -> Log exported: .\$($job.Eco.Name)\Output\$targetLogName" -ForegroundColor Green
                }
            }
        }

        if (Get-YesNoPrompt -Prompt "Export patching result JSONs? (--result-file)") {
            foreach ($job in $batchJobs) {
                $outputDir = Join-Path $job.Eco.Workspace "Output"
                foreach ($app in $job.Apps) {
                    $tempResultFile = Join-Path $outputDir "temp_result_$($app.name).json"
                    if (Test-Path -LiteralPath $tempResultFile) {
                        $targetResultPath = Get-UniqueChildPath -Directory $outputDir -BaseName "Result_$($app.name)_$(Get-Date -Format 'yyyyMMdd_HHmmss')" -Extension '.json'
                        $finalResultName = Split-Path -Path $targetResultPath -Leaf
                        Rename-Item -LiteralPath $tempResultFile -NewName $finalResultName
                        Write-Ui "  -> JSON result exported: .\$($job.Eco.Name)\Output\$finalResultName" -ForegroundColor Green
                    }
                }
            }
        }

        if (Get-YesNoPrompt -Prompt "Open output directories?") {
            foreach ($job in $batchJobs) {
                $outputDir = Join-Path $job.Eco.Workspace "Output"
                if (Test-Path -LiteralPath $outputDir -PathType Container) {
                    try {
                        Invoke-Item -LiteralPath $outputDir -ErrorAction Stop
                    } catch {
                        Write-Ui "  [!] Unable to open directory '$outputDir': $($_.Exception.Message)" -ForegroundColor Yellow
                    }
                }
            }
        }

        $batchCompleted = $true
    } finally {
        # Flush plaintext credentials and dispose SecureStrings on every exit path.
        if ($null -ne $plainPass) {
            $plainPass = $null
            Clear-Variable -Name plainPass -ErrorAction Ignore
        }
        if ($null -ne $plainEntryPass) {
            $plainEntryPass = $null
            Clear-Variable -Name plainEntryPass -ErrorAction Ignore
        }
        if ($null -ne $keystoreCfg) {
            if ($null -ne $keystoreCfg.Pass) { $keystoreCfg.Pass.Dispose() }
            if ($null -ne $keystoreCfg.EntryPass) { $keystoreCfg.EntryPass.Dispose() }
            $keystoreCfg = $null
        }
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()

        # Remove any unexported temporary logs or result JSONs.
        foreach ($job in $batchJobs) {
            $outputDir = Join-Path $job.Eco.Workspace "Output"
            $tempLogFile = Join-Path $outputDir "temp_patch_log.txt"
            if (Test-Path -LiteralPath $tempLogFile) {
                Remove-Item -LiteralPath $tempLogFile -Force -ErrorAction Ignore
            }
            foreach ($app in $job.Apps) {
                $tempResultFile = Join-Path $outputDir "temp_result_$($app.name).json"
                if (Test-Path -LiteralPath $tempResultFile) {
                    Remove-Item -LiteralPath $tempResultFile -Force -ErrorAction Ignore
                }
            }
        }
    }

    if ($batchCompleted) {
        Write-Ui "`nPress Enter to return to the Main Menu..." -ForegroundColor Magenta
        $null = Read-SafeLine -NoPrompt
    }
}

function Invoke-UtilityWorkflow {
    param()

    Clear-UiScreen
    Write-Ui "==============================================" -ForegroundColor Cyan
    Write-Ui "           CHIHAFUYU TOOL - UTILITY           " -ForegroundColor Cyan
    Write-Ui "==============================================" -ForegroundColor Cyan

    Write-Ui "`nSelect Utility Action:" -ForegroundColor Yellow
    Write-Ui "1. Install app to device (adb)"
    Write-Ui "2. Uninstall app from device (adb)"
    Write-Ui "3. Generate Options only"
    Write-Ui "4. Generate list-patches only"
    Write-Ui "5. Generate Custom Keystore (PKCS12)"
    Write-Ui "6. Clear Morphe Cache (Downloaded patches, logs, temp)"
    Write-Ui "B. Back to Main Menu"
    Write-Ui "X. Close Tool"

    $utilChoice = Read-ValidatedInput -Prompt "Enter choice" -RegexPattern "^[1-6bBxX]$" -ErrorMessage "Invalid input. Please enter 1-6, B, or X." -NoBack

    if ($utilChoice -match '^[bB]$') { return $true }
    if ($utilChoice -match '^[xX]$') { return $false }

    if ($utilChoice -in @('1', '2')) {
        Write-Ui "`n  [i] HEADS UP: This feature relies on ADB. Make sure you have Android 'platform-tools' installed and added to your system PATH!" -ForegroundColor Cyan

        # Standalone CLI discovery — no ecosystem prompt needed for ADB-only utilities.
        $cliJar = Read-StandaloneCliJar -SearchRoot $PSScriptRoot
        if (-not $cliJar) { return $true }
        $cliAbsPath = $cliJar.FullName

        if ($utilChoice -eq '1') {
            Write-Ui "`n[INSTALL] Select Install Mode:" -ForegroundColor Yellow
            Write-Ui "1. Non-Root (Standard Install via --apk)"
            Write-Ui "2. Root (Mount Install via --mount)"
            $installMode = Read-ValidatedInput -Prompt "Enter choice (1 or 2)" -RegexPattern "^[12]$" -ErrorMessage "Invalid input."

            $apkPath = $null
            while ($true) {
                $rawPath = (Read-SafeLine -Prompt "Drag and drop the APK file here, or enter the full path (or 'B' to go back)").Trim('"').Trim("'").Trim()
                if ($rawPath -match '^[bB]$') { throw "BACK_TO_MAIN" }
                if ([string]::IsNullOrWhiteSpace($rawPath)) {
                    Write-Ui "  [!] Please provide an APK file path." -ForegroundColor Red
                    continue
                }

                $apkItem = Get-Item -LiteralPath $rawPath -Force -ErrorAction SilentlyContinue
                if ($apkItem -and ($apkItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
                    Write-Ui "  [!] Symlinks or ReparsePoints are not allowed for security reasons." -ForegroundColor Red
                    continue
                }

                if (-not (Test-Path -LiteralPath $rawPath -PathType Leaf)) {
                    Write-Ui "  [!] APK file not found at: $rawPath" -ForegroundColor Red
                    continue
                }

                $apkPath = $rawPath
                break
            }

            # Setup Link Handling features dynamically.
            $routeLinks = Get-YesNoPrompt -Prompt "Route supported web links to the patched app? (--route-links)"
            $disableStock = $false
            if ($routeLinks) {
                $disableStock = Get-YesNoPrompt -Prompt "Also stop the stock app from opening these links? (--disable-stock)"
            }

            Write-Ui "  [i] Ensure your device is connected via USB and ADB debugging is authorized." -ForegroundColor DarkGray

            $baseArgs = [System.Collections.Generic.List[string]]::new()
            foreach ($arg in @("-Xmx2G", "-jar", $cliAbsPath, "utility", "install", "-a", $apkPath)) {
                $baseArgs.Add($arg)
            }
            if ($installMode -eq '2') {
                $pkg = Read-ValidatedInput -Prompt "Target Package Name (e.g., com.google.android.youtube)" -RegexPattern "^(?:[a-zA-Z][a-zA-Z0-9_]*)(?:\.[a-zA-Z][a-zA-Z0-9_]*)+$" -ErrorMessage "Invalid Android package name format."
                $baseArgs.Add("-m")
                $baseArgs.Add($pkg)
            }

            # Link handling flag injections.
            if ($routeLinks) { $baseArgs.Add("--route-links") }
            if ($disableStock) {
                $stockPkg = Read-ValidatedInput -Prompt "Stock Package Name to disable" -RegexPattern "^(?:[a-zA-Z][a-zA-Z0-9_]*)(?:\.[a-zA-Z][a-zA-Z0-9_]*)+$" -ErrorMessage "Invalid Android package name format."
                $baseArgs.Add("--disable-stock")
                $baseArgs.Add($stockPkg)
            }

            Write-Ui "`nExecuting Morphe Utility..." -ForegroundColor Magenta
            $res = Invoke-NativeTool -Executable 'java' -Arguments $baseArgs.ToArray() -StreamToConsole
            if ($res.ExitCode -ne 0) {
                Write-Ui "  [!] Command FAILED (Exit Code: $($res.ExitCode))" -ForegroundColor Red
            } else {
                Write-Ui "  [✓] Command SUCCEEDED" -ForegroundColor Green
            }
        } elseif ($utilChoice -eq '2') {
            Write-Ui "`n[UNINSTALL] Select Uninstall Mode:" -ForegroundColor Yellow
            Write-Ui "1. Non-Root (Standard Uninstall via --package-name)"
            Write-Ui "2. Root (Unmount via --unmount)"
            $uninstallMode = Read-ValidatedInput -Prompt "Enter choice (1 or 2)" -RegexPattern "^[12]$" -ErrorMessage "Invalid input."

            $pkg = Read-ValidatedInput -Prompt "Target Package Name (e.g., com.google.android.youtube)" -RegexPattern "^(?:[a-zA-Z][a-zA-Z0-9_]*)(?:\.[a-zA-Z][a-zA-Z0-9_]*)+$" -ErrorMessage "Invalid Android package name format."

            Write-Ui "  [i] Ensure your device is connected via USB and ADB debugging is authorized." -ForegroundColor DarkGray

            $baseArgs = [System.Collections.Generic.List[string]]::new()
            foreach ($arg in @("-Xmx2G", "-jar", $cliAbsPath, "utility", "uninstall", "-p", $pkg)) {
                $baseArgs.Add($arg)
            }
            if ($uninstallMode -eq '2') {
                $baseArgs.Add("--unmount")
            }

            Write-Ui "`nExecuting Morphe Utility..." -ForegroundColor Magenta
            $res = Invoke-NativeTool -Executable 'java' -Arguments $baseArgs.ToArray() -StreamToConsole
            if ($res.ExitCode -ne 0) {
                Write-Ui "  [!] Command FAILED (Exit Code: $($res.ExitCode))" -ForegroundColor Red
            } else {
                Write-Ui "  [✓] Command SUCCEEDED" -ForegroundColor Green
            }
        }
    } elseif ($utilChoice -in @('3', '4')) {
        $script:OptionsBackupMode = $null

        $ecosystems = @(Resolve-Ecosystem)
        if ($ecosystems.Count -eq 0) { return $true }

        foreach ($eco in $ecosystems) {
            Write-Ui "`n>>> PROCESSING ECOSYSTEM: $($eco.Name.ToUpper()) <<<" -ForegroundColor Cyan

            $envArt = Resolve-EnvironmentArtifact -Workspace $eco.Workspace -ProjectName $eco.Name -RequirePatches $true
            if (-not $envArt) { continue }

            $cliAbsPath = $envArt.Cli.FullName
            $patchAbsPath = $envArt.Patches.FullName
            $extraPatches = $envArt.ExtraPatches

            if ($utilChoice -eq '3') {
                Write-Ui "`n[GENERATE OPTIONS] Running for all supported apps in $($eco.Name)..." -ForegroundColor Yellow

                foreach ($app in $eco.Apps) {
                    $optionSlug = $app.name.ToLower().Replace('_', '-')
                    $jsonFileName = Join-Path $eco.Workspace "$optionSlug-options-$($envArt.Track).json"

                    if (-not (Resolve-OptionsFileBackup -FilePath $jsonFileName -Label $optionSlug)) {
                        Write-Ui "  [!] Skipping $optionSlug due to file operation failure." -ForegroundColor Yellow
                        continue
                    }

                    $optArgs = [System.Collections.Generic.List[string]]::new()
                    foreach ($arg in @("-Xmx2G", "-jar", $cliAbsPath, "options-create", "--patches", $patchAbsPath)) {
                        $optArgs.Add($arg)
                    }
                    if ($extraPatches) {
                        foreach ($ep in $extraPatches) {
                            $optArgs.Add("--patches")
                            $optArgs.Add($ep.FullName)
                        }
                    }
                    foreach ($arg in @("--out", $jsonFileName, "--filter-package-name", $app.package)) {
                        $optArgs.Add($arg)
                    }

                    Write-Ui "  Generating for $($app.package)..." -ForegroundColor DarkGray
                    $res = Invoke-NativeTool -Executable 'java' -Arguments $optArgs.ToArray() -StreamToConsole

                    if ($res.ExitCode -eq 0 -and (Test-Path -LiteralPath $jsonFileName)) {
                        Write-Ui "  [✓] Saved to $(Split-Path -Path $jsonFileName -Leaf)" -ForegroundColor Green
                    } else {
                        Write-Ui "  [!] Failed to generate for $($app.package)" -ForegroundColor Red
                    }
                }
            } elseif ($utilChoice -eq '4') {
                $patchesListFile = Join-Path $eco.Workspace "list-patches-$($envArt.Track).txt"
                Write-Ui "`n[GENERATE LIST] Exporting patches reference to $(Split-Path -Path $patchesListFile -Leaf)..." -ForegroundColor Yellow

                if (Test-Path -LiteralPath $patchesListFile) {
                    try { Remove-Item -LiteralPath $patchesListFile -Force -ErrorAction Stop }
                    catch { Write-Ui "  [!] Warning: Could not remove existing patches list. It may be locked." -ForegroundColor Yellow }
                }

                $incExp = Get-YesNoPrompt -Prompt "Include experimental app versions in the output? (--include-experimental)"

                $listArgs = [System.Collections.Generic.List[string]]::new()
                foreach ($arg in @("-Xmx2G", "-jar", $cliAbsPath, "list-patches", "--with-packages", "--with-versions", "--with-options", "--out", $patchesListFile, "--patches", $patchAbsPath)) {
                    $listArgs.Add($arg)
                }
                if ($incExp) { $listArgs.Add("--include-experimental") }
                if ($extraPatches) {
                    foreach ($ep in $extraPatches) {
                        $listArgs.Add("--patches")
                        $listArgs.Add($ep.FullName)
                    }
                }

                $res = Invoke-NativeTool -Executable 'java' -Arguments $listArgs.ToArray() -StreamToConsole

                if ($res.ExitCode -eq 0 -and (Test-Path -LiteralPath $patchesListFile)) {
                    Write-Ui "  [✓] Reference file created successfully in .\$($eco.Name)\" -ForegroundColor Green
                } else {
                    Write-Ui "  [!] Failed to create patches reference file." -ForegroundColor Red
                }
            }
        }
    } elseif ($utilChoice -eq '5') {
        Write-Ui "`n[GENERATE KEYSTORE] Creating a new PKCS12 Keystore..." -ForegroundColor Yellow

        if (-not (Get-Command -Name 'keytool' -ErrorAction SilentlyContinue)) {
            Write-Ui "  [!] 'keytool' executable not found in PATH. Ensure JDK 25 bin directory is on PATH." -ForegroundColor Red
            Start-Sleep -Seconds 2
            return $true
        }

        while ($true) {
            $ksName = Read-ValidatedInput -Prompt "Enter filename (e.g., my-key.keystore)" -RegexPattern "^[a-zA-Z0-9_\-\.]+$" -ErrorMessage "ASCII letters, numbers, dashes, underscores, and dots only."
            if ($ksName -match '\.\.' -or $ksName -match '^\.') {
                Write-Ui "  Invalid filename. Avoid '..' or leading dots." -ForegroundColor Red
                continue
            }
            break
        }

        if ($ksName -notmatch '\.[a-zA-Z0-9]+$') {
            if ($env:OS -eq 'Windows_NT') {
                $ksName += ".keystore"
                Write-Ui "  [i] Windows OS detected. Auto-appending '.keystore' -> $ksName" -ForegroundColor DarkGray
            } else {
                Write-Ui "  [i] Unix/macOS detected. Keeping extensionless filename -> $ksName" -ForegroundColor DarkGray
            }
        }

        $ksAlias = Read-ValidatedInput -Prompt "Enter Alias" -RegexPattern "^[a-zA-Z0-9_\-\s]+$" -ErrorMessage "ASCII alphanumeric, spaces, underscores, and dashes only."

        $ksSecurePass = $null
        $ksPassEnvVar = "CHIHAFUYU_KS_PASS_$([guid]::NewGuid().ToString('N'))"
        $ksPath = Join-Path $PSScriptRoot $ksName

        try {
            while ($true) {
                $candidatePass = Read-Host -Prompt "Enter Password (min 6 chars, or 'B' to go back)" -AsSecureString
                if ($null -eq $candidatePass) {
                    Write-Ui "  Password must be at least 6 characters." -ForegroundColor Red
                    continue
                }
                if ($candidatePass.Length -eq 1) {
                    $singleChar = ConvertFrom-SecureStringToBstrValue -SecureValue $candidatePass
                    $isBack = ($singleChar -match '^[bB]$')
                    $singleChar = $null
                    if ($isBack) {
                        $candidatePass.Dispose()
                        throw "BACK_TO_MAIN"
                    }
                }
                if ($candidatePass.Length -lt 6) {
                    $candidatePass.Dispose()
                    Write-Ui "  Password must be at least 6 characters." -ForegroundColor Red
                    continue
                }
                $confirmPass = Read-Host -Prompt "Confirm Password" -AsSecureString
                $p1 = ConvertFrom-SecureStringToBstrValue -SecureValue $candidatePass
                $p2 = ConvertFrom-SecureStringToBstrValue -SecureValue $confirmPass
                $match = [string]::Equals($p1, $p2, [System.StringComparison]::Ordinal)
                $p1 = $null; $p2 = $null
                $confirmPass.Dispose()

                if (-not $match) {
                    $candidatePass.Dispose()
                    Write-Ui "  Passwords do not match. Please try again." -ForegroundColor Red
                    continue
                }
                $ksSecurePass = $candidatePass
                break
            }

            Write-Ui "  [i] Android limits META-INF signatures (SignerName) to max 8 characters, NO spaces." -ForegroundColor DarkGray
            $ksSigner = Read-ValidatedInput -Prompt "Enter Signer Name (CN)" -RegexPattern "^[a-zA-Z0-9_\-]{1,8}$" -ErrorMessage "Max 8 chars, no spaces."

            $ksOU = Read-ValidatedInput -Prompt "Enter Organizational Unit (OU) [e.g., IT, Modder]" -RegexPattern "^[a-zA-Z0-9_\-\.\s]+$" -ErrorMessage "ASCII alphanumeric, spaces, dots, underscores, and dashes only."
            $ksOrg = Read-ValidatedInput -Prompt "Enter Organization (O) [e.g., MyCompany]" -RegexPattern "^[a-zA-Z0-9_\-\.\s]+$" -ErrorMessage "ASCII alphanumeric, spaces, dots, underscores, and dashes only."
            $ksCountry = Read-ValidatedInput -Prompt "Enter 2-letter Country Code (C) [e.g., ID, US]" -RegexPattern "^[a-zA-Z]{2}$" -ErrorMessage "Must be exactly 2 letters."

            if (Test-Path -LiteralPath $ksPath) {
                Write-Ui "  [!] File '$ksName' already exists in the root folder!" -ForegroundColor Red
            } else {
                Write-Ui "  Generating keystore using Java keytool..." -ForegroundColor DarkGray

                $envVal = ConvertFrom-SecureStringToBstrValue -SecureValue $ksSecurePass
                [Environment]::SetEnvironmentVariable($ksPassEnvVar, $envVal, [System.EnvironmentVariableTarget]::Process)
                $envVal = $null

                $keytoolArgs = @(
                    "-genkeypair",
                    "-v",
                    "-keystore", $ksPath,
                    "-alias", $ksAlias,
                    "-keyalg", "RSA",
                    "-keysize", "4096",
                    "-validity", "10000",
                    "-storepass:env", $ksPassEnvVar,
                    "-keypass:env", $ksPassEnvVar,
                    "-dname", "CN=$ksSigner, OU=$ksOU, O=$ksOrg, C=$($ksCountry.ToUpper())",
                    "-storetype", "PKCS12"
                )

                $res = Invoke-NativeTool -Executable 'keytool' -Arguments $keytoolArgs

                if ($res.ExitCode -eq 0 -and (Test-Path -LiteralPath $ksPath)) {
                    Write-Ui "  [✓] Keystore generated successfully at: $ksPath" -ForegroundColor Green
                } else {
                    Write-Ui "  [!] Failed to generate keystore (Exit Code: $($res.ExitCode))." -ForegroundColor Red
                    foreach ($line in $res.Output) {
                        if (-not [string]::IsNullOrWhiteSpace($line)) {
                            Write-Ui "      $line" -ForegroundColor DarkGray
                        }
                    }
                }
            }
        } finally {
            [Environment]::SetEnvironmentVariable($ksPassEnvVar, $null, [System.EnvironmentVariableTarget]::Process)
            if ($null -ne $ksSecurePass) { $ksSecurePass.Dispose() }
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
        }
    } elseif ($utilChoice -eq '6') {
        Write-Ui "`n[CLEAR CACHE] Clearing Morphe temporary files and cache..." -ForegroundColor Yellow

        # Standalone CLI discovery — no ecosystem prompt needed.
        $cliJar = Read-StandaloneCliJar -SearchRoot $PSScriptRoot
        if (-not $cliJar) { return $true }
        $cliAbsPath = $cliJar.FullName

        $baseArgs = @("-jar", $cliAbsPath, "utility", "clear-cache", "--info")

        Write-Ui "`nExecuting Morphe Utility..." -ForegroundColor Magenta
        $res = Invoke-NativeTool -Executable 'java' -Arguments $baseArgs

        foreach ($line in $res.Output) {
            Write-Ui "  $line" -ForegroundColor DarkGray
        }

        if ($res.ExitCode -eq 0) {
            Write-Ui "  [✓] Cache cleared successfully." -ForegroundColor Green
        } else {
            Write-Ui "  [!] Failed to clear cache (Exit Code: $($res.ExitCode))." -ForegroundColor Red
        }
    }

    Write-Ui "`nPress Enter to return to the Main Menu..." -ForegroundColor Magenta
    $null = Read-SafeLine -NoPrompt
    return $true
}

function Invoke-MainMenu {
    Clear-UiScreen
    Write-Ui "==============================================" -ForegroundColor Cyan
    Write-Ui "                CHIHAFUYU TOOL                " -ForegroundColor Cyan
    Write-Ui "==============================================" -ForegroundColor Cyan

    Write-Ui "`nWhat do you want to do?" -ForegroundColor Yellow
    Write-Ui "1. Patch apps"
    Write-Ui "2. Use utilities"
    Write-Ui "X. Close"

    while ($true) {
        $choice = Read-ValidatedInput -Prompt "Enter choice" -RegexPattern "^[12xX]$" -ErrorMessage "Invalid input. Please enter 1, 2, or X." -NoBack

        if ($choice -match '^[xX]$') {
            return $false
        } elseif ($choice -eq '1') {
            try {
                Invoke-PatchingWorkflow
            } catch {
                if ($_.Exception.Message -eq "BACK_TO_MAIN") {
                    Write-Ui "`n[i] Operation aborted. Returning to the Main Menu..." -ForegroundColor Yellow
                    Start-Sleep -Seconds 1
                } else {
                    Write-Ui "`n[FATAL ERROR] $($_.Exception.Message)" -ForegroundColor Red
                    Write-Ui "Press Enter to exit..." -ForegroundColor DarkGray
                    $null = Read-SafeLine -NoPrompt
                    exit 1
                }
            }
            return $true
        } elseif ($choice -eq '2') {
            try {
                $keepRunning = Invoke-UtilityWorkflow
                return $keepRunning
            } catch {
                if ($_.Exception.Message -eq "BACK_TO_MAIN") {
                    Write-Ui "`n[i] Operation aborted. Returning to the Main Menu..." -ForegroundColor Yellow
                    Start-Sleep -Seconds 1
                } else {
                    Write-Ui "`n[FATAL ERROR] $($_.Exception.Message)" -ForegroundColor Red
                    Write-Ui "Press Enter to exit..." -ForegroundColor DarkGray
                    $null = Read-SafeLine -NoPrompt
                    exit 1
                }
            }
            return $true
        }
    }
}

function Invoke-ChihafuyuTool {
    if (-not (Test-JavaEnvironment)) {
        exit 1
    }

    while (Invoke-MainMenu) { }

    Write-Ui "`nSession ended. Have a great day!" -ForegroundColor Cyan
    Start-Sleep -Seconds 2

    # Forces a clean exit code so the terminal does not flash previous Java errors.
    exit 0
}

if ($MyInvocation.InvocationName -ne '.') {
    Invoke-ChihafuyuTool
}
