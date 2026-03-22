const express = require("express");
const cors = require("cors");
const https = require("https");


const app = express();
const PORT = process.env.PORT || 3000;
const API_URL = process.env.API_URL || "http://localhost:5000";

app.use(cors());
app.use(express.json());

// HTTPS agent to handle Azure certificates
const httpsAgent = new https.Agent({
  rejectUnauthorized: false // For development - in production use proper certificates
});

// Health check
app.get("/", (req, res) => {
  res.json({ status: "ok", service: "gateway", timestamp: new Date() });
});

app.get("/health", (req, res) => {
  res.json({ status: "healthy", service: "gateway", timestamp: new Date() });
});

// Proxy endpoints to API service
app.get("/users", async (req, res) => {
  try {
    const response = await fetch(`${API_URL}/users`, {
      agent: API_URL.startsWith('https') ? httpsAgent : undefined
    });
    const data = await response.json();
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch users", message: error.message });
  }
});

app.get("/users/:id", async (req, res) => {
  try {
    const response = await fetch(`${API_URL}/users/${req.params.id}`);
    const data = await response.json();
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch user", message: error.message });
  }
});

app.post("/users", async (req, res) => {
  try {
    const response = await fetch(`${API_URL}/users`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(req.body)
    });
    const data = await response.json();
    res.status(response.status).json(data);
  } catch (error) {
    res.status(500).json({ error: "Failed to create user", message: error.message });
  }
});

app.put("/users/:id", async (req, res) => {
  try {
    const response = await fetch(`${API_URL}/users/${req.params.id}`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(req.body)
    });
    const data = await response.json();
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: "Failed to update user", message: error.message });
  }
});

app.delete("/users/:id", async (req, res) => {
  try {
    const response = await fetch(`${API_URL}/users/${req.params.id}`, {
      method: "DELETE"
    });
    const data = await response.json();
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: "Failed to delete user", message: error.message });
  }
});

app.listen(PORT, () => {
  console.log(`Gateway running on port ${PORT}`);
  console.log(`API URL: ${API_URL}`);
});