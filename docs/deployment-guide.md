# Production Deployment Guide

Step-by-step guide to deploy the Disaster Relief Platform from your local repo to **AKS via ArgoCD**.

---

## Prerequisites

| Tool | Purpose |
|------|---------|
| [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) | Manage Azure resources |
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | Interact with AKS cluster |
| [Git](https://git-scm.com/) | Version control |
| GitHub account | Hosting repo + Actions CI/CD |

> [!IMPORTANT]
> This guide assumes your **AKS cluster**, **Azure Container Registry (ACR)**, and **Resource Group** are already provisioned.

---

## Step 1 — Initialize Git & Push to GitHub

```powershell
cd "D:\Projects - ArgoCD"
git init
git add .
git commit -m "feat: initial scaffold — disaster relief platform"
```

Create a new GitHub repository, then:

```powershell
git remote add origin https://github.com/<YOUR_ORG>/<YOUR_REPO>.git
git branch -M main
git push -u origin main
```

---

## Step 2 — Configure GitHub Repository Secrets

Go to **GitHub → Your Repo → Settings → Secrets and variables → Actions** and add:

### `ACR_NAME`
Your Azure Container Registry name (just the name, not the full URL).

```
myacrname
```

### `AZURE_CREDENTIALS`
Generate a service principal with push access to ACR:

```bash
az ad sp create-for-rbac \
  --name "github-actions-disaster-relief" \
  --role contributor \
  --scopes /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP> \
  --sdk-auth
```

Copy the **entire JSON output** and paste it as the `AZURE_CREDENTIALS` secret value.

---

## Step 3 — Update ArgoCD Application Manifest

Edit `argocd-app.yaml` in the repo root — replace the placeholder repo URL:

```yaml
source:
  repoURL: https://github.com/<YOUR_ORG>/<YOUR_REPO>.git   # ← your actual URL
  targetRevision: main
  path: kube
```

Commit and push:

```powershell
git add argocd-app.yaml
git commit -m "chore: set ArgoCD repo URL"
git push
```

---

## Step 4 — Change the PostgreSQL Password

Edit `kube/postgres-statefulset.yaml` and replace the default password:

```yaml
stringData:
  POSTGRES_PASSWORD: <YOUR-STRONG-PASSWORD>   # ← change this
```

> [!CAUTION]
> For production, consider using **Azure Key Vault** with the **Secrets Store CSI Driver** or **Sealed Secrets** instead of storing passwords in Git.

Commit and push:

```powershell
git add kube/postgres-statefulset.yaml
git commit -m "chore: update postgres secret"
git push
```

---

## Step 5 — Connect to Your AKS Cluster

```bash
# Login to Azure
az login

# Get AKS credentials
az aks get-credentials \
  --resource-group <RESOURCE_GROUP> \
  --name <AKS_CLUSTER_NAME>

# Verify connection
kubectl get nodes
```

---

## Step 6 — Install ArgoCD on AKS

```bash
# Create namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for pods to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server \
  -n argocd --timeout=120s
```

### Access the ArgoCD UI

```bash
# Port-forward the ArgoCD server
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Open **https://localhost:8080** in your browser.

### Get the initial admin password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

Login with username `admin` and the password above.

---

## Step 7 — Register Your Git Repository with ArgoCD

If your repo is **private**, register it in ArgoCD:

```bash
# Install ArgoCD CLI (optional — you can also do this in the UI)
# Then:
argocd repo add https://github.com/<YOUR_ORG>/<YOUR_REPO>.git \
  --username <GITHUB_USERNAME> \
  --password <GITHUB_PAT>
```

For **public repos**, this step is not needed.

---

## Step 8 — Deploy the ArgoCD Application

```bash
kubectl apply -f argocd-app.yaml
```

This tells ArgoCD to:
1. Watch the `kube/` directory in your repo
2. Auto-sync any changes to the `default` namespace
3. Prune removed resources and self-heal manual changes

### Verify in ArgoCD UI

Open **https://localhost:8080** → you should see **disaster-relief-platform** syncing.

---

## Step 9 — Trigger the First CI/CD Build

Make any small change and push to `main`:

```powershell
git commit --allow-empty -m "ci: trigger initial build"
git push
```

**What happens automatically:**
1. GitHub Actions builds 4 Docker images
2. Pushes them to ACR tagged with the commit SHA
3. Updates `kube/*.yaml` with the new image tags
4. Commits and pushes the updated manifests
5. ArgoCD detects the change and deploys to AKS

Monitor the pipeline at **GitHub → Actions** tab.

---

## Step 10 — Expose the Frontend Externally

### Option A: LoadBalancer Service

Edit `kube/frontend-deployment.yaml` and change the Service type:

```yaml
spec:
  type: LoadBalancer    # ← change from ClusterIP
  selector:
    app.kubernetes.io/name: frontend
  ports:
    - port: 80
      targetPort: 80
```

### Option B: NGINX Ingress Controller (recommended)

```bash
# Install NGINX Ingress
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace
```

Then create `kube/ingress.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: frontend-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: frontend-service
                port:
                  number: 80
```

Commit, push, and ArgoCD will apply it.

---

## Step 11 — Verify the Deployment

```bash
# Check all pods are running
kubectl get pods

# Check services
kubectl get svc

# Check the frontend external IP (if using LoadBalancer)
kubectl get svc frontend-service -w

# Check ArgoCD sync status
kubectl get application disaster-relief-platform -n argocd
```

---

## Step 12 — Set Up Monitoring (Optional)

### Deploy Loki (for Promtail to send logs to)

```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm install loki grafana/loki-stack \
  --namespace monitoring --create-namespace \
  --set promtail.enabled=false   # we have our own Promtail
```

### Deploy Prometheus

```bash
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace
```

The Prometheus annotations on your Deployments will be automatically detected.

### Apply the Promtail DaemonSet

```bash
kubectl apply -f monitoring/promtail-daemonset.yaml
```

---

## Quick Reference — Full Deployment Flow

```
1. git push to main
        ↓
2. GitHub Actions builds & pushes images to ACR
        ↓
3. GitHub Actions updates kube/ manifests with new image tags
        ↓
4. GitHub Actions commits & pushes updated YAML
        ↓
5. ArgoCD detects change & auto-syncs
        ↓
6. AKS performs rolling update
        ↓
7. ✅ Live on your cluster!
```
