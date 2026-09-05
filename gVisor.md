# gVisor (Beginner-friendly Guide)

This file explains what gVisor is and shows a simple, step-by-step way to run gVisor with CRI-O on Kubernetes. It's written for learners who are new to sandboxed runtimes.

## What is gVisor?

gVisor is an open-source "application kernel" from Google. Instead of letting containers use the host kernel directly, gVisor intercepts system calls and provides a smaller, safer kernel surface for workloads to run on.

Why that matters (short):
- Better isolation than a normal container runtime — reduces the risk if a container is compromised.
- Useful if you need to run untrusted or multi-tenant workloads on the same nodes.
- Lighter-weight than a full virtual machine while still improving security.

Key components (simple):
- The Sentry: a user-space kernel that intercepts and replies to system calls from the application.
- The Gofer: a separate helper process that manages filesystem and other host interactions safely.
- runsc: the gVisor runtime binary (OCI-compatible). Kubernetes uses this via a RuntimeClass.

---

## When to use gVisor

Use gVisor if you want stronger protection for containers that run untrusted code or if you need an extra layer of defense-in-depth on multi-tenant clusters. It is not required for every workload — it trades some compatibility and performance for improved isolation.

---

## Architecture overview (quick)

Pod/container -> runsc (gVisor) -> CRI-O -> Kubelet

runsc intercepts syscalls from the container and either handles or forwards them to the host via the Gofer. CRI-O is the Container Runtime Interface that Kubelet talks to.

---

## Prerequisites

- A Kubernetes node running CRI-O (worker node where you can install runsc).
- sudo access on the node(s) to install the runsc binary.
- kubectl configured to apply RuntimeClass and deploy pods.

---

## Quick setup (step-by-step)

1) Install runsc on each worker node

```bash
# Example: download and install runsc
# Replace the URL below with an official release URL from the gVisor project
URL=https://storage.googleapis.com/gvisor/releases
wget ${URL}/release/latest/runsc
wget ${URL}/release/latest/runsc.sha256
sha256sum -c runsc.sha256
chmod a+rx runsc
sudo mv runsc /usr/local/bin/
```

Notes:
- Use the official gVisor release page to get the correct download URL. The example above is illustrative.
- Verifying the checksum (sha256) ensures the binary wasn't corrupted or tampered with.

2) Tell CRI-O about the new runtime

Create a CRI-O config file (example location: /etc/crio/crio.conf.d/99-gvisor.conf) with this content:

```toml
# /etc/crio/crio.conf.d/99-gvisor.conf
[crio.runtime.runtimes.runsc]
runtime_path = "/usr/local/bin/runsc"
runtime_type = "oci"
runtime_root = "/run/runsc"
```

Then restart CRI-O:

```bash
sudo systemctl restart crio
```

If your CRI-O packages place configs in a different directory, drop the file into the correct directory. The important parts are the handler name (`runsc`) and the runtime_path.

3) Create a Kubernetes RuntimeClass

Save this to gvisor-runtimeclass.yaml:

```yaml
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: gvisor
handler: runsc # must match the name in crio.conf
```

Apply it:

```bash
kubectl apply -f gvisor-runtimeclass.yaml
```

Now Kubernetes knows about the gVisor runtime handler.

---

## Run a sandboxed pod

Create secure-pod.yaml:

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
    command: ["/bin/sh","-c","sleep 3600"]
```

Apply:

```bash
kubectl apply -f secure-pod.yaml
```

Why add a sleep command? It keeps the pod running so you can exec into it for checks.

---

## Verify gVisor is active

1) Check the pod is running:

```bash
kubectl get pods gvisor-test-pod
```

2) Exec into the pod and check kernel info:

```bash
kubectl exec -it gvisor-test-pod -- uname -a
```

Expected: you should see a kernel string that is different from the host kernel or otherwise shows gVisor-specific details. Example (varies by version):

```text
Linux gvisor-test-pod 4.4.0 #1 SMP Sun Jan 1 00:00:00 QEMU 2026 x86_64 Linux
```

If runsc isn't used, `uname -a` will show the node's real kernel version.

3) Check CRI-O runtime for the pod (on the node)

On the node, you can query CRI-O or inspect the container runtime metadata to confirm `runsc` was used. Exact commands vary by platform.

---

## Troubleshooting tips

- Pod stays Pending: ensure CRI-O was restarted after adding the runtime and that the runtime binary exists at the path you configured.
- Permission or exec errors when running runsc: verify the binary is executable (chmod +x) and readable by the runtime user.
- RuntimeClass rejected: confirm `handler` in RuntimeClass matches the name in the CRI-O configuration (case-sensitive).
- If kernel still shows the host kernel: the pod might be using the default runtime. Check that `runtimeClassName: gvisor` is present and spelled correctly.

---

## Notes & gotchas

- gVisor provides extra security but is not a drop-in replacement for all workloads — some syscalls or kernel features may behave differently, which can affect applications.
- Performance: some workloads may run slower under gVisor because syscalls are mediated by the Sentry and Gofer.
- Compatibility: test your application carefully before switching production workloads to gVisor.

---

## Helpful links

- Official gVisor: https://gvisor.dev/
- gVisor releases (binaries and checksums): https://gvisor.dev/docs/user_guide/install/

---

(Edited to simplify language, add practical tips, and make steps clearer for Kubernetes learners.)
