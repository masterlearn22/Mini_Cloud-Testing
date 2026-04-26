# Mini-Cloud Environment — UTS Cloud Computing

Simulasi ekosistem cloud skala kecil menggunakan Docker sebagai media provisioning.

---

## Struktur Proyek

```
mini-cloud/
├── docker-compose.yml        ← Orkestrator utama
├── demo.sh                   ← Script demo untuk video
├── app/
│   ├── Dockerfile            ← Image worker node
│   ├── package.json
│   └── server.js             ← Aplikasi Node.js (API + Redis cache)
├── nginx/
│   └── nginx.conf            ← Load Balancer + CDN config
└── cdn-static/
    ├── index.html            ← Dashboard CDN
    └── assets/
        ├── style.css
        └── app.js
```

---

## Prasyarat

- Docker Desktop (Windows/Mac) atau Docker Engine (Linux)
- Docker Compose v2
- Port 80 dan 8081 kosong

---

## Cara Menjalankan

### 1. Build dan jalankan semua layanan
```bash
docker compose up --build -d
```

### 2. Verifikasi semua container berjalan
```bash
docker compose ps
```

---

## Demonstrasi Per Skenario

### Skenario 1 — Resource Provisioning (IaaS)
```bash
# Lihat semua container (worker nodes = compute instances)
docker compose ps

# Lihat penggunaan resource real-time
docker stats
```
**Teori:** Setiap `docker compose up` adalah analogi provisioning VM di cloud provider.

---

### Skenario 2 — High Availability & Load Balancing
```bash
# Bash
for i in {1..10}; do curl -s http://localhost/ | python3 -c "import sys,json; print(json.load(sys.stdin)['node'])"; done
curl -sI http://localhost/ | grep X-Upstream-Node

# PowerShell
1..10 | ForEach-Object { (curl.exe -s http://localhost/ | ConvertFrom-Json).node }
curl.exe -sI http://localhost/ | findstr X-Upstream-Node
```

**Fault Tolerance:**
```bash
# Matikan node 1
docker compose stop web-node1

# Kirim request — tetap terlayani oleh node 2
curl http://localhost/

# Hidupkan kembali
docker compose start web-node1
```
**Teori:** `proxy_next_upstream` di Nginx memastikan request diteruskan ke node sehat.

---

### Skenario 3 — Elasticity (Horizontal Scaling)
```bash
# Jalankan node 3 (tanpa downtime)
docker compose --profile scale up web-node3 -d

# Uncomment baris "server web-node3:3000" di nginx/nginx.conf
# Kemudian reload Nginx tanpa restart
docker compose exec nginx nginx -s reload

# Bash
for i in {1..9}; do curl -s http://localhost/ | python3 -c "import sys,json; print(json.load(sys.stdin)['node'])"; done

# PowerShell
1..9 | ForEach-Object { (curl.exe -s http://localhost/ | ConvertFrom-Json).node }
```
**Teori:** Horizontal scaling = tambah instance, vs Vertical scaling = tambah CPU/RAM pada satu instance.

---

### Skenario 4 — Caching & CDN
```bash
# Bash
time curl -s http://localhost/ > /dev/null
curl -sI http://localhost:8081/static/style.css

# PowerShell
Measure-Command { curl.exe -s http://localhost/ }
curl.exe -sI http://localhost:8081/static/style.css
```

---

## Endpoint Tersedia

| URL | Deskripsi |
|-----|-----------|
| `http://localhost/` | API utama (melalui Load Balancer) |
| `http://localhost/health` | Health check node |
| `http://localhost/info` | Info detail node |
| `http://localhost/lb-status` | Status Load Balancer |
| `http://localhost:8081/` | CDN Dashboard (static) |

---

## Pembuktian Prinsip IDEAL

| Prinsip | Implementasi |
|---------|-------------|
| **Isolated** | Setiap container berjalan di namespace Linux terpisah (`cloud-net` network) |
| **Democratic** | Satu entry point (`localhost:80`), semua user diperlakukan sama |
| **Elastic** | Node 3 ditambah/dihapus tanpa mematikan node 1 dan 2 |
| **Adaptive** | `proxy_next_upstream` di Nginx redirect otomatis saat node mati |
| **Less-coupled** | App, LB, Cache adalah service terpisah — update satu tidak memengaruhi lain |

---

## Mematikan Semua Layanan
```bash
docker compose down -v
```
