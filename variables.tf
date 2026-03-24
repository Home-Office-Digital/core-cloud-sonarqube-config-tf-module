variable "sonarqube_host" {
  description = "SonarQube server URL"
  type        = string
}

variable "sonarqube_token" {
  description = "SonarQube auth token"
  type        = string
  sensitive   = true
}

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