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

# Kubernetes Sandbox with gVisor and CRI-O

This guide explains how to configure and run **gVisor** as a secure container sandbox runtime in a Kubernetes cluster using **CRI-O** as the Container Runtime Interface.

## Overview

By default, containers share the host OS kernel. If a container is compromised, the host is at risk. **gVisor** addresses this by providing an application kernel (written in Go) called `runsc`. It intercepts application system calls, acting as a secure sandbox boundary between the container and the host kernel.

---

## Architecture Flow

[ Pod / Container ]
│ (System Calls)
▼
[ runsc ]  <-- gVisor Sandbox (Intercepts & filters syscalls)
│
▼
[ CRI-O ] <-- Container Runtime Interface
│
▼
[ Kubelet ] <-- Kubernetes Node Agent

---

## Step-by-Step Configuration

### 1. Install gVisor on the Node
First, download and install the `runsc` binary on your Kubernetes worker nodes.

```bash
# Download the binaries
URL=https://googleapis.com
wget ${URL}/runsc ${URL}/runsc.sha256
sha256sum -c runsc.sha256

# Install runsc
chmod a+rx runsc
sudo mv runsc /usr/local/bin/
```

### 2. Configure CRI-O to Use gVisor
You need to tell CRI-O that a new runtime handler named `runsc` is available. 

Add a new runtime table to your CRI-O configuration file (usually located at `/etc/crio/crio.conf` or inside `/etc/crio/crio.conf.d/`).

```toml
# /etc/crio/crio.conf.d/99-gvisor.conf

[crio.runtime.runtimes.runsc]
runtime_path = "/usr/local/bin/runsc"
runtime_type = "oci"
runtime_root = "/run/runsc"
```

Restart the CRI-O service to apply the changes:

```bash
sudo systemctl restart crio
```

### 3. Create a Kubernetes RuntimeClass
Kubernetes needs to be aware of the new sandbox capability. Define a `RuntimeClass` object that maps to the CRI-O handler.

Create a file named `gvisor-runtimeclass.yaml`:

```yaml
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: gvisor
handler: runsc # This must match the name defined in crio.conf
```

Apply it to your cluster:

```bash
kubectl apply -f gvisor-runtimeclass.yaml
```

---

## Verifying the Setup

### 1. Deploy a Sandboxed Pod
To run a pod inside the gVisor sandbox, reference the `runtimeClassName: gvisor` in the Pod specification.

Create a file named `secure-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: gvisor-test-pod
spec:
  runtimeClassName: gvisor
  containers:
  - name: nginx
    image: nginx:alpine
```

Apply the configuration:

```bash
kubectl apply -f secure-pod.yaml
```

### 2. Verify Kernel Isolation
An easy way to verify that gVisor is working is to check the kernel version inside the container. Standard containers will display the host node's Linux kernel. A gVisor sandbox will display its own custom kernel version (usually `Linux version 4.4.0` or similar, mimicking a specific kernel version).

Run the following command:

```bash
kubectl exec gvisor-test-pod -- uname -a
```

**Expected Output:**
If gVisor is working correctly, the output will explicitly mention `gVisor` or display a distinct, static kernel signature rather than your host machine's actual kernel signature.
```text
Linux gvisor-test-pod 4.4.0 #1 SMP Sun Jan 1 00:00:00 QEMU 2026 x86_64 Linux
```
