#!/bin/bash
set -e

echo "╔══════════════════════════════════════════════════╗"
echo "║  XDC Network Node — Security Upgrade             ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# Preserve user config
echo "📋 Backing up your configuration..."
cp .env .env.backup 2>/dev/null && echo "  ✅ .env backed up" || echo "  ℹ️  No .env found (will use env.example)"
cp .pwd .pwd.backup 2>/dev/null && echo "  ✅ .pwd backed up" || true
cp nodekey nodekey.backup 2>/dev/null && echo "  ✅ nodekey backed up" || true

# Pull latest code
echo ""
echo "📥 Pulling latest code..."
git stash 2>/dev/null || true
git pull

# Restore user config (these are now gitignored, so no conflicts)
echo ""
echo "🔄 Restoring your configuration..."
if [ -f .env.backup ]; then
    mv .env.backup .env
    echo "  ✅ .env restored"
    
    # ── Auto-apply security fixes to existing .env ──
    
    # Fix RPC_ADDR if it's 0.0.0.0
    if grep -q "RPC_ADDR=0.0.0.0" .env; then
        sed -i 's/RPC_ADDR=0.0.0.0/RPC_ADDR=127.0.0.1/' .env
        echo "  🔒 Fixed RPC_ADDR: 0.0.0.0 → 127.0.0.1"
    fi
    
    # Fix WS_ADDR if it's 0.0.0.0
    if grep -q "WS_ADDR=0.0.0.0" .env; then
        sed -i 's/WS_ADDR=0.0.0.0/WS_ADDR=127.0.0.1/' .env
        echo "  🔒 Fixed WS_ADDR: 0.0.0.0 → 127.0.0.1"
    fi
    
    # Fix CORS if it's wildcard
    if grep -q 'RPC_CORS_DOMAIN=\*' .env; then
        sed -i 's/RPC_CORS_DOMAIN=\*/RPC_CORS_DOMAIN=http:\/\/localhost/' .env
        echo "  🔒 Fixed RPC_CORS_DOMAIN: * → http://localhost"
    fi
    
    # Remove debug from RPC_API if present
    if grep -q "debug" .env; then
        sed -i 's/,debug//g; s/debug,//g; s/debug//g' .env
        echo "  🔒 Removed 'debug' from RPC_API"
    fi
    
    # Remove admin from RPC_API if present
    if grep -qE "RPC_API.*admin" .env; then
        sed -i '/^RPC_API/s/,admin//g; /^RPC_API/s/admin,//g' .env
        echo "  🔒 Removed 'admin' from RPC_API"
    fi
    
    # Remove personal from RPC_API if present
    if grep -qE "RPC_API.*personal" .env; then
        sed -i '/^RPC_API/s/,personal//g; /^RPC_API/s/personal,//g' .env
        echo "  🔒 Removed 'personal' from RPC_API"
    fi
    
    # Add RPC_ADDR if missing
    if ! grep -q "RPC_ADDR" .env; then
        echo "RPC_ADDR=127.0.0.1" >> .env
        echo "  ➕ Added RPC_ADDR=127.0.0.1"
    fi
    
    # Add WS_ADDR if missing
    if ! grep -q "WS_ADDR" .env; then
        echo "WS_ADDR=127.0.0.1" >> .env
        echo "  ➕ Added WS_ADDR=127.0.0.1"
    fi
    
    # Add RPC_VHOSTS if missing
    if ! grep -q "RPC_VHOSTS" .env; then
        echo "RPC_VHOSTS=localhost" >> .env
        echo "  ➕ Added RPC_VHOSTS=localhost"
    fi
    
else
    cp env.example .env
    echo "  ℹ️  Created .env from env.example — edit with your settings"
fi

# Restore .pwd
if [ -f .pwd.backup ]; then
    mv .pwd.backup .pwd
    echo "  ✅ .pwd restored"
elif [ ! -f .pwd ]; then
    # Generate new password if none exists
    openssl rand -base64 32 > .pwd
    chmod 600 .pwd
    echo "  🔑 Generated new wallet password in .pwd — BACK THIS UP!"
fi

# Restore nodekey
if [ -f nodekey.backup ]; then
    mv nodekey.backup nodekey
    echo "  ✅ nodekey restored"
fi

# Pull latest Docker image
echo ""
echo "🐳 Pulling latest Docker image..."
docker compose pull 2>/dev/null || docker-compose pull 2>/dev/null || true

# Restart node
echo ""
echo "🔄 Restarting node..."
docker compose down 2>/dev/null || docker-compose down 2>/dev/null || true
docker compose up -d 2>/dev/null || docker-compose up -d 2>/dev/null

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║  ✅ Upgrade complete!                            ║"
echo "║                                                  ║"
echo "║  Security fixes applied automatically:           ║"
echo "║  • RPC bound to 127.0.0.1 (localhost only)       ║"
echo "║  • debug/admin/personal removed from RPC_API     ║"
echo "║  • CORS restricted to localhost                   ║"
echo "║                                                  ║"
echo "║  Verify: curl http://YOUR_IP:8545 should timeout ║"
echo "║  Scanner: https://skynet.xdcindia.com/node-scanner║"
echo "╚══════════════════════════════════════════════════╝"
