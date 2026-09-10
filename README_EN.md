# 2NTECH DevOps Technical Case

This repository contains the MERN application, Python ETL workload, Docker containers, Kubernetes deployment, CI/CD pipeline, and backup/restore work completed as part of the 2NTECH DevOps Technical Case.

## Project Structure

```text
DevOps_Case_Final/
├── .github/
│   └── workflows/
│       └── ci.yml                    # GitHub Actions CI/CD pipeline
│
├── backups/                          # Local backup outputs
│
├── docs/
│   ├── screenshots/                  # Work evidence
│   ├── architecture.md               # System architecture and request flow
│   ├── backup-restore.md             # Backup/restore runbook
│   └── findings.md                   # Errors found when the app was first opened
│
├── k8s/
│   ├── namespace.yaml                # Kubernetes namespace
│   ├── backend-deployment.yaml       # Backend Deployment
│   ├── backend-service.yaml          # Backend ClusterIP Service
│   ├── frontend-deployment.yaml      # Frontend Deployment
│   ├── frontend-service.yaml         # Frontend ClusterIP Service
│   ├── etl-cronjob.yaml              # Hourly Python ETL CronJob
│   ├── ci-mongodb.yaml               # Temporary MongoDB for CI/CD
│   ├── gatewayclass.yaml             # Envoy GatewayClass
│   ├── gateway.yaml                  # Envoy Gateway
│   └── http-route.yaml               # HTTPRoute
│
├── mern-project/
│   ├── client/                       # React frontend
│   └── server/                       # Express.js backend
│
├── python-project/
│   ├── Dockerfile                    # ETL container image
│   ├── ETL.py                        # Current ETL implementation
│   ├── requirements.txt              # Python dependencies
│   └── README.md                     # Initial ETL documentation
│
├── scripts/
│   └── check-alerts.ps1              # Critical alert checks
│
├── .env                              # Local environment/config
├── .gitignore
├── docker-compose.yml                # Local Docker Compose environment
├── setup-k8s.ps1                     # Kubernetes setup/verification script
├── CASE_SONU_CEVAPLARI.md            # Case completion answers
├── CASE_END_ANSWERS.md               # English case answers
├── TESLIM_KANITLARI.md               # Work evidence
├── SUBMISSION_EVIDENCE.md            # English submission evidence
├── DevOps_Teknik_Case_TR.docx        # Turkish case document
├── DevOps_Technical_Case_EN.docx     # English case document
├── README.md                         # Project and usage documentation
└── README_EN.md                      # English README
```

## System Architecture

The application consists of the following main components:

```text
User / Browser
        ↓
Envoy Gateway
        ↓
HTTPRoute
        ↓
Frontend Service
        ↓
React + NGINX
        ↓
Backend Service
        ↓
Node.js + Express
        ↓
MongoDB Atlas
```

The Python ETL retrieves repository information from the GitHub API and updates the `github_repositories` collection in MongoDB.

Detailed architecture diagram and component descriptions:

`docs/architecture.md`

## Technologies

* React
* Node.js / Express
* MongoDB Atlas
* Python
* Docker / Docker Compose
* Kubernetes
* Envoy Gateway
* Helm
* GitHub Actions
* Kind

## Requirements

The following tools must be installed for local execution:

* Docker Desktop
* Docker Compose
* Node.js 20+
* Python 3.10+
* `kubectl`
* Helm

For Kubernetes execution, Docker Desktop Kubernetes or another suitable Kubernetes cluster can be used.

## Configuration

Secrets or connection information are not hardcoded in the source code.

After cloning the repository, several values specific to the execution environment must be prepared by the user. These values are particularly required for MongoDB Atlas and GitHub API access.

### 1. MongoDB Atlas Setup

In the normal Kubernetes deployment, MongoDB is not run inside the Kubernetes cluster; MongoDB Atlas is used instead.

In your own MongoDB Atlas account:

1. Create a MongoDB deployment.
2. Use a database named `sample_training`.
3. Allow the `records` collection used by the backend to be created.
4. Create the `github_repositories` collection used by the ETL, or allow it to be created during the first ETL execution.
5. Make sure the IP address you will use is allowed in the MongoDB Atlas Network Access section.
6. Create an appropriate database user and grant the required permissions.
7. Obtain the connection URI.

> Because MongoDB Atlas is used in the production-style application deployment, the database and collection names must match the usage in the project code and the environment variables below.

### 2. GitHub API Setup

The Python ETL retrieves repository information through the GitHub API.

If you are using your own GitHub repository, change the following values accordingly:

```text
GITHUB_OWNER=<GitHub user or organization name>
GITHUB_REPO=<repository name>
GITHUB_TOKEN=<GitHub Personal Access Token>
```

The token should contain only the GitHub API permissions that are required.

### 3. Creating the `.env` File

Create a `.env` file in the project root.

Example structure:

```text
ATLAS_URI=<MongoDB Atlas connection string>

GITHUB_OWNER=<GitHub owner>
GITHUB_REPO=<GitHub repository>
GITHUB_TOKEN=<GitHub token>

MONGODB_DB=sample_training
MONGODB_URI=<MongoDB connection string>
MONGODB_COLLECTION=github_repositories
```

`ATLAS_URI` is used by the backend, while `MONGODB_URI`, `MONGODB_DB`, and `MONGODB_COLLECTION` are used by the Python ETL.

Do not write real credentials, tokens, or connection string values into the source code, and do not commit them to the Git repository.

### 4. Pay Attention to Name Consistency

During setup, the following names must be consistent with the code and configuration:

| Field                | Usage                      |
| -------------------- | -------------------------- |
| `MONGODB_DB`         | `sample_training`          |
| `MONGODB_COLLECTION` | `github_repositories`      |
| `GITHUB_OWNER`       | GitHub repository owner    |
| `GITHUB_REPO`        | GitHub repository name     |
| `ATLAS_URI`          | Backend MongoDB connection |
| `MONGODB_URI`        | ETL MongoDB connection     |

`GITHUB_OWNER` and `GITHUB_REPO` can be changed. However, when using a different repository, a GitHub token with access to that repository must be provided.

### 5. Kubernetes Secrets

The `setup-k8s.ps1` script reads the sensitive values from `.env` and creates the required Kubernetes Secret resources.

Therefore, the `.env` file must be prepared before Kubernetes deployment.

The script is designed to use secret values without printing them to the screen.

---

## Initial Setup

The recommended order after cloning the repository is:

```text
Clone the repository
        ↓
Install required tools
        ↓
Prepare MongoDB Atlas
        ↓
Create GitHub API token
        ↓
Create the .env file
        ↓
Enable Docker Desktop Kubernetes
        ↓
Run setup-k8s.ps1
        ↓
Verify Kubernetes workloads
        ↓
Test frontend / backend endpoints
        ↓
Check ETL Job / CronJob logs
```

For Kubernetes setup:

```powershell
.\setup-k8s.ps1
```

After setup is complete:

```powershell
kubectl get pods -n devops-case
kubectl get services -n devops-case
kubectl get cronjobs -n devops-case
```

can be used to verify the workload status.

Frontend:

```text
http://localhost/
```

Backend healthcheck:

```text
http://localhost/api/healthcheck/
```

### Alternative: Docker Compose

To validate the local container environment before using Kubernetes:

```powershell
docker compose build
docker compose up -d
```

Then verify:

```text
Frontend:
http://localhost:3000

Backend:
http://localhost:5050/healthcheck/
```

The Compose environment can be stopped with:

```powershell
docker compose down
```

## Running the MERN Application

### Frontend

```powershell
cd mern-project/client
npm install
npm start
```

The frontend is available by default at:

```text
http://localhost:3000
```

### Backend

```powershell
cd mern-project/server
npm install
npm start
```

The backend is available at:

```text
http://localhost:5050
```

Healthcheck:

```text
GET /healthcheck/
```

## Docker Compose

To run all application components as containers from the project root:

```powershell
docker compose build
docker compose up -d
```

To check container status:

```powershell
docker compose ps
```

Frontend:

```text
http://localhost:3000
```

Backend healthcheck:

```text
http://localhost:5050/healthcheck/
```

The ETL container runs as a one-shot workload and is expected to enter the `Exited (0)` state after completion.

Cleanup:

```powershell
docker compose down
```

## Kubernetes Deployment

The Kubernetes manifests are located in the `k8s/` directory.

For automated setup:

```powershell
.\setup-k8s.ps1
```

The script performs the following operations:

1. Create namespace
2. Create Kubernetes Secrets
3. Build Docker images
4. Import images into the Kubernetes environment
5. Deploy frontend, backend, and ETL workloads
6. Verify container security controls
7. Install Envoy Gateway
8. Create Gateway and HTTPRoute
9. Verify endpoints

Namespace:

```text
devops-case
```

Workload verification:

```powershell
kubectl get pods -n devops-case
kubectl get deployments -n devops-case
kubectl get cronjobs -n devops-case
kubectl get services -n devops-case
```

Frontend endpoint:

```text
http://localhost/
```

Backend healthcheck:

```text
http://localhost/api/healthcheck/
```

## Kubernetes Workloads

Frontend:

```text
Deployment + ClusterIP Service
```

Backend:

```text
Deployment + ClusterIP Service
```

Python ETL:

```text
CronJob
```

ETL schedule:

```text
0 * * * *
```

When the same repository is processed again, the ETL updates the existing record using the `github_id` field.

## Kubernetes Security

Containers are not run as the root user.

```text
Backend  → node / UID 1000
Frontend → nginx / UID 101
ETL      → appuser / UID 10001
```

The following controls are also applied to the Kubernetes workloads:

```yaml
runAsNonRoot: true
allowPrivilegeEscalation: false
capabilities:
  drop:
    - ALL
```

Secret values are not embedded in the repository source code or Docker images.

## Python ETL

The ETL retrieves repository information from the GitHub API and transfers it to MongoDB.

Basic flow:

```text
GitHub API
    ↓
Python ETL
    ↓
MongoDB
```

The ETL runs hourly on Kubernetes.

When the same repository is processed again:

```text
github_id = 1361100555
```

is used to update the existing document and prevent duplicate records.

The ETL logs include output such as:

```text
UPDATE: repository updated
MongoDB document count: 1
ETL completed successfully.
```

## CI/CD

CI/CD runs through GitHub Actions.

Pipeline:

```text
Git Push / Pull Request
        ↓
Frontend build
        ↓
Backend validation
        ↓
Python validation
        ↓
Docker image build
        ↓
CI successful
        ↓
Kind Kubernetes cluster
        ↓
Image load
        ↓
Kubernetes deployment
        ↓
Rollout verification
        ↓
Backend healthcheck
        ↓
Frontend HTTP check
```

The deployment job runs only after the CI job completes successfully.

For CI deployment validation, GitHub Actions creates a temporary Kind cluster. A temporary MongoDB container is also run in this environment for testing purposes.

This MongoDB is used only for CI/CD validation. MongoDB Atlas is the data layer used in the normal application deployment.

## Backup and Restore

MongoDB backups are created using `mongodump`, and restores are performed using `mongorestore`.

Backup location:

```text
backups/sample-training-backup/
```

The backup and restore process has been tested end-to-end using real application data.

Detailed commands, retention, RPO/RTO, and production limitations:

`docs/backup-restore.md`

Work evidence:

`TESLIM_KANITLARI.md`

## Logging and Alerts

Operational logs are used on the backend and Python ETL sides.

In addition:

```text
scripts/check-alerts.ps1
```

provides checks for two critical alert scenarios:

* ETL failure or no successful ETL execution within the expected time window

* Frontend or backend health endpoint unavailability

The alert scenarios can be verified using test mode.

## Findings and Improvements

The production-readiness issues identified in the initial application are documented in:

`docs/findings.md`

Main improvements include:

* Managing the frontend API address through environment/configuration
* Backend input validation
* ObjectId validation
* Database connection error handling
* CORS restriction
* HTTP error handling
* Non-root container usage
* Kubernetes securityContext
* ETL duplicate prevention
* CI/CD validation and deployment checks

## Rollback

In case of a deployment problem, the existing Kubernetes Deployment history can be inspected:

```powershell
kubectl rollout history deployment/backend -n devops-case
kubectl rollout history deployment/frontend -n devops-case
```

To return to the previous working version:

```powershell
kubectl rollout undo deployment/backend -n devops-case
kubectl rollout undo deployment/frontend -n devops-case
```

After rollback, rollout and healthcheck validations should be performed again.

## Cleanup

To remove the Kubernetes workloads:

```powershell
kubectl delete namespace devops-case
```

To stop the Docker Compose environment:

```powershell
docker compose down
```

Unused Docker images created locally can also be removed using Docker.

## Documentation and Evidence

Architecture:

`docs/architecture.md`

Initial findings:

`docs/findings.md`

Backup/restore runbook:

`docs/backup-restore.md`

Case completion answers:

`CASE_SONU_CEVAPLARI.md`

Work evidence:

`TESLIM_KANITLARI.md`

Screenshots:

`docs/screenshots/`

Main case document:

`DevOps_Teknik_Case_TR.docx`
