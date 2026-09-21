import { Locator, Page } from "@playwright/test";

/**
 * Base class for Perspective component wrappers.
 * Wraps a Locator and adds common operations.
 */
export class PerspectiveComponent {
  readonly locator: Locator;
  readonly page: Page;

  constructor(locator: Locator, page: Page) {
    this.locator = locator;
    this.page = page;
  }

  async isVisible(timeout = 5_000): Promise<boolean> {
    return this.locator.isVisible({ timeout }).catch(() => false);
  }

  async waitForVisible(timeout = 10_000): Promise<void> {
    await this.locator.waitFor({ state: "visible", timeout });
  }

  async getText(): Promise<string> {
    return (await this.locator.textContent()) ?? "";
  }
}