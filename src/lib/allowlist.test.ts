import { describe, expect, it } from "vitest";
import { isAllowedEmail } from "./allowlist";

describe("isAllowedEmail", () => {
  it("allows listed emails regardless of case and spacing", () => {
    expect(isAllowedEmail("Me@Example.com", " other@x.com, me@example.com ")).toBe(true);
  });

  it("rejects unlisted emails and an empty allowlist", () => {
    expect(isAllowedEmail("stranger@x.com", "me@example.com")).toBe(false);
    expect(isAllowedEmail("me@example.com", undefined)).toBe(false);
  });
});
