const http = require('http');
const redis = require('redis');

// Identitas node (diisi dari environment variable Docker)
const NODE_ID   = process.env.NODE_ID   || 'node-unknown';
const NODE_PORT = parseInt(process.env.PORT || '3000');

// Koneksi Redis untuk caching
const redisClient = redis.createClient({
  url: process.env.REDIS_URL || 'redis://redis:6379'
});

redisClient.on('error', (err) => console.error('[Redis] Error:', err));
redisClient.connect().then(() => console.log(`[${NODE_ID}] Terhubung ke Redis`));

// Counter request per node (simulasi beban kerja)
let requestCount = 0;

const server = http.createServer(async (req, res) => {
  requestCount++;
  const url = req.url;

  // ============================================================
  // Endpoint: / — Halaman utama, simulasi response dari node
  // ============================================================
  if (url === '/' || url === '/index') {
    const cacheKey = 'home:content';
    let content;
    let cacheHit = false;

    try {
      content = await redisClient.get(cacheKey);
      if (content) {
        cacheHit = true;
      } else {
        // Simulasi proses berat di backend (100ms delay)
        await new Promise(r => setTimeout(r, 100));
        content = JSON.stringify({
          message   : 'Selamat datang di Mini-Cloud UTS!',
          timestamp : new Date().toISOString()
        });
        await redisClient.setEx(cacheKey, 30, content); // TTL 30 detik
      }
    } catch {
      content = JSON.stringify({ message: 'Response tanpa cache', timestamp: new Date().toISOString() });
    }

    const parsed = JSON.parse(content);
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      node       : NODE_ID,
      port       : NODE_PORT,
      requests   : requestCount,
      cacheHit,
      data       : parsed
    }));

  // ============================================================
  // Endpoint: /health — Health check untuk Load Balancer
  // ============================================================
  } else if (url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'UP', node: NODE_ID, requests: requestCount }));

  // ============================================================
  // Endpoint: /info — Info node untuk demonstrasi elastisitas
  // ============================================================
  } else if (url === '/info') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      node         : NODE_ID,
      port         : NODE_PORT,
      uptime       : process.uptime(),
      totalRequest : requestCount,
      memory       : process.memoryUsage(),
      pid          : process.pid
    }));

  } else {
    res.writeHead(404, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Endpoint tidak ditemukan', node: NODE_ID }));
  }
});

server.listen(NODE_PORT, () => {
  console.log(`[${NODE_ID}] Server berjalan di port ${NODE_PORT}`);
});

// Graceful shutdown (simulasi fault tolerance)
process.on('SIGTERM', () => {
  console.log(`[${NODE_ID}] Menerima SIGTERM, menutup server...`);
  server.close(() => process.exit(0));
});
