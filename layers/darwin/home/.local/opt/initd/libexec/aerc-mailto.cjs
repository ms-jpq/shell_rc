#!/usr/bin/env -S -- osascript -l JavaScript

"use strict"

ObjC.import("stdlib")

const app = (() => {
  const app = Application.currentApplication()
  app.includeStandardAdditions = true
  return app
})()

const PATH = "/opt/homebrew/bin"

/**
 * @param {string} s
 * @returns {string}
 */
const quoted = (s) => `'${s.replace(/'/g, "'\\''")}'`

/**
 * @param {string} url
 */
const handleURL = (url) => {
  app.doShellScript(
    `${PATH}:kitty --single-instance ${PATH}:aerc ${quoted(url)} &>/dev/null &`,
  )
}

/**
 * @param {string} url
 */
const openLocation = (url) => handleURL(url)
