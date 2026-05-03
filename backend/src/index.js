import express from "express";
import metricsRoute from './routes/metrics.route.js';
import { httpRequestDuration } from './lib/metrics.js';
import dotenv from "dotenv";
import cookieParser from "cookie-parser";
import cors from "cors";
import path from "path";
import { connectDB } from "./lib/db.js";
import authRoutes from "./routes/auth.route.js";
import messageRoutes from "./routes/message.route.js";
import healthRoutes from "./routes/health.route.js";
import { app, server } from "./lib/socket.js";

dotenv.config();

const PORT = process.env.PORT;
const __dirname = path.resolve();

app.use(express.json());
app.use(cookieParser());
app.use(
  cors({
    origin: process.env.NODE_ENV === "production"
      ? ["http://localhost:8080", "http://localhost"]
      : "http://localhost:5173",
    credentials: true,
  })
);

// Metrics middleware
app.use((req, res, next) => {
  if (req.path === '/metrics') return next();
  const start = process.hrtime();
  res.on('finish', () => {
    const diff = process.hrtime(start);
    const durationInSeconds = diff[0] + diff[1] / 1e9;
    httpRequestDuration
      .labels(req.method, req.route?.path || req.path, res.statusCode)
      .observe(durationInSeconds);
  });
  next();
});

// Routes - all explicit routes before static
app.use("/api/auth", authRoutes);
app.use("/api/messages", messageRoutes);
app.use("/health", healthRoutes);
app.use('/metrics', metricsRoute);  // 👈 moved here, mounted at /metrics

// Static - must be last
if (process.env.NODE_ENV === "production") {
  app.use(express.static(path.join(__dirname, "../frontend/dist")));
  app.get("*", (req, res) => {
    res.sendFile(path.join(__dirname, "../frontend", "dist", "index.html"));
  });
}

server.listen(PORT, () => {
  console.log("server is running on PORT:" + PORT);
  connectDB();
});