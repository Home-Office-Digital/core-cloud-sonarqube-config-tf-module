All notable changes to this project will be documented in this file. This will provide a record of all notable module updates with each new release. Semantic versioning (https://semver.org/) must be adhered to for all Core Cloud modules.

eg:

### [0.0.1] 2026-03-13

  * Initial tag created for Core Cloud Sonarqube Config Terraform module

### [0.2.0] 2026-10-16

  * Fix: The apply_template strips the admin user of sonar-administrators, causing perm issues on subsequent runs. Portfolio permissions should use portfolio-scoped sonarqube_permissions resources instead.
  * Deprecated the `sonarqube_host` and `sonarqube_token` variables. They are no
    longer used now that we've done away with the `apply_template` provisioner

### [0.2.1] 2026-10-16

  * Fix: Removes sonar-users from being able to see projects with no project-scope permission having access to the Default template

### [0.2.2] 2026-11-17

  * Fix: For the hod automation to be able to update tags for existing projects, the `sonar-administrators` group needs to be applied on every template so that the automation's token, which is the `admin` user (who is the only member of the sonar-administrators group) has access to read and update tags
  * When `system_admin_group` is overridden and `manage_default_template` is true, the configured group is also granted on the managed default template (alongside the built-in `sonar-administrators` grant, which is unchanged), so it keeps access to new non-tenant projects.
  * `system_admin_group` is validated to differ from `global_admin_group` and every tenant `admin_group`/`user_group`. Each permissions resource is authoritative for one group on one template, so overlapping resources would overwrite each other and changing the variable later could revoke access.

### [0.3.0] 2026-11-18

  * BREAKING: `project_regex` is removed. Tenants now associate with projects solely by the `teams` property in each team's `metadata.yaml` file in the hod-git repo. The automation will add the team name to the Sonarqube project's tags directly.
  * Portfolios use `TAGS` selection with the tenant's teams.
  * One `<team>-template` permission template is created per team. Templates have no key pattern (SonarQube cannot match templates by tag), so the onboarding pipeline applies them explicitly when a project is created. Previous `<tenant>-template` templates are replaced.
