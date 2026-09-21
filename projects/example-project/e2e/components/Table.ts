import { Locator, Page } from "@playwright/test";
import { PerspectiveComponent } from "./PerspectiveComponent";

/**
 * Wrapper for ia.display.table components.
 */
export class Table extends PerspectiveComponent {
  constructor(locator: Locator, page: Page) {
    super(locator, page);
  }

  /** Wait until at least one data row is rendered. */
  async waitForData(timeout = 15_000): Promise<void> {
    await this.locator
      .locator(".ia_table__body__row")
      .first()
      .waitFor({ state: "visible", timeout });
  }

  async getRowCount(): Promise<number> {
    return this.locator.locator(".ia_table__body__row").count();
  }

  async clickRow(index: number): Promise<void> {
    await this.locator
      .locator(".ia_table__body__row")
      .nth(index)
      .click();
  }

  async getCellText(row: number, column: number): Promise<string> {
    const cell = this.locator
      .locator(".ia_table__body__row")
      .nth(row)
      .locator(".ia_table__body__cell")
      .nth(column);
    return (await cell.textContent()) ?? "";
  }
}