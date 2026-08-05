terraform {
  required_providers {
    ns = {
      source = "nullstone-io/ns"
    }
  }
}

data "ns_workspace" "this" {}

// Generate a random suffix to ensure uniqueness of resources
resource "random_string" "resource_suffix" {
  length  = 5
  lower   = true
  upper   = false
  numeric = false
  special = false
}

// This capability creates no AWS resources -- every statement it makes goes to Postgres through the
// pg-db-admin Lambda, so there is no account, region or tagging to resolve here.
locals {
  block_name = data.ns_workspace.this.block_name
  env_name   = data.ns_workspace.this.env_name
}
