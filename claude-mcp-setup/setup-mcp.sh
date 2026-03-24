#!/bin/bash

#
# Setup script for AAP MCP servers in Claude Code
# Adaptado para: AIOps Self-Healing Lab - Allan Roque
#
# AAP MCP: https://aap01.aroque.com.br:3000
# Organização: SRE
#
# Nomes e URLs idênticos à config do Cursor que funciona.
#

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'
BOLD='\033[1m'

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║   AAP MCP Server Setup for Claude Code                      ║"
echo "║   AIOps Self-Healing Lab                                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ---- Carregar credenciais ----
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CRED_FILE="${HOME}/.aap-credentials"

if [ -f "$CRED_FILE" ]; then
    echo -e "${GREEN}Carregando credenciais de ${CRED_FILE}${NC}"
    source "$CRED_FILE"
elif [ -f "${SCRIPT_DIR}/.aap-credentials" ]; then
    echo -e "${YELLOW}Usando credenciais locais (copie para ~/.aap-credentials para segurança)${NC}"
    source "${SCRIPT_DIR}/.aap-credentials"
fi

# ---- Pré-requisitos ----
echo ""
echo -e "${BOLD}Verificando pré-requisitos...${NC}"

if ! command -v claude &> /dev/null; then
    echo -e "${RED}Erro: Claude Code não instalado.${NC}"
    echo "Instale com: npm install -g @anthropic-ai/claude-code"
    exit 1
fi
echo -e "${GREEN}  Claude Code: OK${NC}"

if [ -z "$AAP_SERVER" ]; then
    echo -e "${RED}Erro: AAP_SERVER não definido.${NC}"
    echo 'export AAP_SERVER="https://aap01.aroque.com.br:3000"'
    exit 1
fi
echo -e "${GREEN}  AAP_SERVER: ${AAP_SERVER}${NC}"

if [ -z "$AAP_SERVICE_TOKEN" ]; then
    echo -e "${RED}Erro: AAP_SERVICE_TOKEN não definido.${NC}"
    echo 'export AAP_SERVICE_TOKEN="seu-token"'
    exit 1
fi
echo -e "${GREEN}  AAP_SERVICE_TOKEN: ***${AAP_SERVICE_TOKEN: -4}${NC}"

# ---- Definir toolsets (mesmos nomes do Cursor) ----
TOOLSETS=(
    "aap-mcp-job-management:job_management"
    "aap-mcp-inventory-management:inventory_management"
    "aap-mcp-system-monitoring:system_monitoring"
    "aap-mcp-user-management:user_management"
    "aap-mcp-security-compliance:security_compliance"
    "aap-mcp-platform-configuration:platform_configuration"
)

echo ""
echo -e "${BOLD}Registrando ${#TOOLSETS[@]} MCP servers...${NC}"
echo ""

# ---- Remover servers antigos (se existirem) ----
OLD_NAMES=("aap-job-mgmt" "aap-inventory" "aap-monitoring" "aap-user-mgmt" "aap-security" "aap-config")
for old in "${OLD_NAMES[@]}"; do
    claude mcp remove "$old" --scope user 2>/dev/null || true
done

# ---- Registrar cada toolset ----
for i in "${!TOOLSETS[@]}"; do
    IFS=':' read -r name endpoint <<< "${TOOLSETS[$i]}"
    URL="${AAP_SERVER}/${endpoint}/mcp"
    echo -e "${CYAN}[$((i+1))/${#TOOLSETS[@]}]${NC} Adicionando ${BOLD}${name}${NC}"
    echo -e "      URL: ${URL}"

    claude mcp add --transport http "$name" "$URL" \
        --header "Authorization: Bearer ${AAP_SERVICE_TOKEN}" \
        --scope user 2>&1 | tail -1

    if [ $? -eq 0 ]; then
        echo -e "      ${GREEN}OK${NC}"
    else
        echo -e "      ${RED}FALHOU${NC}"
    fi
    echo ""
done

# ---- Instalar rules file ----
echo -e "${BOLD}Instalando rules file...${NC}"

RULES_DIR="${HOME}/.claude/rules"
mkdir -p "$RULES_DIR"

if [ -f "${SCRIPT_DIR}/aap-mcp-tools.md" ]; then
    cp "${SCRIPT_DIR}/aap-mcp-tools.md" "${RULES_DIR}/aap-mcp-tools.md"
    echo -e "${GREEN}  Rules file instalado em ${RULES_DIR}/aap-mcp-tools.md${NC}"
else
    echo -e "${YELLOW}  aap-mcp-tools.md não encontrado, pulando...${NC}"
fi

# ---- Verificação ----
echo ""
echo -e "${BOLD}Verificando instalação...${NC}"
echo ""
claude mcp list 2>/dev/null || echo "(execute 'claude mcp list' manualmente para verificar)"

echo ""
echo -e "${GREEN}${BOLD}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                  SETUP COMPLETO!                             ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║                                                              ║"
echo "║  6 MCP servers configurados:                                 ║"
echo "║    aap-mcp-job-management         → Jobs, Workflows, EDA    ║"
echo "║    aap-mcp-inventory-management   → Inventários, Hosts      ║"
echo "║    aap-mcp-system-monitoring      → Health, Topology         ║"
echo "║    aap-mcp-user-management        → Users, Teams, RBAC      ║"
echo "║    aap-mcp-security-compliance    → Credentials, Audit      ║"
echo "║    aap-mcp-platform-configuration → Settings, EE, Notif.    ║"
echo "║                                                              ║"
echo "║  AAP MCP: ${AAP_SERVER}              ║"
echo "║  Organização: SRE                                            ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
