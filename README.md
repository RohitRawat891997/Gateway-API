# Kubernetes + Envoy Gateway + cert-manager Setup

This guide walks through deploying a sample UI, exposing it via **Envoy Gateway** (using the Kubernetes Gateway API), and securing it with a TLS certificate from **Let's Encrypt** via **cert-manager**.

## Table of Contents

- [Prerequisites](#prerequisites)
- [1. Deploy a Test UI Pod](#1-deploy-a-test-ui-pod)
- [2. Install Helm](#2-install-helm)
- [3. Install cert-manager](#3-install-cert-manager)
- [4. Create a ClusterIssuer](#4-create-a-clusterissuer)
- [5. Install Envoy Gateway](#5-install-envoy-gateway)
- [6. Create a GatewayClass](#6-create-a-gatewayclass)
- [7. Create the Gateway](#7-create-the-gateway)
- [8. Request a TLS Certificate](#8-request-a-tls-certificate)
- [9. Create an HTTPRoute](#9-create-an-httproute)
- [10. Verify the Certificate](#10-verify-the-certificate)

---

## Prerequisites

- A running Kubernetes cluster with `kubectl` access
- A domain name you control (this guide uses `ui.example.com` as an example)

---

## 1. Deploy a Test UI Pod

Create a namespace, run a sample `nginx` pod, and expose it as a service:

```bash
kubectl create ns ui
kubectl run ui --image=nginx -n ui
kubectl expose pod ui --port=80 -n ui
```

Port-forward the Envoy service to your local machine to test access:

```bash
kubectl port-forward -n ui svc/<envoy-service-name> 8080:80
```

Add a local DNS entry so `ui.example.com` resolves to your machine:

```bash
sudo vim /etc/hosts
```

Add the following line, then save and quit (`:wq`):

```
127.0.0.1 ui.example.com
```

Test the connection:

```bash
curl -H "Host: ui.example.com" http://127.0.0.1:8080/
```

---

## 2. Install Helm

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

---

## 3. Install cert-manager

Add the Jetstack Helm repo and install cert-manager with Gateway API support enabled:

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update

helm upgrade --install cert-manager cert-manager \
  --repo https://charts.jetstack.io \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true \
  --set config.enableGatewayAPI=true
```

Verify the pods are running:

```bash
kubectl get pods -n cert-manager
```

---

## 4. Create a ClusterIssuer

This tells cert-manager how to request certificates from Let's Encrypt using the `HTTP-01` challenge routed through the Gateway API.

Create `clusterissuer.yml`:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    email: rohitrawat891997@gmail.com
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-prod-account-key
    solvers:
    - http01:
        gatewayHTTPRoute:
          parentRefs:
          - name: app-gateway
            namespace: app
```

Apply it and confirm it was created:

```bash
kubectl apply -f clusterissuer.yml
kubectl get clusterissuer
```

---

## 5. Install Envoy Gateway

```bash
helm install eg oci://docker.io/envoyproxy/gateway-helm \
  --version v1.9.1 \
  -n envoy-gateway-system \
  --create-namespace
```

Wait for the controller deployment to become available:

```bash
kubectl wait --timeout=5m -n envoy-gateway-system deployment/envoy-gateway --for=condition=Available
```

Verify the pods:

```bash
kubectl get pods -n envoy-gateway-system
```

---

## 6. Create a GatewayClass

Create `gatewayclass.yml`:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: eg-gatewayclass
spec:
  controllerName: gateway.envoyproxy.io/gatewayclass-controller
```

Apply it:

```bash
kubectl apply -f gatewayclass.yml
```

---

## 7. Create the Gateway

Create `gateway.yml`. This links the `GatewayClass` to the Envoy infrastructure and configures an HTTPS listener with TLS termination:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: eg-gateway
  namespace: envoy-gateway-system
spec:
  gatewayClassName: eg-gatewayclass
  listeners:
  - name: https
    protocol: HTTPS
    port: 443
    hostname: "ui.example.com"
    tls:
      mode: Terminate
      certificateRefs:
      - name: ui-example-tls
    allowedRoutes:
      namespaces:
        from: All
```

Apply it:

```bash
kubectl apply -f gateway.yml
```

---

## 8. Request a TLS Certificate

Create `certificate.yml` to have cert-manager issue a certificate for `ui.example.com` via the `ClusterIssuer` created earlier:

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: ui-example-certificate
  namespace: app
spec:
  secretName: ui-example-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
  - ui.example.com
```

Apply it and watch the certificate status until it's `Ready`:

```bash
kubectl create -f certificate.yml
watch kubectl get certificate -n ui
```

Confirm the TLS secret was created:

```bash
kubectl get secret -n app
```

---

## 9. Create an HTTPRoute

Create `httproute.yml` to route traffic for `ui.example.com` and redirect all incoming HTTP requests to HTTPS:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: ui-route
  namespace: ui
spec:
  parentRefs:
  - name: eg-gateway
  hostnames:
  - "ui.example.com"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    filters:
    - type: RequestRedirect
      requestRedirect:
        scheme: https
        statusCode: 301
```

Apply it:

```bash
kubectl apply -f httproute.yml
```

---

## 10. Verify the Certificate

Check the full status/details of the certificate, including any issuance errors:

```bash
kubectl describe certificate ui-example-certificate -n app
```

---

## Notes

- Replace `ui.example.com`, namespaces (`ui`, `app`), and the ACME email with values specific to your environment.
- The `<envoy-service-name>` placeholder in the port-forward command should be replaced with the actual Envoy Gateway service name (find it with `kubectl get svc -n envoy-gateway-system`).
