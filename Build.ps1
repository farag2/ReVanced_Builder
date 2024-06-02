<#
	.SYNOPSIS
	Build ReVanced app using latest components:
	  * YouTube (latest supported);
	  * ReVanced CLI;
	  * ReVanced Patches;
	  * ReVanced Integrations;
	  * ReVanced microG GmsCore;
	  * Azul Zulu.

	.NOTES
	After compiling, microg.apk and compiled revanced.apk will be located in "Downloads folder\ReVanced"

	.LINKS
	https://github.com/revanced
#>

#Requires -Version 5.1

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if ($Host.Version.Major -eq 5)
{
	# Progress bar can significantly impact cmdlet performance
	# https://github.com/PowerShell/PowerShell/issues/2138
	$Script:ProgressPreference = "SilentlyContinue"
}

# Download all files to "Downloads folder\ReVanced"
$DownloadsFolder = Get-ItemPropertyValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "{374DE290-123F-4565-9164-39C4925E467B}"
if (-not (Test-Path -Path "$DownloadsFolder\ReVanced"))
{
	New-Item -Path "$DownloadsFolder\ReVanced" -ItemType Directory -Force
}

# Get the latest supported YouTube version to patch
# https://api.revanced.app/docs/swagger
$Parameters = @{
	Uri             = "https://api.revanced.app/v2/patches/latest"
	UseBasicParsing = $true
	Verbose         = $true
}
$LatestSupported = ((Invoke-RestMethod @Parameters).patches | Where-Object -FilterScript {$_.name -eq "Video ads"}).compatiblePackages.versions | Sort-Object -Descending -Unique | Select-Object -First 1

# We need a NON-bundle version
# https://apkpure.net/ru/youtube/com.google.android.youtube/versions
$Parameters = @{
	Uri             = "https://apkpure.net/youtube/com.google.android.youtube/download/$($LatestSupported)"
	UseBasicParsing = $true
	Verbose         = $true
}
$DownloadURL = (Invoke-Webrequest @Parameters).Links.href | Where-Object -FilterScript {$_ -match "APK/com.google.android.youtube"} | Select-Object -Index 1

$Parameters = @{
	Uri             = $DownloadURL
	OutFile         = "$DownloadsFolder\ReVanced\youtube.apk"
	UseBasicParsing = $true
	Verbose         = $true
}
Invoke-Webrequest @Parameters

# https://github.com/revanced/revanced-cli
$Parameters = @{
	Uri             = "https://api.github.com/repos/revanced/revanced-cli/releases/latest"
	UseBasicParsing = $true
	Verbose         = $true
}

$Tag = (Invoke-RestMethod @Parameters).tag_name
$Tag2 = $Tag.replace("v", "")
$Parameters = @{
	Uri             = "https://github.com/revanced/revanced-cli/releases/download/$Tag/revanced-cli-$Tag2-all.jar"
	Outfile         = "$DownloadsFolder\ReVanced\revanced-cli.jar"
	UseBasicParsing = $true
	Verbose         = $true
}
Invoke-RestMethod @Parameters

# https://github.com/revanced/revanced-patches
$Parameters = @{
	Uri             = "https://api.github.com/repos/revanced/revanced-patches/releases/latest"
	UseBasicParsing = $true
	Verbose         = $true
}

$Tag = (Invoke-RestMethod @Parameters).tag_name
$Tag2 = $Tag.replace("v", "")
$Parameters = @{
	Uri             = "https://github.com/revanced/revanced-patches/releases/download/$Tag/revanced-patches-$Tag2.jar"
	Outfile         = "$DownloadsFolder\ReVanced\revanced-patches.jar"
	UseBasicParsing = $true
	Verbose         = $true
}
Invoke-RestMethod @Parameters

# https://github.com/revanced/revanced-integrations
$Parameters = @{
	Uri             = "https://api.github.com/repos/revanced/revanced-integrations/releases/latest"
	UseBasicParsing = $true
	Verbose         = $true
}
$IntegrationsTag = (Invoke-RestMethod @Parameters).tag_name

$Parameters = @{
	Uri             = "https://github.com/revanced/revanced-integrations/releases/download/$IntegrationsTag/revanced-integrations-$($IntegrationsTag.replace(`"v`", `"`")).apk"
	Outfile         = "$DownloadsFolder\ReVanced\revanced-integrations.apk"
	UseBasicParsing = $true
	Verbose         = $true
}
Invoke-RestMethod @Parameters

# https://github.com/ReVanced/GmsCore
$Parameters = @{
	Uri             = "https://api.github.com/repos/ReVanced/GmsCore/releases/latest"
	UseBasicParsing = $true
	Verbose         = $true
}
$URL = (Invoke-RestMethod @Parameters).assets.browser_download_url | Where-Object -FilterScript {$_ -notmatch "hw"}

$Parameters = @{
	Uri             = $URL
	Outfile         = "$DownloadsFolder\ReVanced\microg.apk"
	UseBasicParsing = $true
	Verbose         = $true
}
Invoke-RestMethod @Parameters

Remove-Item -Path "$DownloadsFolder\ReVanced\zulu-jdk-win_x64" -Recurse -Force -ErrorAction Ignore

# https://app.swaggerhub.com/apis-docs/azul/zulu-download-community/1.0
$Parameters = @{
	Uri             = "https://api.azul.com/zulu/download/community/v1.0/bundles/latest/?jdk_version=21&bundle_type=jdk&javafx=false&ext=msi&os=windows&arch=x86&hw_bitness=64"
	UseBasicParsing = $true
	Verbose         = $true
}
$URL = (Invoke-RestMethod @Parameters).url

$Parameters = @{
	Uri             = $URL
	Outfile         = "$DownloadsFolder\ReVanced\zulu-jdk-win_x64.msi"
	UseBasicParsing = $true
	Verbose         = $true
}
Invoke-RestMethod @Parameters

# Extract zulu-jdk-win_x64.msi to zulu-jdk-win_x64 folder
$Arguments = @(
	"/a `"$DownloadsFolder\ReVanced\zulu-jdk-win_x64.msi`"",
	"TARGETDIR=`"$DownloadsFolder\ReVanced\zulu-jdk-win_x64`""
	"/qb"
)
Start-Process "msiexec" -ArgumentList $Arguments -Wait

Remove-Item -Path "$DownloadsFolder\ReVanced\zulu-jdk-win_x64.msi" -Force

# https://revanced.app/patches?pkg=com.google.android.youtube
# https://github.com/ReVanced/revanced-cli/blob/main/docs/1_usage.md
& "$DownloadsFolder\ReVanced\zulu-jdk-win_x64\Program Files\Zulu\zulu*\bin\java.exe" `
-jar "$DownloadsFolder\ReVanced\revanced-cli.jar" `
patch "$DownloadsFolder\ReVanced\youtube.apk" `
--patch-bundle "$DownloadsFolder\ReVanced\revanced-patches.jar" `
--merge "$DownloadsFolder\ReVanced\revanced-integrations.apk" `
--exclude comments --exclude premium-heading --exclude hide-captions-button --exclude disable-fullscreen-panels `
--purge `
--out "$DownloadsFolder\ReVanced\revanced.apk"

Invoke-Item -Path "$DownloadsFolder\ReVanced"
