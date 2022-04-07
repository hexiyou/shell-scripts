#!/usr/bin/env -S pwsh -nop
#搜索 Scoop 应用（软件包）

<#PSScriptInfo
.VERSION 1.0
.GUID 410c7a68-d6f3-4a81-b86a-063ac0b6616d
.AUTHOR Rashil Gandhi
.COMPANYNAME
.COPYRIGHT
.TAGS scoop find search bucket apps
.LICENSEURI
.PROJECTURI
.ICONURI
.REQUIREDMODULES PSSQLite
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES
.PRIVATEDATA
#>

<#
.SYNOPSIS
  Find scoop apps.
.DESCRIPTION
  Easily find scoop apps on entire GitHub - that too in blazing fast speed.
.PARAMETER Name
  Name of the app(s).
.PARAMETER Description
  Some string to search in the description of app(s).
.PARAMETER Version
  Version of the app(s).
.PARAMETER Bucket
  Specify a search string in a particular bucket.
.PARAMETER Table
  This is by default set to 'app'. Set it to 'bucket' to search for buckets.
.PARAMETER ForceUpdate
  The database file will get updated if the script finds it to be older than 24 hours. Set this to '$true' to force an update.
.EXAMPLE
  PS C:\> Find-Scoop rust
  Search for all apps that contain the term `rust` in the name
.EXAMPLE
  PS C:\> Find-Scoop -Description golang
  Search for all apps that contain the term `golang` in the description
.EXAMPLE
  PS C:\> Find-Scoop -Table bucket -Bucket java
  Search for all buckets that contain the term `java` in their name
.EXAMPLE
  PS C:\> Find-Scoop -Bucket https://github.com/naderi/scoop-bucket vim
  Search for all apps that contain the term `vim` in the name, in the bucket pointed to by the GitHub URL
.LINK
  Written By: rashil2000
  This script uses `scoop-directory.db` from https://github.com/rasa/scoop-directory
  The discussion can be found here https://github.com/rasa/scoop-directory/pull/62
  It might not work as expected if that database file goes down
#>


param(
  [String]$Name,
  [String]$Description,
  [String]$Version,
  [String]$Bucket,
  [String]$Table = 'app',
  [Switch]$ForceUpdate = $false
)

$DBFile = "~\Projects\Random\scoop_directory.db"
$e = [char]0x1b
function embed_url($url, $text) {
  return "$e]8;;$url$e`\$text$e]8;;$e`\"
}

if ($Table -eq 'bucket') {
  if (!($Bucket)) {
    Write-Host "`nEnter bucket repository query.`n" -ForegroundColor Red
    return
  }
  $query = "SELECT * FROM buckets WHERE bucket_url LIKE `"%$Bucket%`" ORDER BY packages DESC"
} else {
  if (!($Name -or $Description)) {
    Write-Host "`nEnter at least one of name or description.`n" -ForegroundColor Red
    return
  }
  $query = @"
SELECT *
FROM apps
WHERE name LIKE `"%$Name%`" AND description LIKE `"%$Description%`" AND version LIKE `"%$Version%`" AND bucket LIKE `"%$Bucket%`"
ORDER BY
  CASE
    WHEN name LIKE "$Name" THEN 1
    WHEN name LIKE "$Name%" THEN 2
    WHEN name LIKE "%$Name" THEN 3
    ELSE 4
  END
"@
}

if (!(Test-Path $DBFile) -or ((Get-Date) - (Get-Item $DBFile).LastWriteTime).TotalHours -ge 24 -or $ForceUpdate) {
  Invoke-WebRequest 'https://raw.githubusercontent.com/rasa/scoop-directory/master/scoop_directory.db' -UseBasicParsing -OutFile $DBFile
  Write-Host "`nUpdated database - $DBFile.`n" -ForegroundColor Green
}

$retval = Invoke-SqliteQuery -Database $DBFile -Query $query
$apps = @()

for ($i=0; $i -lt $retval.Length; $i++) {
  $apps += [ordered]@{
    Name = embed_url $retval[$i].homepage $retval[$i].name;
    Version = embed_url $retval[$i].manifest_url $retval[$i].version;
    Description = $retval[$i].description;
    Bucket = embed_url $retval[$i].bucket_url $retval[$i].bucket;
    License = embed_url $retval[$i].license_url $retval[$i].license
  }
}

return $apps.ForEach({[PSCustomObject]$_})