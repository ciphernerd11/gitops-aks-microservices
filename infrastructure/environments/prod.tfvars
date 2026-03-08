# ─────────────────────────────────────────────────────
# Prod Environment — Variable Values
# ─────────────────────────────────────────────────────

project_name       = "disaster-relief"
environment        = "prod"
location           = "Central India"
aks_node_count     = 3
aks_node_vm_size   = "Standard_B2s"
kubernetes_version = "1.30.100"
acr_sku            = "Basic"

vnet_cidr        = ["10.3.0.0/16"]
app_subnets_cidr = ["10.3.1.0/24", "10.3.2.0/24"]
db_subnets_cidr  = ["10.3.3.0/24", "10.3.4.0/24"]

tags = {
  Owner       = "devops-team"
  Project     = "disaster-relief"
  Environment = "prod"
}
