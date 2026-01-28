# User Documentation

## What is this?

This is a WordPress website running on Docker. It has three parts:

| Service | What it does |
|---------|--------------|
| **Nginx** | Web server - handles HTTPS connections |
| **WordPress** | The website itself |
| **MariaDB** | Database where WordPress stores everything |

When you visit the site, Nginx receives your request, passes it to WordPress, and WordPress talks to MariaDB to get your data.

---

## Starting and stopping

Open a terminal in the project folder.

**To start:**
```bash
make
```
This builds the containers and starts them. First run takes a bit longer because it downloads stuff.

**To stop:**
```bash
make down
```
Your data stays safe, containers just stop running.

**To restart:**
```bash
make re
```
This does a full cleanup and rebuilds everything. Use this if something is broken.

---

## Accessing the website

Before your first visit, add this line to your hosts file:

```
127.0.0.1 sal-kawa.42.fr
```

On Linux, the file is at `/etc/hosts`. You need sudo to edit it.

Then open your browser and go to:
```
https://sal-kawa.42.fr
```

You'll see a warning about the certificate - that's normal, it's self-signed. Click through it.

### Admin panel

Go to:
```
https://sal-kawa.42.fr/wp-admin
```

Login with:
- **Username:** sal-kawa_hell
- **Password:** check `secrets/wp_admin_password.txt`

There's also a regular user account:
- **Username:** normaluser
- **Password:** check `secrets/wp_user_password.txt`

---

## Credentials

All passwords live in the `secrets/` folder:

| File | What it's for |
|------|---------------|
| `wp_admin_password.txt` | WordPress admin login |
| `wp_user_password.txt` | WordPress regular user login |
| `db_password.txt` | Database user (WordPress uses this) |
| `db_root_password.txt` | Database root (you shouldn't need this) |

To change a password:
1. Stop the project: `make down`
2. Edit the file in `secrets/`
3. Do a full rebuild: `make fclean && make`

Note: changing database passwords after first run can break things. Better to do `make fclean` first so it creates fresh databases with new passwords.

---

## Checking if services are running

**Quick check:**
```bash
make ps
```
You should see three containers (mariadb, wordpress, nginx) all showing "Up".

**Watch the logs:**
```bash
make logs
```
This shows what's happening inside containers. Press Ctrl+C to stop watching.

**Test the website:**
- Open `https://sal-kawa.42.fr` - should show WordPress
- Open `https://sal-kawa.42.fr/wp-admin` - should show login page

**If something looks wrong:**
- Check logs with `make logs`
- Try restarting with `make down && make`
- For serious issues, do `make fclean && make` (this resets everything)

---

## Resources used

<!-- fill this yourself -->

## AI tools used

<!-- fill this yourself -->
