readme = r"""
# Marimo Lab Server Architecture

This project runs multiple interactive marimo apps behind a single entry point using Docker and a reverse proxy.

------------------------------------------------------------
OVERVIEW
------------------------------------------------------------

Users access everything through:

http://localhost:8998

From there:

/        → launcher page
/pca     → PCA Explorer
/dimred  → Dimensionality Reduction
/explore → Data Exploration

Only ONE port is exposed: 8998.

------------------------------------------------------------
ARCHITECTURE

User Browser
    |
    v
localhost:8998
    |
    v
Caddy Reverse Proxy (Docker)
    |
    +--> serves static launcher (HTML)
    |
    +--> routes /pca     -> pca container (marimo)
    +--> routes /dimred  -> dimred container (marimo)
    +--> routes /explore -> explore container (marimo)

------------------------------------------------------------
DOCKER SERVICES

1) Caddy (reverse proxy + static server)
- exposes port 8998
- serves launcher HTML
- routes requests to apps
- strips URL prefixes

2) Marimo apps (internal only)

Each app:
- runs inside its own container
- listens on 0.0.0.0:8080 internally
- NOT exposed directly to host

------------------------------------------------------------
ROUTING RULES (Caddy)

IMPORTANT:

/pca/*     -> pca:8080
/dimred/*  -> dimred:8080
/explore/* -> explore:8080

Prefix is stripped before forwarding so apps always see "/".

------------------------------------------------------------
LAUNCHER

A static HTML page served at "/".

Contains links:
- PCA Explorer
- Dimensionality Reduction
- Data Exploration

No ports exposed in UI.

------------------------------------------------------------
DEPLOYMENT

Start:
docker compose up -d --build

Stop:
docker compose down

------------------------------------------------------------
KEY DESIGN PRINCIPLES

1. Single entry point (8998 only)
2. No direct exposure of apps
3. Full container isolation
4. Reverse proxy handles routing
5. Static launcher (no backend needed)

------------------------------------------------------------
ADDING NEW APP

1. Create folder: app-new/
2. Add marimo app + Dockerfile
3. Add service to docker-compose.yml
4. Add route in Caddyfile:
   /new/* -> new:8080
5. Add link in launcher HTML

------------------------------------------------------------
TECH STACK

- marimo (interactive Python apps)
- Docker
- Caddy reverse proxy
- Static HTML launcher
- Python (numpy, matplotlib, etc.)

------------------------------------------------------------
RESULT

Single URL:

http://localhost:8998

All apps accessible without exposing multiple ports.
"""