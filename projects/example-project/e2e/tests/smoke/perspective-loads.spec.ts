import { test, expect } from "../../fixtures/perspective";

test.describe("Perspective smoke tests", () => {
  test("session loads successfully", async ({ perspective }) => {
    await perspective.openPage("/");
    await perspective.waitForSession();

    // Verify the Perspective session is active by checking for any rendered component
    const anyComponent = perspective.page.locator("[data-component]");
    await expect(anyComponent.first()).toBeVisible({ timeout: 15_000 });
  });

  test("page content renders", async ({ perspective }) => {
    await perspective.openPage("/");
    await perspective.waitForPageContent();

    // At least one Perspective component should exist in the page content area
    const components = perspective.page.locator(
      "[data-component-path^='C'] [data-component]"
    );
    await expect(components.first()).toBeVisible({ timeout: 10_000 });
    expect(await components.count()).toBeGreaterThan(0);
  });

  test("no console errors on load", async ({ perspective }) => {
    const errors: string[] = [];
    perspective.page.on("console", (msg) => {
      if (msg.type() === "error") errors.push(msg.text());
    });

    await perspective.openPage("/");
    await perspective.waitForPageContent();

    // Filter out known benign errors (e.g., favicon 404)
    const realErrors = errors.filter((e) => !e.includes("favicon"));
    expect(realErrors).toEqual([]);
  });
});