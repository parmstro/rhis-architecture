# RHIS Detailed Findings by Repository

**Review Date**: 2026-04-30

---

## Quick Reference Table

| Repository | Roles | YAML | arg_specs | Lint | Links | Priority | Score |
|------------|-------|------|-----------|------|-------|----------|-------|
| rhis-builder-idm | 18 | 79 | ❌ 0/18 | ❌ | ✅ | P0 | 2/10 |
| rhis-builder-satellite | 53 | 295 | ❌ 0/53 | ❌ | ✅ | P0 | 2/10 |
| rhis-builder-pipelines | 4 | 109 | ❌ 0/4 | ❌ | ❌ | P0 | 1/10 |
| rhis-builder-aws-lz | ~10 | ~50 | ❌ | ✅ | ❌ | P1 | 3/10 |
| rhis-builder-azure-lz | ~8 | ~40 | ❌ | ✅ | ❌ | P1 | 3/10 |
| rhis-builder-google-lz | 20 | ~30 | ❌ | ❌ | ❌ | P1 | 2/10 |
| rhis-builder-kvm-lz | 40 | ~100 | ❌ | ✅ | ❌ | P1 | 3/10 |
| rhis-builder-baremetal-init | 14 | ~48 | ❌ | ❌ | ❌ | P1 | 2/10 |
| rhis-builder-nbde | 1 | 27 | ✅ 1/1 | ❌ | ✅ | ✅ | 8/10 |
| rhis-builder-keycloak | ~5 | ~30 | ❌ | ❌ | ❌ | P2 | 2/10 |
| rhis-builder-yubi | ~3 | ~20 | ❌ | ❌ | ❌ | P2 | 2/10 |
| rhis-builder-oscap | ~4 | ~25 | ❌ | ❌ | ❌ | P2 | 2/10 |
| rhis-builder-convert2rhel | ~8 | ~35 | ❌ | ❌ | ❌ | P2 | 1/10 |
| rhis-builder-rhelupgrade | 20 | ~50 | ❌ | ❌ | ❌ | P2 | 1/10 |
| rhis-builder-imagebuilder | 22 | ~56 | ❌ | ❌ | ❌ | P2 | 2/10 |
| rhis-builder-day-2-ops | ~10 | ~40 | ❌ | ❌ | ❌ | P2 | 2/10 |
| rhis-builder-discovery-remaster | ~5 | ~30 | ❌ | ❌ | ❌ | P2 | 2/10 |
| rhis-builder-aap | ~12 | ~60 | ❌ | ❌ | ✅ | P0 | 3/10 |
| rhis-builder-provisioner | ~5 | ~35 | ❌ | ✅ | ❌ | P1 | 3/10 |
| rhis-builder-inventory | 0 | ~40 | N/A | ❌ | ✅ | P1 | 4/10 |
| rhis-provisioner-container | 20 | ~30 | ❌ | ❌ | ❌ | P1 | 3/10 |
| rhis-builder-project-template-files | ~10 | ~25 | ❌ | ❌ | ❌ | P3 | 3/10 |
| rhis-builder-role-template | 17 | ~20 | ❌ | ❌ | ✅ | P3 | 4/10 |
| rhis-architecture | 33 | ~40 | N/A | ❌ | ✅ | P3 | 7/10 |

**Priority Legend**:
- P0: Critical (Bootstrap Infrastructure, AAP)
- P1: High (Landing Zones, Core, Provisioner)
- P2: Medium (Security, Lifecycle)
- P3: Low (Templates, Documentation)

---

## Common Issues Across All Repositories

### Issue #1: Missing Argument Specifications

**Severity**: 🔴 CRITICAL  
**Affected**: 23/24 repos (96%)  
**Exception**: rhis-builder-nbde (recently fixed)

**Impact**:
- No type validation for role parameters
- No required parameter enforcement
- Poor documentation of role interfaces
- Silent failures when parameters are misconfigured
- Difficult for new contributors to understand role usage

**Recommendation**:
Add `meta/argument_specs.yml` to every role following the pattern from rhis-builder-nbde.

**Template**:
```yaml
---
# roles/<role_name>/meta/argument_specs.yml
argument_specs:
  main:
    short_description: <One-line role description>
    description:
      - <Detailed description>
      - <What the role does>
      - <Integration points>
    
    options:
      <role_prefix>_parameter_name:
        description: <Parameter description>
        type: <str|int|bool|list|dict>
        required: <true|false>
        default: <default_value>
        no_log: <true if sensitive>
```

### Issue #2: No Linting Configuration

**Severity**: 🔴 CRITICAL  
**Affected**: 21/24 repos (88%)  
**Has .ansible-lint**: rhis-builder-aws-lz, rhis-builder-azure-lz, rhis-builder-kvm-lz

**Impact**:
- No automated quality checks
- Deprecated features persist
- Inconsistent YAML formatting
- No CI/CD quality gates
- Technical debt accumulates unchecked

**Recommendation**:
Add `.ansible-lint` and `.yamllint` to all repos.

**Template .ansible-lint**:
```yaml
---
profile: production

exclude_paths:
  - .git/
  - .github/
  - tests/

skip_list:
  - experimental
  - role-name

warn_list:
  - no-changed-when
  - command-instead-of-module

enable_list:
  - yaml
  - fqcn-builtins
```

**Template .yamllint**:
```yaml
---
extends: default

rules:
  line-length:
    max: 160
    level: warning
  
  indentation:
    spaces: 2
    indent-sequences: true
```

### Issue #3: No Variable Prefixing

**Severity**: 🟠 HIGH  
**Affected**: 23/24 repos  
**Exception**: rhis-builder-nbde (recently fixed)

**Impact**:
- Variable namespace conflicts
- Difficult to trace variable sources
- Breaking changes when roles are reordered
- Poor debugging experience

**Recommendation**:
Prefix ALL role variables with role name, add backwards compatibility.

**Pattern** (from rhis-builder-nbde):
```yaml
# roles/<role_name>/defaults/main.yml
---
# New prefixed variables
<role_name>_parameter: value

# Backwards compatibility (DEPRECATED - remove in v3.0)
deprecated_parameter: "{{ <role_name>_parameter }}"

# Add deprecation warning in tasks/main.yml
- name: Warn about deprecated variables
  ansible.builtin.debug:
    msg: "WARNING: Variable 'deprecated_parameter' is deprecated. Use '<role_name>_parameter' instead."
  when: deprecated_parameter is defined and <role_name>_parameter is not defined
```

### Issue #4: Missing Architecture Documentation Links

**Severity**: 🟡 MEDIUM  
**Affected**: 16/24 repos (67%)  
**Has Links**: rhis-builder-idm, rhis-builder-satellite, rhis-builder-nbde, rhis-builder-aap, rhis-builder-inventory, rhis-builder-role-template, rhis-builder-project-template-files (partially), rhis-architecture

**Impact**:
- Poor discoverability of centralized documentation
- Difficult for new contributors to understand system context
- Fragmented documentation

**Recommendation**:
Add standard 6-link footer to all READMEs.

**Template**:
```markdown
## Architecture Documentation

This component is part of the [RHIS (Red Hat Infrastructure Standard)](https://github.com/parmstro/rhis-architecture) platform.

For comprehensive documentation:
- **[Architecture Overview](https://github.com/parmstro/rhis-architecture/blob/main/ARCHITECTURE.md)** - Complete system architecture and design
- **[Repository Inventory](https://github.com/parmstro/rhis-architecture/blob/main/REPOSITORIES.md)** - All RHIS components and relationships
- **[Deployment Guide](https://github.com/parmstro/rhis-architecture/blob/main/DEPLOYMENT.md)** - End-to-end deployment instructions
- **[Dependencies](https://github.com/parmstro/rhis-architecture/blob/main/DEPENDENCIES.md)** - Component dependencies and integration points
- **[Contributing](https://github.com/parmstro/rhis-architecture/blob/main/CONTRIBUTING.md)** - Development standards and workflow
```

---

## Priority-Based Remediation Plan

### P0 Repositories (Bootstrap Infrastructure + AAP)

**Immediate Action Required** - These are foundational services

1. **rhis-builder-idm** (18 roles)
   - Add argument_specs to all roles
   - Add linting configuration
   - Implement variable prefixing
   - Estimated effort: 60 hours

2. **rhis-builder-satellite** (53 roles!)
   - Add argument_specs to top 20 roles first
   - Add linting configuration
   - Audit manifest security
   - Estimated effort: 100 hours

3. **rhis-builder-pipelines** (4 roles)
   - Add architecture links
   - Add argument_specs
   - Document deploy_ vs build_ scripts
   - Estimated effort: 12 hours

4. **rhis-builder-aap** (~12 roles)
   - Add argument_specs
   - Add linting
   - Verify AAP 2.4/2.5 compatibility
   - Estimated effort: 30 hours

**Total P0 Effort**: 202 hours

### P1 Repositories (Landing Zones + Core)

**High Priority** - Critical for multi-cloud deployment

5-9. **Landing Zones** (5 repos)
   - Add architecture links to all
   - Add linting where missing
   - Add argument_specs to provisioning roles
   - Cross-repo consistency review
   - Estimated effort: 60 hours (12 per repo)

10-12. **Core** (3 repos)
   - rhis-builder-provisioner: Add argument_specs, architecture links
   - rhis-builder-inventory: Enhance documentation
   - rhis-provisioner-container: Document build process
   - Estimated effort: 30 hours

**Total P1 Effort**: 90 hours

### P2 Repositories (Security + Lifecycle)

**Medium Priority** - Important but can follow foundation work

13-16. **Security & Identity** (4 repos)
   - Add argument_specs with focus on security parameters
   - Security audit (no_log, secrets)
   - Add linting
   - Estimated effort: 50 hours

17-21. **Lifecycle Management** (5 repos)
   - Add argument_specs
   - Safety mechanism audit (rollback, pre-flight checks)
   - Add linting
   - Estimated effort: 60 hours

**Total P2 Effort**: 110 hours

### P3 Repositories (Templates + Docs)

**Lower Priority** - Support infrastructure

22-24. **Development Tools** (3 repos)
   - Update templates with best practices
   - Ensure template quality
   - Estimated effort: 20 hours

**Total P3 Effort**: 20 hours

---

## Grand Total Effort Estimate

- **P0 (Critical)**: 202 hours
- **P1 (High)**: 90 hours
- **P2 (Medium)**: 110 hours
- **P3 (Low)**: 20 hours

**Total**: 422 hours (~10.5 weeks with 1 FTE)

---

## Implementation Approach

### Wave 1 (Weeks 1-4): Foundation
Focus: P0 repos + Quick wins across all repos

- Add linting to ALL repos (quick win)
- Add architecture links to missing repos
- Begin P0 argument specs
- Document helper scripts

### Wave 2 (Weeks 5-8): Critical Roles
Focus: Complete P0 + Start P1

- Complete P0 argument specs
- P0 variable prefixing
- P1 landing zone improvements
- Security audit of P0 repos

### Wave 3 (Weeks 9-12): Consolidation
Focus: P1 + P2 + Quality Infrastructure

- Complete P1 and P2 argument specs
- Add CI/CD pipelines
- FQCN compliance audit
- Begin integration testing

---

**Document Status**: Complete  
**Next Update**: After Wave 1 completion
