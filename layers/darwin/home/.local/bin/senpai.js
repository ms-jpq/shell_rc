#!/usr/bin/env -S -- osascript -l JavaScript

"use strict";

ObjC.import("stdlib");

/**
 * @type {string[]}
 */
const [, , , arg0, ...argv] = ObjC.unwrap(
  $.NSProcessInfo.processInfo.arguments,
).map(ObjC.unwrap);

const app = (() => {
  const app = Application.currentApplication();
  app.includeStandardAdditions = true;
  return app;
})();

const [withTitle, sub, bod] = argv.length ? argv : [""];
const [body, subtitle] = bod ? [bod, sub] : [sub ?? "", ""];
app.displayNotification(body, { withTitle, subtitle });
