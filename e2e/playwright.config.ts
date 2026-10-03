import { defineConfig, devices } from "@playwright/test";
import * as dotenv from "dotenv";
import * as path from "path";

dotenv.config({ path: path.resolve(__dirname, "../.env") });

export default defineConfig({
  testDir: "./tests",
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  workers: 1,
  reporter: [["list"]],
  timeout: 60_000,
  use: {
    baseURL:
      process.env.IGNITION_URL ||
      process.env.IGNITION_GATEWAY_URL ||
      "http://127.0.0.1:8088",
    ignoreHTTPSErrors: true,
    actionTimeout: 15_000,
    trace: "on-first-retry",
    screenshot: "only-on-failure",
  },
  projects: [
    {
      name: "gateway-chromium",
      use: devices["Desktop Chrome"],
    },
  ],
});
