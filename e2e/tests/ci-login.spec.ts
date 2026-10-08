import { expect, test } from "@playwright/test";

test("CI browser user can sign into local Gateway", async ({ page }) => {
  test.skip(!process.env.CI, "Only the disposable CI Gateway provisions demo-ci");
  const user = process.env.IGNITION_USER;
  const password = process.env.IGNITION_PASSWORD;
  if (!user || !password) throw new Error("Missing ephemeral CI browser credentials");

  await page.goto("/data/app/login");
  await expect(page).toHaveURL(/\/idp\/demo-ci\/authn\/login/);

  // The IdP login form keeps both inputs in the DOM but reveals them one at
  // a time: submit the username to make the password step visible.
  await page
    .locator("input.username-field, input[name='username']")
    .first()
    .fill(user);
  await page.locator("div.submit-button").click();
  const passwordField = page
    .locator("input.password-field, input[name='password']")
    .first();
  await passwordField.waitFor({ state: "visible", timeout: 15_000 });
  await passwordField.fill(password);
  await page.locator("div.submit-button").click();
  await page.waitForURL((url) => !url.pathname.includes("/authn/login"), {
    timeout: 30_000,
  });
  await expect(page).not.toHaveURL(/\/data\/app\/login/);
});
