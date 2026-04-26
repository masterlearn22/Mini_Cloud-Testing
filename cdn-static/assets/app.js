// app.js — Di-serve CDN, polling status API ke Load Balancer
async function pollNode() {
  try {
    const res  = await fetch('http://localhost/info');
    const data = await res.json();
    const el   = document.getElementById('node-status');
    if (el) el.textContent = `Dilayani oleh: ${data.node} | Request: ${data.totalRequest}`;
  } catch {
    const el = document.getElementById('node-status');
    if (el) el.textContent = 'Tidak dapat terhubung ke backend';
  }
}
setInterval(pollNode, 3000);
pollNode();
