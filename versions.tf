terraform {
  required_version = ">= 1.9.3"

  required_providers {
    sonarqube = {
      source  = "jdamata/sonarqube"
      version = "0.16.21"
    }
  }
}
