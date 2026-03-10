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

resource "helm_release" "agic" {
  name       = "agic"
  repository = "https://appgwingress.blob.core.windows.net/ingress-azure-helm-package/"
  chart      = "ingress-azure"
  namespace  = "kube-system"
  version    = "1.7.2"

  set {
    name  = "appgw.name"
    value = var.gateway_name
  }

  set {
    name  = "appgw.resourceGroup"
    value = var.resource_group_name
  }

  set {
    name  = "appgw.subscriptionId"
    value = var.subscription_id
  }

  set {
    name  = "armAuth.type"
    value = "msi"
  }

  set {
    name  = "armAuth.identityResourceID"
    value = var.agic_identity_id
  }

  set {
    name  = "armAuth.identityClientId"
    value = var.agic_identity_client_id
  }

  set {
    name  = "rbac.enabled"
    value = "true"
  }

  depends_on = [helm_release.argocd] # Not strictly necessary but keeps it clean
}

