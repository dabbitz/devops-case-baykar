param (
    [switch]$TestMode
)

$ErrorActionPreference = "Stop"

$namespace = "devops-case"
$alerts = @()

function Add-Alert {
    param (
        [string]$Id,
        [string]$Message
    )

    $script:alerts += [PSCustomObject]@{
        Id       = $Id
        Severity = "CRITICAL"
        Message  = $Message
    }

    Write-Host "[CRITICAL][$Id] $Message" -ForegroundColor Red
}

Write-Host "=== Kubernetes Alert Check ===" -ForegroundColor Cyan
Write-Host "Namespace: $namespace" -ForegroundColor DarkGray
Write-Host ""


# ------------------------------------------------------------
# ALERT-001: ETL failure / missing successful run
# ------------------------------------------------------------

Write-Host "Checking ETL CronJob..." -ForegroundColor Yellow

if ($TestMode) {

    Add-Alert `
        -Id "ALERT-001" `
        -Message "ETL CronJob failure detected. The latest ETL execution is considered failed."

}
else {

    $jobsJson = kubectl get jobs `
        -n $namespace `
        -o json `
        2>$null

    if ($LASTEXITCODE -ne 0) {
        throw "Unable to query Kubernetes Jobs."
    }

    $jobs = ($jobsJson | ConvertFrom-Json).items

    $etlJobs = $jobs |
        Where-Object {
            $_.metadata.ownerReferences -and
            ($_.metadata.ownerReferences | Where-Object {
                $_.kind -eq "CronJob" -and $_.name -eq "etl"
            })
        } |
        Sort-Object {
            [datetime]$_.metadata.creationTimestamp
        } -Descending

    if (-not $etlJobs) {

        Add-Alert `
            -Id "ALERT-001" `
            -Message "No ETL Job exists for CronJob 'etl'."

    }
    else {

        $latestJob = $etlJobs | Select-Object -First 1

        $latestJobName = $latestJob.metadata.name
        $latestJobTime = [datetime]$latestJob.metadata.creationTimestamp

        $succeeded = [int]($latestJob.status.succeeded)
        $failed = [int]($latestJob.status.failed)

        if ($failed -gt 0 -and $succeeded -eq 0) {

            Add-Alert `
                -Id "ALERT-001" `
                -Message "ETL Job '$latestJobName' failed."

        }
        elseif (
            $succeeded -eq 0 -and
            $latestJobTime -lt (Get-Date).ToUniversalTime().AddMinutes(-90)
        ) {

            Add-Alert `
                -Id "ALERT-001" `
                -Message "No successful ETL execution has completed within the expected time window."

        }
        else {

            Write-Host "ETL status: OK ($latestJobName)" -ForegroundColor Green
        }
    }
}


# ------------------------------------------------------------
# ALERT-002: Application endpoint unavailable
# ------------------------------------------------------------

Write-Host "Checking application endpoints..." -ForegroundColor Yellow

if ($TestMode) {

    Add-Alert `
        -Id "ALERT-002" `
        -Message "Application endpoint healthcheck failed."

}
else {

    $frontendHealthy = $true
    $backendHealthy = $true

    try {

        curl.exe `
            --silent `
            --show-error `
            --fail `
            "http://localhost/" |
            Out-Null

    }
    catch {
        $frontendHealthy = $false
    }


    try {

        curl.exe `
            --silent `
            --show-error `
            --fail `
            "http://localhost/api/healthcheck/" |
            Out-Null

    }
    catch {
        $backendHealthy = $false
    }


    if (-not $frontendHealthy -or -not $backendHealthy) {

        $failedEndpoints = @()

        if (-not $frontendHealthy) {
            $failedEndpoints += "frontend"
        }

        if (-not $backendHealthy) {
            $failedEndpoints += "backend"
        }

        Add-Alert `
            -Id "ALERT-002" `
            -Message "Application endpoint healthcheck failed: $($failedEndpoints -join ', ')."

    }
    else {

        Write-Host "Application endpoints: OK" -ForegroundColor Green
    }
}


# ------------------------------------------------------------
# Optional webhook notification
# ------------------------------------------------------------

if ($alerts.Count -gt 0) {

    $message = ($alerts | ForEach-Object {
        "[$($_.Severity)][$($_.Id)] $($_.Message)"
    }) -join "`n"

    Write-Host ""
    Write-Host "=== Alerts Detected ===" -ForegroundColor Red
    Write-Host $message -ForegroundColor Red

    if ($env:ALERT_WEBHOOK_URL) {

        $payload = @{
            text = $message
        } | ConvertTo-Json

        try {

            Invoke-RestMethod `
                -Method Post `
                -Uri $env:ALERT_WEBHOOK_URL `
                -ContentType "application/json" `
                -Body $payload

            Write-Host "Webhook notification sent." -ForegroundColor Yellow

        }
        catch {

            Write-Warning "Alert detected, but webhook notification failed."
        }
    }

    exit 1
}

Write-Host ""
Write-Host "No critical alerts detected." -ForegroundColor Green
exit 0