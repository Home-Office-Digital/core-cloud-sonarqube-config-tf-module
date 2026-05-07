mock_provider "sonarqube" {}
mock_provider "null" {}

run "enforces_metadata_naming_conventions" {
  command = plan

  variables {
    sonarqube_host     = "https://sonarqube.example.internal"
    sonarqube_token    = "dummy-token"
    environment        = "sandbox-ops-tooling"
    global_admin_group = "PERM-C-SONAR-Test-GlobalAdminGroup"

    tenants = {
      apc = {
        project_regex = "^apc-.*"
        admin_group   = "PERM-C-SONAR-CoreCloudPlatform-Test-AdminGroup"
        user_group    = "PERM-C-SONAR-CoreCloudPlatform-Test-UserGroup"
      }
      apa = {
        project_regex = "^apa-.*"
        admin_group   = "PERM-C-SONAR-CoreCloudPlatform-Test-AdminGroup"
        user_group    = "PERM-C-SONAR-CoreCloudPlatform-Test-UserGroup"
      }
    }
  }

  override_data {
    target = data.sonarqube_groups.groups
    values = {
      groups = [
        {
          name = "PERM-C-SONAR-Test-GlobalAdminGroup"
        },
        {
          name = "PERM-C-SONAR-CoreCloudPlatform-Test-AdminGroup"
        },
        {
          name = "PERM-C-SONAR-CoreCloudPlatform-Test-UserGroup"
        }
      ]
    }
  }

  assert {
    condition = alltrue([
      for tenant_name, template in sonarqube_permission_template.tenant_template :
      template.name == "${tenant_name}-template"
    ])
    error_message = "Expected permission template names to follow <tenant>-template convention."
  }

  assert {
    condition = alltrue([
      for tenant_name, portfolio in sonarqube_portfolio.tenant_portfolio :
      portfolio.key == "portfolio-${tenant_name}" && portfolio.name == "portfolio-${tenant_name}"
    ])
    error_message = "Expected portfolio key and name to follow portfolio-<tenant> convention."
  }

  assert {
    condition = alltrue([
      for _, portfolio in sonarqube_portfolio.tenant_portfolio :
      portfolio.visibility == "private"
    ])
    error_message = "Expected all tenant portfolios to remain private by default."
  }
}
