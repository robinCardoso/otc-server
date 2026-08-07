/** DOM overlays and UI panels. */

export class UIManager {
  private root: HTMLElement | null = null;

  init(root: HTMLElement): void {
    this.root = root;
  }

  getRoot(): HTMLElement | null {
    return this.root;
  }
}
