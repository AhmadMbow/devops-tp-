// tests/api.test.js
const request = require("supertest");
const app = require("../src/index");

describe("API DevOps UCAD", () => {
  test("GET /ping retourne 'pong' avec un statut 200", async () => {
    const res = await request(app).get("/ping");
    expect(res.statusCode).toBe(200);
    expect(res.text).toBe("pong");
  });

  test("GET /health retourne un statut 'ok'", async () => {
    const res = await request(app).get("/health");
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe("ok");
  });

  test("GET / retourne un message d'accueil", async () => {
    const res = await request(app).get("/");
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty("message");
  });
});
