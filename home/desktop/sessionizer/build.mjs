import { build } from "esbuild";
import { readdirSync } from "fs";
import { join } from "path";

const entryPoints = readdirSync("src")
  .filter((f) => f.endsWith(".tsx"))
  .map((f) => join("src", f));

await build({
  entryPoints,
  bundle: true,
  outdir: "dist",
  platform: "node",
  format: "cjs",
  target: "node20",
  jsx: "automatic",
  external: ["@raycast/api", "react", "react-dom"],
  watch: process.argv.includes("--watch"),
});
