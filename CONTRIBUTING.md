# Contributing to RHIS

Thank you for your interest in contributing to RHIS (Red Hat Infrastructure Standard)!

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

RHIS is composed of 25+ repositories. Contributions can be made to:
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

```bash
# Version control
git

# Ansible development
ansible-core >= 2.14
ansible-lint
yamllint

# Container development (for provisioner)
podman or docker

# Testing
molecule (for role testing)
pytest (for Python components)

# Documentation
markdown linter (markdownlint)
```

### Setting Up

```bash
# Clone the repository you want to work on
git clone https://github.com/parmstro/rhis-builder-<component>
cd rhis-builder-<component>

# Create a branch for your work
git checkout -b feature/your-feature-name

# Install development dependencies
pip install -r requirements-dev.txt  # if present
ansible-galaxy collection install -r requirements.yml
```

---

## Project Standards

### Ansible Best Practices

All RHIS Ansible roles and playbooks must follow:

1. **Variable Naming**: All role variables prefixed with role name
   ```yaml
   # Good
   tang_container_containers: []
   nbde_server_port: 8080
   
   # Bad
   containers: []
   port: 8080
   ```

2. **FQCN (Fully Qualified Collection Names)**
   ```yaml
   # Good
   - name: Install package
     ansible.builtin.package:
       name: httpd
   
   # Bad
   - name: Install package
     package:
       name: httpd
   ```

3. **Role Structure**
   ```
   roles/role_name/
   ├── README.md              # Required
   ├── defaults/
   │   └── main.yml          # Required (with comments)
   ├── meta/
   │   ├── main.yml          # Required (Galaxy metadata)
   │   └── argument_specs.yml # Required (input validation)
   ├── tasks/
   │   └── main.yml          # Required
   ├── templates/            # Optional
   ├── vars/                 # Optional
   └── handlers/             # Optional
   ```

4. **Documentation**
   - Every role MUST have comprehensive README.md
   - Every repository SHOULD have CLAUDE.md for AI context
   - Complex roles SHOULD have BEST_PRACTICES_ANALYSIS.md

5. **Backwards Compatibility**
   - Breaking changes require deprecation warnings
   - Old variable names supported for at least one version
   - Migration guides in README.md

### Code Style

#### YAML

```yaml
---
# Use 2-space indentation
# Use double quotes for strings
# Use trailing commas in lists (where appropriate)

- name: "Task description in imperative mood"
  ansible.builtin.package:
    name: "httpd"
    state: present
  when:
    - condition_one
    - condition_two
```

#### Ansible Task Naming

```yaml
# Good - Imperative, descriptive
- name: "Ensure httpd is installed"
- name: "Configure firewall for Tang service"
- name: "Verify deployment with clevis test"

# Bad - Vague, passive
- name: "Install"
- name: "Firewall"
- name: "Test"
```

### File Naming

- Use `.yml` extension (not `.yaml`)
- Use snake_case for filenames
- Role names use underscores (not dashes)

### Git Commit Messages

```
Short summary (50 chars or less)

Longer description if needed. Explain what and why, not how.

- Bullet points are fine
- Use imperative mood ("Add feature" not "Added feature")

Addresses: #issue-number (if applicable)
Breaking Change: Yes/No
```

Example:
```
Add backwards compatibility for containers variable

Implements Phase 2 from best practices analysis. Renames 'containers'
to 'tang_container_containers' following Ansible conventions while
maintaining backwards compatibility.

- Add deprecation warning when old variable detected
- Update all documentation with migration guide
- Create meta/argument_specs.yml for validation

Addresses: #42
Breaking Change: No (backwards compatible)
```

---

## Contribution Workflow

### 1. Fork and Clone

```bash
# Fork the repository on GitHub
# Then clone your fork
git clone https://github.com/YOUR_USERNAME/rhis-builder-component
cd rhis-builder-component

# Add upstream remote
git remote add upstream https://github.com/parmstro/rhis-builder-component
```

### 2. Create a Branch

```bash
# Update your main branch
git checkout main
git pull upstream main

# Create feature branch
git checkout -b feature/add-new-capability
```

Branch naming conventions:
- `feature/description` - New features
- `fix/description` - Bug fixes
- `docs/description` - Documentation only
- `refactor/description` - Code refactoring
- `test/description` - Test improvements

### 3. Make Changes

```bash
# Make your changes
vim roles/role_name/tasks/main.yml

# Test locally (see Testing section)
ansible-lint .
yamllint .
ansible-playbook tests/test.yml --syntax-check

# Commit changes
git add .
git commit -m "Add new capability"
```

### 4. Push and Create PR

```bash
# Push to your fork
git push origin feature/add-new-capability

# Create Pull Request on GitHub
# - Provide clear title and description
# - Reference any related issues
# - Request review from maintainers
```

### 5. Address Review Feedback

```bash
# Make requested changes
vim roles/role_name/tasks/main.yml

# Commit changes
git add .
git commit -m "Address review feedback: improve error handling"

# Push updates
git push origin feature/add-new-capability

# PR automatically updates
```

---

## Testing

### Ansible Lint

All Ansible code must pass `ansible-lint`:

```bash
# Install
pip install ansible-lint

# Run
ansible-lint .

# Fix auto-fixable issues
ansible-lint --fix .
```

Configuration: `.ansible-lint`
```yaml
---
profile: production

skip_list:
  - yaml[line-length]  # Only if absolutely necessary

warn_list:
  - experimental
```

### YAML Lint

```bash
# Install
pip install yamllint

# Run
yamllint .
```

Configuration: `.yamllint`
```yaml
---
extends: default

rules:
  line-length:
    max: 120
  indentation:
    spaces: 2
```

### Molecule Testing (for roles)

```bash
# Install
pip install molecule molecule-podman

# Create scenario
molecule init scenario -r role_name

# Run tests
molecule test
```

### Manual Testing

1. **Use rhis-provisioner-container**
   ```bash
   # Build container with your changes
   # Test in isolated environment
   ```

2. **Test in Lab Environment**
   - Deploy to test infrastructure
   - Verify functionality
   - Check for regressions

3. **Idempotency Testing**
   ```bash
   # Run playbook twice, should not report changes on second run
   ansible-playbook deploy.yml
   ansible-playbook deploy.yml  # Should be idempotent
   ```

### Test Coverage

- Unit tests for complex logic
- Integration tests for multi-role scenarios
- Idempotency tests for all roles
- Documentation accuracy

---

## Documentation

### README.md (Required for all roles)

Use this template:

```markdown
# role_name

Brief description of what the role does.

## Requirements

- RHEL version(s)
- Required collections
- Prerequisites

## Role Variables

### Required Variables

#### `rolename_variable`
Description of variable.

\`\`\`yaml
rolename_variable: "default_value"
\`\`\`

### Optional Variables

...

## Dependencies

List role dependencies.

## Example Playbook

\`\`\`yaml
---
- name: Deploy Component
  hosts: servers
  roles:
    - role_name
\`\`\`

## License

GPL-3.0

## Author

Your Name
```

### CLAUDE.md (Recommended)

Provide AI context:

```markdown
# CLAUDE.md

## Project Overview

Describe what this component does and why it exists.

## Architecture

Explain how it fits into RHIS architecture.

## Key Technical Details

- Important implementation notes
- Design decisions
- Known limitations

## Common Commands

\`\`\`bash
# Deploy
ansible-playbook deploy.yml

# Verify
./verify.sh
\`\`\`

## Dependencies

List dependencies on other RHIS components.
```

### BEST_PRACTICES_ANALYSIS.md (For mature roles)

See `rhis-builder-nbde/BEST_PRACTICES_ANALYSIS.md` for template.

### Inline Comments

```yaml
# Use comments sparingly - only for non-obvious logic
# Do NOT comment obvious things

# Good
# Workaround for RHEL 8.x bug in firewalld module
- name: "Reload firewall"
  ansible.builtin.command: firewall-cmd --reload

# Bad
# Install httpd package
- name: "Install httpd"
  ansible.builtin.package:
    name: httpd
```

---

## Code Review Process

### Review Criteria

PRs are reviewed for:

1. **Functionality**: Does it work as intended?
2. **Best Practices**: Follows Ansible and RHIS standards?
3. **Documentation**: Adequately documented?
4. **Tests**: Includes appropriate tests?
5. **Backwards Compatibility**: Breaking changes handled properly?
6. **Security**: No security vulnerabilities introduced?

### Review Timeline

- Initial review: Within 7 days
- Follow-up: Within 3 days of updates
- Merge: After approval from maintainer(s)

### Automated Checks

PRs must pass:
- `ansible-lint`
- `yamllint`
- Syntax checks
- CI/CD pipeline (if configured)

### Manual Review

Maintainers will review:
- Code quality
- Architecture alignment
- Documentation completeness
- Test coverage

---

## Specific Contribution Areas

### Adding a New rhis-builder Component

1. Create repository from template
2. Implement role following standards
3. Add to rhis-provisioner-container build
4. Update rhis-builder-inventory with examples
5. Document in REPOSITORIES.md
6. Create Satellite hostgroup definition

### Improving Existing Component

1. Review BEST_PRACTICES_ANALYSIS.md (if exists)
2. Implement improvements
3. Maintain backwards compatibility
4. Update documentation
5. Add migration notes

### Documentation Contributions

1. Identify documentation gaps
2. Add or improve documentation
3. Ensure consistency across repos
4. Update architecture docs if needed

### Container Improvements

1. Test changes in isolation
2. Update Containerfile
3. Document new dependencies
4. Rebuild and test hermetic packaging

---

## Community Guidelines

### Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Assume good intentions
- Help others learn

### Communication

- GitHub Issues: Bug reports, feature requests
- Pull Requests: Code contributions
- Discussions: General questions, ideas

### Recognition

Contributors will be:
- Listed in CONTRIBUTORS.md
- Credited in release notes
- Tagged in relevant commits

---

## Getting Help

- Review [ARCHITECTURE.md](ARCHITECTURE.md)
- Review [DEPLOYMENT.md](DEPLOYMENT.md)
- Open an issue in appropriate repository
- Tag maintainers for guidance

---

## Maintainers

- **parmstro** - Project lead

---

## License

All RHIS components are licensed under GPL-3.0 unless otherwise specified.

By contributing, you agree that your contributions will be licensed under the same license.

---

**Last Updated**: 2026-04-29
