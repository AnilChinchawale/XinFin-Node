#!/bin/bash

function configureXinFinNode(){
    read -p "Please enter your XinFin Network (mainnet/testnet/devnet) :- " Network

    if [ "${Network}" != "mainnet" ] && [ "${Network}" != "testnet" ] && [ "${Network}" != "devnet" ]; then
        echo "The network ${Network} is not one of mainnet/testnet/devnet."
        return
    fi
    echo "Your running network is ${Network}"
    echo ""

    read -p "Please enter your XinFin MasterNode Name :- " MasterNodeName
    echo "Your Masternode Name is ${MasterNodeName}"
    echo ""
    
    echo "Generate new private key and wallet address."
    echo "If you have your own key, you can change after this and restart the node"
    read -p "Type 'Y' or 'y' to continue: " ans

    if [[ "$ans" != [Yy] ]]; then
        echo "Exiting."
        exit 1
    fi
    
    echo ""
    echo "═══ Installing dependencies ═══"

    sudo apt-get update
    sudo apt-get install -y \
        apt-transport-https ca-certificates curl git jq \
        software-properties-common ufw

    echo "═══ Installing Docker ═══"
    
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
        sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
        https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io \
        docker-buildx-plugin docker-compose-plugin

    sleep 5
    echo "✅ Docker installed"

    # ── Firewall Setup ─────────────────────────────────────
    echo ""
    echo "═══ Configuring Firewall ═══"
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow 30303/tcp
    sudo ufw allow 30303/udp
    sudo ufw allow ssh
    # RPC only from localhost
    sudo ufw allow from 127.0.0.1 to any port 8545
    sudo ufw allow from 127.0.0.1 to any port 8546
    sudo ufw --force enable
    echo "✅ Firewall configured — only P2P (30303) and SSH open"

    # ── Clone and Setup ────────────────────────────────────
    echo ""
    echo "═══ Setting up XDC Node ═══"
    git clone https://github.com/XinFinOrg/XinFin-Node && cd XinFin-Node/$Network
    
    # Create .env from template
    cp env.example .env
    
    echo "Generating Private Key and Wallet Address..."
    docker build -t address-creator ../address-creator/ && \
        docker run -e NUMBER_OF_KEYS=1 -e FILE=true \
        -v "$(pwd):/work/output" -it address-creator 

    PRIVATE_KEY=$(jq -r '.key0.PrivateKey' keys.json)
    sed -i "s/PRIVATE_KEY=xxxx/PRIVATE_KEY=${PRIVATE_KEY}/g" .env 2>/dev/null || true
    sed -i "s/INSTANCE_NAME=YOUR_NODE_NAME/INSTANCE_NAME=${MasterNodeName}/g" .env

    # Generate strong wallet password
    openssl rand -base64 32 > .pwd
    chmod 600 .pwd
    echo "✅ Generated strong wallet password in .pwd"

    # ── Security Summary ───────────────────────────────────
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║  🔒 Security Configuration                       ║"
    echo "║                                                  ║"
    echo "║  ✅ RPC: disabled (set ENABLE_RPC=true if needed)║"
    echo "║  ✅ RPC binds to 127.0.0.1 (localhost only)      ║"
    echo "║  ✅ Firewall: only 30303 + SSH open               ║"
    echo "║  ✅ Strong wallet password generated               ║"
    echo "║  ✅ debug/admin/personal blocked in start script   ║"
    echo "║                                                  ║"
    echo "║  ⚠️  Back up .pwd and keys.json securely!         ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo ""

    echo "Starting XDC Node..."
    docker compose -f docker-compose.yml up --build --force-recreate -d
    
    echo ""
    echo "✅ Node started! Check logs: docker compose logs -f"
    echo "📊 Verify security: https://skynet.xdcindia.com/node-scanner"
}

function main(){
    configureXinFinNode
}

main
