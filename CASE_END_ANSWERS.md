# CASE END ANSWERS

## Candidate Information

* **Full Name:** Tunahan Değirmencioğlu
* **Repository URL:** `https://github.com/dabbitz/devops-case-baykar.git`
* **Completion Date:** 10.09.2026
* **Target Environment Used:** Local Kubernetes (Docker Desktop Kubernetes)

---

## 1. Architecture and Request Flow

The system consists of a React + NGINX frontend, Node.js/Express backend, Python ETL, and MongoDB Atlas components. The frontend and backend run as Deployments on Kubernetes, while the ETL runs as an hourly CronJob. External HTTP access is provided through Envoy Gateway and HTTPRoute.

The flow of a user request is as follows:

```text
User / Browser
        ↓
Envoy Gateway
        ↓
HTTPRoute
        ↓
frontend-service
        ↓
React + NGINX
        ↓
/api/*
        ↓
backend-service
        ↓
Node.js / Express
        ↓
MongoDB Atlas
```

NGINX inside the frontend redirects `/api/` requests to `backend-service:5050` inside Kubernetes. The backend performs record CRUD operations in the `sample_training` database on MongoDB Atlas.

Independently of this flow, the Python ETL retrieves repository information from the GitHub API and performs insert/update operations in the MongoDB `github_repositories` collection using `github_id`.

The architecture diagram is available in `docs/architecture.md`.

---

## 2. Critical Findings and Prioritization

The three most critical issues identified in the starter project were:

1. **Frontend API address was hardcoded**

   * The frontend was directly dependent on `http://localhost:5050`.
   * This prevented deployment flexibility because different endpoints are required in containerized and Kubernetes environments.
   * It was changed to be managed through configuration.

2. **Insufficient input validation and ObjectId validation on the backend**

   * Invalid or missing fields could reach the database layer directly.
   * The issue in ObjectId validation could cause invalid requests to be handled incorrectly.
   * Server-side validation and ObjectId validation were added.

3. **Database connection failures were not handled in a controlled manner**

   * Initially, the application could continue running even if the MongoDB connection failed.
   * This could result in the service appearing healthy while database operations were failing.
   * The backend connection logic was changed to fail fast.

Prioritization was based on **production impact, reliability, deployment portability, and risk to data access**. In particular, a service that appears to be running while being unable to access its data layer was considered a higher priority.

The details are documented in `docs/findings.md`.

---

## 3. Items Left Out of Scope

The following topics were not implemented within the current case scope or were left at the production-design level:

* Terraform or another full IaC solution was not used. Kubernetes manifests were considered sufficient for the scope of the case.
* An application Helm chart was not created. Manifest-based deployment was preferred because it has lower scope and introduces less additional complexity.
* A full monitoring stack such as Prometheus/Grafana was not deployed.
* HPA, PDB, and advanced autoscaling policies were not implemented.
* GitOps, canary, or blue/green deployment was not implemented.
* Production-level automated, off-site, and long-term backup storage was not configured.
* MongoDB was not deployed as a Kubernetes StatefulSet; MongoDB Atlas was used as the persistent production data layer.

The main reason for these decisions was to complete the core DevOps functions required by the case in a working and verifiable manner without introducing unnecessary operational complexity.

---

## 4. Target Environment Selection

**Local Kubernetes on Docker Desktop** was used as the development and validation environment. This allowed the Kubernetes manifests, Service/Deployment/CronJob configurations, Envoy Gateway access, and container security settings to be tested directly in a Kubernetes environment.

In addition, a temporary **Kind Kubernetes cluster** is created on GitHub Actions for deployment validation in the CI/CD pipeline. This allows the deployment steps to be validated in the CI environment rather than depending only on the developer's machine.

In a real production environment, I would use:

* A persistent cloud- or Linux VM-based Kubernetes cluster,
* Persistent and accessible ingress/gateway infrastructure,
* Managed MongoDB / MongoDB Atlas,
* TLS and domain management,
* Centralized secret management,
* Monitoring and alerting infrastructure,
* A persistent container registry,
* Automated backup and off-site retention

The current GitHub Actions deployment is intended for validation in a temporary Kind cluster and does not replace a persistent production Kubernetes cluster.

---

## 5. MongoDB Approach

MongoDB is kept on **MongoDB Atlas** in the normal application deployment. This keeps the database separate from the Kubernetes workloads and allows persistent database operations to be handled by a managed service.

The main alternatives considered were:

| Approach                     | Advantage                                                                     | Disadvantage                                                                           |
| ---------------------------- | ----------------------------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| MongoDB Atlas                | Managed backup, operations, and persistent storage; independent of Kubernetes | External network dependency and access/allowlist management are required               |
| Kubernetes StatefulSet + PVC | Full control within the cluster and a Kubernetes-native architecture          | Storage, backup, replication, and database operations remain the user's responsibility |
| Temporary MongoDB Deployment | Simple for CI/testing                                                         | Not suitable for persistent data or production use                                     |

Therefore, Atlas was selected for normal production-like operation, while a temporary MongoDB Deployment was selected for the CI/CD environment to avoid external IP allowlist issues.

`k8s/ci-mongodb.yaml` is used only for the ephemeral CI/test environment.

---

## 6. Helm or Manifest Management

The application's own Kubernetes workloads are managed using plain manifest files.

For example:

```text
k8s/
├── namespace.yaml
├── backend-deployment.yaml
├── backend-service.yaml
├── frontend-deployment.yaml
├── frontend-service.yaml
├── etl-cronjob.yaml
└── ci-mongodb.yaml
```

Plain manifests were preferred for this case because the number of workloads is small and there are not enough environment/variant differences to justify chart templating.

Helm is used for **Envoy Gateway installation**. This allows a ready-made and complex third-party Kubernetes component to be installed through its official Helm chart instead of manually managing a large number of resources.

The advantages of Helm are reusable packaging, versioning, and dependency management. Its disadvantage is that it introduces additional templating and configuration complexity for a small and relatively static application.

Therefore:

* **Own application:** plain manifests
* **Third-party Gateway:** Helm

was the selected approach.

---

## 7. Kubernetes Service Types

The frontend and backend Services in the application are defined as `ClusterIP`.

### Backend

`backend-service`:

```text
type: ClusterIP
port: 5050
```

The backend does not need to be directly accessible from outside the cluster. The frontend accesses the backend through the Kubernetes internal network.

### Frontend

`frontend-service`:

```text
type: ClusterIP
port: 80
```

Instead of exposing the frontend directly as a NodePort or LoadBalancer, external HTTP traffic is received through Envoy Gateway.

### External access

External access follows:

```text
Internet / Browser
        ↓
Envoy Gateway
        ↓
HTTPRoute
        ↓
frontend-service
```

Therefore, NodePort and LoadBalancer were not used, reducing unnecessary direct external exposure.

No Kubernetes Service is used for MongoDB; MongoDB Atlas is used as the external managed service in the normal deployment.

---

## 8. Kubernetes Workload Types

### Frontend

The frontend is a stateless web workload. Because user data is not stored on the Pod filesystem, a `Deployment` was used.

Advantages:

* Replicas can be increased.
* Recreated Pods are not expected to cause data loss.
* Rolling updates are supported.

### Backend

The backend is also a stateless REST API, so a `Deployment` was used.

Persistent backend data is stored in MongoDB rather than inside the container.

### MongoDB

MongoDB is not run inside Kubernetes in the normal application deployment. Since MongoDB Atlas is used, StatefulSet and PVC management are separated from the application cluster.

The MongoDB used in the CI/CD pipeline is only a temporary test environment and does not contain persistent production data.

### ETL

The ETL is a periodic workload, so a `CronJob` was used:

```text
0 * * * *
```

This causes the ETL to run at the beginning of every hour.

Using a Deployment for the ETL would require a continuously running Pod and would therefore consume resources unnecessarily. CronJob also allows Kubernetes to use the Job retry mechanism when an execution fails.

In addition:

```text
concurrencyPolicy: Forbid
backoffLimit: 2
restartPolicy: Never
successfulJobsHistoryLimit: 3
failedJobsHistoryLimit: 3
```

were configured.

---

## 9. Configuration and Secret Management

Sensitive information is not hardcoded in the source code.

Examples:

* MongoDB URI
* GitHub API token

Kubernetes Secret resources are used in the Kubernetes deployment. Non-sensitive configuration is provided through environment variables.

For example, the backend uses:

```text
ATLAS_URI
ALLOWED_ORIGIN
```

and the ETL uses:

```text
GITHUB_TOKEN
MONGODB_URI
```

among other values.

When a secret is changed, an old value injected into a running Pod as an environment variable does not automatically change inside the running process. Therefore, the safe approach is to update the Secret and restart/recreate the relevant Deployment/CronJob workload so that a new Pod receives the new value.

For production, centralized secret management and controlled rollout can be used for secret rotation.

---

## 10. MongoDB Availability Failure

In the current backend implementation, the MongoDB connection is established during startup. If the connection fails, the application fails fast and terminates the process.

This prevents an unhealthy backend from appearing to be operational without database access.

In the current system, the `/healthcheck/` endpoint verifies that the process can respond over HTTP. However, there is currently no separate readiness/liveness probe definition that directly verifies MongoDB dependency availability.

In a production environment, I would separate them as follows:

* **Liveness probe:** checks whether the process is running.
* **Readiness probe:** checks whether the backend can access required dependencies, including MongoDB.

If readiness is designed to fail when MongoDB is unavailable, Kubernetes can help prevent new user traffic from being routed to an unhealthy Pod. Database operations should also return controlled HTTP errors and generate application logs.

In this case, the current healthcheck endpoint is used to verify backend availability during CI/CD.

---

## 11. Faulty Deployment and Rollback

For faulty deployment investigation, I would first inspect:

```text
kubectl get pods -n devops-case
kubectl describe pod <pod> -n devops-case
kubectl logs <pod> -n devops-case
kubectl get events -n devops-case
```

to examine Pod status, container logs, and Kubernetes events.

Deployment rollout status is checked with:

```text
kubectl rollout status deployment/backend -n devops-case
kubectl rollout status deployment/frontend -n devops-case
```

For a faulty version, the previous ReplicaSet can be restored using:

```text
kubectl rollout undo deployment/backend -n devops-case
```

or the same method for the frontend.

After rollback:

```text
kubectl rollout status deployment/backend -n devops-case
```

is used to verify the rollout, followed by backend healthcheck and frontend endpoint tests.

In the CI/CD pipeline, if the deployment job's healthcheck stage fails, the pipeline also fails.

---

## 12. Scalability and Bottlenecks

If traffic increases tenfold, I would expect the first bottleneck to occur in backend resource usage, followed by MongoDB connections and database capacity.

I would first evaluate the following metrics:

* CPU usage
* Memory usage
* HTTP request rate
* Response latency
* HTTP error rate
* MongoDB connection usage
* MongoDB query latency

Because the backend is stateless, it can be horizontally scaled by increasing the number of replicas.

In production, HPA could be introduced if CPU and memory utilization remain above defined thresholds. However, scaling should not rely only on CPU; application metrics such as request rate and latency should also be considered.

The frontend is also stateless and can be scaled by increasing its replica count in a similar way.

On the MongoDB side, increasing the number of application replicas alone is not sufficient. The database connection load generated by the additional replicas, query performance, and database capacity must also be evaluated.

Therefore, scaling decisions should be based on application and database metrics together.

---

## 13. Logging, Monitoring, and Alerting

Operationally meaningful logs are present on the backend and ETL sides.

Backend examples:

```text
Connecting to MongoDB Atlas...
Server listening on port 5050
Database connection failed...
```

ETL examples:

```text
Fetching repository
Github repository received
Connecting to MongoDB
MongoDB connection successful
UPDATE: repository updated
MongoDB document count
ETL completed successfully
```

Kubernetes CronJob logs are used to track the ETL execution stages and whether the execution completed successfully or failed.

In addition, `scripts/check-alerts.ps1` contains two critical alert checks:

* **ALERT-001:** ETL failure or no successful ETL execution within the expected time window
* **ALERT-002:** Frontend or backend health endpoint unavailability

Both alerts were intentionally triggered and verified using the script's test mode.

During an incident, I would first inspect:

```text
1. Alert result
2. Kubernetes Pod / Job status
3. ETL or backend logs
4. Deployment rollout status
5. Backend healthcheck
6. Frontend endpoint
```

In a more advanced production environment, Prometheus/Grafana, centralized log collection, and real notification channels could be added.

---

## 14. Security Risks

### 1. Secret / credential exposure

Exposing sensitive information such as the MongoDB URI or GitHub API token in source code or images would be a serious risk.

Controls:

* Secret information is provided through environment variables / Kubernetes Secrets.
* `.env` and similar secret files are included in `.gitignore`.
* Secret values are not written into Docker images.

A centralized secret management solution can be used in production.

### 2. Running containers as root

A compromised root container could increase the potential impact of an attack inside the container.

Therefore, the workloads use:

```yaml
runAsNonRoot: true
allowPrivilegeEscalation: false
capabilities:
  drop:
    - ALL
```

The container users were verified as:

```text
Backend  → node / UID 1000
Frontend → nginx / UID 101
ETL      → appuser / UID 10001
```

### 3. Unnecessary external network exposure

Exposing the backend directly through a NodePort or LoadBalancer could increase the attack surface.

Therefore, the frontend and backend Services use `ClusterIP`, and external access is restricted through Envoy Gateway.

---

## 15. Python ETL Update Approach

The ETL uses the GitHub repository ID as the unique record key.

Field used:

```text
github_id
```

For example, the repository ID is:

```text
1361100555
```

When the same repository is processed again, the existing record is updated using `github_id` instead of creating a new MongoDB document.

The actual execution produced:

```text
UPDATE: repository updated (github_id=1361100555)
MongoDB document count: 1
ETL completed successfully.
```

This evidence is provided in `docs/screenshots/13-etl-update-without-duplicate.png`.

---

## 16. Backup and Restore Approach

MongoDB Database Tools `mongodump` was used for backup.

Backup:

```text
MongoDB Atlas
      ↓
mongodump
      ↓
backups/sample-training-backup
```

was the selected backup flow.

The entire `sample_training` database was backed up during the backup scenario.

In the actual test:

```text
sample_training.records               → 1 document
sample_training.github_repositories   → 1 document
Total                                 → 2 documents
```

were backed up.

The database was then deleted, the loss of the data was verified both through the web interface and MongoDB Atlas, and the database was restored using `mongorestore`.

Restore result:

```text
2 document(s) restored successfully.
0 document(s) failed to restore.
```

was verified.

The measured restore command duration was approximately:

```text
1.3 seconds
```

This duration represents only the execution time of the restore command and is not considered an end-to-end production RTO.

### RPO / Retention

In the current case solution, backups are taken manually and there is no automated retention or off-site backup storage.

A production target of a maximum **24-hour data loss** could be used as an RPO target. However, the current manual approach does not guarantee this RPO.

Retention is also not currently enforced automatically.

### Backup verification

I would not consider a backup valid merely because the backup files were created.

For verification:

1. `mongodump` output and document count are checked.
2. The restore operation is tested against a clean target.
3. The `mongorestore` result and error count are checked.
4. Collection and document counts are verified.
5. The restored data is verified to be readable through the application.

These steps were performed against real MongoDB Atlas data as part of this case.

### Production approach

In production, I would use:

* Managed MongoDB backup/snapshots,
* Encrypted off-site/object storage,
* Automated retention policy,
* Access control,
* Periodic restore tests,
* Backup monitoring and alerting

The detailed backup/restore runbook is available in `docs/backup-restore.md`. Work evidence is provided in `TESLIM_KANITLARI.md` through screenshots 17–25.

---

## Additional Notes

Two advanced criteria were specifically implemented as part of the case.

First, two critical alert scenarios were defined and tested through `scripts/check-alerts.ps1`. This provides verifiable alert scenarios rather than only generating logs.

Second, container and Kubernetes security were hardened. The backend, frontend, and ETL containers run as non-root users; privilege escalation is disabled and all Linux capabilities are dropped.

The CI/CD deployment uses an ephemeral MongoDB inside a temporary Kind cluster to avoid depending on access to the production database. This prevents external network dependencies such as the GitHub Actions runner IP not being present in the MongoDB Atlas allowlist from blocking deployment validation.

This CI MongoDB is used only for testing/deployment validation and does not replace the MongoDB Atlas data layer used in the normal application deployment.
