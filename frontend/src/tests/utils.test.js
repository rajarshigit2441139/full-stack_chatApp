import { describe, it, expect } from "vitest";
import { formatMessageTime } from "../lib/utils";

describe("formatMessageTime", () => {
  it("returns a string", () => {
    const result = formatMessageTime(new Date());
    expect(typeof result).toBe("string");
  });
});