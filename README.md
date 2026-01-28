*This project has been created as part of the 42 curriculum by sal-kawa.*

# Inception

## Description

Inception is about setting up a small infrastructure using Docker. The goal is to run a WordPress website with its own database, all inside containers, with proper separation and security.

The setup has three services:
- A web server (Nginx) that handles HTTPS traffic
- WordPress running on PHP-FPM
- MariaDB as the database

Each service runs in its own container, built from Debian Bookworm. They communicate through a Docker network and store data in volumes so nothing gets lost when containers restart.

The project follows the principle of one service per container, with no hacky workarounds like infinite loops or tail -f to keep containers alive.

## Instructions

### Prerequisites

- Docker with Compose v2
- Make
- Linux (Debian/Ubuntu works best)
- sudo access

### Setup

1. Clone the repo

2. Add domain to hosts file:
```bash
echo "127.0.0.1 sal-kawa.42.fr" | sudo tee -a /etc/hosts
```

3. Build and run:
```bash
make
```

4. Open https://sal-kawa.42.fr in your browser

### Commands

| Command | What it does |
|---------|--------------|
| `make` | Build and start everything |
| `make down` | Stop containers |
| `make clean` | Stop and clean Docker cache |
| `make fclean` | Remove everything including data |
| `make re` | Full rebuild |
| `make logs` | Watch container logs |
| `make ps` | Show container status |

### Credentials

Passwords are in the `secrets/` folder. WordPress admin is `sal-kawa_hell`.

## Resources

### References

*[Add documentation, articles, tutorials you used here]*

- 
- 
- 

### AI Usage

*[Describe how AI was used, for which tasks and which parts]*

- 
- 
- 

## Project Description

### How Docker is used

Each service has its own folder under `srcs/requirements/` with:
- A Dockerfile that builds the image from Debian Bookworm
- An entrypoint script that configures and starts the service

Docker Compose ties everything together - it defines the network, volumes, and how containers depend on each other. MariaDB starts first, then WordPress waits for it, then Nginx comes up last.

### Sources in the project

| File | Purpose |
|------|---------|
| `srcs/docker-compose.yml` | Defines services, networks, volumes |
| `srcs/.env` | Environment variables (domain, db name, etc.) |
| `srcs/requirements/mariadb/` | MariaDB container setup |
| `srcs/requirements/nginx/` | Nginx with SSL configuration |
| `srcs/requirements/wordpress/` | WordPress + PHP-FPM setup |
| `secrets/` | Password files mounted at runtime |

### Design choices

- **Debian Bookworm** as base image because it's stable and the second-to-last Debian version
- **Entrypoint scripts** handle initialization - they check if setup is needed and configure things at runtime
- **wp-cli** for WordPress installation instead of doing it manually through the web
- **Self-signed certificates** generated on first Nginx start
- **Secrets as files** instead of environment variables for passwords

---

## Comparisons

### Virtual Machines vs Docker

| | Virtual Machines | Docker |
|---|---|---|
| **What it is** | Full OS running on hypervisor | Processes sharing host kernel |
| **Size** | Gigabytes (full OS) | Megabytes (just app + deps) |
| **Startup** | Minutes | Seconds |
| **Isolation** | Complete (separate kernel) | Process-level (shared kernel) |
| **Resources** | Heavy (each VM needs RAM, CPU allocated) | Light (shares host resources) |
| **Use case** | Need different OS, strong isolation | Microservices, same OS, fast deployment |

For this project, Docker makes sense because we don't need different operating systems - all services run on Linux. Containers are faster to start and use less resources than spinning up three VMs.

### Secrets vs Environment Variables

| | Secrets | Environment Variables |
|---|---|---|
| **Storage** | Files mounted into container | Passed at container start |
| **Visibility** | Only accessible inside container filesystem | Visible in `docker inspect`, process list |
| **In images** | Never baked in | Can accidentally end up in image |
| **Management** | Separate files, easy to rotate | In compose file or .env |

This project uses Docker secrets (files in `/run/secrets/`). Passwords never appear in docker-compose.yml or get committed to git. The `secrets/` folder contains plain text files that Docker mounts at runtime.

### Docker Network vs Host Network

| | Docker Network (bridge) | Host Network |
|---|---|---|
| **Isolation** | Containers get their own IPs | Container uses host's network directly |
| **Port mapping** | Need to expose/publish ports | No mapping needed, uses host ports |
| **Container communication** | By container name (DNS) | By localhost |
| **Security** | Better - containers isolated | Worse - no network isolation |

This project uses a bridge network called `inception`. Containers talk to each other by name (wordpress connects to `mariadb:3306`). Only port 443 is exposed to the host.

### Docker Volumes vs Bind Mounts

| | Docker Volumes | Bind Mounts |
|---|---|---|
| **Location** | Docker manages it (`/var/lib/docker/volumes/`) | You specify exact path |
| **Portability** | Easy to backup with docker commands | Just regular folders |
| **Permissions** | Docker handles it | Can have permission issues |
| **Performance** | Slightly better on some systems | Direct filesystem access |

This project uses bind mounts with the `local` driver - data goes to `/home/sal-kawa/data/`. I chose this because:
- Easy to see what's stored (just browse the folder)
- Simple to backup (copy the folder)
- Required by the subject to store data in `/home/login/data`

---

**Author:** Shoaib Al-kawaldeh (sal-kawa)
