# CASE END ANSWERS

Answer all questions below by relating them directly to your implementation.

Answers should be concise, specific, and detailed enough to explain your technical decisions. Where appropriate, reference the relevant source file, manifest, pipeline step, or document path.

---

## Candidate Information

- **Full name:** Tunahan Değirmencioğlu
- **Repository URL:** `https://github.com/dabbitz/devops-case-baykar.git`
- **Completion date:** 11.09.2026
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

```text id="1w0s7k"
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
React    Node.js
+ NGINX  + Express
             ↓
        MongoDB Atlas
```

The frontend NGINX forwards `/api/` requests to `backend-service:5050`. The backend performs record CRUD operations in the `sample_training` database on MongoDB Atlas.

The ETL separately retrieves repository information from the GitHub API and performs an upsert on the `github_repositories` collection using `github_id`.

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

The core case requirements have been completed, while some production-level features were left out of scope.

For example, full IaC with Terraform/OpenTofu, Prometheus/Grafana, HPA/PDB, GitOps, canary/blue-green deployment, automated off-site backup retention, and distributed tracing were not implemented.

At the same time, the solution was extended with AWS EKS, Amazon ECR, GitHub OIDC, IAM, EKS RBAC, Helm-based Envoy Gateway, non-root container hardening, and verifiable alert checks.

These omitted areas can be added as separate scaling, observability, and disaster recovery layers in a production environment when required.

---

## 4. Target Environment Selection

Why did you choose a cloud environment or a virtual machine? Which components or approaches would you use differently in a real production environment?

**Answer:**

AWS EKS was selected because the application is container-based and the frontend, backend, and periodic ETL workloads were intended to run on managed Kubernetes in a real cloud environment.

This allowed Amazon ECR, AWS IAM, GitHub OIDC, EKS RBAC, Envoy Gateway, and the AWS Load Balancer to be used together.

In a production environment, I would additionally use Terraform/OpenTofu, HPA and node autoscaling, PDB/multi-node distribution, Prometheus/Grafana, centralized secret management, automated off-site backups, HTTPS/domain management, and controlled release strategies.

---

## 5. MongoDB Approach

Why did you choose your MongoDB deployment and service approach? Explain the alternatives you considered, along with their advantages, disadvantages, and operational trade-offs.

**Answer:**

MongoDB Atlas was used for the normal deployment. This separates database persistence and operations from the Kubernetes workloads.

Alternatives considered:

| Approach          | Advantage                          | Disadvantage                                                |
| ----------------- | ---------------------------------- | ----------------------------------------------------------- |
| MongoDB Atlas     | Managed operations and persistence | External network dependency                                 |
| StatefulSet + PVC | Kubernetes-native control          | Storage/backup/replication remain the user's responsibility |
| Temporary MongoDB | Simple for CI/testing              | Not suitable for production data                            |

Therefore, Atlas was used for the application deployment, while an ephemeral MongoDB instance was used for CI validation. `k8s/ci-mongodb.yaml` is only intended for CI/testing.

---

## 6. Helm or Manifest Management

If you used Helm, explain why you selected it and what problem it solves in this project.

Describe its advantages and the additional complexity it introduces compared with alternatives such as plain Kubernetes manifests or Kustomize.

If you did not use Helm, explain the method you selected and the reason for your choice.

**Answer:**

The application's own Kubernetes resources are managed using plain manifest files. Since these resources do not require shared templating or multi-environment value management, direct manifest usage was preferred over creating a Helm chart.

Comparison and rationale:

- **Plain Manifests:** The easiest approach to read, understand, and troubleshoot. Since the project does not require multiple environments, the application's own resources are managed with plain YAML files.
- **Helm / Kustomize:** Provide templating, parameter management, and versioning. However, using them for the application's own manifests would introduce unnecessary complexity at the current project scale, so they were used only where they provide clear value, such as managing third-party dependencies.

Envoy Gateway is a third-party component consisting of multiple related Kubernetes resources, so it was installed using its official Helm chart.

Therefore:

```text
Application workloads  → Kubernetes manifests
Envoy Gateway          → Helm
```

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

Application components should not be directly exposed to the internet. Therefore, NodePort, which exposes node ports, and per-service LoadBalancer Services, which would create additional cloud load balancers outside the gateway path, were not used.

Headless or ExternalName Services were also unnecessary because there is no requirement for custom DNS-based Pod discovery or external service proxying. External traffic is routed through AWS Load Balancer → Envoy Gateway → HTTPRoute → Services.

This prevents the backend from being directly exposed through NodePort or LoadBalancer.

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

- **Frontend → `Deployment`:** It is a stateless web workload and does not require persistent storage, a unique Pod identity, or ordered execution. It supports replicas and rolling updates. Liveness/readiness probes and CPU/memory resource requests/limits are defined.
- **Backend → `Deployment`:** It is a stateless REST API; persistent data is stored in MongoDB. No unique Pod identity is required, and it can be horizontally scaled. Liveness/readiness probes using `/healthcheck/` and CPU/memory resource requests/limits are defined. `maxSurge: 0` and `maxUnavailable: 1` are used for controlled rolling updates in the single-node EKS environment.
- **MongoDB:** MongoDB Atlas is used in the normal deployment, so a Kubernetes `StatefulSet` is not required. The MongoDB instance used in CI is only an ephemeral test workload.
- **ETL → `CronJob`:** It is a periodic workload that runs hourly. Each execution creates a separate `Job`; overlapping executions are prevented with `Forbid`, failed executions are retried, and CPU/memory resource requests/limits are defined.

```text
0 * * * *
```

These workload decisions were considered with stateless/stateful operation, persistence requirements, Pod identity and ordering needs, execution frequency, restart behavior, resource usage, and scalability.

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

The existing `/healthcheck/` endpoint verifies that the HTTP process is responsive and is used as both the readiness and liveness probe in the backend Deployment; it does not directly check the MongoDB dependency.

In production, I would separate the readiness probe so that it checks required dependencies including MongoDB. This allows a Pod without database access to be removed from serving new user traffic.

The backend healthcheck is also verified after CI/CD deployment.

---

## 11. Faulty Deployment and Rollback

How would you detect a faulty deployment?

Which method would you use to roll it back, and how would you verify that the previous working version has been restored safely?

**Answer:**

First, I would inspect the Pod and event status using:

```powershell
kubectl get pods -n devops-case
kubectl describe pod <pod> -n devops-case
kubectl logs <pod> -n devops-case
kubectl get events -n devops-case
```

Then I would inspect the Deployment history:

```powershell
kubectl rollout history deployment/backend -n devops-case
kubectl rollout history deployment/frontend -n devops-case
```

and roll back to the previous version:

```powershell
kubectl rollout undo deployment/backend -n devops-case
kubectl rollout undo deployment/frontend -n devops-case
```

After the rollback, rollout status, backend healthcheck, and frontend access are verified again.

A failed healthcheck after CI/CD deployment causes the job to fail.

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

Since the frontend and backend are stateless, their replica counts can be increased. If needed, an HPA (Horizontal Pod Autoscaler) can be used for Pod-level scaling. When node capacity becomes insufficient, node autoscaling mechanisms such as Cluster Autoscaler or Karpenter can be used.

MongoDB connections and database load must also be considered because increasing replicas increases the potential database connection and query load.

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

During an incident, I would first inspect the alert result, Kubernetes Pod/Job status, relevant logs, rollout status, and healthcheck results.

---

## 14. Security Risks

What are the three most important security risks in your solution?

Explain the controls you implemented, or would implement in production, to reduce these risks.

**Answer:**

Three important risks and the corresponding controls are:

1. **Secret exposure:** Secrets are managed through GitHub Actions Secrets / Kubernetes Secrets and are not embedded in source code or images.
2. **Running containers as root:** `runAsNonRoot`, `allowPrivilegeEscalation: false`, and `capabilities.drop: ALL` are applied.
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

For example, the repository ID for this project is:

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

MongoDB Atlas data was backed up at the `sample_training` database level using `mongodump` and stored under `backups/sample-training-backup/`.

Test scope:

```text
records                 → 1 document
github_repositories     → 1 document
Total                   → 2 documents
```

The current case solution uses **manual backups**; no automated backup schedule or retention policy is implemented. A production target of **RPO ≤ 24 hours** can be defined. The measured restore command time was approximately **1.3 seconds**; this only represents the command execution time and is **not considered a production RTO**.

Restore validation included:

- deleting the database and verifying data loss,
- checking the `mongorestore` result and error count,
- verifying collection and document counts,
- confirming that the data could be read again through the application.

Restore result:

```text
2 documents restored successfully.
0 documents failed to restore.
```

In production, I would use automated and encrypted backups, defined retention, off-site/object storage, regular restore tests, and actual RPO/RTO monitoring.

Runbook: `docs/backup-restore.md`

Evidence: the backup/restore section of `SUBMISSION_EVIDENCE.md`:

- **Record creation 1:** `docs/screenshots/29-backup-record-created-01.png`
- **Record creation 2:** `docs/screenshots/30-backup-record-created-02.png`
- **Taking the backup (screenshot or terminal output):** `docs/screenshots/31-backup-taken.png`
- **Dropping the collection or database (screenshot or terminal output):** `docs/screenshots/32-collection-dropped.png`
- **Showing that the data is gone (interface screenshot):** `docs/screenshots/33-data-missing-after-drop-ui.png`
- **Showing that the data is gone (database output):** `docs/screenshots/34-data-missing-after-drop-database.png`
- **Restoring from the backup (screenshot or terminal output):** `docs/screenshots/35-restore-executed.png`
- **Verifying that the data is back (interface screenshot):** `docs/screenshots/36-data-restored-verified-ui.png`
- **Verifying that the data is back (database output (1)):** `docs/screenshots/37-data-restored-verified-database-01.png`
- **Verifying that the data is back (database output (2)):** `docs/screenshots/38-data-restored-verified-database-02.png`

---

## Additional Notes

Use this section for any additional decisions, limitations, or future improvement steps that you would like to highlight.

**Answer:**

In the final stage of the work, the application was moved from local Kubernetes validation to a real AWS EKS environment and automated cloud deployment was established through GitHub Actions.

The CI/CD flow uses GitHub OIDC with an AWS IAM Role, pushes images to Amazon ECR using commit SHA tags, and deploys the same versions to EKS.

Liveness/readiness probes, CPU/memory resource requests/limits, and a controlled rolling update configuration suitable for the single-node EKS environment have also been implemented and verified on the actual EKS environment.

The core requirements specified in the case have been implemented and verified. In addition, extra work has been completed in the areas of packaging/environment management and advanced observability.

The current solution has been completed to satisfy the case requirements. Further production improvements could include fully managed IaC, advanced monitoring and autoscaling, centralized secret management, and more advanced disaster recovery.
