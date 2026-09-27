# Apps

Everything the `apps` Flux Kustomization reconciles from [`../core/apps.yaml`](../core/apps.yaml). One directory per app, each with its own README.

An app that is `**disabled**` is still in the repository but commented out of [`kustomization.yaml`](kustomization.yaml), so Flux does not deploy it. The flag column on the `dashboard` app reads the `dashboard.${domain}/*` annotations on the HTTPRoutes, so routes are also how an app shows up on the landing page.

| App | Namespace | Endpoint | Reconciled |
|---|---|---|---|
| [`adminer`](adminer/README.md) | `adminer` | `https://adminer.${domain}` | enabled |
| [`alloy`](alloy/README.md) | `alloy` | `https://alloy.${domain}` | enabled |
| [`atuin`](atuin/README.md) | `atuin` | `https://atuin.${domain}` | enabled |
| [`backrest`](backrest/README.md) | `backrest` | `https://backrest.${domain}` | enabled |
| [`blocky`](blocky/README.md) | `blocky` | `https://blocky.${domain}` | **disabled** |
| [`blossom`](blossom/README.md) | `blossom` | `https://blossom.${domain}` | enabled |
| [`browserless`](browserless/README.md) | `browserless` | `https://browserless.${domain}` | enabled |
| [`byparr`](byparr/README.md) | `byparr` | - | **disabled** |
| [`cert-manager`](cert-manager/README.md) | `cert-manager` | - | enabled |
| [`city-roads`](city-roads/README.md) | `city-roads` | `https://city-roads.${domain}` | enabled |
| [`cloudflared`](cloudflared/README.md) | `cloudflared` | - | enabled |
| [`cloudnativepg`](cloudnativepg/README.md) | `cnpg-system` | `https://cnpg-platform.${domain}` (+1) | enabled |
| [`code-server`](code-server/README.md) | `code-server` | `https://code-server.${domain}` | enabled |
| [`comics`](comics/README.md) | `comics` | `https://api.comics.${domain}` (+2) | enabled |
| [`commander`](commander/README.md) | `commander` | - | enabled |
| [`cyberchef`](cyberchef/README.md) | `cyberchef` | `https://cyberchef.${domain}` | enabled |
| [`dashboard`](dashboard/README.md) | `dashboard` | `https://dashboard.${domain}` | enabled |
| [`deluge`](deluge/README.md) | `deluge` | `https://deluge.${domain}` | enabled |
| [`descheduler`](descheduler/README.md) | `descheduler` | - | enabled |
| [`excalidraw`](excalidraw/README.md) | `excalidraw` | `https://excalidraw.${domain}` | enabled |
| [`external-dns`](external-dns/README.md) | `external-dns` | - | enabled |
| [`external-services`](external-services/README.md) | `external-services` | - | enabled |
| [`ferretdb`](ferretdb/README.md) | `ferretdb` | - | **disabled** |
| [`flaresolverr`](flaresolverr/README.md) | `flaresolverr` | - | **disabled** |
| [`gatekeeper`](gatekeeper/README.md) | `gatekeeper-system` | - | enabled |
| [`grafana`](grafana/README.md) | `grafana` | `https://grafana.${domain}` | enabled |
| [`grist`](grist/README.md) | `grist` | `https://grist.${domain}` | enabled |
| [`http-echo`](http-echo/README.md) | `http-echo` | `https://http-echo.${domain}` | enabled |
| [`iptvnator`](iptvnator/README.md) | `iptvnator` | `https://api.iptvnator.${domain}` (+1) | enabled |
| [`jellyfin`](jellyfin/README.md) | `jellyfin` | `https://jellyfin.${domain}` | enabled |
| [`jsoncrack`](jsoncrack/README.md) | `jsoncrack` | `https://jsoncrack.${domain}` | enabled |
| [`kaniko`](kaniko/README.md) | `kaniko` | - | enabled |
| [`konflate`](konflate/README.md) | `konflate` | `https://konflate.${domain}` | enabled |
| [`kube-state-metrics`](kube-state-metrics/README.md) | `kube-state-metrics` | - | enabled |
| [`kube-system`](kube-system/README.md) | `kube-system` | - | enabled |
| [`kubeopencode`](kubeopencode/README.md) | `workspace` | - | enabled |
| [`loki`](loki/README.md) | `loki` | `https://loki.${domain}` | enabled |
| [`maddy`](maddy/README.md) | `maddy` | `https://maddy.${domain}` | enabled |
| [`metrics-server`](metrics-server/README.md) | `metrics-server` | - | enabled |
| [`miniflux`](miniflux/README.md) | `miniflux` | `https://miniflux.${domain}` | enabled |
| [`motrix`](motrix/README.md) | `motrix` | `https://motrix.${domain}` | **disabled** |
| [`nats`](nats/README.md) | `nats` | - | enabled |
| [`nfs-downloads`](nfs-downloads/README.md) | `nfs-downloads` | - | enabled |
| [`paint`](paint/README.md) | `paint` | `https://paint.${domain}` | enabled |
| [`pairdrop`](pairdrop/README.md) | `pairdrop` | `https://pairdrop.${domain}` | enabled |
| [`passed`](passed/README.md) | `passed` | `https://passed.${domain}` | enabled |
| [`plex`](plex/README.md) | `plex` | `https://plex.${domain}` | enabled |
| [`pocket-id`](pocket-id/README.md) | `pocket-id` | `https://pocket-id.${domain}` | enabled |
| [`prowlarr`](prowlarr/README.md) | `prowlarr` | `https://prowlarr.${domain}` | enabled |
| [`proxmox`](proxmox/README.md) | `proxmox` | `https://proxmox.${domain}` | enabled |
| [`pyload`](pyload/README.md) | `pyload` | `https://pyload.${domain}` | enabled |
| [`radarr`](radarr/README.md) | `radarr` | `https://radarr.${domain}` | enabled |
| [`radio`](radio/README.md) | `radio` | `https://radio.${domain}` (+1) | enabled |
| [`rathole`](rathole/README.md) | `rathole` | - | enabled |
| [`reactflux`](reactflux/README.md) | `reactflux` | `https://reactflux.${domain}` | enabled |
| [`redisinsight`](redisinsight/README.md) | `redisinsight` | `https://redisinsight.${domain}` | enabled |
| [`reloader`](reloader/README.md) | `reloader` | - | enabled |
| [`renovate`](renovate/README.md) | `renovate` | - | enabled |
| [`restfox`](restfox/README.md) | `restfox` | `https://restfox.${domain}` | enabled |
| [`rustfs`](rustfs/README.md) | `rustfs` | `https://rustfs.${domain}` | enabled |
| [`rustpad`](rustpad/README.md) | `rustpad` | `https://rustpad.${domain}` | enabled |
| [`samba`](samba/README.md) | `samba` | `https://samba.${domain}` | enabled |
| [`sftpgo`](sftpgo/README.md) | `sftpgo` | `https://sftpgo.${domain}` | enabled |
| [`shell2http`](shell2http/README.md) | `shell2http` | `https://shell2http.${domain}` | enabled |
| [`sidekick`](sidekick/README.md) | `sidekick` | `https://sidekick.${domain}` | enabled |
| [`sonarr`](sonarr/README.md) | `sonarr` | `https://sonarr.${domain}` | enabled |
| [`squid`](squid/README.md) | `squid` | `https://squid.${domain}` | **disabled** |
| [`stackedit`](stackedit/README.md) | `stackedit` | `https://stackedit.${domain}` | enabled |
| [`storm`](storm/README.md) | `storm` | `https://storm.${domain}` | enabled |
| [`swingmusic`](swingmusic/README.md) | `swingmusic` | `https://swingmusic.${domain}` | enabled |
| [`syslog`](syslog/README.md) | `syslog` | - | enabled |
| [`tailscale`](tailscale/README.md) | `tailscale` | - | enabled |
| [`thelounge`](thelounge/README.md) | `thelounge` | `https://thelounge.${domain}` | **disabled** |
| [`valkey`](valkey/README.md) | `valkey` | - | enabled |
| [`vaultwarden`](vaultwarden/README.md) | `vaultwarden` | `https://vaultwarden.${domain}` | enabled |
| [`victoria-logs`](victoria-logs/README.md) | `victoria-logs` | `https://victoria-logs.${domain}` | **disabled** |
| [`victoria-logs-collector`](victoria-logs-collector/README.md) | `victoria-logs-collector` | - | **disabled** |
| [`victoria-metrics`](victoria-metrics/README.md) | `victoria-metrics` | `https://victoria-metrics.${domain}` | enabled |
| [`vpn-egress-gateway`](vpn-egress-gateway/README.md) | `vpn-egress-gateway` | - | enabled |
| [`web-check`](web-check/README.md) | `web-check` | `https://web-check.${domain}` | enabled |
| [`weechat`](weechat/README.md) | `weechat` | `https://irc.${domain}` (+1) | enabled |
| [`whoami`](whoami/README.md) | `whoami` | `https://whoami.${domain}` | enabled |
| [`whoogle`](whoogle/README.md) | `whoogle` | `https://whoogle.${domain}` | **disabled** |
| [`ws-screenshot`](ws-screenshot/README.md) | `ws-screenshot` | `https://ws-screenshot.${domain}` | enabled |
| [`zipkin`](zipkin/README.md) | `zipkin` | - | enabled |
