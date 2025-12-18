# Infrastructure-as-Code Configuration Templates

## Overview

Configuration templates for Terraform and OpenTofu projects, covering provider constraints and linting.

## Detection

**Marker Files:**
- `*.tf` files → Terraform/OpenTofu project
- `terragrunt.hcl` → Terragrunt wrapper

**Load When:** Any `.tf` files exist

## Template Hierarchy

```
iac/
├── README.md                    # This file
├── terraform-provider.template  # Provider/version constraints
└── tflint.template             # TFLint configuration
```

## Quick Reference

| Config | Purpose | Required When |
|--------|---------|---------------|
| `versions.tf` | Provider + Terraform version constraints | Any IaC project |
| `.tflint.hcl` | Linting rules | Any IaC project |

## Terraform vs OpenTofu

This repo uses **OpenTofu** (`tofu` CLI), the open-source Terraform fork:

| Command | Description |
|---------|-------------|
| `tofu init` | Initialize providers |
| `tofu plan` | Preview changes |
| `tofu apply` | Apply changes |
| `tofu fmt` | Format files |
| `tofu validate` | Validate syntax |

Configuration files (`.tf`) are compatible with both Terraform and OpenTofu.

## Project Structure

### Single Environment
```
infrastructure/
├── main.tf              # Resources
├── variables.tf         # Input variables
├── outputs.tf          # Outputs
├── versions.tf         # Provider constraints
├── terraform.tfvars    # Variable values (gitignored)
├── .tflint.hcl         # Linting config
└── .terraform/         # Providers (gitignored)
```

### Multi-Environment
```
infrastructure/
├── modules/
│   └── vpc/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── backend.tf
│   │   └── terraform.tfvars
│   ├── staging/
│   └── prod/
├── versions.tf         # Shared version constraints
└── .tflint.hcl
```

### Terragrunt Structure
```
infrastructure/
├── terragrunt.hcl      # Root config
├── modules/
│   └── vpc/
├── environments/
│   ├── dev/
│   │   └── terragrunt.hcl
│   ├── staging/
│   │   └── terragrunt.hcl
│   └── prod/
│       └── terragrunt.hcl
```

## Config Loading Order

1. **Always create:** `versions.tf` with version constraints
2. **Always add:** `.tflint.hcl` for linting
3. **Optional:** Backend config for remote state

## Common Commands

```bash
# Initialize
tofu init

# Format
tofu fmt -recursive

# Validate
tofu validate

# Plan with output
tofu plan -out=tofu.plan

# Apply saved plan
tofu apply tofu.plan

# Destroy
tofu destroy

# Show state
tofu state list
tofu state show <resource>

# Import existing resource
tofu import <address> <id>
```

## State Management

### Remote State (Recommended)

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "project/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

### Alternative Backends

| Backend | Use Case |
|---------|----------|
| `s3` | AWS, with DynamoDB for locks |
| `azurerm` | Azure Blob Storage |
| `gcs` | Google Cloud Storage |
| `remote` | Terraform Cloud/Enterprise |
| `local` | Development only |

## When NOT to Use These Templates

| Scenario | Skip These |
|----------|------------|
| Application code only | All IaC configs |
| Using Pulumi | Use Pulumi configs |
| Using CDK | Use CDK configs |
| Using Ansible | Use Ansible configs |

## Integration Notes

### With 1Password

```hcl
# Use 1Password for secrets
terraform {
  required_providers {
    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 1.4"
    }
  }
}

data "onepassword_item" "db" {
  vault = "Infrastructure"
  uuid  = "xxx"
}
```

### With CI/CD

```bash
# CI pipeline pattern
tofu init -input=false
tofu plan -out=tofu.plan -input=false
# (approval step)
tofu apply tofu.plan
```

## Security Considerations

- **Never commit:** `*.tfvars` with secrets, `*.tfstate`, `.terraform/`
- **Always use:** Remote state with encryption
- **Consider:** State locking for team environments
- **Review:** Plan output before applying
