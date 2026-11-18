mock_provider "sonarqube" {}

run "skips_global_admin_permissions_when_group_missing" {
  command = plan

  variables {
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

  assert {
    condition = sort(sonarqube_permissions.global_admin_template_permissions["apc"].permissions) == sort([
      "admin",
      "user"
    ])
    error_message = "Expected global admin template permissions to be created when global admin group exists."
  }

  assert {
    condition = sort(sonarqube_permissions.tenant_global_admin_permissions["apc"].permissions) == sort([
      "profileadmin",
      "gateadmin",
      "provisioning",
      "scan"
    ])
    error_message = "Expected tenant admin instance-level permissions to match approved set."
  }

  assert {
    condition = sort(sonarqube_permissions.tenant_global_user_permissions["apc"].permissions) == sort([
      "provisioning"
    ])
    error_message = "Expected tenant user instance-level permissions to match approved set."
  }
}

run "default_template_is_private_by_default_when_managed" {
  command = plan

  variables {
    environment             = "sandbox-ops-tooling"
    global_admin_group      = "PERM-C-SONAR-Test-GlobalAdminGroup"
    manage_default_template = true

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
        { name = "PERM-C-SONAR-Test-GlobalAdminGroup" },
        { name = "PERM-C-SONAR-CoreCloudPlatform-Test-AdminGroup" },
        { name = "PERM-C-SONAR-CoreCloudPlatform-Test-UserGroup" }
      ]
    }
  }

  assert {
    condition     = length(sonarqube_permission_template.default_template) == 1
    error_message = "Expected a managed default template to be created when manage_default_template is true."
  }

  assert {
    condition     = sonarqube_permission_template.default_template[0].default == true
    error_message = "Expected the managed default template to be set as the instance default."
  }

  assert {
    condition     = sonarqube_permissions.default_template_admin[0].group_name == "sonar-administrators"
    error_message = "Expected only sonar-administrators to be granted on the managed default template (no sonar-users)."
  }

  assert {
    condition     = !contains(["sonar-users"], sonarqube_permissions.default_template_admin[0].group_name)
    error_message = "The managed default template must not grant sonar-users."
  }

  assert {
    condition     = length(sonarqube_setting.default_project_visibility) == 1
    error_message = "Expected the default project visibility setting to be managed when manage_default_template is true."
  }

  assert {
    condition     = sonarqube_setting.default_project_visibility[0].value == "private"
    error_message = "Expected default project visibility to be enforced as private (template grants alone do not hide public projects)."
  }
}

run "default_template_not_touched_when_unmanaged" {
  command = plan

  variables {
    environment        = "sandbox-ops-tooling"
    global_admin_group = "PERM-C-SONAR-Test-GlobalAdminGroup"
    # manage_default_template defaults to false

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
        { name = "PERM-C-SONAR-Test-GlobalAdminGroup" },
        { name = "PERM-C-SONAR-CoreCloudPlatform-Test-AdminGroup" },
        { name = "PERM-C-SONAR-CoreCloudPlatform-Test-UserGroup" }
      ]
    }
  }

  assert {
    condition     = length(sonarqube_permission_template.default_template) == 0
    error_message = "Expected no managed default template when manage_default_template is false (instance default left untouched)."
  }

  assert {
    condition     = length(sonarqube_setting.default_project_visibility) == 0
    error_message = "Expected default project visibility to be left untouched when manage_default_template is false."
  }
}

run "grants_system_admin_group_on_every_template" {
  command = plan

  variables {
    environment        = "sandbox-ops-tooling"
    global_admin_group = "PERM-C-SONAR-Test-GlobalAdminGroup"

    tenants = {
      apc = {
        project_regex = "^apc-.*"
        admin_group   = "A"
        user_group    = "U"
      }
      apa = {
        project_regex = "^apa-.*"
        admin_group   = "A"
        user_group    = "U"
      }
    }
  }

  override_data {
    target = data.sonarqube_groups.groups
    values = {
      groups = [
        { name = "sonar-administrators" }
      ]
    }
  }

  assert {
    condition     = length(sonarqube_permissions.system_admin_template_permissions) == 2
    error_message = "Expected the system admin group on every tenant template."
  }

  assert {
    condition = sort(sonarqube_permissions.system_admin_template_permissions["apc"].permissions) == sort([
      "admin",
      "user",
      "codeviewer",
      "issueadmin",
      "securityhotspotadmin",
      "scan"
    ])
    error_message = "Expected system admin group template permissions to match the approved set (user = Browse, admin, scan are required by the tagging automation)."
  }
}

run "default_system_admin_group_not_duplicated_on_default_template" {
  command = plan

  variables {
    environment             = "sandbox-ops-tooling"
    global_admin_group      = "PERM-C-SONAR-Test-GlobalAdminGroup"
    manage_default_template = true

    tenants = {
      apc = {
        project_regex = "^apc-.*"
        admin_group   = "A"
        user_group    = "U"
      }
    }
  }

  override_data {
    target = data.sonarqube_groups.groups
    values = {
      groups = [
        { name = "sonar-administrators" }
      ]
    }
  }

  assert {
    condition     = length(sonarqube_permissions.default_template_system_admin) == 0
    error_message = "Default system admin group must not get a duplicate grant on the managed default template."
  }

  assert {
    condition     = sonarqube_permissions.default_template_admin[0].group_name == "sonar-administrators"
    error_message = "Built-in sonar-administrators grant on the managed default template must remain."
  }
}

run "overridden_system_admin_group_also_granted_on_default_template" {
  command = plan

  variables {
    environment             = "sandbox-ops-tooling"
    global_admin_group      = "PERM-C-SONAR-Test-GlobalAdminGroup"
    manage_default_template = true
    system_admin_group      = "custom-admins"

    tenants = {
      apc = {
        project_regex = "^apc-.*"
        admin_group   = "A"
        user_group    = "U"
      }
    }
  }

  override_data {
    target = data.sonarqube_groups.groups
    values = {
      groups = [
        { name = "sonar-administrators" },
        { name = "custom-admins" }
      ]
    }
  }

  assert {
    condition     = sonarqube_permissions.default_template_admin[0].group_name == "sonar-administrators"
    error_message = "Built-in sonar-administrators grant on the managed default template must remain."
  }

  assert {
    condition     = length(sonarqube_permissions.default_template_system_admin) == 1
    error_message = "Overridden system admin group must also be granted on the managed default template."
  }

  assert {
    condition     = sonarqube_permissions.default_template_system_admin[0].group_name == "custom-admins"
    error_message = "Expected the configured system admin group on the managed default template."
  }

  assert {
    condition = sort(sonarqube_permissions.default_template_system_admin[0].permissions) == sort([
      "admin",
      "codeviewer",
      "issueadmin",
      "securityhotspotadmin",
      "user"
    ])
    error_message = "Expected the configured system admin group to match the built-in administrator permission set on the default template."
  }

  assert {
    condition     = length(sonarqube_permissions.system_admin_template_permissions) == 1
    error_message = "Overridden system admin group must also be granted on tenant templates."
  }
}

run "overridden_system_admin_group_missing_is_skipped_on_default_template" {
  command = plan

  variables {
    environment             = "sandbox-ops-tooling"
    global_admin_group      = "PERM-C-SONAR-Test-GlobalAdminGroup"
    manage_default_template = true
    system_admin_group      = "custom-admins"

    tenants = {
      apc = {
        project_regex = "^apc-.*"
        admin_group   = "A"
        user_group    = "U"
      }
    }
  }

  override_data {
    target = data.sonarqube_groups.groups
    values = {
      groups = [
        { name = "sonar-administrators" }
      ]
    }
  }

  assert {
    condition     = length(sonarqube_permissions.default_template_system_admin) == 0
    error_message = "No grant expected on the default template when the configured group does not exist."
  }
}

run "overridden_system_admin_group_not_applied_when_default_template_unmanaged" {
  command = plan

  variables {
    environment             = "sandbox-ops-tooling"
    global_admin_group      = "PERM-C-SONAR-Test-GlobalAdminGroup"
    manage_default_template = false
    system_admin_group      = "custom-admins"

    tenants = {
      apc = {
        project_regex = "^apc-.*"
        admin_group   = "A"
        user_group    = "U"
      }
    }
  }

  override_data {
    target = data.sonarqube_groups.groups
    values = {
      groups = [
        { name = "sonar-administrators" },
        { name = "custom-admins" }
      ]
    }
  }

  assert {
    condition     = length(sonarqube_permissions.default_template_system_admin) == 0
    error_message = "Nothing expected when the default template is not managed."
  }
}

run "rejects_system_admin_group_equal_to_global_admin_group" {
  command = plan

  variables {
    environment        = "sandbox-ops-tooling"
    global_admin_group = "PERM-C-SONAR-Test-GlobalAdminGroup"
    system_admin_group = "PERM-C-SONAR-Test-GlobalAdminGroup"

    tenants = {
      apc = {
        project_regex = "^apc-.*"
        admin_group   = "A"
        user_group    = "U"
      }
    }
  }

  expect_failures = [var.system_admin_group]
}

run "rejects_system_admin_group_equal_to_tenant_admin_group" {
  command = plan

  variables {
    environment        = "sandbox-ops-tooling"
    global_admin_group = "PERM-C-SONAR-Test-GlobalAdminGroup"
    system_admin_group = "tenant-admins"

    tenants = {
      apc = {
        project_regex = "^apc-.*"
        admin_group   = "tenant-admins"
        user_group    = "U"
      }
    }
  }

  expect_failures = [var.system_admin_group]
}

run "rejects_system_admin_group_equal_to_tenant_user_group" {
  command = plan

  variables {
    environment        = "sandbox-ops-tooling"
    global_admin_group = "PERM-C-SONAR-Test-GlobalAdminGroup"
    system_admin_group = "tenant-users"

    tenants = {
      apc = {
        project_regex = "^apc-.*"
        admin_group   = "A"
        user_group    = "tenant-users"
      }
    }
  }

  expect_failures = [var.system_admin_group]
}
