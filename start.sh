#!/bin/bash
set -e

BANK_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── Preflight checks ──────────────────────────────────────────────────────────
if [ -z "$JWT_SECRET" ]; then
  echo "ERROR: JWT_SECRET is not set. Export it before running this script."
  exit 1
fi
if [ -z "$SPRING_AI_OPENAI_API_KEY" ]; then
  echo "ERROR: SPRING_AI_OPENAI_API_KEY is not set. Export it before running this script."
  exit 1
fi

# ── Helpers ───────────────────────────────────────────────────────────────────
wait_for_port() {
  local name=$1 port=$2 timeout=${3:-60}
  echo "Waiting for $name on port $port..."
  for i in $(seq 1 $timeout); do
    if lsof -ti:$port > /dev/null 2>&1; then
      echo "$name is up (port $port)"
      return 0
    fi
    sleep 1
  done
  echo "ERROR: $name did not start within ${timeout}s. Check /tmp/${name}.log"
  exit 1
}

wait_for_log() {
  local name=$1 pattern=$2 timeout=${3:-60}
  echo "Waiting for '$pattern' in $name logs..."
  for i in $(seq 1 $timeout); do
    if grep -q "$pattern" /tmp/${name}.log 2>/dev/null; then
      return 0
    fi
    sleep 1
  done
  echo "ERROR: $name did not reach '$pattern' within ${timeout}s. Check /tmp/${name}.log"
  exit 1
}

# ── Stop any running instances ────────────────────────────────────────────────
echo "Stopping any existing servers..."
lsof -ti:9081,8092,8095 | xargs kill 2>/dev/null || true
sleep 1

# ── 1. bank-portal ───────────────────────────────────────────────────────────
echo ""
echo "Starting bank-portal (port 9081)..."
cd "$BANK_DIR/bank-portal"
mvn spring-boot:run > /tmp/bank-portal.log 2>&1 &

wait_for_log "bank-portal" "Started BankApplication"

# ── 2. bank-mcp-server ───────────────────────────────────────────────────────
echo ""
echo "Starting bank-mcp-server (port 8092)..."
cd "$BANK_DIR/bank-mcp-server"
mvn spring-boot:run > /tmp/bank-mcp-server.log 2>&1 &

wait_for_log "bank-mcp-server" "authenticated as helpdesk"

# ── 3. bank-ai-advisor ───────────────────────────────────────────────────────
echo ""
echo "Starting bank-ai-advisor (port 8095)..."
cd "$BANK_DIR/bank-ai-advisor"
mvn spring-boot:run > /tmp/bank-ai-advisor.log 2>&1 &

wait_for_log "bank-ai-advisor" "Started BankAdvisorApplication"

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo "All servers are up:"
echo "  bank-portal      → http://localhost:9081"
echo "  bank-mcp-server  → http://localhost:8092"
echo "  bank-ai-advisor  → http://localhost:8095"
echo ""
echo "Logs: /tmp/bank-portal.log | /tmp/bank-mcp-server.log | /tmp/bank-ai-advisor.log"
