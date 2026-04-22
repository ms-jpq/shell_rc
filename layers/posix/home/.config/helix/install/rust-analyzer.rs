#!/usr/bin/env -S -- bash -Eeuo pipefail
// || rustc --edition=2021 -o "${T:="$(mktemp)"}" -- "$0" && exec -a "$0" -- "$T" "$0" "$@"

#![deny(clippy::all, clippy::cargo, clippy::pedantic)]

use std::{
  backtrace::Backtrace,
  env::{consts::ARCH, var_os},
  error::Error,
  fs::{create_dir_all, read_dir},
  path::PathBuf,
  process::{Command, Stdio},
};

fn main() -> Result<(), Box<dyn Error>> {
  let uri = {
    let base = "https://github.com/rust-lang/rust-analyzer/releases/latest/download/rust-analyzer";
    #[cfg(target_os = "macos")]
    {
      format!("{base}-{ARCH}-apple-darwin.gz")
    }
    #[cfg(target_os = "linux")]
    {
      format!("{base}-{ARCH}-unknown-linux-gnu.gz")
    }
    #[cfg(target_os = "windows")]
    {
      format!("{base}-{ARCH}-pc-windows-msvc.zip")
    }
  };

  let run = var_os("RUN")
    .map(PathBuf::from)
    .ok_or_else(|| format!("{}", Backtrace::capture()))?;

  let bin_dir = var_os("BIN")
    .map(PathBuf::from)
    .ok_or_else(|| format!("{}", Backtrace::capture()))?;

  let bin = bin_dir.join("rust-analyzer");

  #[cfg(target_family = "windows")]
  let bin = {
    let mut bin = bin;
    bin.set_extension("exe");
    bin
  };

  let mut proc = Command::new("env")
    .arg("--")
    .arg("get.sh")
    .arg(uri)
    .stdout(Stdio::piped())
    .spawn()?;
  let stdin = proc
    .stdout
    .take()
    .ok_or_else(|| format!("{}", Backtrace::capture()))?;
  let status = Command::new("env")
    .arg("--")
    .arg("unpack.sh")
    .arg(&run)
    .stdin(stdin)
    .status()?;

  assert!(proc.wait()?.success());
  assert!(status.success());

  create_dir_all(bin_dir)?;

  #[cfg(target_family = "unix")]
  let prefix = "rust-analyzer-";

  #[cfg(target_family = "windows")]
  let prefix = "rust-analyzer.exe";

  for entry in read_dir(&run)? {
    let entry = entry?;
    if entry
      .file_name()
      .into_string()
      .map_err(|p| format!("{p:?}"))?
      .starts_with(prefix)
    {
      let path = entry.path();
      let status = Command::new("install")
        .arg("-v")
        .arg("-b")
        .arg("--")
        .arg(&path)
        .arg(&bin)
        .status()?;
      assert!(status.success());
      return Ok(());
    }
  }

  Err(format!("{}", line!()).into())
}
