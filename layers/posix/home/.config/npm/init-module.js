const { readFileSync } = require("node:fs");
const { join } = require("node:path");

const pkg = join(__dirname, "package.json");
const data = readFileSync(pkg).toString();
console.info(data);
