#!/usr/bin/env node

import { ok } from "assert";
import { spawnSync } from "child_process";
import { log } from "console";
import { existsSync, mkdirSync } from "fs";
import { delimiter, dirname, join, isAbsolute } from "path";
import { argv, cwd, stdout } from "process";

const [, _, ...args] = argv;

{
  const parent = dirname(new URL(import.meta.url).pathname);
  process.env["PATH"] = process.env["PATH"]
    .split(delimiter)
    .filter((p) => p !== parent)
    .join(delimiter);
}

const global_home = process.env["NPM_GLOBAL_HOME"];
ok(global_home);
ok(isAbsolute(global_home));

const global_set = new Set(["--global", "-g"]);
const is_global_install = (() => {
  const install_set = new Set([
    "add",
    "i",
    "in",
    "ins",
    "inst",
    "insta",
    "instal",
    "install",
    "isnt",
    "isnta",
    "isntal",
  ]);

  const [command] = args;
  const is_install = install_set.has(command);
  const is_global = args.some((arg) => global_set.has(arg));
  return is_install && is_global;
})();

const new_cwd = is_global_install ? global_home : cwd();
const new_args = is_global_install
  ? args.filter((arg) => !global_set.has(arg))
  : args;

if (is_global_install) {
  if (!existsSync(global_home)) {
    mkdirSync(global_home, { recursive: true });
  }
  const packages = join(global_home, "package.json");
  if (!existsSync(packages)) {
    const { status } = spawnSync("npm", ["init", "--yes"], {
      cwd: new_cwd,
      stdio: ["ignore", "inherit", "inherit"],
    });
    ok(status === 0);
  }

  const { columns } = stdout;
  log("-".repeat(columns));
  log(`@ - ${packages} - @`);
  log("-".repeat(columns));
}

const { status } = spawnSync("npm", [...new_args], {
  cwd: new_cwd,
  stdio: "inherit",
});
process.exitCode = status;
