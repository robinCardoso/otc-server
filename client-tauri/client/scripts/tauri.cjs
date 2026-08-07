const { spawnSync } = require("child_process");
const path = require("path");
const os = require("os");

const cargoBin = path.join(os.homedir(), ".cargo", "bin");
const env = {
  ...process.env,
  PATH: `${cargoBin};${process.env.PATH}`,
};

const args = ["tauri", ...process.argv.slice(2)];
const result = spawnSync("npx", args, { env, stdio: "inherit", shell: true });
process.exit(result.status ?? 1);
