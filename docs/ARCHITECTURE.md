# Architecture and Delivery Model

## Application Architecture

```mermaid
flowchart TB
    U[Retail User] --> W[Java Web UI / JSP]
    W --> A[Application Logic]
    A --> C[Container Runtime]
    C --> K[Kubernetes Deployment]
    K --> S[Kubernetes Service]
    S --> I[Ingress or Load Balancer]
    K --> L[Centralized Logs]
    K --> M[Metrics and Health Checks]
```

## DevSecOps Lifecycle

```mermaid
flowchart TD
    A[Plan] --> B[Code]
    B --> C[Build]
    C --> D[Test]
    D --> E[Security Gate]
    E --> F[Package]
    F --> G[Containerize]
    G --> H[Scan Image]
    H --> I[Deploy]
    I --> J[Verify]
    J --> K[Monitor]
    K --> A
```

## Security Decision Flow

```mermaid
flowchart TD
    A[Pipeline Starts] --> B{Secrets Found?}
    B -- Yes --> X[Fail Build and Rotate Secret]
    B -- No --> C{Critical SAST or SCA Findings?}
    C -- Yes --> Y[Fail Build and Remediate]
    C -- No --> D{Container Critical Findings?}
    D -- Yes --> Z[Block Registry Promotion]
    D -- No --> E{Manifest Policy Violations?}
    E -- Yes --> P[Reject Deployment]
    E -- No --> F[Deploy to Test Namespace]
    F --> G{Smoke and Health Checks Pass?}
    G -- No --> R[Rollback]
    G -- Yes --> H[Promote Release]
```

## Kubernetes Deployment View

```mermaid
flowchart LR
    CI[CI Pipeline] --> REG[Container Registry]
    REG --> DEP[Deployment]
    DEP --> POD1[Retail Pod 1]
    DEP --> POD2[Retail Pod 2]
    SVC[Kubernetes Service] --> POD1
    SVC --> POD2
    ING[Ingress] --> SVC
    POD1 --> OBS[Logs and Metrics]
    POD2 --> OBS
```

## Key Engineering Decisions

- Build artifacts should be reproducible and versioned.
- The container image should run as a non-root user.
- Secrets should be injected at runtime, never committed.
- Kubernetes requests, limits, liveness, and readiness probes should be defined.
- Deployments should use immutable image tags or digests.
- Rollback should be tested, not assumed.
