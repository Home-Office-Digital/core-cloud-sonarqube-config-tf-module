# Core Cloud Sonarqube Config Terraform Module

This Sonarqube Config Terraform Module is written and maintained by the Core Cloud Platform team to manage SonarQube configurations such as permission templates, portfolios, and group permissions for multiple tenants.

## Module Structure

<strong>---| [CHANGELOG.md](CHANGELOG.md)</strong> - Contains all significant changes in relation to a semver tag made to this module. \
<strong>---| [CODEOWNERS](CODEOWNERS)</strong> \
<strong>---| [CODE_OF_CONDUCT](CODE_OF_CONDUCT.md)</strong> \
<strong>---| [LICENSE.md](LICENSE.md)</strong>  \
<strong>---| [README.md](README.md)</strong>  \
<strong>---| [main.tf](main.tf)</strong> - Contains the main set of configuration for this module.  \
<strong>---| [outputs.tf](outputs.tf)</strong> - Contain the output definitions for this module.  \
<strong>---| [variables.tf](variables.tf)</strong> - Contains the declarations for module variables, all variables have a defined type and short description outlining their purpose.  

### Module Configuration

Add the following to your Terraform configuration:

```hcl
module "sonarqube_config" {
  source = "git::https://github.com/Home-Office-Digital/core-cloud-sonarqube-config-tf-module.git?ref={tag}"

  environment        = "sandbox-ops-tooling"
  global_admin_group = "PERM-C-SONAR-Test-GlobalAdminGroup"

  tenants = {
    apc = {
      teams       = ["apc"]
      admin_group = "PERM-C-SONAR-CoreCloudPlatform-Test-AdminGroup"
      user_group  = "PERM-C-SONAR-CoreCloudPlatform-Test-UserGroup"
    }
    apa = {
      teams       = ["apa"]
      admin_group = "PERM-C-SONAR-CoreCloudPlatform-Test-AdminGroup"
      user_group  = "PERM-C-SONAR-CoreCloudPlatform-Test-UserGroup"
    }
  }
}
```

### Associating projects with a tenant

The GitHub `team` slug in a team's `metadata.yaml` file in the `core-cloud-hod-git` repo is used as a Sonarqube tag. The onboarding pipeline tags each SonarQube project with its team, so each tenant portfolio uses `TAGS` selection. SonarQube cannot match permission templates by tag, so one `<team>-template` template is created per team and the pipeline applies it to the project when it is created. Every team must be listed under a tenant, otherwise its projects get no portfolio and stay on the default template.

```hcl
tenants = {
  core-cloud = {
    teams       = ["core-cloud-devops"]
    admin_group = "PERM-C-SONAR-CoreCloudPlatform-Test-AdminGroup"
    user_group  = "PERM-C-SONAR-CoreCloudPlatform-Test-UserGroup"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0.0 |
| <a name="requirement_sonarqube"></a> [sonarqube](#requirement\_sonarqube) | 0.16.21 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_sonarqube"></a> [sonarqube](#provider\_sonarqube) | 0.16.21 |

## Resources

| Name | Type |
|------|------|
| [sonarqube_permission_template.tenant_template](https://registry.terraform.io/providers/jdamata/sonarqube/latest/docs/resources/permission_template) | resource |
| [sonarqube_permission_template.default_template](https://registry.terraform.io/providers/jdamata/sonarqube/latest/docs/resources/permission_template) | resource |
| [sonarqube_permissions.default_template_admin](https://registry.terraform.io/providers/jdamata/sonarqube/latest/docs/resources/permissions) | resource |
| [sonarqube_setting.default_project_visibility](https://registry.terraform.io/providers/jdamata/sonarqube/latest/docs/resources/setting) | resource |
| [sonarqube_permissions.tenant_user_template_permissions](https://registry.terraform.io/providers/jdamata/sonarqube/latest/docs/resources/permissions) | resource |
| [sonarqube_permissions.tenant_admin_template_permissions](https://registry.terraform.io/providers/jdamata/sonarqube/latest/docs/resources/permissions) | resource |
| [sonarqube_permissions.system_admin_template_permissions](https://registry.terraform.io/providers/jdamata/sonarqube/latest/docs/resources/permissions) | resource |
| [sonarqube_permissions.default_template_system_admin](https://registry.terraform.io/providers/jdamata/sonarqube/latest/docs/resources/permissions) | resource |
| [sonarqube_permissions.global_admin_template_permissions](https://registry.terraform.io/providers/jdamata/sonarqube/latest/docs/resources/permissions) | resource |
| [sonarqube_portfolio.tenant_portfolio](https://registry.terraform.io/providers/jdamata/sonarqube/latest/docs/resources/portfolio) | resource |
| [sonarqube_permissions.portfolio_user_permissions](https://registry.terraform.io/providers/jdamata/sonarqube/latest/docs/resources/permissions) | resource |
| [sonarqube_permissions.portfolio_admin_permissions](https://registry.terraform.io/providers/jdamata/sonarqube/latest/docs/resources/permissions) | resource |
| [sonarqube_permissions.portfolio_global_admin_permissions](https://registry.terraform.io/providers/jdamata/sonarqube/latest/docs/resources/permissions) | resource |
| [sonarqube_permissions.cc_global_admin_permissions](https://registry.terraform.io/providers/jdamata/sonarqube/latest/docs/resources/permissions) | resource |
| [sonarqube_permissions.tenant_global_admin_permissions](https://registry.terraform.io/providers/jdamata/sonarqube/latest/docs/resources/permissions) | resource |
| [sonarqube_permissions.tenant_global_user_permissions](https://registry.terraform.io/providers/jdamata/sonarqube/latest/docs/resources/permissions) | resource |
| [sonarqube_groups.groups](https://registry.terraform.io/providers/jdamata/sonarqube/latest/docs/data-sources/groups) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name | `string` | n/a | yes |
| <a name="input_global_admin_group"></a> [global\_admin\_group](#input\_global\_admin\_group) | Global admin group name (applied once per environment at instance level) | `string` | n/a | yes |
| <a name="input_tenants"></a> [tenants](#input\_tenants) | Map of tenant configurations. Projects are associated with a tenant by `teams` (GitHub team slugs tagged on the project) | `map(object({ teams = list(string), admin_group = string, user_group = string }))` | n/a | yes |
| <a name="input_system_admin_group"></a> [system\_admin\_group](#input\_system\_admin\_group) | Group granted full project permissions on every team template so the local admin user used by automation keeps project access. It must contain that user. `null` disables | `string` | `"sonar-administrators"` | no |
| <a name="input_manage_default_template"></a> [manage\_default\_template](#input\_manage\_default\_template) | Create and set a managed default permission template granting `sonar-users` no access, and enforce private default project visibility | `bool` | `false` | no |
| <a name="input_default_template_name"></a> [default\_template\_name](#input\_default\_template\_name) | Name of the managed default permission template. Only used when `manage_default_template` is true | `string` | `"core-cloud-managed-default-template"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_portfolios"></a> [portfolios](#output\_portfolios) | Portfolio information for all tenants |
| <a name="output_tenant_template_ids"></a> [tenant\_template\_ids](#output\_tenant\_template\_ids) | Permission template IDs, keyed by team |
| <a name="output_tenant_groups_status"></a> [tenant\_groups\_status](#output\_tenant\_groups\_status) | Status of tenant groups existence |
| <a name="output_global_admin_status"></a> [global\_admin\_status](#output\_global\_admin\_status) | Status of global admin group |
| <a name="output_environment"></a> [environment](#output\_environment) | Environment name |
