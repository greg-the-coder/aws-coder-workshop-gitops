terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = ">= 2.13.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.38.0"
    }
  }
}