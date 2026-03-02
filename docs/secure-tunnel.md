# Secure Quick Tunnel (No Cloudflare Account)

If you need temporary cloud access without a Cloudflare account, do not tunnel the raw SmallTV endpoint directly. Instead, run a local token-protected proxy and tunnel that proxy.

Prerequisite: `cloudflared` must be installed for the tunnel step.
- macOS (Homebrew): `brew install cloudflared`
- Windows (winget): `winget install Cloudflare.cloudflared`
- Linux: https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/

## 1. Start the local secure proxy

```bash
export SMALLTV_DEVICE_IP=192.168.5.253
export SMALLTV_PROXY_TOKEN="replace-with-a-long-random-token"
python3 scripts/smalltv-secure-proxy.py
```

You can also pass values as CLI arguments (arguments override env vars):

```bash
python3 scripts/smalltv-secure-proxy.py \
  --device-ip 192.168.5.253 \
  --token "replace-with-a-long-random-token" \
  --host 127.0.0.1 \
  --port 18080
```

If `--device-ip` is omitted (and `SMALLTV_DEVICE_IP` is unset), the script
auto-detects `SmallTV-Ultra` devices by scanning your local `/24` subnet:
- Exactly one device found: it is selected automatically.
- No devices found: script exits and asks you to pass `--device-ip`.
- Multiple devices found: script exits and asks you to pass `--device-ip`.

## 2. Start a quick tunnel to the proxy

In another terminal:

```bash
cloudflared tunnel --url http://127.0.0.1:18080
```

## 3. Test the public URL

```bash
# Should fail (no token)
curl -i "https://<your-trycloudflare-url>/v.json"

# Should succeed (with token)
curl -i \
  -H "Authorization: Bearer replace-with-a-long-random-token" \
  "https://<your-trycloudflare-url>/v.json"
```

Expected behavior:
- No token: `401 Unauthorized`
- Valid token: `200 OK` and SmallTV JSON payload

## Notes

- This proxy exposes all SmallTV endpoints behind bearer-token auth.
- `GET /healthz` is intentionally unauthenticated.
- Keep the tunnel session short-lived and rotate the token between sessions.
- This means destructive endpoints are also reachable with a valid token.
- For stronger production controls (identity, service tokens, policies), use a named Cloudflare Tunnel with Cloudflare Access (requires a Cloudflare account).
