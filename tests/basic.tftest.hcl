mock_provider "sonarqube" {}
mock_provider "null" {}

run "creates_templates_portfolios_and_outputs" {
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
    condition     = length(sonarqube_permission_template.tenant_template) == 2
    error_message = "Expected one permission template per tenant."
  }

  assert {
    condition     = length(sonarqube_portfolio.tenant_portfolio) == 2
    error_message = "Expected one portfolio per tenant."
  }

  assert {
    condition     = output.environment == "sandbox-ops-tooling"
    error_message = "Expected output.environment to match input environment."
  }

  assert {
    condition     = output.portfolios["apc"].portfolio_key == "portfolio-apc"
    error_message = "Expected APC portfolio output key naming convention to be preserved."
  }
}

run "creates_permissions_only_for_existing_tenant_groups" {
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
        admin_group   = "PERM-C-SONAR-CoreCloudPlatform-Missing-AdminGroup"
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
    condition     = length(sonarqube_permissions.tenant_admin_template_permissions) == 1
    error_message = "Expected admin template permissions only for tenants with existing admin groups."
  }

  assert {
    condition     = length(sonarqube_permissions.tenant_user_template_permissions) == 2
    error_message = "Expected user template permissions for tenants with existing user groups."
  }

  assert {
    condition     = output.tenant_groups_status["apa"].admin_exists == false
    error_message = "Expected tenant group status output to report missing APA admin group."
  }
}
