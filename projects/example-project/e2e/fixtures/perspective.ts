import { test as base } from "@playwright/test";
import { PerspectivePage } from "../pages/PerspectivePage";

type PerspectiveFixtures = {
  perspective: PerspectivePage;
};

export const test = base.extend<PerspectiveFixtures>({
  perspective: async ({ page }, use) => {
    const perspective = new PerspectivePage(page);
    await use(perspective);
  },
});

export { expect } from "@playwright/test";