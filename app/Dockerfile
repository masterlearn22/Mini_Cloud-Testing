# ─── Stage: Runtime ───────────────────────────────────────────
# Menggunakan image Node.js Alpine (ringan) sebagai base image
# Konsep IaaS: provisioning OS + runtime secara instan via image
FROM node:18-alpine


# Label metadata kontainer (Less-coupled principle)
LABEL maintainer="Mini-Cloud UTS"
LABEL description="Worker Node - Simulasi IaaS Cloud Computing"

# Working directory di dalam kontainer (Isolated principle)
WORKDIR /app

# Copy dependency manifest terlebih dahulu (layer caching Docker)
COPY package.json ./

# Install dependencies
RUN npm install --production

# Copy source code aplikasi
COPY server.js ./

# Expose port (deklaratif, bukan binding langsung)
EXPOSE 3000

# Health check — Load Balancer akan mendeteksi node UP/DOWN
HEALTHCHECK --interval=10s --timeout=3s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

# Jalankan aplikasi sebagai non-root (security best practice)
USER node

# Entrypoint
CMD ["node", "server.js"]
