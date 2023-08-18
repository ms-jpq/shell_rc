#!/usr/bin/env -S -- node

import { stdin, stdout } from "node:process";
import { stripVTControlCharacters } from "node:util";

const acc = [];
for await (const bytes of stdin) {
  acc.push(bytes);
}
const buf = Buffer.concat(acc);
const raw = buf.toString();
const stripped = stripVTControlCharacters(raw);
stdout.write(stripped);
