# SUBMISSION EVIDENCE

For the submission to be considered complete, add screenshots of the running system to the `docs/screenshots/` directory and specify the related file path under each item below.

Screenshots must not expose real credentials, tokens, passwords, private keys, or sensitive connection details.

## 1. Web Application

### 1.1 Home page

- **Screenshot:** `docs/screenshots/01-web-home.png`
- **Explanation:** The React frontend application is shown to be accessible and operational. The main page provides access to the application's primary user flows.

### 1.2 Create operation

- **Form screenshot:** `docs/screenshots/02-record-create-form.png`
- **Successful result screenshot:** `docs/screenshots/03-record-created.png`
- **Explanation:** A new record was created successfully by completing the create form. The created record was verified on the `/records` page.

### 1.3 Edit operation

- **Before-edit screenshot:** `docs/screenshots/04-record-edit-before.png`
- **After-edit screenshot:** `docs/screenshots/05-record-edit-after.png`
- **Explanation:** An existing record was updated through the edit form. The updated values were verified on the `/records` page after the operation.

## 2. Docker

- **Kubernetes image build screenshot:** `docs/screenshots/06-docker-images-kubernetes-build.png`
- **Compose image build screenshot:** `docs/screenshots/07-docker-images-compose-build.png`
- **Running containers screenshot:** `docs/screenshots/08-docker-images-compose-and-kubernetes.png`
- **Explanation:** Docker images for the frontend, backend, and Python ETL are shown to have been successfully built and run in container environments. The same application images are also pushed to Amazon ECR for AWS EKS deployment, as shown in the CI/CD evidence.

## 3. Kubernetes

### 3.1 Local Kubernetes

- **Pod/workload status:** `docs/screenshots/09-kubernetes-workloads.png`
- **Service and Gateway status:** `docs/screenshots/10-kubernetes-services-gateway.png`
- **ETL CronJob/Job status:** `docs/screenshots/11-etl-cronjob-job.png`
- **Explanation:** The application was deployed in a local Kubernetes environment within the `devops-case` namespace. Frontend and backend Deployment/Service resources were created, and the Python ETL was configured as an hourly CronJob. Internal routing was provided through Envoy Gateway and HTTPRoute.

### 3.2 AWS EKS

- **EKS cluster and node status:** `docs/screenshots/12-eks-cluster-node.png`
- **EKS workload status:** `docs/screenshots/13-eks-workloads.png`
- **Service and Gateway status:** `docs/screenshots/14-eks-services-gateway.png`
- **ECR images (backend):** `docs/screenshots/15-ecr-images-backend.png`
- **ECR images (frontend):** `docs/screenshots/16-ecr-images-frontend.png`
- **ECR images (ETL):** `docs/screenshots/17-ecr-images-etl.png`
- **Health check and resource definitions (backend):** `docs/screenshots/41-eks-healthchecks-resources-backend.png`
- **Health check and resource definitions (frontend):** `docs/screenshots/42-eks-healthchecks-resources-frontend.png`
- **Health check and resource definitions (ETL):** `docs/screenshots/43-eks-cpu-memory-limits-etl.png`
- **Explanation:** The application has been deployed to the `devops-case-eks` cluster on AWS EKS. The backend and frontend Deployments, Service resources, and the Python ETL CronJob are running on EKS. Container images are pulled from Amazon ECR.

Liveness/readiness probes are defined for the backend and frontend Deployments, while CPU and memory resource requests/limits are configured for all main workloads. The backend Deployment uses a controlled RollingUpdate strategy with `maxSurge: 1` and `maxUnavailable: 0`(detailed in Section 7.2).

### 3.3 Cloud external access

- **AWS Load Balancer and Gateway screenshot:** `docs/screenshots/18-eks-external-access.png`
- **Backend healthcheck screenshot:** `docs/screenshots/19-eks-backend-healthcheck.png`
- **Frontend external access screenshot:** `docs/screenshots/01-web-home.png`
- **Explanation:** The Envoy Gateway has been exposed to the internet through an AWS Elastic Load Balancer via a `LoadBalancer` Service. The HTTPRoute routes `/` requests to `frontend-service` and `/api` requests to `backend-service`. Real external HTTP requests successfully verified both the React frontend application and the backend `/api/healthcheck` endpoint.

## 4. Python ETL

### 4.1 Initial data load

Show that GitHub repository information was stored in MongoDB for the first time.

- **Screenshot or terminal output:** `docs/screenshots/20-etl-first-load.png`
- **Explanation:** The Python ETL retrieves repository information through the GitHub API and stores it in MongoDB. During the initial run, a new repository document was created.

### 4.2 Update of the same repository

Show that processing the same repository again did not create a duplicate and instead updated the existing record. Where possible, include both the repository count and the updated field in the same evidence.

- **Screenshot or terminal output:** `docs/screenshots/21-etl-update-without-duplicate.png`
- **Unique field used:** `github_id`
- **Explanation:** When the same repository was processed again, no new MongoDB document was created; the existing record was updated using `github_id=1361100555`. The ETL log shows the `UPDATE: repository updated (github_id=1361100555)` message and `MongoDB document count: 1`. This demonstrates that no duplicate was created and that the upsert/update logic is working correctly.

### 4.3 ETL execution on EKS

- **Screenshot or terminal output:** `docs/screenshots/22-eks-etl-success.png`
- **Explanation:** A Job created by the hourly ETL CronJob running on EKS was successfully completed. The Job retrieved the GitHub repository information, established a MongoDB connection, and updated the existing repository using `github_id`. The container was running the ETL image from Amazon ECR with a commit SHA tag, and the Job reached the `Completed` state.

## 5. CI/CD

- **Successful pipeline screenshot:** `docs/screenshots/23-cicd-pipeline-success.png`
- **Screenshot showing build/image/deployment stages:** `docs/screenshots/24-build-validation-steps.png`
- **ECR push and EKS deployment stages screenshot:** `docs/screenshots/25-build-ecr-eks-deployment-steps.png`
- **Explanation:** The CI/CD pipeline has been successfully executed on GitHub Actions. During the CI stage, the frontend build, backend validation, Python ETL validation, and Docker image build processes are performed. In addition, the frontend, backend, and Python ETL container images created during the CI stage are scanned for security vulnerabilities using Trivy. Trivy checks OS packages and application dependencies for known vulnerabilities and scans the images for accidentally embedded secret information. Scan results are reported in the GitHub Actions logs. In the current case environment, vulnerability findings are reported, but deployment is not automatically blocked because `exit-code: 0` is used.

  A `deploy-eks` job runs after a push to the `main` branch. The workflow assumes the AWS IAM Role through GitHub OIDC, pushes the Docker images to Amazon ECR using the commit SHA as the image tag, connects to the EKS cluster using kubeconfig, and updates the Kubernetes Secrets.

  During the deployment stage, the `k8s/overlays/prod` Kustomize overlay is first validated using `kubectl apply --dry-run=server -k k8s/overlays/prod` and then applied to the EKS environment using `kubectl apply -k k8s/overlays/prod`. The images are subsequently updated with the corresponding commit SHA tags, and the rollout status of the backend, frontend, and ETL workloads is verified.

  After deployment, the Gateway and HTTPRoute resources are verified, and the backend health check and frontend accessibility are automatically tested through the AWS Load Balancer.

  If a build or validation step in the CI stage fails, the `deploy-eks` job is not executed. This ensures that cloud deployment takes place only after a successful CI result.

### 5.1 GitHub OIDC and AWS authentication

- **Screenshot:** `docs/screenshots/26-github-oidc-aws-auth.png`
- **Explanation:** GitHub Actions does not use long-lived AWS access keys for AWS access. The workflow assumes the `GitHubActions-EKS-Deploy` IAM Role through GitHub OIDC and uses temporary AWS credentials to perform ECR and EKS operations.

### 5.2 EKS RBAC

- **Kubernetes RBAC screenshot:** `docs/screenshots/27-eks-cd-rbac.png`
- **AWS EKS Access Entry screenshot:** `docs/screenshots/28-access-entry.png`
- **Explanation:** The GitHub Actions IAM Role is mapped to the `github-actions-deploy` Kubernetes group through an EKS Access Entry. A Role/RoleBinding limited to the `devops-case` namespace is defined for this group. GitHub Actions is not granted unnecessary `cluster-admin` privileges.

## 6. Backup and Restore

All six steps below must be evidenced. It must be clear that the steps were performed in order and on the same record.

The steps in Sections 6.1–6.6 represent the **manual end-to-end backup and restore test** performed against real application data.

The regular production backup mechanism is separate and is shown under **Section 7.6 - Advanced Criteria #7**, where the automated EKS CronJob → Amazon S3 backup flow is evidenced.

The following six steps were performed in order on the same `sample_training` database.

### 6.0 Backup/Restore Script

- **Script:** `scripts/backup-restore.ps1`
- **Explanation:** Backup and restore operations can be executed reproducibly using the PowerShell script included in the repository. The `-Action Backup` and `-Action Restore -DropExisting` scenarios have been successfully tested.

```powershell
.\scripts\backup-restore.ps1 -Action Backup

.\scripts\backup-restore.ps1 -Action Restore
```

To restore over existing collections:

```powershell
.\scripts\backup-restore.ps1 -Action Restore -DropExisting
```

The script does not contain any real credentials; it reads the MongoDB connection string from the `ATLAS_URI` value in the local `.env` file.

This script is used for the **manual backup/restore end-to-end test** and is separate from the daily automated S3 backup mechanism used for the production deployment.

### 6.1 Record creation

- **Screenshot 1:** `docs/screenshots/29-backup-record-created-01.png`
- **Screenshot 2:** `docs/screenshots/30-backup-record-created-02.png`
- **Explanation:** Before the backup scenario was started, the application data was verified to be present. The `sample_training` database and its relevant collections were displayed in MongoDB Atlas. The backup scenario contained a total of 2 documents: 1 document in the `records` collection and 1 document in the `github_repositories` collection.

### 6.2 Taking the (manual) backup

- **Screenshot or terminal output:** `docs/screenshots/31-backup-taken.png`
- **Method and commands used (3 commands, executed sequentially from the project root):**

MongoDB Database Tools `mongodump` was used. The manual end-to-end test backup was performed using the following method:

```powershell
New-Item -ItemType Directory -Path ".\backups" -Force

$atlasUri = (Get-Content .\.env | Where-Object { $_ -match '^ATLAS_URI=' }) -replace '^ATLAS_URI=', ''

& "C:\Program Files\MongoDB\Tools\100\bin\mongodump.exe" `
  --uri="$atlasUri" `
  --db=sample_training `
  --out=".\backups\sample-training-backup"
```

The script uses the same `mongodump` method. This local backup operation is only part of the end-to-end backup/restore test.

- **Backup storage location:** `backups/sample-training-backup`
- **Explanation:** The entire `sample_training` database was backed up. The backup output shows 1 document for `sample_training.records` and 1 document for `sample_training.github_repositories`.

Production automated backups are not stored in the local `backups/` directory. They are stored as timestamped archive files in Amazon S3, as shown in Section 7.7.

### 6.3 Dropping the collection or database

- **Screenshot or terminal output:** `docs/screenshots/32-collection-dropped.png`
- **Explanation:** The `sample_training` database was completely deleted through MongoDB Atlas.

### 6.4 Showing that the data is gone

- **Interface screenshot:** `docs/screenshots/33-data-missing-after-drop-ui.png`
- **Database output:** `docs/screenshots/34-data-missing-after-drop-database.png`
- **Explanation:** After the database was deleted, it was verified that the records were no longer displayed on the application's `/records` page and that the `sample_training` database was no longer present in MongoDB Atlas.

### 6.5 Restoring from the backup

- **Screenshot or terminal output:** `docs/screenshots/35-restore-executed.png`
- **Measured restore duration:** The restore command completed in approximately 1.3 seconds. This value represents only the execution time of the restore command and is not considered an end-to-end production RTO.
- **Explanation:** The `sample_training` database was restored from the backup taken during the manual end-to-end test using `mongorestore`. A total of 2 documents were successfully restored and 0 documents failed to restore.

### 6.6 Verifying that the data is back

- **Interface screenshot:** `docs/screenshots/36-data-restored-verified-ui.png`
- **Database output (1):** `docs/screenshots/37-data-restored-verified-database-01.png`
- **Database output (2):** `docs/screenshots/38-data-restored-verified-database-02.png`
- **Explanation:** After the restore operation, the `sample_training.records` and `sample_training.github_repositories` collections were recreated, and the previous data was confirmed to be accessible again through both MongoDB Atlas and the web interface.

> The runbook, RPO/RTO targets, backup schedule, and retention limitations are documented in `docs/backup-restore.md`.

## 7. Logging, Monitoring, and Advanced Criteria

Add evidence for any implemented logging, monitoring, alerting, Helm, Terraform, security scanning, or other advanced criteria.

The evidence for the implemented logging, monitoring, alerting, security controls, and other advanced criteria is provided below. Upper criteria 2, 3, 4, 5, 6, and 7 are completed.

### 7.1 Advanced Criteria #2 - Packaging and Environment Management: Kustomize

- **Backend environment evidence:** `docs/screenshots/39-kustomize-backend-dev-test-prod.png`
- **Frontend environment evidence:** `docs/screenshots/40-kustomize-frontend-dev-test-prod.png`
- **Explanation:** Kubernetes resources are managed using Kustomize with a base and environment overlay structure. Shared resources are kept under `k8s/eks/`, while environment-specific differences are defined under `k8s/overlays/dev`, `k8s/overlays/test`, and `k8s/overlays/prod`.

  CPU request values for both the backend and frontend are configured as `50m / 75m / 100m` for dev/test/prod respectively. Memory requests are kept at `32Mi` across all environments to avoid scheduling issues on the single `t3.small` worker node. The deployment replica count is set to `1` in all environments due to the current Free Tier / single-node capacity constraints.

  The ETL CronJob configuration is managed through the shared base because no meaningful environment-specific differences are required. Secret values are not stored as plaintext in the Kustomize files and are provided through Kubernetes Secrets instead.

  The production environment is deployed to AWS EKS using the `k8s/overlays/prod` Kustomize overlay. The Kustomize output is validated with a server-side dry run before deployment using `kubectl apply --dry-run=server -k k8s/overlays/prod`, followed by `kubectl apply -k k8s/overlays/prod`.

  The `GatewayClass` is not included in the Kustomize base because it is a cluster-scoped resource and the GitHub Actions role uses namespace-scoped RBAC permissions. The existing GatewayClass in the EKS cluster is therefore reused, avoiding unnecessary cluster-wide permissions for the deployment workflow.

### 7.2 Advanced Criteria #3 - High Availability and Scaling: Rolling Update and Capacity Approach

- **Health check and resource configuration screenshots:**

  - `docs/screenshots/41-eks-healthchecks-resources-backend.png`
  - `docs/screenshots/42-eks-healthchecks-resources-frontend.png`
  - `docs/screenshots/43-eks-cpu-memory-limits-etl.png`

- **Rolling update screenshot:** `docs/screenshots/44-eks-rolling-update.png`
- **Explanation:** CPU and memory resource requests/limits are defined for the Kubernetes workloads. The backend Deployment uses a controlled `RollingUpdate` strategy with `maxSurge: 1` and `maxUnavailable: 0`. During deployment, the new Pod is created first, and the old Pod is not terminated until the new Pod has been confirmed ready by the readiness probe. This results in a version transition of `v1 → v1 + v2 → v2`. This behavior was verified during an actual rollout in the EKS environment and is evidenced by `docs/screenshots/44-eks-rolling-update.png`.

### 7.3 Advanced Criteria #4 - Advanced Observability: Verified Alert Scenarios

- **Alert check and test screenshot:** `docs/screenshots/45-alerts-check.png`
- **Alert definition:** `scripts/check-alerts.ps1`
- **Explanation:** The `check-alerts.ps1` script provides executable alert checks for two critical events. `ALERT-001` checks whether the ETL CronJob has failed or whether no successful run has occurred within the expected time window. `ALERT-002` checks whether the frontend or backend health endpoints are inaccessible. In test mode, both alerts were intentionally triggered and the script terminated with exit code 1. During the normal check with the system in a healthy state, no critical alert was generated and the script completed successfully.

### 7.4 Advanced Criteria #5 - Advanced Security: Image / Dependency / Secret Scanning

- **Trivy container security scan screenshot:** `docs/screenshots/46-trivy-security-scan.png`
- **Explanation:** The frontend, backend, and Python ETL container images are scanned using Trivy as part of the GitHub Actions CI pipeline. The scan checks OS packages, application dependencies, and potentially embedded secrets within the images. Scan results are reported in the GitHub Actions logs, and under the current case configuration, vulnerability findings do not automatically block deployment.

### 7.5 Advanced Criteria #6 - GitOps and Release Strategy: Controlled Production Approval

- **Production approval waiting screenshot:** `docs/screenshots/47-production-deployment-approval-pending.png`
- **Post-approval deployment screenshot:** `docs/screenshots/48-production-deployment-approval-granted.png`
- **Explanation:** Production deployment is protected by a controlled approval process using the `production` Environment in GitHub Actions. After a successful push to the `main` branch, the `validate-and-build` job completes, after which the `deploy-eks` job enters a waiting state for production approval.

  No deployment to AWS EKS is performed until the production deployment is approved by an authorized reviewer. After approval, the `deploy-eks` job runs and performs the ECR image push, EKS authentication, Kustomize deployment, and workload verification steps.

  `docs/screenshots/47-production-deployment-approval-pending.png` shows that the production deployment is waiting for approval, while `docs/screenshots/48-production-deployment-approval-granted.png` shows that the deployment job continued and completed successfully after approval.

  The workflow defines the production deployment environment as:

```yaml
environment: production
```

The `production` Environment is also restricted to deployments from the `main` branch.

This setup ensures that every production deployment passes through a controlled human approval step after CI validation.

### 7.6 Advanced Criteria #7 - Advanced Disaster Recovery: Off-Cluster Scheduled Backup

- **Automated backup and S3 evidence:** `docs/screenshots/49-backup-cronjob-scheduled-success.png`
- **Explanation:** An automated backup mechanism runs on AWS EKS using the `mongodb-backup` Kubernetes CronJob to keep MongoDB Atlas data outside the Kubernetes cluster. The CronJob is configured with the `0 2 * * *` (At 02.00 a.m.) schedule and the `Europe/Istanbul` timezone for daily execution.

  The backup workload uses `mongodump` to back up the `sample_training` database in `.archive.gz` format and uploads the timestamped archive file to the `sample_training/` prefix in Amazon S3.

  Each backup is stored as a separate object, so previous backups are not overwritten. The backup file is checked with `test -s` to ensure that it is not empty, and `aws s3api head-object` is used after the upload to verify that the S3 object was successfully created.

  The backup workload uses a dedicated `s3-backup` ServiceAccount, and the required S3 access is restricted through a least-privilege IAM policy. The backup containers also run as non-root users with privilege escalation disabled.

  Successful execution of the real scheduled backup Job and the resulting S3 backup are evidenced by `docs/screenshots/49-backup-cronjob-scheduled-success.png`.

  This mechanism is separate from the manual end-to-end backup/restore test in Section 6. The manual test verifies that a backup can be restored, while the automated mechanism provides regular, off-cluster backup storage.

  S3 Lifecycle-based automatic retention/deletion, PITR, automated restore verification, and periodic full DR drills have not been implemented as part of this case. The backup schedule, storage approach, restore method, RPO/RTO assessment, and limitations are documented in `docs/backup-restore.md`.

### 7.7 ETL Logging

- **ETL log screenshot:** `docs/screenshots/21-etl-update-without-duplicate.png`
- **Explanation:** The logs of the ETL CronJob running on Kubernetes show the retrieval of the GitHub repository, the MongoDB connection, the update of the existing repository using `github_id`, the document count check, and the successful completion of the ETL process.

### 7.8 ETL Scheduling

- **EKS CronJob schedule screenshot:** `docs/screenshots/50-eks-cronjob-schedule.png`
- **Explanation:** The `etl` CronJob running on EKS is shown to use the `0 * * * *` schedule for hourly execution and the `Europe/Istanbul` timezone.

## 8. Additional Evidence

### 8.1 Kubernetes Security Hardening

- **Backend non-root evidence:** `docs/screenshots/51-backend-non-root-kubernetes.png`
- **Frontend non-root evidence:** `docs/screenshots/52-frontend-non-root-kubernetes.png`
- **ETL non-root evidence:** `docs/screenshots/53-etl-non-root-kubernetes.png`
- **Explanation:** The Kubernetes workloads were verified not to run as the root user. The backend runs as `node` (UID 1000), the frontend as `nginx` (UID 101), and the ETL as `appuser` (UID 10001). In addition, `allowPrivilegeEscalation` is disabled and all Linux capabilities are dropped.

### 8.2 AWS / EKS deployment configuration

- **EKS cluster and node status:** `docs/screenshots/54-eks-cluster-config.png`
- **EKS managed node group configuration:** `docs/screenshots/55-eks-node-group-config.png`
- **Explanation:** The `devops-case-eks` EKS cluster is shown to be running in the `eu-central-1` region with a `Ready` worker node. The running node uses Kubernetes `v1.36.3` and Amazon Linux 2023. The EKS managed node group is configured with the name `devops-workers` and uses the `t3.small` instance type with 1 desired node. The cluster and node group configuration is defined in the repository's `eks-cluster.yaml` file. Kubernetes workload configuration is managed through Kustomize overlays for each environment, with the production deployment performed using `k8s/overlays/prod`.
