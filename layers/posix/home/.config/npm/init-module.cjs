const conf = "tsconfig.json";
const { cwd } = require("node:process");
const { join } = require("node:path");
const {
  copyFileSync,
  constants: { COPYFILE_FICLONE },
} = require("node:fs");

module.exports = require("./package.json");
copyFileSync(join(__dirname, conf), join(cwd(), conf), COPYFILE_FICLONE);
