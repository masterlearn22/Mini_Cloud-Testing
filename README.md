# Mini-Cloud Environment — UTS Cloud Computing

Simulasi ekosistem cloud skala kecil menggunakan Docker sebagai media provisioning.

---

## Struktur Proyek

```
mini-cloud/
├── docker-compose.yml        ← Orkestrator utama
├── app/
│   ├── Dockerfile            ← Image worker node (Node.js)
│   ├── package.json
│   └── server.js             ← Aplikasi Backend + Redis cache
├── nginx/
│   └── nginx.conf            ← Load Balancer + CDN config
└── cdn-static/
    ├── index.html            ← Dashboard CDN
    └── assets/               ← Static Files (style.css, app.js)
```

---

## Prasyarat

- Docker Desktop (Windows/Mac)
- Port 80 dan **8081** kosong (Port 8080 sering bentrok dengan PHP/Lainnya)

---

## Cara Menjalankan

### 1. Jalankan semua layanan
```powershell
docker compose up --build -d
```

### 2. Verifikasi container
```powershell
docker compose ps
```

---

## 🚀 Panduan Pengujian (Khusus PowerShell)

Gunakan perintah di bawah ini untuk rekaman OBS Anda (Terminal Windows).

### Skenario 1 — IaaS Resource Provisioning
Melihat kontainer sebagai "Virtual Instance" yang disediakan.
```powershell
# Cek semua instance yang berjalan
docker compose ps

# Cek penggunaan RAM/CPU tiap instance
docker stats --no-stream
```

### Skenario 2 — High Availability & Load Balancing
Membuktikan traffic dibagi rata ke beberapa node.
```powershell
# 1. Tes Distribusi Beban (Loop 10x)
1..10 | ForEach-Object { (curl.exe -s http://localhost/ | ConvertFrom-Json).node }

# 2. Cek Header Upstream
curl.exe -sI http://localhost/ | findstr X-Upstream-Node

# 3. Simulasi Fault Tolerance (Matikan Node 1)
docker compose stop web-node1
curl.exe -s http://localhost/  # Tetap jalan lewat Node 2
docker compose start web-node1 # Hidupkan lagi
```

### Skenario 3 — Elasticity (Horizontal Scaling)
Menambah kapasitas tanpa mematikan sistem.
```powershell
# 1. Jalankan Node 3
docker compose --profile scale up web-node3 -d

# 2. RELOAD Nginx (Setelah uncomment baris 38 di nginx.conf)
docker compose exec nginx nginx -s reload

# 3. Verifikasi Node 3 ikut bekerja
1..9 | ForEach-Object { (curl.exe -s http://localhost/ | ConvertFrom-Json).node }
```

### Skenario 4 — Caching & CDN Layer
Mempercepat akses file dan data.
```powershell
# 1. Tes Kecepatan Caching (Bandingkan waktu eksekusi)
Measure-Command { curl.exe -s http://localhost/ }

# 2. Cek Data di Redis Cache
docker exec redis-cache redis-cli KEYS "*"

# 3. Tes CDN (Mengakses file statis di Port 8081)
curl.exe -sI http://localhost:8081/static/style.css
```

---

## Endpoint Tersedia

| URL | Deskripsi |
|-----|-----------|
| `http://localhost/` | API Utama (Load Balancer) |
| `http://localhost:8081/` | CDN Dashboard |
| `http://localhost:8081/static/style.css` | File Statis CDN |

---

## Mematikan Semua Layanan
```powershell
docker compose down -v
```
