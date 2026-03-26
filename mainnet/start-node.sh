#!/bin/bash

# ══════════════════════════════════════════════════════════════
# XDC Node Start Script — Security Hardened
# ══════════════════════════════════════════════════════════════

set -e

# ── Wallet Setup ──────────────────────────────────────────────
if [ ! -d /work/xdcchain/XDC/chaindata ]; then
    wallet=$(XDC account new --password /work/.pwd --datadir /work/xdcchain | awk -F '[{}]' '{print $2}')
    echo "Initializing Genesis Block"
    coinbaseaddr="$wallet"
    coinbasefile=/work/xdcchain/coinbase.txt
    touch $coinbasefile
    if [ -f "$coinbasefile" ]; then
        echo "$coinbaseaddr" >"$coinbasefile"
    fi
    XDC init --datadir /work/xdcchain /work/genesis.json
else
    wallet=$(XDC account list --datadir /work/xdcchain | head -n 1 | awk -F '[{}]' '{print $2}')
fi

# ── Bootnodes ─────────────────────────────────────────────────
input="/work/bootnodes.list"
bootnodes=""
while IFS= read -r line; do
    if [ -z "${bootnodes}" ]; then
        bootnodes=$line
    else
        bootnodes="${bootnodes},$line"
    fi
done <"$input"

# ── Log Level ─────────────────────────────────────────────────
log_level=${LOG_LEVEL:-2}

# ── Sync Mode ─────────────────────────────────────────────────
sync_mode=${SYNC_MODE:-full}
gc_mode=${GC_MODE:-archive}

# ── Ethstats ──────────────────────────────────────────────────
INSTANCE_IP=$(curl -sf https://checkip.amazonaws.com 2>/dev/null || echo "unknown")
netstats="${INSTANCE_NAME:-XF_MasterNode}:xinfin_xdpos_hybrid_network_stats@stats.xinfin.network:3000"

echo "Starting XDC node..."
echo "  Wallet: ${wallet}"
echo "  Sync: ${sync_mode} | GC: ${gc_mode}"
echo "  RPC enabled: ${ENABLE_RPC:-false}"

# ── Base Arguments ────────────────────────────────────────────
args=(
    --ethstats "${netstats}"
    --bootnodes "${bootnodes}"
    --syncmode "${sync_mode}"
    --gcmode "${gc_mode}"
    --datadir /work/xdcchain
    --XDCx.datadir /work/xdcchain/XDCx
    --networkid 50
    --port 30303
    --unlock "${wallet}"
    --password /work/.pwd
    --mine
    --gasprice "1"
    --targetgaslimit "420000000"
    --verbosity "${log_level}"
)

# ── RPC Configuration (Security Hardened) ─────────────────────
if echo "${ENABLE_RPC}" | grep -iq "true"; then

    # ══ SECURITY CHECKS ══════════════════════════════════════
    
    # Block dangerous namespaces
    if echo "${RPC_API}" | grep -iq "debug"; then
        echo ""
        echo "╔══════════════════════════════════════════════════╗"
        echo "║  SECURITY ERROR: 'debug' detected in RPC_API    ║"
        echo "║                                                  ║"
        echo "║  debug_setHead can DESTROY your chain state.     ║"
        echo "║  debug_writeMemProfile can write arbitrary files.║"
        echo "║                                                  ║"
        echo "║  Remove 'debug' from RPC_API in your .env file.  ║"
        echo "╚══════════════════════════════════════════════════╝"
        echo ""
        exit 1
    fi

    if echo "${RPC_API}" | grep -iq "admin"; then
        echo ""
        echo "╔══════════════════════════════════════════════════╗"
        echo "║  SECURITY ERROR: 'admin' detected in RPC_API    ║"
        echo "║                                                  ║"
        echo "║  admin_startHTTP can open new RPC listeners.     ║"
        echo "║  admin_addPeer enables eclipse attacks.          ║"
        echo "║                                                  ║"
        echo "║  Remove 'admin' from RPC_API in your .env file.  ║"
        echo "╚══════════════════════════════════════════════════╝"
        echo ""
        exit 1
    fi

    if echo "${RPC_API}" | grep -iq "personal"; then
        echo ""
        echo "╔══════════════════════════════════════════════════╗"
        echo "║  SECURITY ERROR: 'personal' in RPC_API          ║"
        echo "║                                                  ║"
        echo "║  personal_importRawKey exposes key management.   ║"
        echo "║  Remove 'personal' from RPC_API in your .env.    ║"
        echo "╚══════════════════════════════════════════════════╝"
        echo ""
        exit 1
    fi

    # Warn if binding to all interfaces
    RPC_ADDR="${RPC_ADDR:-127.0.0.1}"
    if [ "${RPC_ADDR}" = "0.0.0.0" ]; then
        echo ""
        echo "⚠️  WARNING: RPC binding to 0.0.0.0 (all interfaces)"
        echo "   Your node's signing key will be accessible from the internet!"
        echo "   Use RPC_ADDR=127.0.0.1 unless behind a reverse proxy with auth."
        echo ""
        sleep 3
    fi

    # Warn if CORS is wildcard
    if [ "${RPC_CORS_DOMAIN}" = "*" ]; then
        echo "⚠️  WARNING: RPC_CORS_DOMAIN=* allows any website to access your RPC"
        echo "   Set specific domains: RPC_CORS_DOMAIN=http://localhost"
    fi

    # ══ ADD RPC ARGS ═════════════════════════════════════════
    args+=(
        --rpc
        --rpcaddr "${RPC_ADDR}"
        --rpcport "${RPC_PORT:-8545}"
        --rpcapi "${RPC_API:-net,web3,XDPoS}"
        --rpccorsdomain "${RPC_CORS_DOMAIN:-http://localhost}"
        --rpcvhosts "${RPC_VHOSTS:-localhost}"
        --store-reward
        --ws
        --wsaddr "${WS_ADDR:-127.0.0.1}"
        --wsport "${WS_PORT:-8546}"
        --wsapi "${WS_API:-net,web3,XDPoS}"
        --wsorigins "${WS_ORIGINS:-http://localhost}"
    )
    
    echo "  RPC: ${RPC_ADDR}:${RPC_PORT:-8545} | API: ${RPC_API:-net,web3,XDPoS}"
    echo "  WS:  ${WS_ADDR:-127.0.0.1}:${WS_PORT:-8546}"
else
    echo "  RPC: disabled (set ENABLE_RPC=true to enable)"
fi

# ── Start Node ────────────────────────────────────────────────
exec XDC "${args[@]}" 2>&1
