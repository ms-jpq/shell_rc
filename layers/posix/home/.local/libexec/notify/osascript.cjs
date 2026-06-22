#!/usr/bin/env -S -- osascript -l JavaScript

"use strict"

ObjC.import("stdlib")

/**
 * @type {string[]}
 */
const [, , , _arg0, ...argv] = ObjC.unwrap(
  $.NSProcessInfo.processInfo.arguments,
).map(ObjC.unwrap)

const app = (() => {
  const app = Application.currentApplication()
  app.includeStandardAdditions = true
  return app
})()

const [withTitle = "", body = "", soundName = ""] = argv
if (withTitle || body) {
  app.displayNotification(body, { withTitle, soundName: soundName || null })
}
