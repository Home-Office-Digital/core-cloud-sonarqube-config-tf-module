mock_provider "sonarqube" {}
mock_provider "null" {}

run "skips_global_admin_permissions_when_group_missing" {
  command = plan

  variables {
    sonarqube_host     = "https://sonarqube.example.internal"
    sonarqube_token    = "dummy-token"
    environment        = "sandbox-ops-tooling"
    global_admin_group = "PERM-C-SONAR-Missing-GlobalAdminGroup"

    tenants = {
      apc = {
        project_regex = "^apc-.*"
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
          name = "PERM-C-SONAR-CoreCloudPlatform-Test-AdminGroup"
        },
        {
          name = "PERM-C-SONAR-CoreCloudPlatform-Test-UserGroup"
        }
      ]
    }
  }

  assert {
    condition     = length(sonarqube_permissions.global_admin_template_permissions) == 0
    error_message = "Expected zero global admin template permission resources when global admin group is absent."
  }

  assert {
    condition     = length(sonarqube_permissions.cc_global_admin_permissions) == 0
    error_message = "Expected zero global admin instance-level permission resources when global admin group is absent."
  }

  assert {
    condition     = output.global_admin_status.group_exists == false
    error_message = "Expected output to report missing global admin group."
  }
}

run "keeps_permission_sets_within_expected_bounds" {
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
    condition = sort(sonarqube_permissions.tenant_user_template_permissions["apc"].permissions) == sort([
      "codeviewer",
      "user"
    ])
    error_message = "Expected tenant user template permissions to stay limited to codeviewer and user."
  }

  assert {
    condition = sort(sonarqube_permissions.tenant_admin_template_permissions["apc"].permissions) == sort([
      "admin",
      "user",
      "codeviewer",
      "issueadmin",
      "securityhotspotadmin",
      "scan"
    ])
    error_message = "Expected tenant admin template permissions to match approved set."
  }

  assert {
    condition = sort(sonarqube_permissions.cc_global_admin_permissions[0].permissions) == sort([
      "admin",
      "provisioning",
      "applicationcreator",
      "portfoliocreator",
      "gateadmin",
      "profileadmin"
    ])
    error_message = "Expected global admin instance-level permissions to match approved set."
  }
}
