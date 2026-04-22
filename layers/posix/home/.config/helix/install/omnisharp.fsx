#!/usr/bin/env -S -- dotnet fsi --

open System
open System.Diagnostics
open System.IO
open System.Runtime.InteropServices

let run = Environment.GetEnvironmentVariable "RUN"
let lib = Environment.GetEnvironmentVariable "LIB"

let arch = Runtime.InteropServices.Architecture()
let win = RuntimeInformation.IsOSPlatform OSPlatform.Windows

match win with
| true -> System.Environment.Exit 0
| _ -> ()

let base_uri =
    "https://github.com/OmniSharp/omnisharp-roslyn/releases/latest/download/omnisharp"

let uri =
    if RuntimeInformation.IsOSPlatform OSPlatform.OSX then
        sprintf "%s-%s" base_uri "osx-arm64-net6.0.tar.gz"
    elif RuntimeInformation.IsOSPlatform OSPlatform.Linux then
        sprintf "%s-%s-%A-%s" base_uri "linux-" arch "-net6.0.tar.gz"
    else
        sprintf "%s-%s-%A-%s" base_uri "win-" arch "-net6.0.zip"

let pipe arg0 argv (input: 'a) =
    let start =
        ProcessStartInfo(arg0, RedirectStandardInput = true, RedirectStandardOutput = true)

    argv |> Seq.iter start.ArgumentList.Add

    use proc = Process.Start start

    do
        use stdin = proc.StandardInput
        stdin.Write input

    proc.WaitForExit()
    assert (proc.ExitCode = 0)
    proc.StandardOutput.ReadToEnd()

"" |> pipe "get.sh" [ uri ] |> pipe "unpack.sh" [ run ] |> Console.Write

try
    Directory.Delete(lib, true)
with :? DirectoryNotFoundException ->
    ()

do
  use proc = Process.Start("cp", [ "-r"; "--"; run; lib ])
  proc.WaitForExit()
  assert (proc.ExitCode = 0)
