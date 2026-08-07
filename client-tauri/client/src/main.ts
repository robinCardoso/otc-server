import { GameRenderer } from "./renderer";

let renderer: GameRenderer | null = null;

window.addEventListener("DOMContentLoaded", async () => {
  const canvas = document.querySelector<HTMLCanvasElement>("#game-canvas");
  if (!canvas) return;

  renderer = new GameRenderer();
  await renderer.init(canvas);
});
