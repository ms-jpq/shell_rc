#!/usr/bin/env -S -- dotnet fsi --

open System
open System.Diagnostics
open System.IO
open System.Runtime.InteropServices

let pkg = Environment.GetCommandLineArgs() |> Seq.item 2

let home =
    Path.Join(Environment.GetEnvironmentVariable "HOME", ".cache", "helix-rt", "dotnet", pkg)

let tmp = Path.Join(Path.GetTempPath(), "dotnet")

let argv = [ "tool"; "install"; "--tool-path"; home; pkg ]

let cmd = ProcessStartInfo("dotnet", argv)
cmd.Environment.Add("NUGET_PACKAGES", Path.Join(tmp, "packages"))
cmd.Environment.Add("NUGET_HTTP_CACHE_PATH", Path.Join(tmp, "http"))

do
    use proc = Process.Start cmd

    proc.WaitForExit()
    assert (proc.ExitCode = 0)
