#!/usr/bin/env -S -- node
"use strict"

import { stdin, stdout } from "node:process"
import { text } from "node:stream/consumers"

const graphemes = new Intl.Segmenter("und", { granularity: "grapheme" })
const emoji = /^\p{Emoji}$/u
const pictograph = /^\p{Extended_Pictographic}$/u
const emojiPresentation = /^\p{Emoji_Presentation}$/u

/** @param {Intl.SegmentData} part @returns {string} */
const normalizeGrapheme = ({ segment }) =>
  emoji.test(segment) &&
  pictograph.test(segment) &&
  !emojiPresentation.test(segment)
    ? segment + "\uFE0F"
    : segment

/** @param {string} input @returns {string} */
export const normalize = (input) =>
  graphemes
    .segment(input)
    [Symbol.iterator]()
    .map(normalizeGrapheme)
    .toArray()
    .join("")

if (import.meta.main) {
  stdout.write(normalize(await text(stdin)))
}
