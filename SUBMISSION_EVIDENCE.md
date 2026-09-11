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
- **Health check and resource definitions (backend):** `docs/screenshots/46-eks-healthchecks-resources-backend.png`
- **Health check and resource definitions (frontend):** `docs/screenshots/47-eks-healthchecks-resources-frontend.png`
- **Health check and resource definitions (etl):** `docs/screenshots/48-eks-cpu-memory-limits-etl.png`
- **Explanation:** The application has been deployed to the `devops-case-eks` cluster on AWS EKS. The backend and frontend Deployments, Service resources, and the Python ETL CronJob are running on EKS. Container images are pulled from Amazon ECR.

Kubernetes liveness/readiness probes are defined for the backend and frontend Deployments. The backend uses the `/healthcheck/` endpoint, while the frontend uses the `/` endpoint. CPU and memory resource requests/limits are defined for the backend, frontend, and ETL workloads. The backend Deployment uses `maxSurge: 0` and `maxUnavailable: 1` for a controlled rolling update suitable for the single-node EKS environment.

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
- **Explanation:** A real CI/CD pipeline was successfully executed using GitHub Actions. During the CI stage, the frontend build, backend validation, Python ETL validation, and Docker image build operations were performed.

  After a push to the `main` branch, the `deploy-eks` job runs. The workflow assumes an AWS IAM Role using GitHub OIDC, pushes Docker images tagged with the commit SHA to Amazon ECR, connects to the EKS cluster using kubeconfig, updates Kubernetes Secrets, and applies the Service, Deployment, and CronJob resources under `k8s/eks/`.

  After deployment, backend and frontend rollout status is checked, Gateway and HTTPRoute resources are verified, and backend healthcheck and frontend access are automatically tested through the AWS Load Balancer.

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

### 6.0 Backup/Restore Script

- **Script:** `scripts/backup-restore.ps1`
- **Explanation:** Backup and restore operations can be executed reproducibly using the PowerShell script included in the repository. The `-Action Backup` and `-Action Restore -DropExisting` scenarios have been successfully tested. The manual command chain beginning in Section 6.1 is provided to clearly document the MongoDB backup method used.

```powershell
.\scripts\backup-restore.ps1 -Action Backup

.\scripts\backup-restore.ps1 -Action Restore
```

To restore over existing collections:

```powershell
.\scripts\backup-restore.ps1 -Action Restore -DropExisting
```

The script does not contain any real credentials; it reads the MongoDB connection string from the `ATLAS_URI` value in the local `.env` file. Backup output is created under `backups/` and excluded from the repository through `.gitignore`.

### 6.1 Record creation

- **Screenshot 1:** `docs/screenshots/29-backup-record-created-01.png`
- **Screenshot 2:** `docs/screenshots/30-backup-record-created-02.png`
- **Explanation:** Before the backup scenario was started, the application data was verified to be present. The `sample_training` database and its relevant collections were displayed in MongoDB Atlas. The backup scenario contained a total of 2 documents: 1 document in the `records` collection and 1 document in the `github_repositories` collection.

### 6.2 Taking the backup

- **Screenshot or terminal output:** `docs/screenshots/31-backup-taken.png`
- **Method and command(s) used (3 commands, executed sequentially from the project root):**

MongoDB Database Tools `mongodump` was used. The backup can also be performed directly using the following script:

```powershell
New-Item -ItemType Directory -Path ".\backups" -Force

$atlasUri = (Get-Content .\.env | Where-Object { $_ -match '^ATLAS_URI=' }) -replace '^ATLAS_URI=', ''

& "C:\Program Files\MongoDB\Tools\100\bin\mongodump.exe" `
  --uri="$atlasUri" `
  --db=sample_training `
  --out=".\backups\sample-training-backup"
```

The script runs the `mongodump` command with the required parameters. The manual command chain is provided only to clearly document the method used.

- **Backup storage location:** `backups/sample-training-backup`
- **Explanation:** The entire `sample_training` database was backed up. The backup output shows 1 document for `sample_training.records` and 1 document for `sample_training.github_repositories`.

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
- **Explanation:** The `sample_training` database was restored from the backup using `mongorestore`. A total of 2 documents were successfully restored and 0 documents failed to restore.

### 6.6 Verifying that the data is back

- **Interface screenshot:** `docs/screenshots/36-data-restored-verified-ui.png`
- **Database output (1):** `docs/screenshots/37-data-restored-verified-database-01.png`
- **Database output (2):** `docs/screenshots/38-data-restored-verified-database-02.png`
- **Explanation:** After the restore operation, the `sample_training.records` and `sample_training.github_repositories` collections were recreated, and the previous data was confirmed to be accessible again through both MongoDB Atlas and the web interface.

> The runbook, RPO/RTO targets, and retention period must be documented in `docs/backup-restore.md`.

## 7. Logging, Monitoring, and Advanced Criteria

Add evidence for any implemented logging, monitoring, alerting, Helm, Terraform, security scanning, or other advanced criteria.

- **ETL log screenshot:** `docs/screenshots/21-etl-update-without-duplicate.png`
- **Explanation:** The logs of the ETL CronJob running on Kubernetes show the retrieval of the GitHub repository, the MongoDB connection, the update of the existing repository using `github_id`, the document count check, and the successful completion of the ETL process.
- **EKS CronJob schedule screenshot:** `docs/screenshots/39-eks-cronjob-schedule.png`
- **Explanation:** The `etl` CronJob running on EKS is shown to use the `0 * * * *` schedule for hourly execution and the `Europe/Istanbul` timezone.

## 8. Additional Evidence

### 8.1 Critical Alerts

- **Alert check and test screenshot:** `docs/screenshots/40-alerts-check.png`
- **Alert definition:** `scripts/check-alerts.ps1`
- **Explanation:** The `check-alerts.ps1` script provides executable alert checks for two critical events. `ALERT-001` checks whether the ETL CronJob has failed or whether no successful run has occurred within the expected time window. `ALERT-002` checks whether the frontend or backend health endpoints are inaccessible. In test mode, both alerts were intentionally triggered and the script terminated with exit code 1. During the normal check with the system in a healthy state, no critical alert was generated and the script completed successfully.

### 8.2 Kubernetes Security Hardening

- **Backend non-root evidence:** `docs/screenshots/41-backend-non-root-kubernetes.png`
- **Frontend non-root evidence:** `docs/screenshots/42-frontend-non-root-kubernetes.png`
- **ETL non-root evidence:** `docs/screenshots/43-etl-non-root-kubernetes.png`
- **Explanation:** The Kubernetes workloads were verified not to run as the root user. The backend runs as `node` (UID 1000), the frontend as `nginx` (UID 101), and the ETL as `appuser` (UID 10001). In addition, `allowPrivilegeEscalation` is disabled and all Linux capabilities are dropped.

### 8.3 AWS / EKS deployment configuration

- **EKS cluster and node status:** `docs/screenshots/44-eks-cluster-config.png`
- **EKS managed node group configuration:** `docs/screenshots/45-eks-node-group-config.png`
- **Explanation:** The `devops-case-eks` EKS cluster is shown to be running in the `eu-central-1` region with a `Ready` worker node. The running node uses Kubernetes `v1.36.3` and Amazon Linux 2023. The EKS managed node group is configured with the name `devops-workers` and uses the `t3.small` instance type with 1 desired node. The cluster and node group configuration is defined in the repository's `eks-cluster.yaml` file.
