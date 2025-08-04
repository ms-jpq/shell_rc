#!/usr/bin/env -S -- node

import { ok } from "node:assert/strict"
import { spawnSync } from "node:child_process"
import { randomBytes } from "node:crypto"
import { existsSync } from "node:fs"
import { open, rm } from "node:fs/promises"
import { basename, dirname, extname, join } from "node:path"
import { argv, cwd, stdin, stdout } from "node:process"
import { pipeline } from "node:stream/promises"

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

const _eslint = async (eslint = "", filename = "") => {
  const { error, status, signal } = spawnSync(
    eslint,
    ["--exit-on-fatal-error", "--no-ignore", "--fix", "--", filename],
    { stdio: "inherit" },
  )

  if (error) {
    throw error
  } else if (signal) {
    throw signal
  } else if (status) {
    process.exitCode = status ?? undefined
  }

  const fd = await open(filename)
  try {
    await pipeline(fd.createReadStream(), stdout)
  } finally {
    fd.close()
  }
}

const [, , filename] = argv
ok(filename)
;(async () => {
  for (const path of _parents()) {
    const eslint = join(path, "node_modules", ".bin", "eslint")
    if (existsSync(eslint)) {
      for await (const tmp of _tmp(filename)) {
        return await _eslint(eslint, tmp)
      }
    }
  }
  stdin.pipe(stdout)
})()
