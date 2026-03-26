# XDC Node Security Guide

## ⚠️ Before You Deploy

1. **Generate a strong wallet password:**
   ```bash
   openssl rand -base64 32 > mainnet/.pwd
   chmod 600 mainnet/.pwd
   ```

2. **Copy env.example to .env:**
   ```bash
   cp mainnet/env.example mainnet/.env
   nano mainnet/.env  # Set your INSTANCE_NAME and CONTACT_DETAILS
   ```

3. **Configure firewall:**
   ```bash
   sudo ufw default deny incoming
   sudo ufw default allow outgoing
   sudo ufw allow 30303/tcp
   sudo ufw allow 30303/udp
   sudo ufw allow ssh
   sudo ufw enable
   ```

## 🔒 RPC Security

RPC is **disabled by default**. If you need it:

1. Set `ENABLE_RPC=true` in `.env`
2. RPC binds to `127.0.0.1` (localhost only) — this is correct
3. Use a reverse proxy (nginx/caddy) with authentication for external access
4. **NEVER set `RPC_ADDR=0.0.0.0`** unless behind a firewall

### Dangerous RPC Namespaces — NEVER Enable

| Namespace | Why It's Dangerous |
|-----------|-------------------|
| `debug` | `debug_setHead("0x0")` **destroys your entire chain state** |
| `admin` | `admin_startHTTP` opens new RPC endpoints on any port |
| `personal` | `personal_importRawKey` exposes key management |
| `miner` | `miner_stop` halts block production |

The start script will **refuse to start** if debug, admin, or personal are in `RPC_API`.

### Safe RPC_API for Validators
```
RPC_API=net,web3,XDPoS
```

### If You Need Block Queries (dApp/RPC node)
```
RPC_API=eth,net,web3,XDPoS,txpool
```
Note: `eth` includes `eth_sign` and `eth_sendTransaction`. Use a reverse proxy to block these methods if exposed externally.

## ✅ Post-Deployment Security Check

Run from an **external machine** (not the server itself):

```bash
# Should FAIL (timeout/refused) — RPC not accessible
curl -sf --connect-timeout 3 http://YOUR_SERVER_IP:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"rpc_modules","params":[],"id":1}' \
  && echo "❌ VULNERABLE — RPC exposed!" \
  || echo "✅ SECURE — RPC not accessible"

# Also check port 8989 (Docker-mapped)
curl -sf --connect-timeout 3 http://YOUR_SERVER_IP:8989 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"rpc_modules","params":[],"id":1}' \
  && echo "❌ VULNERABLE — RPC exposed on 8989!" \
  || echo "✅ SECURE"
```

## 🔗 Live Security Scanner

Check your node's security score: https://skynet.xdcindia.com/node-scanner

## 📋 Security Checklist

- [ ] Strong wallet password in `.pwd` (not empty)
- [ ] Unique nodekey (not the shared bootnode key)
- [ ] Firewall enabled (only 30303 + SSH open)
- [ ] `ENABLE_RPC=false` (or `RPC_ADDR=127.0.0.1`)
- [ ] `RPC_API` does not contain debug/admin/personal
- [ ] `RPC_CORS_DOMAIN` is not `*`
- [ ] SSH key-based authentication (password auth disabled)
- [ ] Docker running as non-root (or with resource limits)
- [ ] `.env`, `.pwd`, `nodekey` NOT committed to git

## Reporting Security Issues

If you discover a vulnerability, please report it responsibly to security@xdc.org or via GitHub Security Advisories.
