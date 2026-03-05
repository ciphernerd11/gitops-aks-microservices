# ─────────────────────────────────────────────────────
# Dev Environment — Variable Values
# ─────────────────────────────────────────────────────

project_name       = "disaster-relief"
environment        = "dev"
location           = "East US"
aks_node_count     = 2
aks_node_vm_size   = "Standard_B2s"
kubernetes_version = "1.29"
acr_sku            = "Basic"

tags = {
  Owner   = "devops-team"
  Purpose = "disaster-relief-platform"
}
