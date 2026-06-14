# ngrok setup for reconciliation-services

Exposes the Dockerized reconciliation runtime (host port **8000**) over a public
ngrok tunnel on your Raspberry Pi, running persistently via systemd.

## 1. Install the ngrok agent

ngrok ships an APT repo for Raspberry Pi OS (Debian-based), which keeps it updated:

```bash
curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc \
  | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null \
  && echo "deb https://ngrok-agent.s3.amazonaws.com buster main" \
  | sudo tee /etc/apt/sources.list.d/ngrok.list \
  && sudo apt update && sudo apt install ngrok
```

> If `apt` install puts the binary somewhere other than `/usr/local/bin/ngrok`,
> run `which ngrok` and update `ExecStart=` in `ngrok-recon.service` to match.

Verify: `ngrok version`

## 2. Add your authtoken

Grab it from https://dashboard.ngrok.com/get-started/your-authtoken, then:

```bash
ngrok config add-authtoken <YOUR_TOKEN>
```

This writes the token into ngrok's own config so it stays out of git. (The
`authtoken` field in `ngrok.yml` is left blank for that reason.)

## 3. Install the config

```bash
mkdir -p ~/.config/ngrok
cp ngrok.yml ~/.config/ngrok/ngrok.yml
```

Then edit `~/.config/ngrok/ngrok.yml` and replace `YOUR-DEV-DOMAIN.ngrok-free.app`
with your account's free Dev Domain (find it at
https://dashboard.ngrok.com/domains). This domain is fixed and survives restarts,
so your public URL stays the same.

Confirm ngrok reads it: `ngrok config check`

## 4. Test it manually first

With your Docker stack up (`make up` / `docker compose ... up -d`):

```bash
ngrok start --all --config ~/.config/ngrok/ngrok.yml
```

You'll see a `https://<random>.ngrok-free.app` URL forwarding to `localhost:8000`.
Open it in a browser to confirm it reaches the recon service, then `Ctrl-C`.

## 5. Run it as a service (auto-start on boot)

```bash
sudo cp ngrok-recon.service /etc/systemd/system/
# edit User= in the unit if your account isn't 'pi'
sudo systemctl daemon-reload
sudo systemctl enable --now ngrok-recon
```

Check status / logs:

```bash
systemctl status ngrok-recon
journalctl -u ngrok-recon -f
```

## Your public URL

With the Dev Domain set in `ngrok.yml`, your URL is fixed — it's just the
`https://YOUR-DEV-DOMAIN.ngrok-free.app` you configured, and it stays the same
across restarts and reboots. The local inspection UI is at `http://<pi-ip>:4040`
(also queryable: `curl -s http://localhost:4040/api/tunnels`).

## Notes & next steps

- **Dev Domain**: free, one per account, auto-assigned (you can't rename it), and
  HTTPS-only. It's the free way to get a stable endpoint. For a custom/branded
  domain or multiple domains, you'd need a paid plan and would just change `url:`.
- **Security**: this tunnel is currently open to anyone with the URL. Since the
  service handles reconciliation data, consider adding a traffic policy
  (basic auth or IP allowlist) before sharing it widely — ngrok supports both via
  the endpoint's `traffic_policy` field. Happy to add that when you want it.
- **Port**: tied to `RECON_PORT` (default 8000) from `.env`. If you change that,
  update `upstream.url` in `ngrok.yml` to match.
