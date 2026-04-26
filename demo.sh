#!/bin/bash
# ============================================================
# demo.sh — Script Demonstrasi Mini-Cloud untuk Video UTS
# Jalankan: chmod +x demo.sh && ./demo.sh
# ============================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

banner() { echo -e "\n${CYAN}══════════════════════════════════════════${NC}"; echo -e "${CYAN}  $1${NC}"; echo -e "${CYAN}══════════════════════════════════════════${NC}\n"; }
info()   { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()   { echo -e "${YELLOW}[DEMO]${NC} $1"; }
err()    { echo -e "${RED}[ERR]${NC}  $1"; }

# ── 1. BUILD & START ──────────────────────────────────────────
banner "STEP 1: Resource Provisioning (IaaS)"
info "Membangun image dan menjalankan semua kontainer..."
docker compose up --build -d
echo ""
info "Daftar kontainer yang berjalan:"
docker compose ps
sleep 3

# ── 2. VERIFIKASI LOAD BALANCING ─────────────────────────────
banner "STEP 2: Verifikasi Load Balancing (Round-Robin)"
warn "Mengirim 6 request ke Load Balancer (port 80)..."
for i in {1..6}; do
  echo -n "  Request $i → Node: "
  curl -s http://localhost/ | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['node'], '| Cache:', d['cacheHit'])" 2>/dev/null || echo "(parsing error)"
  sleep 0.5
done

# ── 3. SIMULASI CACHING ───────────────────────────────────────
banner "STEP 3: Simulasi Redis Caching"
warn "Request pertama: backend akan diproses (cache MISS)..."
time curl -s http://localhost/ > /dev/null
warn "Request kedua: seharusnya cache HIT (lebih cepat)..."
time curl -s http://localhost/ > /dev/null
info "Cek isi Redis:"
docker exec redis-cache redis-cli KEYS "*"

# ── 4. FAULT TOLERANCE ───────────────────────────────────────
banner "STEP 4: Fault Tolerance — Matikan Node 1"
warn "Mematikan web-node1..."
docker compose stop web-node1
sleep 2
info "Status kontainer sekarang:"
docker compose ps
warn "Mengirim 4 request setelah node1 mati — semua harus tetap berhasil:"
for i in {1..4}; do
  echo -n "  Request $i → Node: "
  curl -s http://localhost/ | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['node'])" 2>/dev/null || echo "(error)"
  sleep 0.5
done
warn "Menghidupkan kembali web-node1..."
docker compose start web-node1
sleep 2

# ── 5. HORIZONTAL SCALING ────────────────────────────────────
banner "STEP 5: Elasticity — Horizontal Scaling"
warn "Menambahkan web-node3 (tanpa mematikan layanan)..."
docker compose --profile scale up web-node3 -d
sleep 3
info "Aktifkan node3 di nginx.conf, lalu reload:"
docker compose exec nginx nginx -s reload 2>/dev/null || warn "Uncomment dulu baris web-node3 di nginx.conf, lalu jalankan: docker compose exec nginx nginx -s reload"
info "Status setelah scale-out:"
docker compose ps

# ── 6. CDN LAYER ─────────────────────────────────────────────
banner "STEP 6: CDN Layer — Static Content"
warn "Mengakses konten statis via CDN (port 8080)..."
curl -sI http://localhost:8080/ | grep -E "Content-Type|X-Cache|X-Served"

# ── 7. RINGKASAN IDEAL ────────────────────────────────────────
banner "RINGKASAN PRINSIP IDEAL"
echo -e "  ${GREEN}I${NC}solated   → Setiap kontainer punya namespace sendiri"
echo -e "  ${GREEN}D${NC}emocratic → Semua user akses via 1 entry point (port 80)"
echo -e "  ${GREEN}E${NC}lastic    → Tambah node3 tanpa downtime"
echo -e "  ${GREEN}A${NC}daptive   → Load Balancer auto-redirect saat node mati"
echo -e "  ${GREEN}L${NC}ess-coupled → Layanan independen, update tanpa restart semua"

echo ""
info "Demo selesai! Semua container:"
docker compose ps
