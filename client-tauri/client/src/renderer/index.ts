/** Pixi.js renderer for the Tibia game view. */

import { Application } from "pixi.js";

export class GameRenderer {
  private app: Application | null = null;

  async init(canvas: HTMLCanvasElement): Promise<void> {
    this.app = new Application();
    await this.app.init({
      canvas,
      resizeTo: canvas.parentElement ?? canvas,
      background: "#1a1a2e",
    });
  }

  destroy(): void {
    this.app?.destroy();
    this.app = null;
  }
}
