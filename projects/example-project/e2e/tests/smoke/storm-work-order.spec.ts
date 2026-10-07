import { test, expect } from "../../fixtures/perspective";

test("operator triages external work order through Gateway into Postgres", async ({ perspective }) => {
  await perspective.openPage("/");
  const page = perspective.page;
  await expect(page.getByText("Storm | Work-order triage")).toBeVisible();
  await expect(page.getByText("No work order triaged yet")).toBeVisible();
  const triageButton = page.getByRole("button", { name: "Triage now · WO-1042" });
  await expect(triageButton).toHaveCSS("background-color", "rgb(15, 118, 110)");
  await triageButton.click();
  await expect(page.getByText("WO-1042 | Mixer-7 | Expedite")).toBeVisible();
  await expect(page.getByText("Excess vibration on discharge bearing")).toBeVisible();
  const response = await page.request.get("/system/webdev/example-project/storm-demo?id=WO-1042");
  expect(response.ok()).toBeTruthy();
  expect((await response.json()).order.triage_state).toBe("Expedite");
});
