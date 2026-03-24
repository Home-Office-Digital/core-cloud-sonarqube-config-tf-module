output "portfolios" {
  description = "Portfolio information for all tenants"
  value = {
    for tenant_name, _ in var.tenants : tenant_name => {
      portfolio_key  = "portfolio-${tenant_name}"
      portfolio_name = "portfolio-${tenant_name}"
    }
  }
}

output "tenant_template_ids" {
  description = "Permission template IDs for all tenants"
  value = {
    for tenant_name, _ in var.tenants : tenant_name => sonarqube_permission_template.tenant_template[tenant_name].id
  }
}

output "tenant_groups_status" {
  description = "Status of tenant groups existence"
  value       = local.tenant_group_status
}

output "global_admin_status" {
  description = "Status of global admin group"
  value = {
    group_exists = local.global_admin_exists
    group_name   = var.global_admin_group
  }
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}