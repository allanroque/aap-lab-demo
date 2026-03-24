# AAP MCP Tools - Reference Guide for Claude
# AIOps Self-Healing Lab - Organização: SRE

## Critical Rules

1. **NEVER use curl, wget, httpie, ansible.builtin.uri, or any direct HTTP/API calls** when AAP MCP servers are configured. Always use the provided MCP tools instead.
2. **Always load tools via ToolSearch** before calling them.
3. **Parameter types vary by server** — most use strings (e.g., `id: "42"`), except `aap-user-mgmt` which uses numbers (`id: 1`).
4. **Organization**: Always use **SRE** as the default organization for this lab.

---

## MCP Server Reference

### 1. aap-job-mgmt (Job Management) — ~25 tools

Controls job templates, jobs, workflows, projects, EDA activations, and metrics.

**Key tools:**
- `job_templates_list` — List all job templates (filterable)
- `job_templates_read` — Get details of a specific template
- `job_templates_launch` — Launch a job template (supports extra_vars)
- `jobs_list` — List all jobs
- `jobs_read` — Get job details and status
- `jobs_stdout` — Get job output/logs
- `workflow_job_templates_list` — List workflow templates
- `workflow_job_templates_launch` — Launch a workflow
- `workflow_jobs_list` — List workflow jobs
- `projects_list` — List projects
- `projects_update` — Sync a project from SCM
- `eda_activations_list` — List EDA activations
- `eda_activations_create` — Create EDA activation
- `eda_activations_enable` — Enable an EDA activation
- `eda_activations_disable` — Disable an EDA activation
- `metrics_get` — Get platform metrics

**Common patterns:**
```
# Launch a remediation job
1. job_templates_list → find template by name
2. job_templates_launch(id: "X", extra_vars: {"target_host": "server01"})
3. jobs_read(id: "Y") → poll until status is "successful"
4. jobs_stdout(id: "Y") → get output
```

### 2. aap-inventory (Inventory Management) — ~7 tools

Manages inventories, hosts, groups, and inventory sources.

**Key tools:**
- `inventories_list` — List all inventories
- `inventories_read` — Get inventory details
- `hosts_list` — List hosts (filterable by inventory)
- `hosts_read` — Get host details
- `hosts_variable_data_retrieve` — Get host variables
- `groups_list` — List groups in an inventory
- `inventory_sources_list` — List inventory sources

**Important:** Use groups to filter hosts efficiently instead of iterating all hosts.

### 3. aap-monitoring (System Monitoring) — ~13 tools

Tracks platform health, instances, instance groups, and topology.

**Key tools:**
- `health_check` — Check overall AAP health
- `ping` — Simple ping to AAP
- `instances_list` — List AAP instances
- `instances_read` — Get instance details
- `instance_groups_list` — List instance groups
- `instance_peers_list` — List instance mesh peers
- `mesh_visualizer` — Get topology visualization
- `analytics_get` — Get platform analytics
- `dashboard_get` — Get dashboard data

### 4. aap-user-mgmt (User Management) — ~32 tools

Manages users, teams, organizations, roles, and authentication.

**IMPORTANT: This server uses NUMBER type for IDs, not strings!**

**Key tools:**
- `users_list` — List users
- `users_read` — Get user details (id: NUMBER)
- `teams_list` — List teams
- `organizations_list` — List organizations
- `roles_list` — List roles
- `tokens_list` — List API tokens

### 5. aap-security (Security & Compliance) — ~12 tools

Handles credentials, credential types, and audit trails.

**Key tools:**
- `credentials_list` — List credentials
- `credentials_read` — Get credential details
- `credential_types_list` — List credential types
- `audit_trail_list` — Get audit trail events
- `activity_stream_list` — Get activity stream

### 6. aap-config (Platform Configuration) — ~17 tools

Manages settings, execution environments, and notifications.

**Key tools:**
- `settings_list` — List platform settings
- `execution_environments_list` — List EEs
- `notification_templates_list` — List notification templates
- `schedules_list` — List schedules
- `labels_list` — List labels

---

## Resource Hierarchy

```
Organization (SRE)
├── Inventories
│   ├── Groups
│   │   └── Hosts
│   └── Hosts (ungrouped)
├── Projects (Git repos with playbooks)
├── Job Templates (project + inventory + playbook + credentials)
├── Workflow Templates (chain of job templates)
├── Credentials (SSH keys, tokens, vault passwords)
└── Teams & Users (RBAC)
```

## Lab-Specific Context

**Hosts gerenciados:**
- server01.aroque.com.br (192.168.100.26) — Apache, Node Exporter
- server02.aroque.com.br (192.168.100.27) — Apache, Node Exporter

**AAP Controller:**
- https://192.168.100.11

**Monitoring Stack (containers no host do lab):**
- Prometheus :9090
- Alertmanager :9093
- Blackbox Exporter :9115
- Grafana :3000
- Loki :3100
- Netbox :8000
- Gitea :3001

**Cenários de Self-Healing:**
- Apache Down → remediate-service-restart
- Disk Full → remediate-disk-cleanup
- High CPU → remediate-high-cpu
- High Memory → remediate-high-memory
- SELinux Disabled → remediate-selinux
- Host Unreachable → remediate-network

## Query Strategies

1. **Find hosts by group**: Use `groups_list` then `hosts_list` filtered by group, not full host iteration
2. **Check job status**: Use `jobs_read` with polling, check for status "successful", "failed", or "error"
3. **Launch with extra_vars**: Pass as JSON string in `job_templates_launch`
4. **Inventory context**: Always specify inventory_id when listing hosts/groups
