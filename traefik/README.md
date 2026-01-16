# Docker Network Proxy

## Quick Start

```
bin/up
```

## Enabling proxy support in a docker-compose.yml file

Add the following to the service you want proxied, substituting `myservice` and `myhostname` appropriately (`myservice` can be anything you want, but it must be unique across all your docker containers)
    
```yaml
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.myservice.rule=Host(`myhostname.local.fair.pm`)"
      - "traefik.http.routers.myservice-https.rule=Host(`myhostname.local.fair.pm`)"
      - "traefik.http.routers.myservice-https.tls=true"
    networks:
      - ${TRAEFIK_PROXY_NETWORK:-traefik}
```            

Add the following to the top level keys in the same docker-compose.yml file

```yaml
    networks:
      traefik:
        name: ${TRAEFIK_PROXY_NETWORK:-traefik}
        external: true
```
