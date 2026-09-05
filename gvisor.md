## What is a gVisor Sandbox?

A **gVisor** sandbox is an open-source application kernel developed by Google that provides a secure isolation layer for Kubernetes pods. Unlike standard container runtimes (`runc`) that share the host machine's kernel, gVisor implements a substantial portion of the Linux system-call interface in user space.

### Key Components
* **The Sentry:** An unprivileged user-space kernel that intercepts and responds to application system calls.
* **The Gofer:** A separate, isolated process that safely manages and restricts file system interactions.
* **`runsc` Runtime:** The Open Container Initiative (OCI)-compliant binary used as a drop-in replacement for standard container runtimes via Kubernetes `RuntimeClass`.

### Why Use It in Kubernetes?
* **Enhanced Security:** Adds a strong defense-in-depth barrier against container escapes and privilege escalations.
* **Multi-Tenancy:** Safely run untrusted, multi-tenant, or model-generated code on shared cluster nodes.
* **Lightweight Isolation:** Delivers virtual-machine-level isolation with the fast startup times and low resource overhead of a traditional container.
  
