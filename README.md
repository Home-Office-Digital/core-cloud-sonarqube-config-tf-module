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

## Usage 

Add sonarqube_host and sonarqube_token as Github Environment secrets.

### Module Configuration

Add the following to your Terraform configuration:

```hcl
module "sonarqube_config" {
  source = "git::https://github.com/UKHomeOffice/core-cloud-sonarqube-config-tf-module.git?ref={tag}"

  sonarqube_host     = var.sonarqube_host
  sonarqube_token    = var.sonarqube_token
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
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_sonarqube"></a> [sonarqube](#provider\_sonarqube) | n/a |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |

## Resources

| Name | Type |
|------|------|
| [sonarqube_permission_template.tenant_template](https://registry.terraform.io/providers/jdamata/sonarqube/latest/docs/resources/permission_template) | resource |
| [sonarqube_permissions.tenant_user_template_permissions](https://registry.terraform.io/providers/jdamata/sonarqube/latest/docs/resources/permissions) | resource |
| [sonarqube_permissions.tenant_admin_template_permissions](https://registry.terraform.io/providers/jdamata/sonarqube/latest/docs/resources/permissions) | resource |
| [sonarqube_permissions.global_admin_template_permissions](https://registry.terraform.io/providers/jdamata/sonarqube/latest/docs/resources/permissions) | resource |
| [sonarqube_portfolio.tenant_portfolio](https://registry.terraform.io/providers/jdamata/sonarqube/latest/docs/resources/portfolio) | resource |
| [sonarqube_permissions.cc_global_admin_permissions](https://registry.terraform.io/providers/jdamata/sonarqube/latest/docs/resources/permissions) | resource |
| [sonarqube_permissions.tenant_global_admin_permissions](https://registry.terraform.io/providers/jdamata/sonarqube/latest/docs/resources/permissions) | resource |
| [sonarqube_permissions.tenant_global_user_permissions](https://registry.terraform.io/providers/jdamata/sonarqube/latest/docs/resources/permissions) | resource |
| [null_resource.apply_portfolio_template](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [sonarqube_groups.groups](https://registry.terraform.io/providers/jdamata/sonarqube/latest/docs/data-sources/groups) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_sonarqube_host"></a> [sonarqube\_host](#input\_sonarqube\_host) | SonarQube server URL | `string` | n/a | yes |
| <a name="input_sonarqube_token"></a> [sonarqube\_token](#input\_sonarqube\_token) | SonarQube auth token | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name | `string` | n/a | yes |
| <a name="input_global_admin_group"></a> [global_admin_group](#input\_global_admin\_group) | Global admin group name (applied once per environment at instance level) | `string` | n/a | yes |
| <a name="input_tenants"></a> [tenants](#input\_tenants) | Map of tenant configurations | `map(object({ project_regex = string, admin_group = string, user_group = string }))` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_portfolios"></a> [portfolios](#output\_portfolios) | Portfolio information for all tenants |
| <a name="output_tenant_template_ids"></a> [tenant\_template\_ids](#output\_tenant\_template\_ids) | Permission template IDs for all tenants |
| <a name="output_tenant_groups_status"></a> [tenant\_groups\_status](#output\_tenant\_groups\_status) | Status of tenant groups existence |
| <a name="output_global_admin_status"></a> [global_admin_status](#output\_global\_admin\_status) | Status of global admin group |
| <a name="output_environment"></a> [environment](#output\_environment) | Environment name |
