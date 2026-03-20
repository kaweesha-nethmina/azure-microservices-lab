const express = require("express");
const cors = require("cors");
const { v4: uuidv4 } = require("uuid");

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());

// In-memory data store (for demo purposes)
const users = [
  { id: uuidv4(), name: "John Doe", email: "john@example.com" },
  { id: uuidv4(), name: "Jane Smith", email: "jane@example.com" }
];

// Health check
app.get("/health", (req, res) => {
  res.json({ status: "healthy", service: "api-service", timestamp: new Date() });
});

// Get all users
app.get("/users", (req, res) => {
  res.json({ data: users, count: users.length });
});

// Get user by ID
app.get("/users/:id", (req, res) => {
  const user = users.find(u => u.id === req.params.id);
  if (user) {
    res.json(user);
  } else {
    res.status(404).json({ error: "User not found" });
  }
});

// Create new user
app.post("/users", (req, res) => {
  const { name, email } = req.body;
  if (!name || !email) {
    return res.status(400).json({ error: "Name and email are required" });
  }
  const newUser = { id: uuidv4(), name, email };
  users.push(newUser);
  res.status(201).json(newUser);
});

// Update user
app.put("/users/:id", (req, res) => {
  const user = users.find(u => u.id === req.params.id);
  if (!user) {
    return res.status(404).json({ error: "User not found" });
  }
  if (req.body.name) user.name = req.body.name;
  if (req.body.email) user.email = req.body.email;
  res.json(user);
});

// Delete user
app.delete("/users/:id", (req, res) => {
  const index = users.findIndex(u => u.id === req.params.id);
  if (index === -1) {
    return res.status(404).json({ error: "User not found" });
  }
  const deletedUser = users.splice(index, 1);
  res.json({ deleted: deletedUser[0] });
});

app.listen(PORT, () => {
  console.log(`API service running on port ${PORT}`);
});
