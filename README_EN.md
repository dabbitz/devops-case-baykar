# Baykar DevOps Technical Case

This repository contains the MERN application and Python ETL workload developed as part of the DevOps Technical Case, along with their containerization, Kubernetes deployment, AWS EKS, Amazon ECR, CI/CD, backup/restore, and environment management processes and documentation.

## Project Structure

```text
DevOps_Case_Final/
├── .github/
│   └── workflows/
│       └── ci.yml                         # GitHub Actions CI/CD pipeline
│
├── docs/
│   ├── screenshots/                       # Evidence screenshots
│   ├── architecture.md                    # System architecture and request flow
│   ├── backup-restore.md                  # Backup/restore runbook
│   └── findings.md                        # Issues identified in the initial application
│
├── k8s/
│   ├── eks/                               # Shared EKS Kubernetes resources
│   │   ├── backend-deployment.yaml        # EKS backend Deployment
│   │   ├── backend-service.yaml           # EKS backend ClusterIP Service
│   │   ├── backup-cronjob.yaml            # Daily MongoDB → S3 backup CronJob
│   │   ├── backup-serviceaccount.yaml     # Backup workload ServiceAccount
│   │   ├── cd-rbac.yaml                   # GitHub Actions Kubernetes RBAC
│   │   ├── etl-cronjob.yaml               # EKS hourly Python ETL CronJob
│   │   ├── frontend-deployment.yaml       # EKS frontend Deployment
│   │   ├── frontend-service.yaml          # EKS frontend ClusterIP Service
│   │   ├── gateway.yaml                   # EKS Envoy Gateway
│   │   ├── gatewayclass.yaml              # EKS Envoy Gateway Class
│   │   ├── http-route.yaml                # EKS HTTPRoute
│   │   └── kustomization.yaml             # EKS Kustomize base
│   │
│   ├── overlays/
│   │   ├── dev/
│   │   │   └── kustomization.yaml         # Development overlay
│   │   ├── prod/
│   │   │   └── kustomization.yaml         # Production overlay
│   │   └── test/
│   │       └── kustomization.yaml         # Test overlay
│   │
│   ├── backend-deployment.yaml            # Local Kubernetes backend Deployment
│   ├── backend-service.yaml               # Local Kubernetes backend ClusterIP Service
│   ├── ci-mongodb.yaml                    # Temporary MongoDB for CI/CD
│   ├── etl-cronjob.yaml                   # Local Kubernetes hourly Python ETL CronJob
│   ├── frontend-deployment.yaml           # Local Kubernetes frontend Deployment
│   ├── frontend-service.yaml              # Local Kubernetes frontend ClusterIP Service
│   ├── gateway.yaml                       # Local Envoy Gateway
│   ├── gatewayclass.yaml                  # Local Envoy GatewayClass
│   ├── http-route.yaml                    # Local HTTPRoute
│   └── namespace.yaml                     # Local Kubernetes namespace
│
├── mern-project/
│   ├── client/                            # React frontend
│   ├── server/                            # Express.js backend
│   └── .gitignore                         # .gitignore file for the mern-project folder
│
├── python-project/
│   ├── .dockerignore                      # .dockerignore file for the python-project folder
│   ├── Dockerfile                         # ETL container image
│   ├── ETL.py                             # Current ETL implementation
│   ├── README.md                          # ETL introductory documentation
│   └── requirements.txt                   # Python dependencies
│
├── scripts/
│   ├── backup-restore.ps1                 # MongoDB backup/restore script
│   └── check-alerts.ps1                   # Critical alert checks
│
├── .gitignore                             # Project .gitignore file
├── CASE_END_ANSWERS.md                    # English case answers
├── CASE_SONU_CEVAPLARI.md                 # Turkish case answers
├── DevOps_Technical_Case_EN.docx          # English case document
├── DevOps_Teknik_Case_TR.docx             # Turkish case document
├── docker-compose.yml                     # Local Docker Compose environment
├── eks-cluster.yaml                       # AWS EKS cluster and node group configuration
├── README_EN.md                           # English project and execution documentation
├── README.md                              # Turkish project and execution documentation
├── setup-k8s.ps1                          # Local Kubernetes setup/verification script
├── SUBMISSION_EVIDENCE.md                 # English submission evidence
└── TESLIM_KANITLARI.md                    # Turkish submission evidence
```

## AWS EKS Deployment

The primary deployment environment of the project is AWS EKS. The frontend, backend, and Python ETL workloads run on Kubernetes, with external access provided through an AWS Elastic Load Balancer via Envoy Gateway.

The repository also includes Docker Compose and local Kubernetes configurations so that the application can be run locally for development, testing, and reproducibility purposes. These local configurations are alternatives to the primary AWS EKS deployment and do not replace the cloud environment.

### Current AWS EKS Deployment

The application was accessed through the AWS EKS deployment used during the project. The AWS Load Balancer hostnames shown below are displayed as `[REDACTED]` in the public repository to avoid unnecessarily exposing cloud environment details.

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

**Create:**

```text
http://[REDACTED].eu-central-1.elb.amazonaws.com/create
```

**Edit:**

```text
http://[REDACTED].eu-central-1.elb.amazonaws.com/edit/<document-id>
```

> **Important:** The addresses used belong to the AWS Load Balancer created during this project. They should **not be considered permanent production URLs**. In particular, if the EKS cluster, Envoy Gateway, or Load Balancer is recreated, AWS may assign a new hostname. The addresses may also become inaccessible if the AWS resources used for the project are removed after submission.

> **Actual EKS access address:** In the public repository, the Load Balancer hostname is shown as `[REDACTED]`. The actual access address used during the project is provided in a `.txt` file located in the project root of the submitted `.zip` file.

### Finding the Current EKS Access Address

The current hostname assigned by the AWS Load Balancer can be obtained from the Kubernetes Service output in the terminal.

First, list the Envoy Gateway Services:

```powershell
kubectl get svc -n envoy-gateway-system
```

In the output, find the Envoy Gateway Service whose `TYPE` is `LoadBalancer`. The `EXTERNAL-IP` field in that row contains the current Load Balancer hostname assigned by AWS.

For example:

```text
NAME                                  TYPE          CLUSTER-IP    EXTERNAL-IP
envoy-devops-case-devops-gateway-... LoadBalancer  10.x.x.x     <AWS Load Balancer hostname>
```

To view the current hostname in more detail:

```powershell
kubectl get svc -n envoy-gateway-system -o wide
```

The `<AWS Load Balancer hostname>` value can then be used to construct the application addresses:

```text
http://<EXTERNAL-IP>/
http://<EXTERNAL-IP>/api/healthcheck
http://<EXTERNAL-IP>/records
http://<EXTERNAL-IP>/create
http://<EXTERNAL-IP>/edit/<document-id>
```

Therefore, if the hostname listed in this README is no longer valid, check the current `EXTERNAL-IP` value from the Kubernetes Service before attempting to access the application.

### EKS Cluster Configuration

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

To inspect the AWS EKS environment:

```powershell
eksctl get cluster --region eu-central-1
kubectl get nodes -o wide
kubectl get pods -n devops-case
kubectl get deployments -n devops-case
kubectl get cronjobs -n devops-case
kubectl get services -n devops-case
```

The active EKS node runs Kubernetes `v1.36.3-eks-cb19647` on Amazon Linux 2023.

### EKS Workloads

```text
Frontend → Deployment + ClusterIP Service + liveness/readiness probes
Backend  → Deployment + ClusterIP Service + liveness/readiness probes + controlled RollingUpdate
ETL      → CronJob
Backup   → Daily CronJob → mongodump → Amazon S3
Gateway  → Envoy Gateway
Routing  → HTTPRoute
```

CPU and memory resource requests/limits are defined for the backend, frontend, and ETL workloads.

Shared Kubernetes resources for the EKS deployment are located under `k8s/eks/`, while environment-specific configurations are managed through Kustomize overlays. See **Kustomize Environment Management** for details.

To inspect workloads running on EKS:

```powershell
kubectl get pods -n devops-case -o wide
kubectl get deployments -n devops-case
kubectl get services -n devops-case
kubectl get cronjobs -n devops-case
kubectl get gateway -n devops-case
kubectl get httproute -n devops-case
```

Liveness/readiness probes are defined for the backend and frontend Deployments. The backend application healthcheck endpoint is `/healthcheck/`, while the frontend healthcheck endpoint is `/`.

The backend Deployment is configured with `maxSurge: 1` and `maxUnavailable: 0` for the single-node EKS environment. The old Pod is terminated only after the new Pod is ready according to the readiness probe, resulting in a `v1 → v1 + v2 → v2` transition.

For external EKS access, requests to `/` are routed to the frontend and requests to `/api` are routed to the backend. Therefore, the backend `/healthcheck/` endpoint is publicly accessible through Envoy Gateway at `/api/healthcheck`.

### EKS Gateway Configuration

Because `GatewayClass` is a cluster-scoped resource, it is not included in the EKS Kustomize base. The existing Envoy GatewayClass in the EKS cluster is reused, avoiding unnecessary cluster-wide permissions for the GitHub Actions deployment role.

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

The Python ETL runs as a separate workflow, retrieving repository information from the GitHub API and updating the `github_repositories` collection in MongoDB.

```text
GitHub API
    ↓
Python ETL
    ↓
MongoDB Atlas
```

MongoDB Atlas data is also backed up automatically on a daily basis:

```text
MongoDB Atlas
      ↓
mongodb-backup CronJob
      ↓
mongodump
      ↓
.archive.gz
      ↓
Amazon S3
```

In the local Kubernetes environment, the application can be accessed through the local Envoy Gateway instead of the AWS Elastic Load Balancer.

Detailed architecture diagram and component descriptions:

`docs/architecture.md`

## Technologies

- React
- Node.js / Express
- MongoDB Atlas
- Python
- Docker / Docker Compose
- Kubernetes
- Kustomize
- AWS EKS
- Amazon ECR
- Amazon S3
- AWS IAM
- GitHub Actions
- GitHub OIDC
- Trivy
- Kubernetes RBAC
- Envoy Gateway
- Helm

> Helm is used to install Kubernetes dependencies such as Envoy Gateway. The application's own Kubernetes resources are managed using Kustomize.

## Requirements

To use the existing deployment running on AWS:

- An AWS account with the necessary permissions
- Access to the GitHub repository

For local execution or development:

- Docker Desktop (Kubernetes enabled)
- Docker Compose
- Node.js 20+
- Python 3.10+
- `kubectl`
- Helm

For AWS EKS management and infrastructure operations:

- AWS CLI
- `eksctl`

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

To validate the local container environment without Kubernetes:

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

## Kustomize Environment Management

The application's Kubernetes resources are managed using Kustomize with a shared base and environment-specific overlays.

Shared EKS resources:

```text
k8s/eks/
```

Environment overlays:

```text
k8s/overlays/dev/
k8s/overlays/test/
k8s/overlays/prod/
```

Backend and frontend CPU requests are environment-specific, while memory requests are kept at `32Mi` across environments because of the capacity of the single `t3.small` worker node:

| Environment |  CPU | Memory |
| ----------- | ---: | -----: |
| dev         |  50m |   32Mi |
| test        |  75m |   32Mi |
| prod        | 100m |   32Mi |

The deployment replica count is kept at `1` across environments.

The ETL CronJob uses the shared base because no meaningful environment-specific differences are required.

Secret values are not stored as plaintext in the Kustomize files. Sensitive values are provided through Kubernetes Secret resources.

Before production deployment, the Kustomize output is validated with a server-side dry run:

```powershell
kubectl apply --dry-run=server -k k8s/overlays/prod
```

The production overlay is then applied:

```powershell
kubectl apply -k k8s/overlays/prod
```

To inspect the generated Kustomize manifests:

```powershell
kubectl kustomize .\k8s\overlays\dev
kubectl kustomize .\k8s\overlays\test
kubectl kustomize .\k8s\overlays\prod
```

## Kubernetes Workloads

Kubernetes liveness/readiness probes are defined for the backend and frontend. The backend is monitored through the `/healthcheck/` endpoint, while the frontend is monitored through the `/` endpoint.

The backend Deployment is configured with `maxSurge: 1` and `maxUnavailable: 0` to support controlled rolling updates in the single-node EKS environment. The old Pod is terminated only after the new Pod is ready according to the readiness probe, resulting in a `v1 → v1 + v2 → v2` transition.

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

Resource requests/limits and application health probes are also defined for the Kubernetes workloads.

Secret values are not embedded in the repository source code or Docker images.

## Container Security Scanning

The frontend, backend, and Python ETL container images are scanned using Trivy as part of the CI/CD pipeline.

The Trivy scan performs the following checks:

```text
Docker images
     ↓
Trivy
     ↓
OS package vulnerabilities
Application dependencies
Embedded secrets
```

Scan results are reported in the GitHub Actions logs. Under the current case configuration, vulnerability findings are reported, but they do not automatically block deployment because `exit-code: 0` is used.

This control provides image, dependency, and secret scanning as part of the CI/CD security checks.

## Python ETL

The ETL retrieves repository information from the GitHub API and transfers it to MongoDB.

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
Trivy security scan
        ↓
CI successful
        ↓
Production approval
        ↓
GitHub OIDC
        ↓
AWS IAM Role
        ↓
Amazon ECR image push
        ↓
AWS EKS authentication
        ↓
Kustomize production overlay validation
        ↓
Kustomize production deployment
        ↓
Image update with commit SHA
        ↓
Rollout verification
        ↓
Backend healthcheck
        ↓
Frontend HTTP check
```

When a Pull Request is opened, the `validate-and-build` job runs and deployment is not performed.

After a successful push to the `main` branch, the `deploy-eks` job enters the production approval state. After approval from an authorized reviewer, the deployment steps are executed.

The deployment job:

1. Assumes the AWS IAM Role through GitHub OIDC.
2. Builds the frontend, backend, and ETL Docker images.
3. Tags the images with the Git commit SHA.
4. Pushes the images to Amazon ECR.
5. Scans the frontend, backend, and ETL images with Trivy for OS package vulnerabilities, application dependencies, and embedded secrets.
6. Creates the kubeconfig for the EKS cluster.
7. Updates the Kubernetes Secret resources.
8. Validates the `k8s/overlays/prod` Kustomize overlay using `kubectl apply --dry-run=server -k k8s/overlays/prod`.
9. Applies the production overlay using `kubectl apply -k k8s/overlays/prod`.
10. Updates the Deployment images to the corresponding commit SHA tags.
11. Checks the backend and frontend rollout status.
12. Verifies the Gateway and HTTPRoute resources.
13. Performs the backend healthcheck through the AWS Load Balancer.
14. Verifies external frontend access.

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

The IAM Role uses an OIDC trust policy restricted to the repository's `production` Environment. The `production` Environment is configured to allow deployments only from the `main` branch.

## EKS RBAC

The GitHub Actions IAM Role is mapped through an EKS Access Entry to the following Kubernetes group:

```text
github-actions-deploy
```

A Kubernetes `Role` and `RoleBinding` limited to the `devops-case` namespace are defined for this group.

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

MongoDB Atlas data is automatically backed up in the production environment using a daily Kubernetes CronJob running on AWS EKS.

Automatic backup flow:

```text
MongoDB Atlas
      ↓
EKS mongodb-backup CronJob
      ↓
mongodump
      ↓
.archive.gz
      ↓
Amazon S3
sample_training/
```

Backup schedule:

```text
0 2 * * *
```

Timezone:

```text
Europe/Istanbul
```

Backup files are created as separate archive files with UTC timestamps.

Example:

```text
sample_training_20260912T230006Z.archive.gz
```

Backups are stored outside the cluster in Amazon S3:

```text
s3://devops-case-baykar-backups-203309795174/sample_training/
```

The backup archive is checked to ensure that it is not empty, and the uploaded S3 object is verified using `aws s3api head-object`.

The backup workload uses a dedicated `s3-backup` ServiceAccount, and the required S3 access is restricted through a least-privilege IAM policy. The backup containers run as non-root users with privilege escalation disabled.

S3 Lifecycle-based automatic retention/deletion, PITR, automated restore verification, and periodic full DR drills have not been implemented as part of this case.

To verify backup restorability end-to-end, the PowerShell script included in the repository can also be used. This manual test is separate from the automated S3 backup mechanism used in production:

```powershell
.\scripts\backup-restore.ps1 -Action Backup

.\scripts\backup-restore.ps1 -Action Restore
```

To restore over existing collections:

```powershell
.\scripts\backup-restore.ps1 -Action Restore -DropExisting
```

Local backup location used during the manual E2E test:

```text
backups/sample-training-backup/
```

This directory is excluded from the repository through `.gitignore`.

The backup and restore process was tested end-to-end using real data. During the test, a record was created, a backup was taken, the database was deleted, the data loss was verified, and the data was restored using `mongorestore`. After the restore, the data was verified to be accessible again through both MongoDB Atlas and the web interface.

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
- Kustomize environment management
- Container image, dependency, and secret scanning with Trivy
- Automated MongoDB backup to Amazon S3

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

## Environment Limitations

The AWS EKS case environment runs on a single `t3.small` worker node. Due to Free Tier resource constraints, system components and application workloads share the same node.

Because of these resource constraints, application workload replicas are kept at `1` across environments and resource requests are intentionally kept low. Higher capacity, multiple worker nodes, and an appropriate high-availability configuration would typically be used in a real production environment.

## Documentation and Evidence

Architecture:

`docs/architecture.md`

Initial findings:

`docs/findings.md`

Backup/restore runbook:

`docs/backup-restore.md`

Case answers:

`CASE_END_ANSWERS.md`

Submission evidence:

`SUBMISSION_EVIDENCE.md`

Screenshots:

`docs/screenshots/`

Main case document:

`DevOps_Technical_Case_EN.docx`
