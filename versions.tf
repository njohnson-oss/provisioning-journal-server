terraform {
  required_version = ">= 1.9"

  required_providers {
    infomaniak = {
      source  = "Infomaniak/infomaniak"
      version = "~> 1.4"
    }
  }
}

# Credentials are read from the INFOMANIAK_TOKEN environment variable.
# The token needs the dns:read and dns:write scopes.
provider "infomaniak" {}
