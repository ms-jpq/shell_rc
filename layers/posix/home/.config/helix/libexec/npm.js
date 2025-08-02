#!/usr/bin/env -S -- node

import { chdir } from "node:process"
import { dirname } from "node:path"
import { fileURLToPath } from "node:url"

const dir = dirname(fileURLToPath(import.meta.url))
chdir(dir)
