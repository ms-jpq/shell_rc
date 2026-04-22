#!/usr/bin/env -S -- runhaskell

import           Data.Function      ((&))
import           Data.Functor       ((<&>))
import           System.Directory   (createDirectoryIfMissing)
import           System.Environment (getEnv)
import           System.Exit        (exitSuccess)
import           System.FilePath    (dropExtension, takeBaseName, (</>))
import           System.Info        (os)
import           System.Process     (callProcess, readProcess)
import           Text.Printf        (printf)


repo = "haskell/stylish-haskell"
base = "https://github.com/haskell/stylish-haskell/releases/latest/download/stylish-haskell"

uri "darwin" = printf "%s-%s-darwin-x86_64.zip" base
uri "linux"  = printf "%s-%s-linux-x86_64.tar.gz" base

nameof "linux" = dropExtension
nameof _       = id

run "mingw32" = exitSuccess
run os = do
  binDir <- getEnv "BIN"
  run <- getEnv "RUN"
  version <- readProcess "env" ["--", "gh-latest.sh", ".", repo] ""

  let link = uri os version
  let name = nameof os link & takeBaseName
  let srv = run </> name </> "stylish-haskell"

  _ <- readProcess "env" ["--", "get.sh", link] ""
    >>= readProcess "env" ["--", "unpack.sh", run]
    >>= putStr

  _ <- createDirectoryIfMissing True binDir
  _ <- callProcess "install" ["-v", "-b", "--", srv, binDir </> "stylish"]
  exitSuccess

main = run os
