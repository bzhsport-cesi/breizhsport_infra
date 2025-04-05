
terraform {
  required_providers {
    warren = {
      source = "WarrenCloudPlatform/warren"
      version = "0.1.3"
    }
    ansible = {
      source  = "ansible/ansible"
      version = "1.3.0"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

provider "warren" {
  api_url = "https://api.denv-r.com/v1"
  api_token = "${var.api_token}"
}