mock_provider "sonarqube" {}

variables {
  environment        = "sandbox-ops-tooling"
  global_admin_group = "PERM-C-SONAR-Test-GlobalAdminGroup"
}

run "tenants_get_tag_portfolios_and_per_team_templates" {
  command = plan

  variables {
    tenants = {
      core-cloud = {
        teams       = ["core-cloud-ai-ops", "core-cloud-developer-tooling"]
        admin_group = "PERM-C-SONAR-CoreCloudPlatform-Test-AdminGroup"
        user_group  = "PERM-C-SONAR-CoreCloudPlatform-Test-UserGroup"
      }
      hermes = {
        teams       = ["hermes"]
        admin_group = "PERM-C-SONAR-CoreCloudPlatform-Test-AdminGroup"
        user_group  = "PERM-C-SONAR-CoreCloudPlatform-Test-UserGroup"
      }
    }
  }

  override_data {
    target = data.sonarqube_groups.groups
    values = {
      groups = [
        { name = "PERM-C-SONAR-Test-GlobalAdminGroup" },
        { name = "sonar-administrators" },
        { name = "PERM-C-SONAR-CoreCloudPlatform-Test-AdminGroup" },
        { name = "PERM-C-SONAR-CoreCloudPlatform-Test-UserGroup" }
      ]
    }
  }

  assert {
    condition     = length(sonarqube_permission_template.tenant_template) == 3
    error_message = "Expected one template per team."
  }

  assert {
    condition     = sonarqube_permission_template.tenant_template["core-cloud-ai-ops"].name == "core-cloud-ai-ops-template"
    error_message = "Expected templates to be named <team>-template."
  }

  assert {
    condition     = sonarqube_permission_template.tenant_template["core-cloud-ai-ops"].project_key_pattern == null
    error_message = "Templates must not carry a key pattern."
  }

  assert {
    condition     = length(sonarqube_portfolio.tenant_portfolio) == 2
    error_message = "Expected one portfolio per tenant."
  }

  assert {
    condition     = sonarqube_portfolio.tenant_portfolio["core-cloud"].selection_mode == "TAGS"
    error_message = "Portfolios must use TAGS selection."
  }

  assert {
    condition     = length(sonarqube_portfolio.tenant_portfolio["core-cloud"].tags) == 2
    error_message = "Portfolio must select every listed team tag."
  }

  assert {
    condition     = length(sonarqube_permissions.tenant_admin_template_permissions) == 3
    error_message = "Expected admin template permissions per template."
  }

  assert {
    condition     = length(sonarqube_permissions.tenant_user_template_permissions) == 3
    error_message = "Expected user template permissions per template."
  }

  assert {
    condition     = length(sonarqube_permissions.system_admin_template_permissions) == 3
    error_message = "Expected the system admin group to be granted on every template."
  }

  assert {
    condition = sort(sonarqube_permissions.system_admin_template_permissions["hermes"].permissions) == sort([
      "admin",
      "user",
      "codeviewer",
      "issueadmin",
      "securityhotspotadmin",
      "scan"
    ])
    error_message = "Expected system admin group team template permissions to match the approved set (user = Browse, admin, scan are required by the tagging automation)."
  }
}

run "rejects_tenant_with_no_teams" {
  command = plan

  variables {
    tenants = {
      bad = {
        teams       = []
        admin_group = "a"
        user_group  = "b"
      }
    }
  }

  expect_failures = [var.tenants]
}

run "rejects_duplicate_team" {
  command = plan

  variables {
    tenants = {
      one = {
        teams       = ["dup"]
        admin_group = "a"
        user_group  = "b"
      }
      two = {
        teams       = ["dup"]
        admin_group = "a"
        user_group  = "b"
      }
    }
  }

  expect_failures = [var.tenants]
}

run "rejects_invalid_tag_characters" {
  command = plan

  variables {
    tenants = {
      one = {
        teams       = ["Not_A_Tag"]
        admin_group = "a"
        user_group  = "b"
      }
    }
  }

  expect_failures = [var.tenants]
}
