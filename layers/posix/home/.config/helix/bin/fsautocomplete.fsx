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
    Path.Join(home, ".cache", "helix-rt", "dotnet", "fsautocomplete", "fsautocomplete")

let argv = Environment.GetCommandLineArgs() |> Seq.skip 2

let _ =
    let cmd = ProcessStartInfo(bin, argv)
    cmd.Environment.Add("DOTNET_ROOT", dotnet)

    use proc = Process.Start cmd
    proc.StandardOutput.ReadToEnd() |> ignore
    Environment.ExitCode <- proc.ExitCode
