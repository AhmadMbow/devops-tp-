// src/index.js
// Definition de l'application Express (separee du demarrage du serveur
// pour pouvoir la tester sans ouvrir de port reseau).
const express = require("express");

const app = express();

app.use(express.json());

// Route principale demandee par le TP : repond "pong"
app.get("/ping", (req, res) => {
  res.status(200).send("pong");
});

// Route de sante, pratique pour le monitoring / les healthchecks Docker
app.get("/health", (req, res) => {
  res.status(200).json({ status: "ok", uptime: process.uptime() });
});

// Page d'accueil
app.get("/", (req, res) => {
  res.status(200).json({
    message: "API DevOps UCAD - essayez GET /ping",
  });
});

module.exports = app;
