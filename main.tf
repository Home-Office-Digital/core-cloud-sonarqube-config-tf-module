data "sonarqube_groups" "groups" {}

locals {
  available_groups = toset([for group in data.sonarqube_groups.groups.groups : group.name])
  
  # Check global admin exists (applied once per environment)
  global_admin_exists = contains(local.available_groups, var.global_admin_group)
  
  # Build a map of tenant group existence checks
  tenant_group_status = {
    for tenant_name, tenant_config in var.tenants : tenant_name => {
      admin_exists = contains(local.available_groups, tenant_config.admin_group)
      user_exists  = contains(local.available_groups, tenant_config.user_group)
    }
  }
}

resource "sonarqube_permission_template" "tenant_template" {
  for_each = var.tenants

  name                = "${each.key}-template"
  description         = "Permission template for ${each.key}"
  project_key_pattern = each.value.project_regex
}


# Apply user group permissions to the tenant template
resource "sonarqube_permissions" "tenant_user_template_permissions" {
  for_each = {
    for tenant_name, tenant_config in var.tenants : tenant_name => tenant_config
    if local.tenant_group_status[tenant_name].user_exists
  }

  group_name  = each.value.user_group
  template_id = sonarqube_permission_template.tenant_template[each.key].id
  permissions = ["codeviewer", "user"]
}

# Apply admin group permissions to the tenant template
resource "sonarqube_permissions" "tenant_admin_template_permissions" {
  for_each = {
    for tenant_name, tenant_config in var.tenants : tenant_name => tenant_config
    if local.tenant_group_status[tenant_name].admin_exists
  }

  group_name  = each.value.admin_group
  template_id = sonarqube_permission_template.tenant_template[each.key].id
  permissions = ["admin", "user", "codeviewer", "issueadmin", "securityhotspotadmin", "scan"]
}

# Apply global admin group permissions to the tenant template
resource "sonarqube_permissions" "global_admin_template_permissions" {
  for_each = local.global_admin_exists ? var.tenants : {}

  group_name  = var.global_admin_group
  template_id = sonarqube_permission_template.tenant_template[each.key].id
  permissions = ["admin", "user"]
}

# Portfolio per tenant
resource "sonarqube_portfolio" "tenant_portfolio" {
  for_each = var.tenants

  key            = "portfolio-${each.key}"
  name           = "portfolio-${each.key}"
  description    = "Portfolio for ${each.key}"
  selection_mode = "REGEXP"
  regexp         = each.value.project_regex
  visibility     = "private"
}

# Apply tenant template to portfolio
resource "null_resource" "apply_portfolio_template" {
  for_each = var.tenants

  triggers = {
    portfolio_key = sonarqube_portfolio.tenant_portfolio[each.key].key
    template_name = sonarqube_permission_template.tenant_template[each.key].name
  }

  provisioner "local-exec" {
    command = <<-EOT
      curl -X POST "${var.sonarqube_host}/api/permissions/apply_template" \
        -H "Authorization: Bearer ${var.sonarqube_token}" \
        -d "templateName=${sonarqube_permission_template.tenant_template[each.key].name}&projectKey=portfolio-${each.key}" \
        --fail --silent --show-error
    EOT
  }

  depends_on = [
    sonarqube_portfolio.tenant_portfolio,
    sonarqube_permission_template.tenant_template,
    sonarqube_permissions.tenant_admin_template_permissions,
    sonarqube_permissions.tenant_user_template_permissions,
    sonarqube_permissions.global_admin_template_permissions
  ]
}

# Global admin instance-level permissions
resource "sonarqube_permissions" "cc_global_admin_permissions" {
  count       = local.global_admin_exists ? 1 : 0
  group_name  = var.global_admin_group
  permissions = ["admin", "provisioning", "applicationcreator", "portfoliocreator", "gateadmin", "profileadmin"]
}

# Tenant admin instance-level permissions
resource "sonarqube_permissions" "tenant_global_admin_permissions" {
  for_each = {
    for tenant_name, tenant_config in var.tenants : tenant_name => tenant_config
    if local.tenant_group_status[tenant_name].admin_exists
  }

  group_name  = each.value.admin_group
  permissions = ["profileadmin", "gateadmin", "provisioning", "scan"]
}

# Tenant user instance-level permissions
resource "sonarqube_permissions" "tenant_global_user_permissions" {
  for_each = {
    for tenant_name, tenant_config in var.tenants : tenant_name => tenant_config
    if local.tenant_group_status[tenant_name].user_exists
  }

  group_name  = each.value.user_group
  permissions = ["provisioning"]
}