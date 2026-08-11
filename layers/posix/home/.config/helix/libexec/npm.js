#!/usr/bin/env -S -- node

import { ok } from "node:assert/strict"
import { spawnSync } from "node:child_process"
import { mkdirSync, writeFileSync } from "node:fs"
import { homedir, tmpdir } from "node:os"
import { join, sep } from "node:path"
import { env, platform } from "node:process"
import { parseArgs } from "node:util"

const {
  values: { ignoreScripts },
  positionals,
} = parseArgs({
  allowNegative: true,
  allowPositionals: true,
  options: {
    ignoreScripts: { type: "boolean", default: true },
  },
})

const [pkg, ...pkgs] = positionals.map((a) => a.trim())

ok(pkg)

const cwd = join(
  homedir(),
  ".cache",
  "helix-rt",
  "nodejs",
  pkg.replaceAll(sep, "-"),
)
const json = {
  dependencies: Object.fromEntries([pkg, ...pkgs].map((p) => [p, "*"])),
}

mkdirSync(cwd, { recursive: true })
writeFileSync(join(cwd, "package.json"), JSON.stringify(json))

const args = [
  "install",
  `--ignore-scripts=${ignoreScripts}`,
  "--no-package-lock",
  "--no-update-notifier",
  "--no-fund",
  "--fetch-retries",
  "5",
  "--cache",
  join(tmpdir(), "npm"),
  "--no-progress",
]
const [command, commandArgs] = (() => {
  if (platform === "win32") {
    return [env.ComSpec ?? "cmd.exe", ["/d", "/c", "npm.cmd", ...args]]
  }
  return ["npm", args]
})()

const { error, status, signal } = spawnSync(command, commandArgs, {
  cwd,
  stdio: "inherit",
})

if (error) {
  console.warn(error)
} else if (signal) {
  throw signal
} else {
  process.exitCode = status ?? undefined
}
