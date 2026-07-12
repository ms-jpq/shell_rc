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

let name = Environment.GetCommandLineArgs() |> Seq.item 2 |> Path.GetFileName
let tmp = Directory.CreateTempSubdirectory()
let buf = Path.Join(tmp.FullName, name)

try
    do
        use stdin = Console.OpenStandardInput()
        use out = File.Create buf
        stdin.CopyTo out

    let cmd = ProcessStartInfo(bin, [ buf ], RedirectStandardOutput = true)
    cmd.Environment.Add("DOTNET_ROOT", dotnet)

    use proc = Process.Start cmd
    proc.StandardOutput.ReadToEnd() |> ignore
    proc.WaitForExit()

    Environment.ExitCode <- proc.ExitCode

    File.ReadAllText buf |> Console.Write
finally
    tmp.Delete true
