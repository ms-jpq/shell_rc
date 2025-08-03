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
    Path.Join(home, ".cache", "helix-rt", "dotnet", "fantomas", "fantomas")

let src = Environment.GetCommandLineArgs() |> Seq.item 2 |> Path.GetFileName
let tmp = Directory.CreateTempSubdirectory()
let dst = Path.Join(tmp.FullName, src)

try
    let cmd = ProcessStartInfo(bin, [ "--out"; dst; src ])
    cmd.Environment.Add("DOTNET_ROOT", dotnet)
    cmd.RedirectStandardOutput <- true

    use proc = Process.Start cmd
    proc.StandardOutput.ReadToEnd() |> ignore
    proc.WaitForExit()
    Environment.ExitCode <- proc.ExitCode

    File.ReadAllText dst |> Console.Write
finally
    tmp.Delete true
