terraform {
  required_version = ">= 1.9.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
    sonarqube = {
      source  = "jdamata/sonarqube"
      version = "0.16.21"
    }
  }
}