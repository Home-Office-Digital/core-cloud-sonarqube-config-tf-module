variable "environment" {
  description = "Environment name"
  type        = string
}

variable "global_admin_group" {
  description = "Global admin group name (applied once per environment at instance level)"
  type        = string
}

variable "tenants" {
  description = <<-EOT
    Projects are associated with a tenant by `teams`: a list of
    `team` values (as resolved by core-cloud-hod-git-configuration).
  EOT
  type = map(object({
    teams       = list(string)
    admin_group = string
    user_group  = string
  }))

  validation {
    condition     = alltrue([for t in values(var.tenants) : length(t.teams) > 0])
    error_message = "Each tenant must list at least one team in teams."
  }

  validation {
    condition = alltrue([
      for t in values(var.tenants) : alltrue([for o in t.teams : can(regex("^[a-z0-9-]+$", o))])
    ])
    error_message = "teams values must be valid SonarQube tags matching ^[a-z0-9-]+$."
  }

  validation {
    condition = (
      length(flatten([for t in values(var.tenants) : t.teams])) ==
      length(distinct(flatten([for t in values(var.tenants) : t.teams])))
    )
    error_message = "A team may only be listed under one tenant."
  }
}

variable "system_admin_group" {
  description = "Group is solely for the admin user so it can access all projects in order to update tags for the hod automation"
  type        = string
  default     = "sonar-administrators"

  # Each sonarqube_permissions resource is authoritative for one group on one template. A group that
  # appears in two resources on the same template would have its grants overwritten by whichever applies last,
  # and changing this variable later could revoke access still intended by the other resource.
  validation {
    condition     = var.system_admin_group == null || var.system_admin_group != var.global_admin_group
    error_message = "system_admin_group must not be the same group as global_admin_group (overlapping permission resources on the same templates)."
  }

  validation {
    condition = var.system_admin_group == null || alltrue([
      for t in values(var.tenants) : var.system_admin_group != t.admin_group && var.system_admin_group != t.user_group
    ])
    error_message = "system_admin_group must not be the same group as any tenant admin_group or user_group (overlapping permission resources on the same templates)."
  }
}

variable "manage_default_template" {
  description = "When true, the module creates and sets a managed default permission template that grants NO sonar-users (all authenticated users) access, so new projects that do not match a tenant pattern are private by default rather than world-visible. Leave false to not touch the instance default template."
  type        = bool
  default     = false
}

variable "default_template_name" {
  description = "Name of the module-managed default permission template. Only used when manage_default_template is true."
  type        = string
  default     = "core-cloud-managed-default-template"
}
