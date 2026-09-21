import { Locator, Page } from "@playwright/test";
import { PerspectiveComponent } from "./PerspectiveComponent";

/**
 * Wrapper for ia.input.button components.
 */
export class Button extends PerspectiveComponent {
  constructor(locator: Locator, page: Page) {
    super(locator, page);
  }

  async click(): Promise<void> {
    await this.waitForVisible();
    await this.locator.click();
  }

  async isEnabled(): Promise<boolean> {
    // Perspective disables buttons via an "ia_button--disabled" class
    const classes = (await this.locator.getAttribute("class")) ?? "";
    return !classes.includes("disabled");
  }
}