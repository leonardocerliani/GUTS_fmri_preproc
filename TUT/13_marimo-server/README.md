# 🔬 Marimo Lab Server - WORK IN PROGRESS


A self-hosted, private server that makes interactive Python (marimo) apps available to all members of a lab through a single browser URL — no installation required on the users' side.

---

## Quick test
Clone this repo anywhere on storm, cd into the repo and run

```bash
docker compose up -d --build
# docker ps - to inspect the processes
# docker compose down - to stop everything
```

Open the port `8998` and connect to `localhost:8998` from the local (home) browser.

---

## Purpose

Lab members SSH into a shared server and open `http://localhost:8998` in their local browser (via VS Code port forwarding or an SSH tunnel). They see a simple launcher page with links to all available apps. Each app is a fully interactive [marimo](https://marimo.io/) notebook running in its own container.

The server is inaccessible from the outside world. All traffic stays between the user's laptop and the server over the SSH connection.

---

## Architecture

```
Lab member's browser (laptop)
        │
        │  SSH tunnel / VS Code port forwarding
        │
        ▼
localhost:8998  (on the remote server)
        │
        ▼
┌───────────────────────────────┐
│   Caddy  (reverse proxy)      │
│   listens on :8998            │
│                               │
│  /          → launcher page   │  ← static HTML, served directly by Caddy
│  /pca/*     → pca:8080        │
│  /dimred/*  → dimred:8080     │
│  /explore/* → explore:8080    │
└───────────────────────────────┘
        │           │           │
        ▼           ▼           ▼
  ┌──────────┐ ┌──────────┐ ┌──────────┐
  │  pca     │ │  dimred  │ │  explore │
  │ marimo   │ │ marimo   │ │ marimo   │
  │ :8080    │ │ :8080    │ │ :8080    │
  └──────────┘ └──────────┘ └──────────┘
  (internal Docker network only — not exposed to host)
```

**Key design choices:**

- **Single exposed port** — only port `8998` is reachable. Users never need to know or type individual app ports.
- **Caddy as reverse proxy** — routes URL paths to the correct app container and strips the path prefix before forwarding, so each marimo app always sees requests at `/`.
- **Static HTML launcher** — a plain `index.html` served by Caddy itself. No Python process needed for the landing page.
- **Full container isolation** — each app runs in its own Docker container with only the dependencies it needs.
- **Auto-restart** — all containers use `restart: unless-stopped`, so everything comes back automatically after a server reboot.

---

## Project Structure

```
marimo-server/
├── docker-compose.yml        # Defines all services and their relationships
├── Caddyfile                 # Reverse proxy routing rules
│
├── launcher/
│   ├── index.html            # Landing page shown at http://localhost:8998/
│   └── Dockerfile            # Serves index.html via Python's built-in HTTP server
│
├── app-pca/
│   ├── app.py                # Marimo notebook: PCA Explorer
│   └── Dockerfile            # Builds and runs the marimo app
│
├── app-dimred/
│   ├── app.py                # Marimo notebook: Dimensionality Reduction Explorer
│   └── Dockerfile            # Builds and runs the marimo app
│
└── app-data-exploration/
    ├── app.py                # Marimo notebook: Data Exploration
    └── Dockerfile            # Builds and runs the marimo app
```

---

## How It Works

### Caddy (`Caddyfile`)

Caddy listens on port 8998 and acts as the single entry point:

- Requests to `/pca/*` are forwarded to the `pca` container at `pca:8080`, with the `/pca` prefix stripped.
- Similarly for `/dimred/*` → `dimred:8080` and `/explore/*` → `explore:8080`.
- All other requests (i.e. `/`) are served from `/srv`, which is the `launcher/` folder mounted as a volume — this serves `index.html`.

### Launcher (`launcher/index.html`)

A plain HTML page with links to each app using relative paths (`/pca/`, `/dimred/`, `/explore/`). Caddy serves this file directly — no backend process needed.

### Marimo Apps

Each app lives in its own folder with two files:

- **`app.py`** — a marimo notebook structured with `app = marimo.App()` and `@app.cell` decorated functions.
- **`Dockerfile`** — installs Python dependencies, copies `app.py`, and runs `marimo run app.py --host 0.0.0.0 --port 8080`.

The app containers are connected only to Docker's internal network — they are **not** directly exposed to the host machine.

### Docker Compose (`docker-compose.yml`)

Orchestrates all services:

- `caddy` — uses the official `caddy` image, mounts `Caddyfile` and the `launcher/` folder, and exposes port 8998 on the host.
- `pca`, `dimred`, `explore` — each built from their respective folder; no host ports exposed.
- All services use `restart: unless-stopped` to survive server reboots.

---

## Deployment

### Start everything

```bash
docker compose up -d --build
```

This builds all images and starts all containers in the background.

### Stop everything

```bash
docker compose down
```

### View logs

```bash
# All services
docker compose logs -f

# One service
docker compose logs -f caddy
docker compose logs -f pca
```

### Rebuild a single service (e.g. after editing an app)

```bash
docker compose build pca
docker compose up -d pca
```

---

## Accessing the Server

Lab members connect to the server via SSH. With **VS Code Remote SSH**, port `8998` is automatically forwarded to their local machine. They can then open:

```
http://localhost:8998
```

With a plain SSH client, they can forward the port manually:

```bash
ssh -L 8998:localhost:8998 user@your-server
```

---

## Adding a New App

Follow these steps to add a new marimo app called `myapp` as an example:

### 1. Create the app folder and files

```
app-myapp/
├── app.py
└── Dockerfile
```

**`app-myapp/app.py`** — write your marimo notebook:

```python
import marimo

app = marimo.App()

@app.cell
def _():
    import marimo as mo
    return mo,

@app.cell
def _(mo):
    mo.md("# My New App")
    return

if __name__ == "__main__":
    app.run()
```

**`app-myapp/Dockerfile`** — install your dependencies:

```dockerfile
FROM python:3.12-slim

RUN pip install marimo numpy  # add any other packages you need

WORKDIR /app
COPY app.py .

EXPOSE 8080

CMD ["marimo", "run", "app.py", "--host", "0.0.0.0", "--port", "8080"]
```

### 2. Add a service to `docker-compose.yml`

```yaml
  myapp:
    build: ./app-myapp
    restart: unless-stopped
```

### 3. Add a routing rule to `Caddyfile`

```caddy
handle /myapp/* {
    uri strip_prefix /myapp
    reverse_proxy myapp:8080
}
```

### 4. Add a link to `launcher/index.html`

```html
<li><a href="/myapp/">My New App</a></li>
```

### 5. Rebuild and restart

```bash
docker compose up -d --build
```

Your new app is now available at `http://localhost:8998/myapp/`.

---

## Tech Stack

| Component | Role |
|---|---|
| [marimo](https://marimo.io/) | Interactive, reactive Python notebooks |
| [Docker](https://www.docker.com/) & Docker Compose | Container orchestration and isolation |
| [Caddy](https://caddyserver.com/) | Reverse proxy and static file server |
| Python 3.12 | Runtime for marimo apps |
| Static HTML | Launcher landing page (no backend needed) |
