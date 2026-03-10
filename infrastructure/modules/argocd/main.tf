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

resource "azurerm_federated_identity_credential" "agic" {
  name                = "fic-agic"
  resource_group_name = var.resource_group_name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = var.oidc_issuer_url
  parent_id           = var.agic_identity_id
  subject             = "system:serviceaccount:kube-system:ingress-azure"
}

resource "helm_release" "agic" {
  name       = "agic"
  chart      = "oci://mcr.microsoft.com/azure-application-gateway/charts/ingress-azure"
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
    value = "workloadIdentity"
  }

  set {
    name  = "armAuth.identityClientID"
    value = var.agic_identity_client_id
  }

  set {
    name  = "rbac.enabled"
    value = "true"
  }

  depends_on = [helm_release.argocd, azurerm_federated_identity_credential.agic]
}

