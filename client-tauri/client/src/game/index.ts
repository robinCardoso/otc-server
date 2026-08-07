/** Game state and session lifecycle (TFS 8.60 client). */

export type GameState = "idle" | "connecting" | "in_game";

export class Game {
  private state: GameState = "idle";

  getState(): GameState {
    return this.state;
  }

  setState(state: GameState): void {
    this.state = state;
  }
}
