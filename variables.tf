variable "environment" {
  description = "Environment name"
  type        = string
}

variable "global_admin_group" {
  description = "Global admin group name (applied once per environment at instance level)"
  type        = string
}

variable "tenants" {
  description = "Map of tenant configurations"
  type = map(object({
    project_regex = string
    admin_group   = string
    user_group    = string
  }))
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