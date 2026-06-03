// src/server.js
// Point d'entree qui demarre reellement le serveur HTTP.
const app = require("./index");

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`Serveur demarre sur http://localhost:${PORT}`);
  console.log(`Test : curl http://localhost:${PORT}/ping  ->  pong`);
});
