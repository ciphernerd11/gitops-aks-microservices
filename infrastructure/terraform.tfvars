# ─────────────────────────────────────────────────────
# Dev Environment — Variable Values
# ─────────────────────────────────────────────────────

project_name       = "disaster-relief"
environment        = "dev"
location           = "Central India"
aks_node_count     = 2
aks_node_vm_size   = "Standard_B2ats_v2"
kubernetes_version = "1.35"
acr_sku            = "Basic"

tags = {
  Owner   = "devops-team"
  Purpose = "disaster-relief-platform"
}
