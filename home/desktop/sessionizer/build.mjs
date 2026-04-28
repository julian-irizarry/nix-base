import { build, context } from "esbuild";
import { readdirSync } from "fs";
import { join } from "path";

const entryPoints = readdirSync("src")
  .filter((f) => f.endsWith(".tsx"))
  .map((f) => join("src", f));

const opts = {
  entryPoints,
  bundle: true,
  outdir: "dist",
  platform: "node",
  format: "cjs",
  target: "node20",
  jsx: "automatic",
  external: ["@raycast/api", "react", "react-dom"],
};

if (process.argv.includes("--watch")) {
  const ctx = await context(opts);
  await ctx.watch();
} else {
  await build(opts);
}
