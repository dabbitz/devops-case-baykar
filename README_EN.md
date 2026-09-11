# 2NTECH DevOps Technical Case

This repository contains the MERN application, Python ETL workload, Docker containers, Kubernetes deployments, AWS EKS environment, Amazon ECR repositories, CI/CD pipeline, and backup/restore work developed as part of the 2NTECH DevOps Technical Case.

## Project Structure

```text
DevOps_Case_Final/
├── .github/
│   └── workflows/
│       └── ci.yml                   # GitHub Actions CI/CD pipeline
│
├── docs/
│   ├── screenshots/                 # Evidence screenshots
│   ├── architecture.md              # System architecture and request flow
│   ├── backup-restore.md            # Backup/restore runbook
│   └── findings.md                  # Issues identified in the initial application
│
├── k8s/
│   └── eks/
│   │   ├── backend-deployment.yaml  # EKS backend Deployment
│   │   ├── backend-service.yaml     # EKS backend ClusterIP Service
│   │   ├── cd-rbac.yaml             # GitHub Actions Kubernetes RBAC
│   │   ├── etl-cronjob.yaml         # EKS hourly Python ETL CronJob
│   │   ├── frontend-deployment.yaml # EKS frontend Deployment
│   │   ├── frontend-service.yaml    # EKS frontend ClusterIP Service
│   │   ├── gateway.yaml             # EKS Envoy Gateway
│   │   ├── gatewayclass.yaml        # EKS Envoy GatewayClass
│   │   └── http-route.yaml          # EKS HTTPRoute
│   ├── backend-deployment.yaml      # Local Kubernetes backend Deployment
│   ├── backend-service.yaml         # Local Kubernetes backend ClusterIP Service
│   ├── ci-mongodb.yaml              # Temporary MongoDB for CI/CD
│   ├── etl-cronjob.yaml             # Local Kubernetes hourly Python ETL CronJob
│   ├── frontend-deployment.yaml     # Local Kubernetes frontend Deployment
│   ├── frontend-service.yaml        # Local Kubernetes frontend ClusterIP Service
│   ├── gateway.yaml                 # Envoy Gateway
│   ├── gatewayclass.yaml            # Envoy GatewayClass
│   ├── http-route.yaml              # HTTPRoute
│   └── namespace.yaml               # Local Kubernetes namespace
│
├── mern-project/
│   ├── client/                      # React frontend
│   ├── server/                      # Express.js backend
│   └── .gitignore                   # .gitignore file for the mern-project folder
│
├── python-project/
│   ├── .dockerignore                # .dockerignore file for the python-project folder
│   ├── Dockerfile                   # ETL container image
│   ├── ETL.py                       # Current ETL implementation
│   ├── README.md                    # ETL introductory documentation
│   └── requirements.txt             # Python dependencies
│
├── scripts/
│   └── check-alerts.ps1             # Critical alert checks
│
├── .gitignore                       # .gitignore file of the project
├── CASE_END_ANSWERS.md              # English case answers
├── CASE_SONU_CEVAPLARI.md           # Turkish case answers
├── DevOps_Technical_Case_EN.docx    # English case document
├── DevOps_Teknik_Case_TR.docx       # Turkish case document
├── docker-compose.yml               # Local Docker Compose environment
├── eks-cluster.yaml                 # AWS EKS cluster and node group configuration
├── README_EN.md                     # English project and execution documentation
├── README.md                        # Turkish project and execution documentation
├── setup-k8s.ps1                    # Local Kubernetes setup/verification script
├── SUBMISSION_EVIDENCE.md           # English submission evidence
└── TESLIM_KANITLARI.md              # Turkish submission evidence
```

## Current AWS EKS Deployment

The **current AWS EKS deployment used during this work** is directly accessible through the following addresses:

**Application:**

```text
http://[REDACTED].eu-central-1.elb.amazonaws.com/
```

**Records:**

```text
http://[REDACTED].eu-central-1.elb.amazonaws.com/records
```

**Backend healthcheck:**

```text
http://[REDACTED].eu-central-1.elb.amazonaws.com/api/healthcheck
```

> **Important:** The addresses above belong to the AWS Load Balancer created for the current deployment during this work. They **must not be considered permanent production URLs**. In particular, if the EKS cluster, Envoy Gateway, or Load Balancer is recreated, AWS may assign a new hostname. In addition, the addresses may no longer be accessible after submission if the AWS resources used for this deployment are removed.

### Finding the Current EKS Access Address

The current hostname assigned by the AWS Load Balancer can be obtained from the Kubernetes Service output in the terminal.

First, list the Envoy Gateway Services:

```powershell
kubectl get svc -n envoy-gateway-system
```

In the output, find the Envoy Gateway Service whose `TYPE` is `LoadBalancer`. The `EXTERNAL-IP` field in that row contains the current Load Balancer hostname assigned by AWS.

For example:

```text
NAME                                      TYPE           CLUSTER-IP      EXTERNAL-IP
envoy-devops-case-devops-gateway-...     LoadBalancer   10.x.x.x        <AWS Load Balancer hostname>
```

To view the current hostname in more detail:

```powershell
kubectl get svc -n envoy-gateway-system -o wide
```

The `<AWS Load Balancer hostname>` value can then be used to construct the application addresses as follows:

```text
http://<EXTERNAL-IP>/
http://<EXTERNAL-IP>/records
http://<EXTERNAL-IP>/api/healthcheck
```

Therefore, if the hostname listed in this README is no longer valid, check the current `EXTERNAL-IP` value from the Kubernetes Service before attempting to access the application.

## System Architecture

The main request flow of the application on AWS EKS is as follows:

```text
User / Browser
        ↓
AWS Elastic Load Balancer
        ↓
Envoy Gateway
        ↓
HTTPRoute
   ┌────┴────┐
   ↓         ↓
Frontend   Backend
Service    Service
   ↓         ↓
React      Node.js
+ NGINX    + Express
              ↓
          MongoDB Atlas
```

The Python ETL runs as a separate workflow, retrieving repository information from the GitHub API and updating the `github_repositories` collection in MongoDB:

```text
GitHub API
    ↓
Python ETL
    ↓
MongoDB Atlas
```

In the local Kubernetes environment, the application can be accessed through the local Envoy Gateway instead of the AWS Elastic Load Balancer.

Detailed architecture diagram and component descriptions:

`docs/architecture.md`

## Technologies

* React
* Node.js / Express
* MongoDB Atlas
* Python
* Docker / Docker Compose
* Kubernetes
* AWS EKS
* Amazon ECR
* AWS IAM
* GitHub Actions
* GitHub OIDC
* Kubernetes RBAC
* Envoy Gateway
* Helm
* Kind

## Requirements

To use the existing deployment running on AWS, the following are required:

* An AWS account with the necessary permissions
* Access to the GitHub repository

For local execution or development, the following can additionally be used:

* Docker Desktop
* Docker Compose
* Node.js 20+
* Python 3.10+
* `kubectl`
* Helm

For AWS EKS management and infrastructure operations:

* AWS CLI
* `eksctl`

## Configuration

Secrets and connection information are not hardcoded in the source code.

For cloud deployment, sensitive values are transferred from GitHub Actions Secrets to Kubernetes Secret resources. For local execution, a `.env` file is used.

### 1. MongoDB Atlas Setup

In the normal Kubernetes deployment, MongoDB is not run inside the Kubernetes cluster; MongoDB Atlas is used instead.

In your own MongoDB Atlas account:

1. Create a MongoDB deployment.
2. Use a database named `sample_training`.
3. Allow the `records` collection used by the backend to be created.
4. Create the `github_repositories` collection used by the ETL, or allow it to be created during the first ETL execution.
5. Make sure the IP address you will use is allowed in MongoDB Atlas Network Access.
6. Create an appropriate database user and grant the required permissions.
7. Obtain the connection URI.

> Because the application uses MongoDB Atlas in the production environment, the database and collection names must remain consistent with the environment variables and the values used by the project code.

### 2. GitHub API Setup

The Python ETL retrieves repository information through the GitHub API.

If you want to use your own GitHub repository, update the following values accordingly:

```text
GITHUB_OWNER=<GitHub user or organization name>
GITHUB_REPO=<repository name>
GITHUB_TOKEN=<GitHub Personal Access Token>
```

The token should contain only the GitHub API permissions that are actually required.

### 3. Creating the `.env` File

For local execution, create a file named `.env` in the project root.

Example:

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

Do not write real credentials, tokens, or connection strings into the source code or commit them to the Git repository.

### 4. Pay Attention to Naming Consistency

During setup, the following names must remain consistent with the code and configuration:

| Field                | Usage                      |
| -------------------- | -------------------------- |
| `MONGODB_DB`         | `sample_training`          |
| `MONGODB_COLLECTION` | `github_repositories`      |
| `GITHUB_OWNER`       | GitHub repository owner    |
| `GITHUB_REPO`        | GitHub repository name     |
| `ATLAS_URI`          | Backend MongoDB connection |
| `MONGODB_URI`        | ETL MongoDB connection     |

`GITHUB_OWNER` and `GITHUB_REPO` can be changed. However, when using a different repository, a GitHub token with access to that repository must be provided to the ETL.

### 5. Kubernetes Secrets

For local Kubernetes deployment, the `setup-k8s.ps1` script reads sensitive values from `.env` and creates the required Kubernetes Secret resources.

For AWS EKS deployment, Secret values are obtained from GitHub Actions Secrets and transferred to Kubernetes Secret resources in the EKS namespace.

Secret values are not hardcoded into the workflow file or source code.

---

## Initial Setup

The primary deployment environment of the project is AWS EKS. The repository defines the AWS EKS cluster, ECR image repositories, and GitHub Actions-based CI/CD deployment structure.

The basic flow for the existing cloud deployment is:

```text
Repository
        ↓
MongoDB Atlas setup
        ↓
GitHub Actions Secrets
        ↓
Push to main branch
        ↓
CI validation
        ↓
GitHub OIDC
        ↓
AWS IAM Role
        ↓
Amazon ECR
        ↓
AWS EKS
        ↓
Frontend / Backend / ETL
```

AWS EKS cluster configuration:

```text
Cluster:
devops-case-eks

Region:
eu-central-1

Managed node group:
devops-workers

Node instance type:
t3.small
```

The manifests used for the EKS deployment are located under:

```text
k8s/eks/
```

To inspect the AWS EKS environment:

```powershell
eksctl get cluster --region eu-central-1
kubectl get nodes -o wide
kubectl get pods -n devops-case
kubectl get deployments -n devops-case
kubectl get cronjobs -n devops-case
kubectl get services -n devops-case
```

External cloud access is provided through the AWS Elastic Load Balancer created by Envoy Gateway.

The local execution methods below can still be used when local development or testing is required.

---

## Alternative: Docker Compose

To validate the local container environment without Kubernetes:

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

Stop the Compose environment with:

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

The frontend runs by default at:

```text
http://localhost:3000
```

### Backend

```powershell
cd mern-project/server
npm install
npm start
```

The backend runs at:

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

Check container status:

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

Local Kubernetes manifests are located in the `k8s/` directory.

To perform the setup automatically:

```powershell
.\setup-k8s.ps1
```

The script performs the following operations:

1. Create the namespace
2. Create Kubernetes Secrets
3. Build Docker images
4. Transfer images to the Kubernetes environment
5. Deploy the frontend, backend, and ETL workloads
6. Verify container security settings
7. Install Envoy Gateway
8. Create the Gateway and HTTPRoute
9. Verify endpoints

Namespace:

```text
devops-case
```

Workload checks:

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

## AWS EKS Deployment

AWS EKS-specific Kubernetes manifests are located under:

```text
k8s/eks/
```

The EKS deployment consists of:

```text
Frontend → Deployment + ClusterIP Service
Backend  → Deployment + ClusterIP Service
ETL      → CronJob
Gateway  → Envoy Gateway
Routing  → HTTPRoute
```

Container images are pulled from Amazon ECR.

To inspect workloads running on EKS:

```powershell
kubectl get pods -n devops-case -o wide
kubectl get deployments -n devops-case
kubectl get services -n devops-case
kubectl get cronjobs -n devops-case
kubectl get gateway -n devops-case
kubectl get httproute -n devops-case
```

For external EKS access, requests to `/` are routed to the frontend and requests to `/api` are routed to the backend.

Backend healthcheck:

```text
/api/healthcheck
```

This endpoint is accessible through the AWS Load Balancer.

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

The ETL runs hourly using the `Europe/Istanbul` timezone.

When the same repository is processed again, the existing record is updated using the `github_id` field.

## Kubernetes Security

Containers are not run as the root user.

```text
Backend  → node / UID 1000
Frontend → nginx / UID 101
ETL      → appuser / UID 10001
```

The Kubernetes workloads also apply the following security settings:

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
MongoDB Atlas
```

The ETL runs hourly on Kubernetes.

When the same repository is processed again:

```text
github_id = 1361100555
```

is used to update the existing document without creating a duplicate record.

ETL logs contain entries such as:

```text
UPDATE: repository updated
Updated fields: ...
MongoDB document count: 1
ETL completed successfully.
```

## CI/CD

CI/CD runs on GitHub Actions.

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
GitHub OIDC
        ↓
AWS IAM Role
        ↓
Amazon ECR image push
        ↓
AWS EKS authentication
        ↓
Kubernetes deployment
        ↓
Rollout verification
        ↓
Backend healthcheck
        ↓
Frontend HTTP check
```

When a Pull Request is opened, the `validate-and-build` job runs and deployment is not performed.

After a successful push to the `main` branch, the `deploy-eks` job runs.

The deployment job:

1. Assumes the AWS IAM Role through GitHub OIDC.
2. Builds the frontend, backend, and ETL Docker images.
3. Tags the images with the Git commit SHA.
4. Pushes the images to Amazon ECR.
5. Creates the kubeconfig for the EKS cluster.
6. Updates the Kubernetes Secret resources.
7. Applies the Service, Deployment, and CronJob resources under `k8s/eks/`.
8. Updates the Deployment images to the commit SHA tags.
9. Applies the Gateway and HTTPRoute resources.
10. Checks the backend and frontend rollout status.
11. Performs the backend healthcheck through the AWS Load Balancer.
12. Verifies external frontend access.

If a build or validation step in the CI stage fails, the `deploy-eks` job is not executed.

## GitHub OIDC and AWS Authentication

Long-lived AWS access keys are not used for GitHub Actions AWS access.

Authentication flow:

```text
GitHub Actions
      ↓
GitHub OIDC token
      ↓
GitHubActions-EKS-Deploy IAM Role
      ↓
Temporary AWS credentials
      ↓
Amazon ECR + AWS EKS
```

The IAM Role uses an OIDC trust policy restricted to the GitHub repository and the `main` branch.

## EKS RBAC

The GitHub Actions IAM Role is mapped through an EKS Access Entry to the following Kubernetes group:

```text
github-actions-deploy
```

A Kubernetes `Role` and `RoleBinding` limited to the:

```text
devops-case
```

namespace are defined for this group.

GitHub Actions is not granted `cluster-admin` privileges.

RBAC definition:

```text
k8s/eks/cd-rbac.yaml
```

## Amazon ECR

The CI/CD pipeline uses three separate Amazon ECR repositories:

```text
devops-case-backend
devops-case-frontend
devops-case-etl
```

Images are tagged using the Git commit SHA.

Example:

```text
devops-case-etl:<commit-sha>
```

This allows the deployed image version to be directly associated with the corresponding source commit.

## Backup and Restore

MongoDB backups are created using `mongodump`, and restores are performed using `mongorestore`.

Backup location (won't be seen in the repository as it is included in .gitignore):

```text
backups/sample-training-backup/
```

The backup and restore process has been tested end-to-end using real data.

Detailed commands, retention, RPO/RTO, and production limitations:

`docs/backup-restore.md`

Evidence:

`SUBMISSION_EVIDENCE.md`

## Logging and Alerts

Operational logs are used on the backend and Python ETL sides.

ETL logs show repository information, MongoDB connection status, update operations, document count, and successful completion.

In addition:

```text
scripts/check-alerts.ps1
```

checks two critical alert scenarios:

- ETL failure or the absence of a successful ETL execution within the expected time window
- Inaccessibility of the frontend or backend health endpoints

The alert scenarios can be validated using test mode.

## Findings and Improvements

Production-readiness issues identified in the initial application are documented in:

`docs/findings.md`

Main improvements include:

- Frontend API address managed through environment/configuration
- Backend input validation
- ObjectId validation
- Database connection error handling
- CORS restriction
- HTTP error handling
- Non-root container usage
- Kubernetes securityContext
- ETL duplicate prevention
- CI/CD validation and deployment controls
- AWS EKS deployment
- Amazon ECR image management
- GitHub OIDC authentication
- Namespace-scoped Kubernetes RBAC

## Rollback

In case of a deployment problem, inspect the existing Kubernetes Deployment history:

```powershell
kubectl rollout history deployment/backend -n devops-case
kubectl rollout history deployment/frontend -n devops-case
```

To return to the previous working version:

```powershell
kubectl rollout undo deployment/backend -n devops-case
kubectl rollout undo deployment/frontend -n devops-case
```

After the rollback, rollout and healthcheck verification should be performed again.

Because deployed images are tagged with the commit SHA, the corresponding previous image version can also be identified in Amazon ECR.

## Cleanup

To remove local Kubernetes workloads:

```powershell
kubectl delete namespace devops-case
```

To stop the Docker Compose environment:

```powershell
docker compose down
```

Unused locally built Docker images can also be removed through Docker.

Removing application workloads from EKS does not automatically delete the EKS cluster or the underlying AWS infrastructure. Cluster and infrastructure cleanup must be managed separately.

## Documentation and Evidence

Architecture:

`docs/architecture.md`

Initial findings:

`docs/findings.md`

Backup/restore runbook:

`docs/backup-restore.md`

Case answers:

`CASE_END_ANSWERS.md`

Evidence:

`SUBMISSION_EVIDENCE.md`

Screenshots:

`docs/screenshots/`

Main case document:

`DevOps_Technical_Case_EN.docx`
