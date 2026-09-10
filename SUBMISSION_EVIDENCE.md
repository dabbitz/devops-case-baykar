# SUBMISSION EVIDENCE

For the submission to be considered complete, add screenshots of the running system to the `docs/screenshots/` directory and specify the related file path under each item below.

Screenshots must not expose real credentials, tokens, passwords, private keys, or sensitive connection details.

## 1. Web Application

### 1.1 Home page

- **Screenshot:** `docs/screenshots/01-web-home.png`
- **Explanation:** The React frontend application is shown to be accessible and operational. The main page provides access to the application's core user flows.

### 1.2 Create operation

- **Form screenshot:** `docs/screenshots/02-record-create-form.png`
- **Successful result screenshot:** `docs/screenshots/03-record-created.png`
- **Explanation:** A new record was entered through the create form and the create operation was completed successfully. The newly created record was verified on the `/records` page.

### 1.3 Edit operation

- **Before-edit screenshot:** `docs/screenshots/04-record-edit-before.png`
- **After-edit screenshot:** `docs/screenshots/05-record-edit-after.png`
- **Explanation:** An existing record was updated through the edit form. The updated values were subsequently verified on the `/records` page.

## 2. Docker

- **Kubernetes image build screenshot:** `docs/screenshots/06-docker-images-kubernetes-build.png`
- **Compose image build screenshot:** `docs/screenshots/07-docker-images-compose-build.png`
- **Running containers screenshot:** `docs/screenshots/08-docker-images-compose-and-kubernetes.png`
- **Explanation:** The Docker images for the frontend, backend, and Python ETL were successfully built and run in container environments.

## 3. Kubernetes

- **Pod/workload status:** `docs/screenshots/09-kubernetes-workloads.png`
- **Service and Ingress status, where applicable:** `docs/screenshots/10-kubernetes-services-gateway.png`
- **ETL CronJob/Job status:** `docs/screenshots/11-etl-cronjob-job.png`
- **Explanation:** The application was deployed within a Kubernetes namespace. Frontend and backend Deployment/Service resources were created, and the Python ETL was configured as an hourly CronJob. External access is provided through Envoy Gateway and HTTPRoute.

## 4. Python ETL

### 4.1 Initial data load

Show that GitHub repository information was stored in MongoDB for the first time.

- **Screenshot or terminal output:** `docs/screenshots/12-etl-first-load.png`
- **Explanation:** The Python ETL retrieves repository information from the GitHub API and stores it in MongoDB. During the first execution, a new record was created for the repository.

### 4.2 Update of the same repository

Show that processing the same repository again did not create a duplicate and instead updated the existing record. Where possible, include both the repository count and the updated field in the same evidence.

- **Screenshot or terminal output:** `docs/screenshots/13-etl-update-without-duplicate.png`
- **Unique field used:** `github_id`
- **Explanation:** When the same repository was processed again, no new MongoDB document was created. Instead, the existing record was updated using `github_id=1361100555`. The ETL log shows the `UPDATE: repository updated` message and `MongoDB document count: 1`. This demonstrates that the duplicate prevention and upsert/update logic are working as intended.

## 5. CI/CD

- **Successful pipeline screenshot:** `docs/screenshots/14-cicd-pipeline-success.png`
- **Screenshot showing build/image stages:** `docs/screenshots/15-build-image-steps.png`
- **Screenshot showing build/deployment stages:** `docs/screenshots/16-build-deployment-steps.png`
- **Explanation:** The CI/CD pipeline was successfully executed through GitHub Actions. During the CI stage, the frontend build, backend validation, Python ETL validation, and Docker image build operations were performed. After CI completed successfully, the deployment job created a temporary Kind Kubernetes cluster, loaded the Docker images into the cluster, deployed the Kubernetes workloads, and performed rollout, frontend, and backend healthcheck verification. If a build, validation, or image creation step fails during CI, the deployment job is not executed.

## 6. Backup and Restore

All six steps below must be evidenced. It must be clear that the steps were performed in order and on the same record.

### 6.1 Record creation

- **Screenshot 1:** `docs/screenshots/17-backup-record-created-01.png`
- **Screenshot 2:** `docs/screenshots/18-backup-record-created-02.png`
- **Explanation:** Before starting the backup scenario, the existence of the application data was verified. The `sample_training` database and the related collections were shown in MongoDB Atlas.

### 6.2 Taking the backup

- **Screenshot or terminal output:** `docs/screenshots/19-backup-taken.png`
- **Method and commands used (3 commands, in order, from the project root):** MongoDB Database Tools `mongodump` was used:

```powershell
New-Item -ItemType Directory -Path ".\backups" -Force

$atlasUri = (Get-Content .\.env | Where-Object { $_ -match '^ATLAS_URI=' }) -replace '^ATLAS_URI=', ''

"C:\Program Files\MongoDB\Tools\100\bin\mongodump.exe" `
  --uri="$atlasUri" `
  --db=sample_training `
  --out=".\backups\sample-training-backup"
```

- **Backup storage location:** `backups/sample-training-backup`
- **Explanation:** The entire `sample_training` database was backed up. The backup output shows one document backed up for `sample_training.records` and one document backed up for `sample_training.github_repositories`.

### 6.3 Dropping the collection or database

- **Screenshot or terminal output:** `docs/screenshots/20-collection-dropped.png`
- **Explanation:** The `sample_training` database was completely deleted through MongoDB Atlas.

### 6.4 Showing that the data is gone

- **Interface screenshot:** `docs/screenshots/21-data-missing-after-drop-ui.png`
- **Database output:** `docs/screenshots/22-data-missing-after-drop-database.png`
- **Explanation:** After the database was deleted, it was verified that the records were no longer displayed on the application's `/records` page and that the `sample_training` database was no longer present in MongoDB Atlas.

### 6.5 Restoring from the backup

- **Screenshot or terminal output:** `docs/screenshots/23-restore-executed.png`
- **Measured restore duration:** The restore command completed in approximately 1.3 seconds. This value represents only the execution time of the restore command and is not considered an end-to-end production RTO.
- **Explanation:** The `sample_training` database was restored from the backup using `mongorestore`. A total of 2 documents were successfully restored, with 0 restore errors.

### 6.6 Verifying that the data is back

- **Interface screenshot:** `docs/screenshots/24-data-restored-verified-ui.png`
- **Database output:** `docs/screenshots/25-data-restored-verified-database.png`
- **Explanation:** After the restore, the `sample_training.records` and `sample_training.github_repositories` collections were recreated, and the previous data was verified to be accessible again through both MongoDB Atlas and the web interface.

> The runbook, RPO/RTO targets, and retention period are documented in `docs/backup-restore.md`.

## 7. Logging, Monitoring, and Advanced Criteria

Add evidence for any implemented logging, monitoring, alerting, Helm, Terraform, security scanning, or other advanced criteria.

- **Screenshot:** `docs/screenshots/26-ETL-cronjob-logging.png`
- **Explanation:** The logs of the Kubernetes ETL CronJob show the retrieval of the GitHub repository, the MongoDB connection, the update of the existing repository using `github_id`, the document count check, and the successful completion of the ETL process.

## 8. Additional Evidence

### 8.1 Critical Alerts

- **Alert check and test screenshot:** `docs/screenshots/27-alerts-check.png`
- **Alert definition:** `scripts/check-alerts.ps1`
- **Explanation:** The `check-alerts.ps1` script provides executable alert checks for two critical events. `ALERT-001` checks for ETL CronJob failure or the absence of a successful execution within the expected time window, while `ALERT-002` checks whether the frontend or backend health endpoints are unavailable. In test mode, both alerts were intentionally triggered and the script terminated with `exit code 1`. During a normal check on a healthy system, no critical alert was generated and the script completed successfully.

### 8.2 Kubernetes Security Hardening

- **Backend non-root evidence:** `docs/screenshots/28-backend-non-root-kubernetes.png`
- **Frontend non-root evidence:** `docs/screenshots/29-frontend-non-root-kubernetes.png`
- **ETL non-root evidence:** `docs/screenshots/30-etl-non-root-kubernetes.png`
- **Explanation:** It was verified that the containers in the Kubernetes workloads do not run as the root user. The backend runs as `node` (UID 1000), the frontend as `nginx` (UID 101), and the ETL as `appuser` (UID 10001). In addition, `allowPrivilegeEscalation` is disabled and all Linux capabilities are dropped.
