# CASE END ANSWERS

Answer all questions below by relating them directly to your implementation.

Answers should be concise, specific, and detailed enough to explain your technical decisions. Where appropriate, reference the relevant source file, manifest, pipeline step, or document path.

---

## Candidate Information

- **Full name:** Tunahan Değirmencioğlu
- **Repository URL:** `https://github.com/dabbitz/devops-case-baykar.git`
- **Completion date:** 13.09.2026
- **Target environment used:** AWS EKS (`devops-case-eks`, `eu-central-1`)

---

## 1. Architecture and Request Flow

Explain the architecture you implemented and the path a user request follows from the frontend through the backend to the database.

Also prepare an architecture diagram showing the system components, connections between components, traffic flow, and external access points, and add it to the project repository as one of the following:

- `docs/architecture.md`
- `docs/architecture.pdf`

The diagram may be created with Mermaid, Draw.io, Excalidraw, or a similar tool. Include the editable source file in the repository as well.

**Answer:**

The primary deployment runs on AWS EKS. The frontend and backend run as `Deployment + ClusterIP Service`, while the Python ETL runs as an hourly `CronJob`.

```text
User / Browser
      ↓
AWS Load Balancer
      ↓
Envoy Gateway
      ↓
HTTPRoute
   ┌──┴────┐
   ↓       ↓
Frontend Backend
Service  Service
   ↓       ↓
React   Node.js
+ NGINX + Express
           ↓
      MongoDB Atlas
```

The frontend NGINX forwards `/api/` requests to `backend-service:5050`. The backend performs record CRUD operations in the `sample_training` database on MongoDB Atlas.

The ETL separately retrieves repository information from the GitHub API and performs an upsert on the `github_repositories` collection using `github_id`.

MongoDB Atlas data is also backed up daily by the `mongodb-backup` Kubernetes CronJob using `mongodump` and stored outside the cluster in Amazon S3.

Detailed architecture: `docs/architecture.md`

---

## 2. Critical Findings and Prioritization

What were the three most critical issues you identified in the starter projects? Which impact and risk criteria did you use to prioritize them?

**Answer:**

The three priority issues were:

1. **Hardcoded frontend API address:** The localhost dependency reduced deployment portability. The API address was changed to be managed through configuration/environment variables.
2. **Input validation and ObjectId validation:** Server-side validation and ObjectId checks were added to prevent invalid requests from reaching the database layer.
3. **Improper handling of MongoDB connection failures:** The backend was changed to fail fast when the MongoDB connection cannot be established.

Prioritization was based on production impact, reliability, security, deployment portability, and data-access risks.

Details: `docs/findings.md`

---

## 3. Items Left Out of Scope

Which issues did you intentionally leave unresolved or out of scope? Explain the reasons for these decisions.

**Answer:**

The core case requirements have been completed, while some advanced production-level features were left out of scope.

Full IaC with Terraform/OpenTofu, Prometheus/Grafana-based advanced monitoring, HPA/PDB and multi-node high availability, GitOps, canary/blue-green deployment, PITR, automated restore verification, S3 Lifecycle-based automatic retention, and distributed tracing were not implemented.

However, Kustomize-based environment management, controlled `RollingUpdate`, CPU/memory resource management, verifiable alert checks, Trivy image/dependency/secret scanning, and daily automated MongoDB backup to cluster-external Amazon S3 were implemented and verified in the actual EKS environment.

The omitted areas can be added separately according to production scaling, observability, release management, and disaster recovery requirements.

---

## 4. Target Environment Selection

Why did you choose a cloud environment or a virtual machine? Which components or approaches would you use differently in a real production environment?

**Answer:**

AWS EKS was selected because the application is container-based and the frontend, backend, and periodic ETL workloads were intended to run on managed Kubernetes in a real cloud environment.

This allowed Amazon ECR, AWS IAM, GitHub OIDC, EKS RBAC, Envoy Gateway, AWS Load Balancer, and Amazon S3 to be used together.

In a production environment, I would additionally use Terraform/OpenTofu for full IaC, HPA and node autoscaling, PDB and multi-node distribution, Prometheus/Grafana, centralized secret management, HTTPS/domain management, defined backup retention, automated restore verification/PITR, and controlled release strategies.

---

## 5. MongoDB Approach

Why did you choose your MongoDB deployment and service approach? Explain the alternatives you considered, along with their advantages, disadvantages, and operational trade-offs.

**Answer:**

MongoDB Atlas was used for the normal deployment. This separates database persistence and operations from the Kubernetes workloads.

Alternatives considered:

| Approach          | Advantage                          | Disadvantage                                                                 |
| ----------------- | ---------------------------------- | ---------------------------------------------------------------------------- |
| MongoDB Atlas     | Managed operations and persistence | External network dependency                                                  |
| StatefulSet + PVC | Kubernetes-native control          | Storage, backup, and replication management remain the user's responsibility |
| Temporary MongoDB | Simple for CI/testing              | Not suitable for production data                                             |

Therefore, Atlas was used for the application deployment, while an ephemeral MongoDB instance was used for CI validation. `k8s/ci-mongodb.yaml` is only intended for CI/testing.

---

## 6. Helm or Manifest Management

If you used Helm, explain why you selected it and what problem it solves in this project.

Describe its advantages and the additional complexity it introduces compared with alternatives such as plain Kubernetes manifests or Kustomize.

If you did not use Helm, explain the method you selected and the reason for your choice.

**Answer:**

The application's own Kubernetes resources are managed using Kustomize with a shared base and environment-specific overlays.

Shared resources are kept under `k8s/eks/`, while environment-specific differences are defined under `k8s/overlays/dev`, `k8s/overlays/test`, and `k8s/overlays/prod`.

Kustomize was selected because it allows the same Kubernetes resources to be managed across environments without introducing the additional templating complexity of a Helm chart. Backend and frontend CPU request values differ by environment, while memory requests are kept at `32Mi` because of the capacity of the single `t3.small` worker node.

Helm is used for third-party Kubernetes dependencies rather than the application's own workloads. Envoy Gateway is installed using its Helm chart.

Therefore:

```text
Application Kubernetes resources → Kustomize

Envoy Gateway                   → Helm
```

Plain manifests are simpler to read and troubleshoot, but environment-specific configuration can lead to more duplication and manual changes. Helm provides stronger templating and package/version management, but a Helm chart was not necessary for the application's own resources at this project scale.

Kustomize structure: `k8s/eks/`, `k8s/overlays/`

---

## 7. Kubernetes Service Types

Which criteria did you use to select Kubernetes Service types?

For each service, explain why you chose `ClusterIP`, `NodePort`, `LoadBalancer`, `ExternalName`, or a headless Service. State which services should be accessible from outside the cluster and how you prevented unnecessary external exposure.

**Answer:**

Service types were designed around **minimum external exposure (least exposure) and centralized traffic management**.

`ClusterIP` is used for the frontend and backend:

```text
frontend-service → ClusterIP :80
backend-service  → ClusterIP :5050
```

The frontend and backend do not need to be directly exposed to the internet, so NodePort and separate LoadBalancer Services were not used. External traffic enters through a single path:

```text
AWS Load Balancer
       ↓
Envoy Gateway
       ↓
HTTPRoute
       ↓
Services
```

Headless or ExternalName Services were also unnecessary because the application does not require custom Pod DNS discovery or external service proxying.

This prevents the backend from being directly exposed through NodePort or an additional LoadBalancer.

Manifests: `k8s/` and `k8s/eks/`

---

## 8. Kubernetes Workload Types

Which criteria did you use to select workload types for the application components?

Explain why you used `Deployment`, `StatefulSet`, `Job`, `CronJob`, or another workload type for the frontend, backend, MongoDB, and ETL components.

Describe how you evaluated the following:

- Stateless or stateful behavior
- Persistent-storage requirements
- Pod identity and ordered-execution requirements
- Execution frequency
- Restart behavior
- Scalability requirements

**Answer:**

- **Frontend → `Deployment`:** It is a stateless web workload and does not require persistent storage, a unique Pod identity, or ordered execution. It supports rolling updates and replica management. Liveness/readiness probes and CPU/memory resource requests/limits are defined.
- **Backend → `Deployment`:** It is a stateless REST API; persistent data is stored in MongoDB Atlas. It does not require a dedicated Pod identity or ordered execution and can be scaled horizontally. Liveness/readiness probes are defined on `/api/healthcheck/`, together with CPU/memory resource requests/limits. A controlled `RollingUpdate` strategy uses `maxSurge: 1` and `maxUnavailable: 0`.
- **MongoDB → MongoDB Atlas:** MongoDB Atlas is used in the normal application deployment, so a Kubernetes `StatefulSet` is not required. The MongoDB instance used in CI is only an ephemeral test workload.
- **ETL → `CronJob`:** It is a periodic workload that runs hourly. Each execution creates a separate `Job`. Overlapping executions are prevented with `Forbid`, and failed executions are retried.

```text
0 * * * *
```

These workload decisions were based on stateless/stateful behavior, persistence requirements, Pod identity and ordering needs, execution frequency, restart behavior, resource usage, and scalability.

---

## 9. Configuration and Secret Management

How did you manage application configuration and secrets?

When a secret value is changed or rotated, how would you ensure that the application securely starts using the new value?

**Answer:**

Secrets are not hardcoded into source code or Docker images.

For local Kubernetes deployment, `setup-k8s.ps1` creates Kubernetes Secret resources from `.env` values. For AWS EKS deployment, values are transferred from GitHub Actions Secrets to Kubernetes Secrets.

Important values include `ATLAS_URI`, `GITHUB_TOKEN`, and `MONGODB_URI`.

When a Secret changes, existing environment variables inside running Pods do not change automatically, so the workload must be rolled out with new Pods. In production, a centralized secret manager can be used for controlled secret rotation.

---

## 10. MongoDB Availability Failure

If MongoDB becomes unavailable, how will the backend application, readiness/liveness checks, and user requests behave?

What measures did you take, or would you take, to reduce user impact and allow the service to recover in a controlled manner?

**Answer:**

The backend establishes the MongoDB connection during startup and fails fast if the connection cannot be established.

The existing `/api/healthcheck/` endpoint verifies that the HTTP process is responsive and is used as the readiness/liveness probe in the backend Deployment; it does not directly check the MongoDB dependency.

In production, I would separate the readiness probe so that it checks required dependencies including MongoDB. This allows a Pod without database access to be removed from serving new user traffic.

---

## 11. Faulty Deployment and Rollback

How would you detect a faulty deployment?

Which method would you use to roll it back, and how would you verify that the previous working version has been restored safely?

**Answer:**

First, I would inspect Pod, event, and log status:

```powershell
kubectl get pods -n devops-case
kubectl describe pod <pod> -n devops-case
kubectl logs <pod> -n devops-case
kubectl get events -n devops-case
```

Then I would inspect Deployment history:

```powershell
kubectl rollout history deployment/backend -n devops-case
kubectl rollout history deployment/frontend -n devops-case
```

and roll back to the previous version when necessary:

```powershell
kubectl rollout undo deployment/backend -n devops-case
kubectl rollout undo deployment/frontend -n devops-case
```

After the rollback, rollout status, backend healthcheck, and frontend access are verified again.

The backend `RollingUpdate` configuration ensures that the old Pod is not terminated until the new Pod has passed its readiness probe.

A failed rollout or healthcheck after CI/CD deployment causes the workflow to fail.

---

## 12. Scalability and Bottlenecks

If traffic increases tenfold, where do you expect the first bottleneck to occur?

Which components would you scale, and based on which metrics and thresholds? Explain how you would evaluate database connections, resource usage, and dependent services.

**Answer:**

With a tenfold traffic increase, I would first investigate backend CPU/memory usage and MongoDB connection/query load.

Important metrics include:

- CPU / memory
- request rate
- response latency
- error rate
- MongoDB connection usage
- query latency

Since the frontend and backend are stateless, their replica counts can be increased. If needed, HPA can be used for Pod-level scaling. When node capacity becomes insufficient, node autoscaling mechanisms such as Cluster Autoscaler or Karpenter can be considered.

MongoDB connection usage, query latency, and database resource consumption must also be monitored because increasing application replicas can increase database connection and query load.

---

## 13. Logging, Monitoring, and Alerting

Which logs, metrics, and alerts did you create?

During an incident, which dashboards, logs, metrics, or alert records would you examine first to diagnose the problem?

**Answer:**

Operational logs are maintained for the backend and ETL.

ETL logs show repository information, MongoDB connection status, update operations, document count, and successful completion.

Two critical alert scenarios were implemented:

- **ALERT-001:** ETL failure or no successful ETL execution within the expected time window
- **ALERT-002:** Frontend or backend health endpoint unavailable

These checks are implemented and tested through `scripts/check-alerts.ps1`.

The current case environment does not include a centralized Prometheus/Grafana dashboard. During an incident, I would first inspect the alert result, Kubernetes Pod/Job status, relevant logs, rollout status, and healthcheck results.

---

## 14. Security Risks

What are the three most important security risks in your solution?

Explain the controls you implemented, or would implement in production, to reduce these risks.

**Answer:**

Three important risks and the corresponding controls are:

1. **Secret exposure:** Secrets are managed through GitHub Actions Secrets / Kubernetes Secrets and are not embedded in source code or images.
2. **Container and image security:** `runAsNonRoot`, `allowPrivilegeEscalation: false`, and `capabilities.drop: ALL` are used. Docker images are also scanned during CI with Trivy for OS package vulnerabilities, application dependencies, and embedded secrets. Under the current case configuration, scan findings are reported but do not automatically block deployment.
3. **Unnecessary external exposure:** Frontend and backend are kept as `ClusterIP` Services and external access is provided through Envoy Gateway.

GitHub Actions also uses OIDC for AWS access, IAM least privilege, and namespace-scoped Kubernetes RBAC.

---

## 15. Python ETL Record Update Behavior

When the Python ETL receives the same repository information again, how does it find and update the existing record?

Which field did you use as the unique record key, and which screenshot or output demonstrates that no duplicate was created?

**Answer:**

The unique record key is:

```text
github_id
```

For this project:

```text
github_id = 1361100555
```

When the same repository is processed again, `update_one(..., upsert=True)` updates the existing document instead of creating a duplicate.

Evidence:

- `docs/screenshots/20-etl-first-load.png`
- `docs/screenshots/21-etl-update-without-duplicate.png`
- `docs/screenshots/22-eks-etl-success.png`

The ETL logs show the update operation and `MongoDB document count: 1`. They also show which fields were updated using `Updated fields: ...`.

---

## 16. Backup and Restore Approach

Which backup method and storage location did you choose for MongoDB?

What are your backup frequency, retention period, RPO, and RTO targets, and what was the actual restore duration you measured?

How would you verify that a backup is not corrupted or incomplete, and how would you change this approach in a real production environment?

Provide your runbook in `docs/backup-restore.md` and reference the evidence from `SUBMISSION_EVIDENCE.md`.

**Answer:**

MongoDB Atlas data is backed up in the production environment by the `mongodb-backup` Kubernetes CronJob running on AWS EKS.

Backup flow:

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

The backup archive is checked with `test -s` to ensure that it is not empty, and the uploaded S3 object is verified using `aws s3api head-object`.

The backup workload uses a dedicated `s3-backup` ServiceAccount, and the required S3 access is restricted through a least-privilege IAM policy. The backup containers run as non-root users with privilege escalation disabled.

No S3 Lifecycle-based automatic retention/deletion policy was implemented as part of this case. Therefore, no formal production retention period was defined.

Because the backup is scheduled daily, the theoretical maximum backup window is approximately 24 hours. This is not a formal production SLA; it reflects the backup frequency used in the case environment.

S3 upload success is automatically verified. In addition, a manual end-to-end restore test was performed in the local environment to verify that the backup is actually restorable.

The manual test used `scripts/backup-restore.ps1` and followed this flow:

```text
Record creation
      ↓
Backup
      ↓
Database deletion
      ↓
Verify data loss
      ↓
mongorestore
      ↓
UI + MongoDB verification
```

The test covered:

```text
records              → 1 document
github_repositories  → 1 document
Total                → 2 documents
```

Restore result:

```text
2 documents restored successfully.
0 documents failed to restore.
```

The measured `mongorestore` execution time was approximately **1.3 seconds**. This represents only the restore command execution time and should not be interpreted as an end-to-end production RTO.

No formal production RPO/RTO SLA was defined for the case environment. In production, these targets should be explicitly defined according to business requirements and supported by backup frequency, restore verification, retention, encryption, S3 Lifecycle, PITR, and regular DR drills.

Runbook: `docs/backup-restore.md`

Backup script and manual E2E test: `scripts/backup-restore.ps1`

Automatic backup manifests:

- `k8s/eks/backup-cronjob.yaml`
- `k8s/eks/backup-serviceaccount.yaml`

Evidence: the `Backup and Restore` section of `SUBMISSION_EVIDENCE.md`.

- **Record creation 1:** `docs/screenshots/29-backup-record-created-01.png`
- **Record creation 2:** `docs/screenshots/30-backup-record-created-02.png`
- **Manual backup:** `docs/screenshots/31-backup-taken.png`
- **Collection or database deletion:** `docs/screenshots/32-collection-dropped.png`
- **Data loss verification (user interface):** `docs/screenshots/33-data-missing-after-drop-ui.png`
- **Data loss verification (database):** `docs/screenshots/34-data-missing-after-drop-database.png`
- **Restore from backup:** `docs/screenshots/35-restore-executed.png`
- **Restore verification (user interface):** `docs/screenshots/36-data-restored-verified-ui.png`
- **Restore verification (database 1):** `docs/screenshots/37-data-restored-verified-database-01.png`
- **Restore verification (database 2):** `docs/screenshots/38-data-restored-verified-database-02.png`

Automatic scheduled backup evidence:

`docs/screenshots/47-backup-cronjob-scheduled-success.png`

---

## Additional Notes

Use this section for any additional decisions, limitations, or future improvement steps that you would like to highlight.

**Answer:**

In the final stage of the work, the application was moved to a real AWS EKS environment and automated cloud deployment was established through GitHub Actions.

The CI/CD flow uses GitHub OIDC with an AWS IAM Role, pushes images to Amazon ECR using commit SHA tags, and deploys the production environment through the `k8s/overlays/prod` Kustomize overlay.

Before deployment, the Kustomize output is validated with a server-side dry run, followed by application of the production overlay. Deployment images are then updated using commit SHA tags, and rollout and healthcheck verification are performed.

The core case requirements have been implemented and verified. In addition, the solution implements Kustomize-based environment management, controlled RollingUpdate and capacity-aware workload configuration, verified alert scenarios, Trivy-based image/dependency/secret scanning, and daily automated MongoDB backup to cluster-external Amazon S3.

The backup/restore implementation separates the automated production backup mechanism from the manual end-to-end restore test. The automated mechanism provides regular off-cluster backup storage, while the manual test verifies that the backup can actually be restored.

Further production improvements could include full IaC, advanced monitoring and autoscaling, centralized secret management, multi-node high availability, controlled release strategies, S3 Lifecycle/PITR, automated restore verification, and regular DR drills.
