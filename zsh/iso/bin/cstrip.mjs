#!/usr/bin/env -S -- node

import { EOL } from "node:os";
import { stdin, stdout } from "node:process";
import { createInterface } from "node:readline/promises";
import { pipeline } from "node:stream/promises";
import { stripVTControlCharacters } from "node:util";

await pipeline(async function* () {
  for await (const line of createInterface({
    input: stdin,
    crlfDelay: Infinity,
  })) {
    yield stripVTControlCharacters(line);
    yield EOL;
  }
}, stdout);
