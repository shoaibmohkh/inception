# Developer Documentation

## Setting up from scratch

### Prerequisites

You need:
- Docker and Docker Compose (v2)
- Make
- A Linux system (tested on Debian/Ubuntu)
- sudo access (for creating data directories)

### Project structure

```
.
├── Makefile
├── secrets/
│   ├── db_password.txt
│   ├── db_root_password.txt
│   ├── wp_admin_password.txt
│   └── wp_user_password.txt
└── srcs/
    ├── .env
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   └── tools/entrypoint.sh
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/nginx.conf
        │   └── tools/entrypoint.sh
        └── wordpress/
            ├── Dockerfile
            └── tools/entrypoint.sh
```

### Configuration files

**srcs/.env** - Environment variables shared by containers:
```
DOMAIN_NAME=sal-kawa.42.fr
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
DB_HOST=mariadb
WP_URL=https://sal-kawa.42.fr
WP_TITLE=Inception
WP_ADMIN_USER=sal-kawa_hell
WP_ADMIN_EMAIL=sal-kawa@student.42.fr
WP_USER=normaluser
WP_USER_EMAIL=user@student.42.fr
```

If you fork this, change `sal-kawa` to your login everywhere.

### Secrets

The `secrets/` folder has password files. Each file contains one password, no newline at the end.

Docker Compose mounts these into containers at `/run/secrets/`. They never get baked into images.

To generate new passwords:
```bash
openssl rand -base64 24 > secrets/db_password.txt
openssl rand -base64 24 > secrets/db_root_password.txt
openssl rand -base64 24 > secrets/wp_admin_password.txt
openssl rand -base64 24 > secrets/wp_user_password.txt
```

---

## Building and launching

### Using Make

| Command | What happens |
|---------|--------------|
| `make` | Creates data dirs, builds images, starts containers |
| `make up` | Same as above |
| `make down` | Stops containers |
| `make clean` | Stops + prunes unused Docker stuff |
| `make fclean` | Nukes everything - containers, images, volumes, data dirs |
| `make re` | fclean + make (full rebuild) |
| `make ps` | Shows container status |
| `make logs` | Follows container logs |

### Using Docker Compose directly

If you want more control:

```bash
cd srcs

# Build and start
docker compose up -d --build

# Stop
docker compose down

# Stop and remove volumes
docker compose down -v
```

### Build process

When you run `make`:

1. `prep` target creates `/home/$USER/data/mariadb` and `/home/$USER/data/wordpress`
2. Docker Compose builds three images from `srcs/requirements/*/Dockerfile`
3. All images use `debian:bookworm` as base
4. Containers start in order: mariadb → wordpress → nginx (because of `depends_on`)

---

## Managing containers and volumes

### Containers

```bash
# See running containers
make ps

# Or directly
docker ps

# Get into a container
docker exec -it mariadb bash
docker exec -it wordpress bash
docker exec -it nginx bash

# Check container logs
docker logs mariadb
docker logs wordpress
docker logs nginx

# Restart a single container
docker restart wordpress
```

### Volumes

Two volumes defined in docker-compose.yml:
- `mariadb_data` → bind mount to `/home/sal-kawa/data/mariadb`
- `wordpress_data` → bind mount to `/home/sal-kawa/data/wordpress`

```bash
# List volumes
docker volume ls

# Inspect a volume
docker volume inspect srcs_mariadb_data

# Remove volumes (stops containers first)
docker compose -f srcs/docker-compose.yml down -v
```

### Network

All containers connect to `inception` network (bridge driver).

```bash
# See networks
docker network ls

# Check what's connected
docker network inspect inception
```

---

## Data storage and persistence

### Where data lives

| Data | Location on host | Location in container |
|------|------------------|----------------------|
| MariaDB files | `/home/sal-kawa/data/mariadb` | `/var/lib/mysql` |
| WordPress files | `/home/sal-kawa/data/wordpress` | `/var/www/html` |

These are bind mounts, not Docker volumes. The actual files sit on your disk at those paths.

### What gets persisted

- Database tables (users, posts, settings)
- WordPress core files
- wp-config.php
- Uploaded media
- Installed themes/plugins

### What doesn't persist

- SSL certificates (regenerated on nginx start)
- PHP sessions
- Container logs (unless you configure Docker logging)

### Resetting data

To start fresh:
```bash
make fclean
make
```

This removes the data directories and recreates everything from scratch.

To keep WordPress files but reset the database:
```bash
sudo rm -rf /home/sal-kawa/data/mariadb/*
make down && make
```
Note: WordPress will fail until you also reset wp-config.php or the whole wordpress folder.

---

## How each container works

### MariaDB

The entrypoint script:
1. Creates `/run/mysqld` directory
2. If database is empty, runs `mariadb-install-db`
3. Starts a temporary server with no network (socket only)
4. Creates the database and user from env vars
5. Sets root password from secrets
6. Stops temp server, starts real one on port 3306

### Nginx

The entrypoint script:
1. Checks if SSL cert exists at `/etc/nginx/ssl/`
2. If not, generates self-signed cert with openssl
3. Runs nginx

The nginx.conf:
- Listens on 443 with SSL
- Serves from /var/www/html
- Proxies PHP files to wordpress:9000 via FastCGI

### WordPress

The entrypoint script:
1. Waits for MariaDB to accept connections (loops until ready)
2. Downloads wp-cli if missing
3. Downloads WordPress if missing
4. Creates wp-config.php if missing
5. Runs `wp core install` if not installed
6. Creates a secondary user
7. Starts php-fpm on port 9000

---

## Resources used

<!-- fill this yourself -->

## AI tools used

<!-- fill this yourself -->
