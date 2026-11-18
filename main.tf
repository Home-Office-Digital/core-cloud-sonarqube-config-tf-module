data "sonarqube_groups" "groups" {}

locals {
  available_groups = toset([for group in data.sonarqube_groups.groups.groups : group.name])

  # Check global admin exists (applied once per environment)
  global_admin_exists = contains(local.available_groups, var.global_admin_group)

  system_admin_exists = var.system_admin_group != null && contains(local.available_groups, coalesce(var.system_admin_group, "-"))

  # Build a map of tenant group existence checks
  tenant_group_status = {
    for tenant_name, tenant_config in var.tenants : tenant_name => {
      admin_exists = contains(local.available_groups, tenant_config.admin_group)
      user_exists  = contains(local.available_groups, tenant_config.user_group)
    }
  }
}

# One permission template per team. Templates have no key pattern (SonarQube cannot match
# templates on tags), so the onboarding pipeline applies "<team>-template" explicitly to a project
# when it is created.
locals {
  templates = merge([
    for tenant_name, tenant_config in var.tenants : {
      for team in tenant_config.teams : team => { tenant = tenant_name }
    }
  ]...)
}

resource "sonarqube_permission_template" "tenant_template" {
  for_each = local.templates

  name        = "${each.key}-template"
  description = "Permission template for ${each.key} (tenant ${each.value.tenant})"
}

# Default template, as a fallback for new projects not matching anything. Currently, this would allow any user to view these projects
resource "sonarqube_permission_template" "default_template" {
  count = var.manage_default_template ? 1 : 0

  name        = var.default_template_name
  description = "Core Cloud managed default template. Grants no sonar-users access so new non-tenant projects are private by default."
  default     = true
}

# Keep system administrators able to administer new non-tenant projects. Removes sonar-users grant as we don't want everyone to be able to see these projects.
resource "sonarqube_permissions" "default_template_admin" {
  count = var.manage_default_template ? 1 : 0

  group_name  = "sonar-administrators"
  template_id = sonarqube_permission_template.default_template[0].id
  permissions = ["admin", "codeviewer", "issueadmin", "securityhotspotadmin", "user"]
}

# When system_admin_group is overridden, it must also keep access to new non-tenant projects. The built-in
# sonar-administrators grant above is left as is; this only adds the configured group when it is a different group.
resource "sonarqube_permissions" "default_template_system_admin" {
  count = var.manage_default_template && local.system_admin_exists && var.system_admin_group != "sonar-administrators" ? 1 : 0

  group_name  = var.system_admin_group
  template_id = sonarqube_permission_template.default_template[0].id
  permissions = ["admin", "codeviewer", "issueadmin", "securityhotspotadmin", "user"]
}

# Enforce private default project visibility.
resource "sonarqube_setting" "default_project_visibility" {
  count = var.manage_default_template ? 1 : 0

  key   = "projects.default.visibility"
  value = "private"
}


# Apply user group permissions to the tenant template
resource "sonarqube_permissions" "tenant_user_template_permissions" {
  for_each = {
    for key, template in local.templates : key => template
    if local.tenant_group_status[template.tenant].user_exists
  }

  group_name  = var.tenants[each.value.tenant].user_group
  template_id = sonarqube_permission_template.tenant_template[each.key].id
  permissions = ["codeviewer", "user"]
}

# Apply admin group permissions to the tenant template
resource "sonarqube_permissions" "tenant_admin_template_permissions" {
  for_each = {
    for key, template in local.templates : key => template
    if local.tenant_group_status[template.tenant].admin_exists
  }

  group_name  = var.tenants[each.value.tenant].admin_group
  template_id = sonarqube_permission_template.tenant_template[each.key].id
  permissions = ["admin", "user", "codeviewer", "issueadmin", "securityhotspotadmin", "scan"]
}

# Apply global admin group permissions to the tenant template
resource "sonarqube_permissions" "global_admin_template_permissions" {
  for_each = local.global_admin_exists ? local.templates : {}

  group_name  = var.global_admin_group
  template_id = sonarqube_permission_template.tenant_template[each.key].id
  permissions = ["admin", "user"]
}

# System admin group (contains the local admin user used by automation): Administer System is instance-level
# and does not give access to a project, so grant it on every template or projects become invisible to the
# pipeline that tags them and mints their tokens.
resource "sonarqube_permissions" "system_admin_template_permissions" {
  for_each = local.system_admin_exists ? local.templates : {}

  group_name  = var.system_admin_group
  template_id = sonarqube_permission_template.tenant_template[each.key].id
  permissions = ["admin", "user", "codeviewer", "issueadmin", "securityhotspotadmin", "scan"]
}

# Portfolio per tenant
resource "sonarqube_portfolio" "tenant_portfolio" {
  for_each = var.tenants

  key            = "portfolio-${each.key}"
  name           = "portfolio-${each.key}"
  description    = "Portfolio for ${each.key}"
  selection_mode = "TAGS"
  tags           = each.value.teams
  visibility     = "private"
}

# User group: browse + see source on the portfolio
resource "sonarqube_permissions" "portfolio_user_permissions" {
  for_each = {
    for tenant_name, tenant_config in var.tenants : tenant_name => tenant_config
    if local.tenant_group_status[tenant_name].user_exists
  }

  group_name  = each.value.user_group
  project_key = sonarqube_portfolio.tenant_portfolio[each.key].key
  permissions = ["codeviewer", "user"]
}

# Admin group: full management on the portfolio
resource "sonarqube_permissions" "portfolio_admin_permissions" {
  for_each = {
    for tenant_name, tenant_config in var.tenants : tenant_name => tenant_config
    if local.tenant_group_status[tenant_name].admin_exists
  }

  group_name  = each.value.admin_group
  project_key = sonarqube_portfolio.tenant_portfolio[each.key].key
  permissions = ["admin", "user", "codeviewer", "issueadmin", "securityhotspotadmin"]
}

# Global admin group: admin + browse on every portfolio
resource "sonarqube_permissions" "portfolio_global_admin_permissions" {
  for_each = local.global_admin_exists ? var.tenants : {}

  group_name  = var.global_admin_group
  project_key = sonarqube_portfolio.tenant_portfolio[each.key].key
  permissions = ["admin", "user"]
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
