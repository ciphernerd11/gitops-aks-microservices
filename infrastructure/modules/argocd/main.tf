terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "5.46.7"

  set {
    name  = "server.extraArgs"
    value = "{--insecure}"
  }
}

resource "kubernetes_manifest" "postgres_kv_sync" {
  manifest = {
    apiVersion = "secrets-store.csi.x-k8s.io/v1"
    kind       = "SecretProviderClass"
    metadata = {
      name      = "postgres-kv-sync"
      namespace = "default"
    }
    spec = {
      provider = "azure"
      parameters = {
        usePodIdentity         = "false"
        useVMManagedIdentity   = "true"
        userAssignedIdentityID = var.kubelet_identity_client_id
        keyvaultName           = var.key_vault_name
        cloudName              = ""
        tenantId               = var.tenant_id
        objects                = <<EOF
array:
  - |
    objectName: postgres-password
    objectType: secret
    objectVersion: ""
EOF
      }
      secretObjects = [
        {
          secretName = "postgres-secret"
          type       = "Opaque"
          data = [
            {
              key        = "POSTGRES_PASSWORD"
              objectName = "postgres-password"
            }
          ]
        }
      ]
    }
  }
  
  depends_on = [helm_release.argocd]
}
