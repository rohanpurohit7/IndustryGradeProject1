# Architecture and Delivery Model

## Application Architecture

```mermaid
flowchart TB
    U[Retail User] --> E[External Entry Point]
    E --> LB[LoadBalancer Service or Ingress]
    LB --> S[Kubernetes Service]
    S --> P1[Retail Pod Replica 1]
    S --> P2[Retail Pod Replica 2]
    S --> P3[Retail Pod Replica 3]
    D[Deployment] --> RS[ReplicaSet]
    RS --> P1
    RS --> P2
    RS --> P3
    P1 --> L[Centralized Logs]
    P2 --> L
    P3 --> L
    P1 --> M[Metrics and Health Checks]
    P2 --> M
    P3 --> M
```

## Kubernetes Object Relationship

A Kubernetes **Deployment** declares the desired application state and replica count. The Deployment manages a **ReplicaSet**, and the ReplicaSet maintains the requested number of **Pod replicas**. The Pods are the actual running application instances.

A **Service** selects those Pods by label and provides a stable DNS name and virtual IP. Traffic is load-balanced across healthy Pod replicas. For external access, the Service may use `type: LoadBalancer`, or an **Ingress** may route external traffic to the Service.

```mermaid
flowchart LR
    DEP[Deployment replicas: 3] --> RS[ReplicaSet]
    RS --> P1[Pod 1]
    RS --> P2[Pod 2]
    RS --> P3[Pod 3]
    CLIENT[Client] --> EXT[External Load Balancer or Ingress]
    EXT --> SVC[Service DNS / ClusterIP]
    SVC --> P1
    SVC --> P2
    SVC --> P3
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
    DEP --> RS[ReplicaSet]
    RS --> POD1[Retail Pod Replica 1]
    RS --> POD2[Retail Pod Replica 2]
    RS --> POD3[Retail Pod Replica 3]
    SVC[Service: stable DNS and virtual IP] --> POD1
    SVC --> POD2
    SVC --> POD3
    EXT[Ingress or LoadBalancer Service] --> SVC
    POD1 --> OBS[Logs and Metrics]
    POD2 --> OBS
    POD3 --> OBS
```

## Key Engineering Decisions

- Build artifacts should be reproducible and versioned.
- The container image should run as a non-root user.
- Secrets should be injected at runtime, never committed.
- Kubernetes requests, limits, liveness, and readiness probes should be defined.
- Deployments should use immutable image tags or digests.
- Services should select Pods through stable labels.
- External traffic should enter through an Ingress or a `LoadBalancer` Service.
- Rollback should be tested, not assumed.
