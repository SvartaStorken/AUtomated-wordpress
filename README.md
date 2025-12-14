# Red Hat UBI 10 & MariaDB 12.2 Reference Implementation

**A Proof-of-Concept for deploying next-generation software stacks in Rootless OpenShift environments.**

This repository hosts a complete CI/CD solution for deploying a custom-built LEMP stack (Linux, Nginx/Apache, MariaDB, PHP). It leverages **Red Hat Universal Base Image 10 (UBI 10)** to run bleeding-edge versions of MariaDB and WordPress within strict security constraints (Arbitrary User ID/SCC).

## 📘 Project Context
This project was architected and developed within the scope of the **DevOps Engineer** program at **Lernia** (Course: *CI/CD Tools*).

The primary objective was to engineer a pipeline that moves beyond standard legacy images, demonstrating how to package, configure, and orchestrate modern, unreleased, or custom-compiled software versions in a strictly controlled enterprise Kubernetes environment like OpenShift.

---

## 🏗️ Architecture & Deployment Flow

The entire lifecycle of the application is automated via **GitHub Actions**.

### 1. The CI/CD Pipeline
The workflow (`deploy.yml`) handles the delivery process:
* **Build:** Custom container images are built from scratch using `Containerfile`.
* **Publish:** Images are pushed to **GitHub Container Registry (GHCR)**.
* **Deploy:** The pipeline authenticates against the OpenShift cluster and applies Kubernetes manifests (`Deployment`, `Service`, `Route`, `PVC`, `Secret`).
* **Rollout:** A zero-downtime restart is triggered to propagate the new images.

### 2. OpenShift Integration
The deployment utilizes a Stateful architecture:
* **MariaDB:** Runs as a StatefulSet with a Persistent Volume Claim (PVC) mounted at `/var/lib/mysql`.
* **WordPress:** Configured as a Deployment with read/write access to `wp-content` for uploads and plugins.
* **Security:** Both containers run as non-root users (Arbitrary UID) compliant with OpenShift's default Security Context Constraints.

---

## 🐳 Running with Podman (Standalone)

You can pull and run these containers independently using Podman. This is useful for local development or testing the image logic without a full cluster.

### Prerequisites
* Podman installed.
* Access to the container registry (or build locally).

### 1. Create a Pod (Shared Network)
To allow the containers to communicate easily, create a pod:
```bash
podman pod create --name wp-stack -p 8080:8080
```

### 2. Deploy MariaDB
The MariaDB container requires specific environment variables to initialize the database on the first run.

```bash
podman run -d --name mariadb --pod wp-stack \
  -e DB_USER=wordpress \
  -e DB_PASSWORD=my_secure_password \
  -e DB_NAME=wordpress_db \
  ghcr.io/SvartaStorken/mariadb:latest
```

### 3. Deploy WordPress
Connect WordPress to the database using the same credentials. Note that `DB_HOST` refers to `localhost` since they share the pod's network namespace.

```bash
podman run -d --name wordpress --pod wp-stack \
  -e DB_HOST=127.0.0.1 \
  -e DB_USER=wordpress \
  -e DB_PASSWORD=my_secure_password \
  -e DB_NAME=wordpress_db \
  ghcr.io/SvartaStorken/wordpress:latest
```

You can now access the site at `http://localhost:8080`.

---

## ⚙️ Configuration & Environment Variables

### MariaDB Initialization Logic
The MariaDB image utilizes a custom entrypoint script designed for UBI 10. When the container starts, the script checks the `/var/lib/mysql` directory:

1.  **If the directory is empty:** The script initializes a new database using `mariadb-install-db`. It then bootstraps the `root` user and creates a secondary application user based on the environment variables provided.
2.  **If data exists:** The script skips initialization and starts the daemon normally, preserving existing data.

| Variable | Description | Required |
| :--- | :--- | :--- |
| `DB_USER` | Username for the application user. | Yes (First run) |
| `DB_PASSWORD` | Password for the application user. | Yes (First run) |
| `DB_NAME` | Name of the database to create. | Yes (First run) |

### WordPress Configuration
The WordPress image features a modified `wp-config.php` and PHP-FPM configuration to support **runtime injection**. Unlike standard builds where configuration might be hardcoded, this image reads secrets directly from the environment, making it secure for CI/CD pipelines.

| Variable | Description | Default |
| :--- | :--- | :--- |
| `DB_HOST` | Hostname/IP of the database. | `mariadb` |
| `DB_USER` | Database username. | `wordpress` |
| `DB_PASSWORD` | Database password. | *None (Required)* |
| `DB_NAME` | Database name. | `wordpress_db` |

---

## 🔧 Technical Highlights

* **UBI 10 Base:** Built on the preview version of Red Hat Enterprise Linux 10 base image.
* **MariaDB 12.2:** Features the rolling release version of MariaDB, compiled/installed for UBI 10.
* **PHP-FPM Env Patch:** Includes a custom patch for PHP-FPM to prevent environment variable clearing (`clear_env = no`), solving a common issue in Red Hat S2I-based PHP images.
* **Rootless Filesystem:** Directory permissions are engineered to support OpenShift's random UID assignment (Group 0 write access).

---
*Maintained by [SvartaStorken](https://github.com/SvartaStorken)*