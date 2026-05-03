import request from "supertest";
import { app } from "../lib/socket.js";

describe("Health Route", () => {
  it("should return 200", async () => {
    const res = await request(app).get("/health");
    expect(res.statusCode).toBe(200);
  });
});