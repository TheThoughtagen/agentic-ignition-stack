import { test as setup } from "@playwright/test";
import * as path from "path";

const AUTH_FILE = path.resolve(__dirname, "../.auth/user.json");

setup.setTimeout(60_000);

setup("authenticate", async ({ page }) => {
  const project =
    process.env.PERSPECTIVE_PROJECT || "MyProject";

  await page.goto(`/data/perspective/client/${project}`);

  // Wait for either a login form or a live Perspective session.
  // In guest mode, the session starts directly without login.
  // After a project scan, Perspective takes up to 30s to reload.
  // Use polling instead of waitForFunction to avoid actionTimeout cap.
  let result: string = "timeout";
  const deadline = Date.now() + 45_000;
  while (Date.now() < deadline) {
    result = await page.evaluate(() => {
      if (document.querySelector("input.username-field")) return "login";
      if (document.querySelectorAll("[data-component]").length > 0)
        return "session";
      return "waiting";
    });
    if (result === "login" || result === "session") break;
    await page.waitForTimeout(1_000);
  }

  if (result === "timeout" || result === "waiting") {
    throw new Error(
      "Neither login form nor Perspective session appeared within 45s"
    );
  }

  if (result === "login") {
    const user = process.env.IGNITION_USER;
    const pass = process.env.IGNITION_PASSWORD;

    if (!user || !pass) {
      throw new Error(
        "Login form detected but IGNITION_USER/PASSWORD not set in e2e/.env"
      );
    }

    await page.locator("input.username-field").fill(user);
    await page.locator("input.password-field").fill(pass);
    await page.locator("div.submit-button").click();

    await page.waitForFunction(
      () => document.querySelectorAll("[data-component]").length > 0,
      { timeout: 30_000 }
    );
  }

  // Session is live — persist auth state for reuse
  await page.context().storageState({ path: AUTH_FILE });
});