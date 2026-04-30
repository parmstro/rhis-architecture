# RHIS Architecture Diagrams

Visual representations of the RHIS (Red Hat Infrastructure Standard) platform architecture, deployment flows, and component relationships.

All diagrams use Mermaid format and render natively on GitHub.

---

## Available Diagrams

### 1. [High-Level Architecture](01-high-level-architecture.md)
**Overview of the complete RHIS platform**

- Multi-layer architecture visualization
- Component relationships
- Deployment order
- Platform support (AWS, Azure, GCP, KVM, Bare Metal)

**Key Concepts:**
- Identity-first design with IdM
- Satellite-driven provisioning
- Hermetic container packaging
- Configuration as code

---

### 2. [Deployment Flow](02-deployment-flow.md)
**Step-by-step deployment sequence**

- Complete deployment timeline
- Administrator interactions
- Service initialization order
- Phase-by-phase breakdown with durations

**Phases Covered:**
1. Preparation (manual configuration)
2. Landing zone deployment
3. IdM deployment
4. Satellite deployment
5. Infrastructure services deployment

---

### 3. [Dependency Graph](03-dependency-graph.md)
**Repository dependencies and relationships**

- All 25 repositories mapped
- Deploy order visualization
- Service-to-service dependencies
- External dependencies (collections, products)

**Critical Path:**
```
Landing Zone → IdM → Satellite → Services
```

---

### 4. [Container Architecture](04-container-architecture.md)
**Hermetic packaging and container build strategy**

- Container layer breakdown
- Build-time vs runtime dependencies
- Air-gap deployment workflow
- Version management strategy

**Key Features:**
- All dependencies baked in
- 3-4 GB total size
- Reproducible deployments
- Offline deployment ready

---

### 5. [Integration and Data Flow](05-integration-dataflow.md)
**Service integrations and communication patterns**

- Identity authentication flow
- Provisioning workflow
- Service integration map
- Data persistence strategies
- Network communication patterns

**Integration Points:**
- IdM ↔ Satellite (realm integration)
- IdM ↔ Keycloak (identity backend)
- Satellite ↔ AAP (inventory sync)
- All services ↔ IdM (DNS, auth, certs)

---

## Diagram Format

All diagrams use **Mermaid** syntax, which renders automatically on GitHub, in VS Code (with extension), and many documentation platforms.

### Viewing Diagrams

**On GitHub:**
- Simply open any `.md` file in this directory
- Diagrams render automatically

**Locally in VS Code:**
- Install "Markdown Preview Mermaid Support" extension
- Open diagram file and use preview (Ctrl+Shift+V)

**In Documentation Sites:**
- MkDocs with mermaid plugin
- GitBook with mermaid support
- Docusaurus with mermaid plugin

### Editing Diagrams

1. Edit the Mermaid code blocks directly
2. Preview changes in VS Code or GitHub
3. Adjust styling with CSS classes
4. Commit and push

**Mermaid Documentation:** https://mermaid.js.org/

---

## Diagram Categories

### Architecture Diagrams
- High-level system design
- Component relationships
- Layer models

### Flow Diagrams
- Deployment sequences
- Data flows
- Process workflows

### Dependency Diagrams
- Repository relationships
- Service dependencies
- Integration points

### Technical Diagrams
- Container internals
- Network architecture
- Security architecture

---

## Adding New Diagrams

To add a new diagram:

1. Create a new `.md` file in this directory
2. Use numeric prefix for ordering (e.g., `06-new-diagram.md`)
3. Include Mermaid code block:
   ````markdown
   ```mermaid
   graph TB
       A[Component A]
       B[Component B]
       A --> B
   ```
   ````
4. Add description and context
5. Update this README with link and description
6. Commit and push

---

## Future Diagrams

Planned additions:

- [ ] Network topology diagram
- [ ] Security architecture deep-dive
- [ ] Backup and disaster recovery flow
- [ ] Multi-site architecture
- [ ] Performance and scaling patterns
- [ ] Development workflow
- [ ] CI/CD pipeline integration

---

**Last Updated**: 2026-04-29  
**Total Diagrams**: 5
