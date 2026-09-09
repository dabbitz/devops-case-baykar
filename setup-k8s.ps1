$ErrorActionPreference = "Stop"

Write-Host "=== DevOps Case Kubernetes Setup ===" -ForegroundColor Cyan

# ------------------------------------------------------------
# 0. Prerequisites
# ------------------------------------------------------------

if (-not (Test-Path ".env")) {
    throw ".env file not found. Copy .env.example to .env and fill in the required values."
}

if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    throw "kubectl is not available. Make sure Docker Desktop Kubernetes is enabled."
}

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "docker is not available."
}

if (-not (Get-Command helm -ErrorAction SilentlyContinue)) {
    throw "helm is not available. Install Helm before running this script."
}

$context = kubectl config current-context 2>$null

if (-not $context) {
    throw "No Kubernetes context is available. Create/start the Docker Desktop Kubernetes cluster first."
}

Write-Host "Kubernetes context: $context" -ForegroundColor Green


# ------------------------------------------------------------
# Helper: Read a value from .env without printing it
# ------------------------------------------------------------

function Get-DotEnvValue {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Key
    )

    $line = Get-Content ".env" |
        Where-Object { $_ -match "^\s*$([regex]::Escape($Key))\s*=" } |
        Select-Object -First 1

    if (-not $line) {
        throw "$Key is missing from .env"
    }

    $value = $line -replace "^\s*$([regex]::Escape($Key))\s*=", ""
    $value = $value.Trim()

    if (
        ($value.StartsWith('"') -and $value.EndsWith('"')) -or
        ($value.StartsWith("'") -and $value.EndsWith("'"))
    ) {
        $value = $value.Substring(1, $value.Length - 2)
    }

    if ([string]::IsNullOrWhiteSpace($value)) {
        throw "$Key is empty in .env"
    }

    return $value
}


# ------------------------------------------------------------
# Helper: Run a native command and stop on failure
# ------------------------------------------------------------

function Assert-LastExitCode {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    if ($LASTEXITCODE -ne 0) {
        throw $Message
    }
}


# ------------------------------------------------------------
# 1. Read secrets from .env
# ------------------------------------------------------------

$atlasUri = Get-DotEnvValue "ATLAS_URI"
$mongoUri = Get-DotEnvValue "MONGODB_URI"
$githubToken = Get-DotEnvValue "GITHUB_TOKEN"

Write-Host "Required .env values found." -ForegroundColor Green


# ------------------------------------------------------------
# 2. Namespace
# ------------------------------------------------------------

Write-Host "`n[1/7] Creating namespace..." -ForegroundColor Yellow

kubectl apply -f k8s/namespace.yaml

Assert-LastExitCode "Failed to create/update Kubernetes namespace."

Write-Host "Namespace ready." -ForegroundColor Green


# ------------------------------------------------------------
# 3. Kubernetes Secrets
# ------------------------------------------------------------

Write-Host "`n[2/7] Creating/updating Kubernetes secrets..." -ForegroundColor Yellow

kubectl create secret generic backend-secret `
    --namespace=devops-case `
    --from-literal="ATLAS_URI=$atlasUri" `
    --dry-run=client `
    -o yaml |
    kubectl apply -f -

Assert-LastExitCode "Failed to create/update backend-secret."

kubectl create secret generic etl-secret `
    --namespace=devops-case `
    --from-literal="GITHUB_TOKEN=$githubToken" `
    --from-literal="MONGODB_URI=$mongoUri" `
    --dry-run=client `
    -o yaml |
    kubectl apply -f -

Assert-LastExitCode "Failed to create/update etl-secret."

Write-Host "Secrets configured." -ForegroundColor Green


# ------------------------------------------------------------
# 4. Build application images
# ------------------------------------------------------------

Write-Host "`n[3/7] Building Docker images..." -ForegroundColor Yellow

docker build `
    -t devops-case-backend:k8s `
    ./mern-project/server

Assert-LastExitCode "Failed to build backend Docker image."

docker build `
    --build-arg REACT_APP_API_URL=/api `
    -t devops-case-frontend:k8s `
    ./mern-project/client

Assert-LastExitCode "Failed to build frontend Docker image."

docker build `
    -t devops-case-etl:k8s `
    ./python-project

Assert-LastExitCode "Failed to build ETL Docker image."

Write-Host "Docker images built successfully." -ForegroundColor Green


# ------------------------------------------------------------
# 5. Import images into Kind Kubernetes node
# ------------------------------------------------------------

Write-Host "`n[4/7] Importing images into Kubernetes..." -ForegroundColor Yellow

$tempDir = Join-Path $PWD ".k8s-image-cache"

if (Test-Path $tempDir) {
    Remove-Item $tempDir -Recurse -Force
}

New-Item -ItemType Directory -Path $tempDir | Out-Null


function Import-ImageToKindNode {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Image,

        [Parameter(Mandatory = $true)]
        [string]$TarName
    )

    $tarPath = Join-Path $tempDir $TarName
    $remotePath = "/root/$TarName"

    Write-Host "Exporting $Image..." -ForegroundColor DarkGray

    docker image save $Image -o $tarPath

    Assert-LastExitCode "Failed to export Docker image: $Image"

    Write-Host "Copying $TarName to Kubernetes node..." -ForegroundColor DarkGray

    docker cp $tarPath "desktop-control-plane:$remotePath"

    Assert-LastExitCode "Failed to copy $TarName to desktop-control-plane."

    Write-Host "Importing $Image into containerd..." -ForegroundColor DarkGray

    docker exec desktop-control-plane `
        ctr -n k8s.io images import $remotePath

    Assert-LastExitCode "Failed to import $Image into Kubernetes containerd."

    Write-Host "Removing temporary image archive from Kubernetes node..." -ForegroundColor DarkGray

    docker exec desktop-control-plane `
        rm -f $remotePath

    Assert-LastExitCode "Failed to remove temporary archive: $remotePath"
}


Import-ImageToKindNode `
    "devops-case-backend:k8s" `
    "backend-k8s.tar"

Import-ImageToKindNode `
    "devops-case-frontend:k8s" `
    "frontend-k8s.tar"

Import-ImageToKindNode `
    "devops-case-etl:k8s" `
    "etl-k8s.tar"


Remove-Item $tempDir -Recurse -Force

Write-Host "Images imported successfully." -ForegroundColor Green


# ------------------------------------------------------------
# 6. Application workloads
# ------------------------------------------------------------

Write-Host "`n[5/7] Deploying application workloads..." -ForegroundColor Yellow

kubectl apply -f k8s/backend-service.yaml
Assert-LastExitCode "Failed to apply backend-service.yaml."

kubectl apply -f k8s/backend-deployment.yaml
Assert-LastExitCode "Failed to apply backend-deployment.yaml."

kubectl apply -f k8s/frontend-service.yaml
Assert-LastExitCode "Failed to apply frontend-service.yaml."

kubectl apply -f k8s/frontend-deployment.yaml
Assert-LastExitCode "Failed to apply frontend-deployment.yaml."

kubectl apply -f k8s/etl-cronjob.yaml
Assert-LastExitCode "Failed to apply etl-cronjob.yaml."


Write-Host "Waiting for backend..." -ForegroundColor DarkGray

kubectl rollout status `
    deployment/backend `
    -n devops-case `
    --timeout=180s

Assert-LastExitCode "Backend deployment did not become ready."


Write-Host "Waiting for frontend..." -ForegroundColor DarkGray

kubectl rollout status `
    deployment/frontend `
    -n devops-case `
    --timeout=180s

Assert-LastExitCode "Frontend deployment did not become ready."

Write-Host "Application workloads ready." -ForegroundColor Green


# ------------------------------------------------------------
# 7. Envoy Gateway
# ------------------------------------------------------------

Write-Host "`n[6/7] Installing/updating Envoy Gateway..." -ForegroundColor Yellow

helm upgrade --install eg `
    oci://docker.io/envoyproxy/gateway-helm `
    --version v1.9.1 `
    -n envoy-gateway-system `
    --create-namespace

Assert-LastExitCode "Failed to install/update Envoy Gateway."


kubectl rollout status `
    deployment/envoy-gateway `
    -n envoy-gateway-system `
    --timeout=180s

Assert-LastExitCode "Envoy Gateway controller did not become ready."

Write-Host "Envoy Gateway controller ready." -ForegroundColor Green


# ------------------------------------------------------------
# 8. Gateway resources
# ------------------------------------------------------------

Write-Host "`n[7/7] Configuring Gateway and HTTP routing..." -ForegroundColor Yellow

kubectl apply -f k8s/gatewayclass.yaml
Assert-LastExitCode "Failed to apply gatewayclass.yaml."

kubectl apply -f k8s/gateway.yaml
Assert-LastExitCode "Failed to apply gateway.yaml."

kubectl apply -f k8s/http-route.yaml
Assert-LastExitCode "Failed to apply http-route.yaml."

Write-Host "Gateway resources applied." -ForegroundColor Green


# ------------------------------------------------------------
# 9. Wait for Gateway to become programmed
# ------------------------------------------------------------

Write-Host "`nWaiting for Gateway to become PROGRAMMED=True..." -ForegroundColor Yellow

$gatewayReady = $false

for ($i = 0; $i -lt 60; $i++) {

    $programmed = kubectl get gateway devops-gateway `
        -n devops-case `
        -o jsonpath="{.status.conditions[?(@.type=='Programmed')].status}" 2>$null

    if ($programmed -eq "True") {
        $gatewayReady = $true
        break
    }

    Start-Sleep -Seconds 2
}

if (-not $gatewayReady) {
    throw "Gateway did not become PROGRAMMED=True within 120 seconds."
}

Write-Host "Gateway: PROGRAMMED=True" -ForegroundColor Green


# ------------------------------------------------------------
# 10. Wait for HTTPRoute
# ------------------------------------------------------------

Write-Host "Waiting for HTTPRoute to be accepted..." -ForegroundColor Yellow

$routeReady = $false

for ($i = 0; $i -lt 30; $i++) {

    $accepted = kubectl get httproute devops-route `
        -n devops-case `
        -o jsonpath="{.status.parents[0].conditions[?(@.type=='Accepted')].status}" 2>$null

    $resolved = kubectl get httproute devops-route `
        -n devops-case `
        -o jsonpath="{.status.parents[0].conditions[?(@.type=='ResolvedRefs')].status}" 2>$null

    if ($accepted -eq "True" -and $resolved -eq "True") {
        $routeReady = $true
        break
    }

    Start-Sleep -Seconds 2
}

if (-not $routeReady) {
    throw "HTTPRoute was not accepted/resolved within 60 seconds."
}

Write-Host "HTTPRoute: Accepted=True, ResolvedRefs=True" -ForegroundColor Green


# ------------------------------------------------------------
# 11. Final status
# ------------------------------------------------------------

Write-Host "`n=== Deployment Status ===" -ForegroundColor Cyan

kubectl get pods -n devops-case
Write-Host ""

kubectl get services -n devops-case
Write-Host ""

kubectl get cronjob -n devops-case
Write-Host ""

kubectl get gateway -n devops-case
Write-Host ""

kubectl get httproute -n devops-case


# ------------------------------------------------------------
# 12. Endpoint verification
# ------------------------------------------------------------

Write-Host "`n[Verification] Testing Kubernetes endpoints..." -ForegroundColor Yellow


curl.exe `
    --silent `
    --show-error `
    --fail `
    http://localhost/ |
    Out-Null

if ($LASTEXITCODE -ne 0) {
    throw "Frontend endpoint verification failed."
}


curl.exe `
    --silent `
    --show-error `
    --fail `
    http://localhost/api/healthcheck/ |
    Out-Null

if ($LASTEXITCODE -ne 0) {
    throw "Backend healthcheck verification failed."
}


Write-Host "Frontend endpoint: OK" -ForegroundColor Green
Write-Host "Backend healthcheck: OK" -ForegroundColor Green


# ------------------------------------------------------------
# 13. Complete
# ------------------------------------------------------------

Write-Host "`n=== Setup Complete ===" -ForegroundColor Green
Write-Host "Frontend: http://localhost/" -ForegroundColor Cyan
Write-Host "API:      http://localhost/api/healthcheck/" -ForegroundColor Cyan
Write-Host "Compose:  http://localhost:3000/" -ForegroundColor Cyan