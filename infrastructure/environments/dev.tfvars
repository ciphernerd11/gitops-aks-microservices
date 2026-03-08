# ─────────────────────────────────────────────────────
# Dev Environment — Variable Values
# ─────────────────────────────────────────────────────

project_name       = "disaster-relief"
environment        = "dev"
location           = "Central India"
aks_node_count     = 2
aks_node_vm_size   = "Standard_B2s"
kubernetes_version = "1.33.7"
acr_sku            = "Basic"

vnet_cidr        = ["10.0.0.0/16"]
app_subnets_cidr = ["10.0.1.0/24", "10.0.2.0/24"]
db_subnets_cidr  = ["10.0.3.0/24", "10.0.4.0/24"]

tags = {
  Owner       = "devops-team"
  Project     = "disaster-relief"
  Environment = "dev"
}
