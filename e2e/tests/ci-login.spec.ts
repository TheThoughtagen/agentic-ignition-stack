import { expect, test } from "@playwright/test";

test("CI browser user can sign into local Gateway", async ({ page }) => {
  test.skip(!process.env.CI, "Only the disposable CI Gateway provisions demo-ci");
  const user = process.env.IGNITION_USER;
  const password = process.env.IGNITION_PASSWORD;
  if (!user || !password) throw new Error("Missing ephemeral CI browser credentials");

  await page.goto("/data/app/login");
  await expect(page).toHaveURL(/\/idp\/demo-ci\/authn\/login/);
  await page.getByRole("button", { name: "Log In", exact: true }).click();
  await page.locator('input[name="username"]').fill(user);
  await page.locator("div.submit-button").click();
  await page.locator('input[name="password"]').fill(password);
  await page.locator("div.submit-button").click();
  await page.waitForURL((url) => !url.pathname.includes("/authn/login"), {
    timeout: 30_000,
  });
  await expect(page).not.toHaveURL(/\/data\/app\/login/);
});
