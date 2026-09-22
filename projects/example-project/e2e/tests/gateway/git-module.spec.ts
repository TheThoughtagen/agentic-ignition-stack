import { expect, test } from "@playwright/test";

const projectName = "git-example-project";
const repository =
  "https://github.com/TheThoughtagen/agentic-ignition-example-project.git";

test("Git module lists the commissioned sample project", async ({ page }) => {
  const username = process.env.IGNITION_USER;
  const password = process.env.IGNITION_PASSWORD;
  if (!username || !password) {
    throw new Error("IGNITION_USER and IGNITION_PASSWORD are required");
  }

  const routeFailures: string[] = [];
  page.on("response", (response) => {
    if (response.url().includes("/data/git/") && response.status() >= 400) {
      routeFailures.push(`${response.status()} ${response.url()}`);
    }
  });

  await page.goto("/web/config/git/projects");
  const loginButton = page.getByRole("button", {
    name: "Log In",
    exact: true,
  });

  await loginButton.waitFor({ state: "visible" });
  await Promise.all([
    page.waitForResponse((response) =>
      response.url().includes("/authn/next-challenge")
    ),
    loginButton.click(),
  ]);

  const usernameInput = page.locator('input[name="username"]');
  await usernameInput.waitFor({ state: "visible" });
  await usernameInput.fill(username);
  await page.locator("div.submit-button").click();

  await page.locator('input[name="password"]').fill(password);
  await Promise.all([
    page.waitForResponse((response) =>
      response.url().includes("/authn/next-challenge")
    ),
    page.locator("div.submit-button").click(),
  ]);
  await page.waitForURL((url) => !url.pathname.includes("/authn/login"));

  const projectsResponse = page.waitForResponse(
    (response) =>
      response.url().endsWith("/data/git/projects") &&
      response.request().method() === "GET"
  );
  await page.goto("/app/git/projects");

  await expect(
    page.getByRole("heading", { name: "Git Projects Configuration" })
  ).toBeVisible();
  await expect(page.getByText(projectName, { exact: true })).toBeVisible();
  await expect(page.getByText(repository, { exact: true })).toBeVisible();

  const response = await projectsResponse;
  expect(response.status()).toBe(200);
  const projects = (await response.json()) as Array<{
    projectName: string;
    uri: string;
  }>;
  expect(projects).toContainEqual(
    expect.objectContaining({ projectName, uri: repository })
  );
  expect(routeFailures).toEqual([]);
});
