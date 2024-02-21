/**
 * @param arg0 {string}
 * @param argv {string[]}
 * @returns {number}
 */
const system = (arg0, ...argv) => {
  const task = $.NSTask.alloc.init;
  task.executableURL = $.NSURL.alloc.initFileURLWithPath("/usr/bin/env");
  task.arguments = ["--", arg0, ...argv];

  const nserr = Ref();
  if (!task.launchAndReturnError(nserr)) {
    throw new Error(nserr[0]);
  }
  task.waitUntilExit;
  return task.terminationStatus;
};
