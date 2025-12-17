# OpenTofu/Terraform Standards

**Standards for terraform/tofu repositories in DTLR infrastructure**

---

## CLI Usage

### Use OpenTofu (tofu), Not Terraform

**Rule**: Always use `tofu` CLI, not `terraform`

**Why**: tf-msvcs has migrated to OpenTofu for licensing reasons

**Examples**:
```bash
✅ GOOD:
tofu init
tofu plan -out=tofu.plan
tofu apply tofu.plan

❌ BAD:
terraform init
terraform plan
terraform apply
```

---

## File Organization

### Standard Module Structure

```
module-name/
├── main.tf              # Primary resource definitions
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── versions.tf          # Provider version constraints
├── providers.tf         # Provider configurations (optional)
├── data.tf              # Data sources (optional)
├── locals.tf            # Local values (optional)
└── CLAUDE.md            # AI context for this module
```

---

## Provider Version Constraints

### Required Providers Block

Always specify provider versions in `versions.tf`:

```hcl
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.34.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80.0"
    }
  }
}
```

**Use pessimistic constraints** (`~>`) to allow patch updates but prevent breaking changes.

---

## State Management

### Remote State Backend

All modules use Cloudflare R2 for remote state:

```hcl
terraform {
  backend "s3" {
    bucket                      = "tf-remote-state"
    key                         = "module-name/terraform.tfstate"
    region                      = "auto"
    endpoint                    = "https://316c0ba9429f31c14edaf70a48220769.r2.cloudflarestorage.com"
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_metadata_api_check     = true
  }
}
```

**Key naming**: `<module-name>/terraform.tfstate`

---

## Formatting and Style

### Use tofu fmt

Always format code before committing:

```bash
tofu fmt -recursive
```

**Pre-commit**: Run `tofu fmt` as part of commit workflow

---

### Variable Naming

- Use lowercase with underscores: `vpc_cidr_block`
- Be descriptive: `database_instance_class` not `db_class`
- Avoid abbreviations unless standard: `vpc` OK, `db` OK, `rg` avoid

---

### Resource Naming

**Pattern**: `<provider>_<resource_type>.<logical_name>`

```hcl
✅ GOOD:
resource "digitalocean_kubernetes_cluster" "main" {
  name    = "doks-prod"
  region  = "nyc3"
}

❌ BAD:
resource "digitalocean_kubernetes_cluster" "k8s_cluster_1" {
  name = "cluster"
}
```

---

## Module Dependencies

### Data Sources for Cross-Module References

Use `terraform_remote_state` data sources to reference outputs from other modules:

```hcl
data "terraform_remote_state" "digitalocean" {
  backend = "s3"
  config = {
    bucket   = "tf-remote-state"
    key      = "0-digitalocean/terraform.tfstate"
    region   = "auto"
    endpoint = "https://316c0ba9429f31c14edaf70a48220769.r2.cloudflarestorage.com"
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_metadata_api_check     = true
  }
}

# Reference output
resource "example" "foo" {
  vpc_id = data.terraform_remote_state.digitalocean.outputs.vpc_id
}
```

---

## Secret Management

### Use 1Password Provider

**Never hardcode secrets** - use 1Password provider:

```hcl
data "onepassword_item" "database_password" {
  vault = var.onepassword_vault_id
  title = "postgres-admin-password"
}

resource "azurerm_postgresql_flexible_server" "main" {
  administrator_password = data.onepassword_item.database_password.password
}
```

---

## Validation and Testing

### Validation Workflow

Before applying changes:

```bash
# 1. Validate syntax
tofu validate

# 2. Format check
tofu fmt -check -recursive

# 3. Generate plan
tofu plan -out=tofu.plan

# 4. Review plan carefully
# (manual step)

# 5. Apply saved plan
tofu apply tofu.plan
```

---

## Common Patterns

### Conditional Resources

Use `count` for conditional creation:

```hcl
resource "azurerm_network_security_group" "optional" {
  count               = var.create_nsg ? 1 : 0
  name                = "nsg-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
}
```

---

### Dynamic Blocks

Use `dynamic` blocks for repeating nested blocks:

```hcl
resource "azurerm_network_security_group" "main" {
  name                = "nsg-main"
  location            = var.location
  resource_group_name = var.resource_group_name

  dynamic "security_rule" {
    for_each = var.security_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }
}
```

---

## Anti-Patterns

### ❌ Don't Use Inline Backends

```hcl
# BAD - backend config in module code
terraform {
  backend "s3" {
    # ... hardcoded values
  }
}
```

**Use partial backend config** and provide values via `-backend-config` or environment variables.

---

### ❌ Don't Hardcode Values

```hcl
# BAD
resource "digitalocean_kubernetes_cluster" "main" {
  name   = "prod-cluster"  # hardcoded
  region = "nyc3"          # hardcoded
}

# GOOD
resource "digitalocean_kubernetes_cluster" "main" {
  name   = var.cluster_name
  region = var.region
}
```

---

### ❌ Don't Use Default Tags Everywhere

```hcl
# BAD - tags in every resource
resource "azurerm_virtual_machine" "vm1" {
  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

resource "azurerm_disk" "disk1" {
  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# GOOD - use provider default_tags (if supported) or locals
locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Repository  = "tf-msvcs"
  }
}

resource "azurerm_virtual_machine" "vm1" {
  tags = merge(local.common_tags, {
    Role = "application"
  })
}
```

---

## Related Documentation

- **Deployment Safety**: `.governance/ai/iac/conventions/deployment-safety.md`
- **IaC Overview**: `.governance/ai/iac/README.md`
- **System Rules**: `.governance/ai/core/rules/SYSTEM.md`
