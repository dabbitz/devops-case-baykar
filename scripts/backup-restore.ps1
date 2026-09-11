param(
    [ValidateSet("Backup", "Restore")]
    [string]$Action = "Backup",

    [string]$BackupPath = ".\backups\sample-training-backup",

    [switch]$DropExisting
)

$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$EnvFile = Join-Path $ProjectRoot ".env"

$MongoDump = "C:\Program Files\MongoDB\Tools\100\bin\mongodump.exe"
$MongoRestore = "C:\Program Files\MongoDB\Tools\100\bin\mongorestore.exe"

function Get-EnvValue {
    param(
        [string]$Name
    )

    if (-not (Test-Path $EnvFile)) {
        throw ".env file not found: $EnvFile"
    }

    $line = Get-Content $EnvFile |
        Where-Object { $_ -match "^$Name=" } |
        Select-Object -First 1

    if (-not $line) {
        throw "$Name was not found in .env"
    }

    $value = $line -replace "^$Name=", ""
    $value = $value.Trim()

    if (($value.StartsWith('"') -and $value.EndsWith('"')) -or
        ($value.StartsWith("'") -and $value.EndsWith("'"))) {
        $value = $value.Substring(1, $value.Length - 2)
    }

    return $value
}

if (-not (Test-Path $MongoDump)) {
    throw "mongodump.exe not found: $MongoDump"
}

if (-not (Test-Path $MongoRestore)) {
    throw "mongorestore.exe not found: $MongoRestore"
}

$AtlasUri = Get-EnvValue "ATLAS_URI"

if ($Action -eq "Backup") {

    Write-Host "Creating backup directory..."
    New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null

    Write-Host "Starting MongoDB backup..."

    & $MongoDump `
        --uri="$AtlasUri" `
        --db=sample_training `
        --out="$BackupPath"

    if ($LASTEXITCODE -ne 0) {
        throw "mongodump failed with exit code $LASTEXITCODE"
    }

    Write-Host ""
    Write-Host "Backup completed successfully."
    Write-Host "Backup location: $BackupPath"
}
else {

    if (-not (Test-Path $BackupPath)) {
        throw "Backup directory not found: $BackupPath"
    }

    if ($DropExisting) {
        Write-Host "Existing collections will be dropped before restore."
        $DropArgument = "--drop"
    }
    else {
        $DropArgument = $null
    }

    Write-Host "Starting MongoDB restore..."

    if ($DropArgument) {
        & $MongoRestore `
            --uri="$AtlasUri" `
            $DropArgument `
            "$BackupPath"
    }
    else {
        & $MongoRestore `
            --uri="$AtlasUri" `
            "$BackupPath"
    }

    if ($LASTEXITCODE -ne 0) {
        throw "mongorestore failed with exit code $LASTEXITCODE"
    }

    Write-Host ""
    Write-Host "Restore completed successfully."
}