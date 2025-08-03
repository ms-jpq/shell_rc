#!/usr/bin/env -S -- dotnet fsi --

open System
open System.Diagnostics
open System.IO
open System.Runtime.InteropServices

let pkg = Environment.GetCommandLineArgs() |> Seq.item 2

let home =
    Path.Join(Environment.GetEnvironmentVariable "HOME", ".cache", "helix-rt", "dotnet", pkg)

let argv = [ "tool"; "install"; "--tool-path"; home; pkg ]

do
    use proc = ProcessStartInfo("dotnet", argv) |> Process.Start

    proc.WaitForExit()
    assert (proc.ExitCode = 0)
