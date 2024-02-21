/**
 * @param arg0 {string}
 * @param argv {string[]}
 * @returns {number}
 */
const cmd = (arg0, ...argv) => {
  const task = $.NSTask.alloc.init;
  task.executableURL = $.NSURL.alloc.initFileURLWithPath(arg0);
  task.arguments = argv;

  const err = Ref();
  if (!task.launchAndReturnError(err)) {
    throw new Error(err[0]);
  }
  task.waitUntilExit;
  return task.terminationStatus;
};
