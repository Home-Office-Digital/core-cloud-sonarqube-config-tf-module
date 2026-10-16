All notable changes to this project will be documented in this file. This will provide a record of all notable module updates with each new release. Semantic versioning (https://semver.org/) must be adhered to for all Core Cloud modules.

eg:

### [0.0.1] 2026-03-13

  * Initial tag created for Core Cloud Sonarqube Config Terraform module

### [0.2.0] 2026-10-16

  * Fix: The apply_template strips the admin user of sonar-administrators, causing perm issues on subsequent runs. Portfolio permissions should use portfolio-scoped sonarqube_permissions resources instead.
  * Deprecated the `sonarqube_host` and `sonarqube_token` variables. They are no
    longer used now that we've done away with the `apply_template` provisioner
