#!/usr/bin/env -S -- dotnet fsi --

open System
open System.Diagnostics
open System.IO

let dotnet =
    AppContext.BaseDirectory
    |> Path.GetDirectoryName
    |> Path.GetDirectoryName
    |> Path.GetDirectoryName
    |> Path.GetDirectoryName

let bin =
    let home = Environment.GetEnvironmentVariable "HOME"
    Path.Join(home, ".cache", "helix-rt", "more", "omnisharp.fsx", "lib", "OmniSharp")

let argv = Environment.GetCommandLineArgs() |> Seq.skip 2

let cmd = ProcessStartInfo(bin, argv)
cmd.Environment.Add("DOTNET_ROOT", dotnet)
cmd.Environment.Add("OMNISHARPHOME", Path.GetTempPath())

do
    use proc = Process.Start cmd
    proc.WaitForExit()

    Environment.ExitCode <- proc.ExitCode
