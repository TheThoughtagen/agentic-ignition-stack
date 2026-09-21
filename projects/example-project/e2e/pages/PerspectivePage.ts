import { Page, Locator } from "@playwright/test";

/**
 * Base page object for Perspective views.
 *
 * Perspective is a React SPA served over WebSocket. Key DOM facts:
 * - data-component-path uses positional indices, NOT named paths from view.json
 * - Prefix convention: L[n]=left dock, T[n]=top dock, C=center (page content)
 * - $ separates embedded view boundaries, : separates child indices
 * - Never use page.goto() after the initial session open — it creates a new session
 */
export class PerspectivePage {
  readonly page: Page;

  constructor(page: Page) {
    this.page = page;
  }

  private get project(): string {
    return process.env.PERSPECTIVE_PROJECT || "MyProject";
  }

  /** Open a Perspective session at the given page route. Call once per test. */
  async openPage(pageRoute: string): Promise<void> {
    const route = pageRoute.startsWith("/") ? pageRoute : `/${pageRoute}`;
    await this.page.goto(
      `/data/perspective/client/${this.project}${route}`
    );
    await this.waitForPageContent();
  }

  /** Wait for the center (page) content area to render. */
  async waitForPageContent(timeout = 30_000): Promise<void> {
    await this.page
      .locator("[data-component-path^='C']")
      .first()
      .waitFor({ state: "visible", timeout });
  }

  /** Wait for any Perspective components to load (docks included). */
  async waitForSession(timeout = 30_000): Promise<void> {
    await this.page.waitForFunction(
      () => document.querySelectorAll("[data-component]").length > 3,
      { timeout }
    );
  }

  /** Scope a locator to the page content area (excludes docks). */
  pageContent(): Locator {
    return this.page.locator("[data-component-path^='C']").first();
  }

  /** Find a component by type within the page content area. */
  componentByType(type: string): Locator {
    return this.page.locator(
      `[data-component-path^='C'] [data-component='${type}'], [data-component-path^='C'][data-component='${type}']`
    );
  }

  /** Find a label containing specific text in the page content area. */
  pageLabelWithText(text: string): Locator {
    return this.page
      .locator("[data-component-path^='C'] [data-component='ia.display.label']")
      .filter({ hasText: text });
  }

  /** Find visible text anywhere in the page content (not docks). */
  pageText(text: string): Locator {
    return this.pageContent().getByText(text);
  }

  /** Dismiss any popup overlays (e.g. startup script modals). */
  async dismissPopups(): Promise<void> {
    const overlay = this.page.locator(".popup-overlay .close-button");
    if (await overlay.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await overlay.click();
    }
  }

  /** Get all component paths currently in the DOM (useful for debugging). */
  async dumpComponentPaths(): Promise<string[]> {
    return this.page.evaluate(() => {
      const els = document.querySelectorAll("[data-component-path]");
      return Array.from(els).map((el) => {
        const path = el.getAttribute("data-component-path") || "";
        const comp = el.getAttribute("data-component") || "";
        return `${path} → ${comp}`;
      });
    });
  }
}