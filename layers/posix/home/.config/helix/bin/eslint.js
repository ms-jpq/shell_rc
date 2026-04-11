#!/usr/bin/env -S -- node
"use strict"

import { ok } from "node:assert/strict"
import { spawnSync } from "node:child_process"
import { randomBytes } from "node:crypto"
import { existsSync } from "node:fs"
import { open, rm } from "node:fs/promises"
import { basename, dirname, extname, join } from "node:path"
import { cwd, execPath, stdin, stdout } from "node:process"
import { pipeline } from "node:stream/promises"
import { fileURLToPath } from "node:url"
import { parseArgs } from "node:util"

/**
 * @return {IterableIterator<string>}
 */
const _parents = function* (path = cwd()) {
  const parent = dirname(path)
  yield path
  if (parent !== path) {
    yield* _parents(parent)
  }
}

const _tmp = async function* (filename = "") {
  const ext = extname(filename)
  const base = basename(filename, ext)

  while (true) {
    const name = `${base}.${randomBytes(16).toString("hex")}${ext}`
    const tmp = join(cwd(), name)
    if (!existsSync(tmp)) {
      const fd = await open(tmp, "w")
      try {
        await pipeline(stdin, fd.createWriteStream())
      } finally {
        fd.close()
      }
      try {
        yield tmp
      } finally {
        try {
          await rm(tmp, { recursive: true, force: true })
        } finally {
          break
        }
      }
    }
  }
}

const _spawn = async (arg0 = "", argv = [""], pwd = cwd()) => {
  const { error, status, signal } = spawnSync(arg0, argv, {
    stdio: "inherit",
    cwd: pwd,
  })

  if (error) {
    throw error
  } else if (signal) {
    throw signal
  } else if (status !== null) {
    process.exitCode = status
  }
  return true
}

const _eslint = async (eslint = "", filename = "") => {
  const cwd = dirname(dirname(dirname(eslint)))
  const ext = await _spawn(
    eslint,
    [
      "--exit-on-fatal-error",
      "--suppress-all",
      "--no-ignore",
      "--fix",
      "--",
      filename,
    ],
    cwd,
  )

  const fd = await open(filename)
  try {
    await pipeline(fd.createReadStream(), stdout)
  } finally {
    fd.close()
  }
  return ext
}

;(async () => {
  const {
    positionals: [filename],
  } = parseArgs({ allowPositionals: true })
  ok(filename)

  let found = false
  l1: for (const path of _parents()) {
    const eslint = join(path, "node_modules", ".bin", "eslint")
    if (existsSync(eslint)) {
      for await (const tmp of _tmp(filename)) {
        try {
          if (await _eslint(eslint, tmp)) {
            found = true
          }
        } finally {
          break l1
        }
      }
    }
  }

  if (found) {
    return
  }

  const dir = dirname(fileURLToPath(import.meta.url))
  await _spawn(execPath, [
    join(dir, "prettier"),
    "--tabsize=2",
    "--sort",
    "--filename",
    filename,
  ])
})()
