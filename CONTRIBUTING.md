---
layout: default
title: Contributing to RHIS
---

# Contributing to RHIS

Thank you for your interest in contributing to RHIS (Red Hat Infrastructure
Standard).

Last Updated: 2026-10-16

---

## Table of Contents

- [Getting Started](#getting-started)
- [Development Environment](#development-environment)
- [Project Standards](#project-standards)
- [Contribution Workflow](#contribution-workflow)
- [Testing](#testing)
- [Documentation](#documentation)
- [Code Review Process](#code-review-process)

---

## Getting Started

RHIS is composed of 28 repositories. Contributions can be made to:
- Individual component repositories (rhis-builder-*)
- Central configuration (rhis-builder-inventory)
- Container build (rhis-provisioner-container)
- Architecture documentation (rhis-architecture)

### Before Contributing

1. Review [ARCHITECTURE.md](ARCHITECTURE.md) to understand the system
2. Review [REPOSITORIES.md](REPOSITORIES.md) to find the right repository
3. Check existing issues in the target repository
4. For large changes, open an issue first to discuss

---

## Development Environment

### Required Tools

- git
- ansible-core >= 2.14
- ansible-lint (production profile)
- podman (for container builds and provisioner)
- VS Code with Remote SSH (recommended)

### Setting Up

```bash
# Clone the repository you want to work on
git clone https://github.com/parmstro/rhis-builder-<component>
cd rhis-builder-<component>

# Create a branch for your work
git checkout -b feature/your-feature-name

# Install collections if needed
ansible-galaxy collection install -r requirements.yml
```

**Note**: Prefer RHEL RPM packages over `pip install` for Python dependencies.
Only use `pip` when absolutely necessary and no RPM equivalent exists.

---

## Project Standards

### Ansible Conventions

All RHIS Ansible roles and playbooks must follow these conventions:

#### 1. FQCN Required

Always use fully qualified collection names. Never use short module names.

```yaml
# Correct
- name: "Install package"
  ansible.builtin.dnf:
    name: httpd

# Wrong
- name: "Install package"
  dnf:
    name: httpd
```

#### 2. Variable Naming — Component-Scoped Prefixes

Variables use **component-scoped** prefixes (`satellite_`, `idm_`, `kvm_`,
`platform_`), NOT role-scoped prefixes.

```yaml
# Correct — component-scoped
satellite_admin_password: "..."
idm_realm_name: "EXAMPLE.CA"
platform_ssl_certs_base_dir: "/etc/ipa/private"

# Wrong — role-scoped
sat_primary_admin_password: "..."
install_idm_realm_name: "..."
```

#### 3. `when:` Placement

`when:` must immediately follow `name:` in tasks.

```yaml
# Correct
- name: "Configure firewall for service"
  when: service_enabled | bool
  ansible.posix.firewalld:
    service: http
    state: enabled
    permanent: true

# Wrong — when: at bottom
- name: "Configure firewall for service"
  ansible.posix.firewalld:
    service: http
    state: enabled
    permanent: true
  when: service_enabled | bool
```

#### 4. Output Formatting

Use `ansible.builtin.pause seconds: 0` with `prompt:` for multi-line
formatted output. Do not use `debug msg:`.

#### 5. Timestamps

Never use `now()` in `vars:` — use `ansible.builtin.set_fact` to freeze
timestamps.

#### 6. Fail Fast

Resolve and validate runtime dependencies early, before expensive work.

#### 7. localhost User Context

Use `lookup('env', ...)` for user/environment context on implicit localhost
connections, not `ansible_user`.

#### 8. Collection Overrides

RHIS intentionally uses collections beyond their declared `requires_ansible`.
This is by design, not an error.

### ansible-lint

All repos use the RHIS standard `.ansible-lint` configuration:

```yaml
---
profile: production

kinds:
  - playbook: "**/playbooks/*.{yml,yaml}"
  - tasks: "**/tasks/*.{yml,yaml}"
  - handlers: "**/handlers/*.{yml,yaml}"
  - vars: "**/{vars,defaults}/*.{yml,yaml}"
  - meta: "**/meta/*.{yml,yaml}"
  - yaml: "**/*.{yml,yaml}"
```

`kinds:` ordering matters: specific patterns (playbook, tasks, handlers,
vars, meta) before yaml catch-all. Repo-specific exceptions are appended
below the standard config with comments.

### File Naming

- Use `.yml` extension (not `.yaml`)
- Use snake_case for filenames
- Role names use underscores (not dashes)

### Git Standards

#### Commit Messages

Use conventional commits:

```
feat: add gateway TLS certificate support

Implement per-component certificate paths in platform_installer_config.
Each AAP component now references its own inventory group for cert paths.

- Gateway, hub, EDA, database each use their own group
- Growth topology fallbacks ensure groups always resolve
```

Prefixes: `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`

#### Branch Naming

- `feature/<description>` — new features
- `fix/<description>` — bug fixes
- `docs/<description>` — documentation only
- `refactor/<description>` — code refactoring

**Always use `main` as the default branch.** Never use "master" or "slave"
for branch names.

#### Push Policy

- Push directly to `main` for infrastructure/config changes
- Use PRs for feature branches
- No force-push to `main`

### Security

- Never commit secrets, tokens, or credentials
- Use Ansible Vault for all sensitive data
- Never run `pip install` unless absolutely necessary — use RHEL RPMs
- Token/credential cleanup is mandatory in container builds
- `ansible.cfg` must be redacted at end of container builds

---

## Contribution Workflow

### Internal Contributors

```bash
# Create feature branch
git checkout -b feature/add-new-capability

# Make changes, lint, test
ansible-lint .

# Commit with conventional format
git commit -m "feat: add new capability"

# Push and create PR (for feature work)
git push origin feature/add-new-capability
```

### External Contributors

```bash
# Fork the repository on GitHub, then clone your fork
git clone https://github.com/YOUR_USERNAME/rhis-builder-<component>
cd rhis-builder-<component>

# Add upstream remote
git remote add upstream https://github.com/parmstro/rhis-builder-<component>

# Create feature branch
git checkout -b feature/your-feature
git push origin feature/your-feature

# Create Pull Request on GitHub
```

---

## Testing

### ansible-lint (Required)

All code must pass `ansible-lint` with the production profile. Every RHIS
Ansible repo has `.ansible-lint` configuration (100% coverage).

```bash
ansible-lint .
```

### Manual Testing

1. **Use the provisioner container** — deploy to test infrastructure
2. **Verify functionality** against IdM, Satellite, AAP as applicable
3. **Check idempotency** — run playbook twice, second run should report
   no changes
4. **Test in both growth and enterprise topologies** where applicable

### Container Build Testing

For changes to repos baked into the container:

1. Make changes in local repo
2. Rebuild provisioner container
3. Test deployment from rebuilt container
4. Verify scan pipeline passes (Grype, Trivy, ClamAV)

---

## Documentation

### Repository-Level Documentation

| File | Status | Purpose |
|------|--------|---------|
| README.md | Required | What the repo does, how to use it |
| .ansible-lint | Required | Lint configuration (RHIS standard) |
| CLAUDE.md | Recommended | AI context for the repository |

### Configuration Documentation

- `inventory_template/` is the source of truth — document configuration
  there, not in `deployments/`
- `deployments/` is rendered output, never edited directly

### Inline Comments

Default to no comments. Only add one when the WHY is non-obvious:
a hidden constraint, a subtle invariant, a workaround for a specific bug.

```yaml
# Correct — explains a non-obvious constraint
# IdM requires the realm name in uppercase regardless of domain case
idm_realm: "{{ basevars_global_domain_name | upper }}"

# Wrong — states the obvious
# Set the admin password
idm_admin_password: "{{ vault_idm_admin_password }}"
```

---

## Code Review Process

### Review Criteria

PRs are reviewed for:

1. **Functionality** — does it work as intended?
2. **Convention compliance** — follows RHIS Ansible standards?
3. **Variable naming** — component-scoped prefixes?
4. **FQCN** — no short module names?
5. **`when:` placement** — immediately after `name:`?
6. **Security** — no secrets exposed?
7. **Idempotency** — can it run twice safely?
8. **Documentation** — changes reflected in docs?

### Automated Checks

PRs must pass:
- `ansible-lint` with production profile
- No committed secrets or credentials

---

## Adding a New rhis-builder Component

1. Create repository with RHIS standard `.ansible-lint`
2. Implement roles following conventions above
3. Add to `configure_rhis_builder.yml` in rhis-provisioner-container
4. Create helper scripts (`build_*.sh`) in rhis-provisioner-container
5. Add `COPY` directives to Containerfile
6. Update `rhis-builder-inventory` with configuration templates
7. Document in REPOSITORIES.md
8. Create Satellite hostgroup definition if applicable

---

## Maintainers

- **parmstro** — Project lead and primary author

---

## License

All RHIS components are licensed under GPL-3.0 unless otherwise specified.
By contributing, you agree that your contributions will be licensed under
the same license.

---

**Document Version**: 2.0
**Last Updated**: 2026-10-16
