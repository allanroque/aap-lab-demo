#!/bin/bash

#
# Remove all AAP MCP servers from Claude Code
#

set -e

echo "Removendo AAP MCP servers do Claude Code..."

SERVERS=(
    "aap-mcp-job-management"
    "aap-mcp-inventory-management"
    "aap-mcp-system-monitoring"
    "aap-mcp-user-management"
    "aap-mcp-security-compliance"
    "aap-mcp-platform-configuration"
    "aap-job-mgmt"
    "aap-inventory"
    "aap-monitoring"
    "aap-user-mgmt"
    "aap-security"
    "aap-config"
)

for server in "${SERVERS[@]}"; do
    echo "  Removendo ${server}..."
    claude mcp remove "$server" --scope user 2>/dev/null || true
done

echo ""
echo "Todos os AAP MCP servers foram removidos."
echo "Verificar: claude mcp list"
