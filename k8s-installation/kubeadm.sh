#!/bin/bash

set -e

KUBERNETES_VERSION="v1.35"
CRIO_VERSION="v1.35"

echo "========================================="
echo " Kubernetes + CRI-O Installation"
echo " Kubernetes: $KUBERNETES_VERSION"
echo " CRI-O:      $CRIO_VERSION"
echo "========================================="

# -----------------------------------------
# 1. Update system packages
# -----------------------------------------
echo
echo "[1/8] Updating APT packages..."
apt-get update -y

# -----------------------------------------
# 2. Install dependencies
# -----------------------------------------
echo
echo "[2/8] Installing required dependencies..."

DEBIAN_FRONTEND=noninteractive apt-get install -y \
    software-properties-common \
    curl \
    gpg \
    ca-certificates

# Create keyrings directory
mkdir -p /etc/apt/keyrings

# -----------------------------------------
# 3. Add Kubernetes repository
# -----------------------------------------
echo
echo "[3/8] Adding Kubernetes repository..."

curl -fsSL \
    "https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/Release.key" |
    gpg --dearmor --yes \
    -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/ /" |
    tee /etc/apt/sources.list.d/kubernetes.list > /dev/null

# -----------------------------------------
# 4. Add CRI-O repository
# -----------------------------------------
echo
echo "[4/8] Adding CRI-O repository..."

curl -fsSL \
    "https://download.opensuse.org/repositories/isv:/cri-o:/stable:/$CRIO_VERSION/deb/Release.key" |
    gpg --dearmor --yes \
    -o /etc/apt/keyrings/cri-o-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://download.opensuse.org/repositories/isv:/cri-o:/stable:/$CRIO_VERSION/deb/ /" |
    tee /etc/apt/sources.list.d/cri-o.list > /dev/null

# -----------------------------------------
# 5. Update repositories
# -----------------------------------------
echo
echo "[5/8] Updating APT repositories..."

apt-get update -y

# -----------------------------------------
# 6. Install Kubernetes + CRI-O
# -----------------------------------------
echo
echo "[6/8] Installing Kubernetes and CRI-O..."
echo "This may take a few minutes..."
echo

DEBIAN_FRONTEND=noninteractive apt-get install -y \
    cri-o \
    kubelet \
    kubeadm \
    kubectl

# -----------------------------------------
# 7. Configure CRI-O and Kubernetes
# -----------------------------------------
echo
echo "[7/8] Configuring CRI-O and Kubernetes..."

# Enable and start CRI-O
systemctl enable --now crio

# Disable swap
swapoff -a

# Disable swap permanently
sed -i '/[[:space:]]swap[[:space:]]/ s/^/#/' /etc/fstab

# Load kernel module
modprobe br_netfilter

# Make br_netfilter persistent
cat > /etc/modules-load.d/kubernetes.conf <<EOF
br_netfilter
EOF

# Kubernetes networking settings
cat > /etc/sysctl.d/kubernetes.conf <<EOF
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sysctl --system

# Enable kubelet
systemctl enable kubelet

# -----------------------------------------
# 8. Bootstrap Kubernetes cluster
# -----------------------------------------
echo
echo "[8/8] Initializing Kubernetes cluster..."
echo

kubeadm init --cri-socket=unix:///var/run/crio/crio.sock

echo
echo "========================================="
echo " Kubernetes cluster initialized!"
echo "========================================="
echo
echo "Next steps:"
echo
echo "mkdir -p \$HOME/.kube"
echo "sudo cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config"
echo "sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config"
echo
echo "Then verify:"
echo "kubectl get nodes"
echo
