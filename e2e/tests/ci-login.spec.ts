import { expect, test } from "@playwright/test";

test("CI browser user can sign into local Gateway", async ({ page }) => {
  test.skip(!process.env.CI, "Only the disposable CI Gateway provisions demo-ci");
  const user = process.env.IGNITION_USER;
  const password = process.env.IGNITION_PASSWORD;
  if (!user || !password) throw new Error("Missing ephemeral CI browser credentials");

  await page.goto("/data/app/login");
  await expect(page).toHaveURL(/\/idp\/demo-ci\/authn\/login/);

  // The internal IdP renders the classic Ignition login form: username and
  // password fields on one page (same component as the sample's auth.setup).
  // Some layouts show an intermediate "Log In" button first; click it only
  // when the form itself is not already present.
  const loginButton = page.getByRole("button", { name: "Log In", exact: true });
  const usernameField = page
    .locator("input.username-field, input[name='username']")
    .first();
  await loginButton.or(usernameField).waitFor({ state: "visible", timeout: 15_000 });
  const formVisible = await usernameField.isVisible().catch(() => false);
  if (!formVisible && (await loginButton.isVisible().catch(() => false))) {
    await loginButton.click();
  }

  await page
    .locator("input.username-field, input[name='username']")
    .first()
    .fill(user);
  await page
    .locator("input.password-field, input[name='password']")
    .first()
    .fill(password);
  await page.locator("div.submit-button").click();
  await page.waitForURL((url) => !url.pathname.includes("/authn/login"), {
    timeout: 30_000,
  });
  await expect(page).not.toHaveURL(/\/data\/app\/login/);
});
