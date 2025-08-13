#!/usr/bin/env -S -- clojure.sh -M

(import '[java.lang ProcessBuilder ProcessBuilder$Redirect]
        '[java.nio.file FileAlreadyExistsException Files Path StandardCopyOption]
        '[java.nio.file.attribute FileAttribute PosixFilePermissions])

(def arch (System/getProperty "os.arch"))
(def os (System/getProperty "os.name"))
(def tmp (-> "RUN"
             System/getenv
             (Path/of (into-array String []))))

(def base "https://github.com/clojure-lsp/clojure-lsp/releases/latest/download/clojure-lsp-native")

(def uri
  (str base "-"
       (case (System/getProperty "os.name")
         "Linux" (str "static-linux-" arch ".zip")
         "Mac OS X" (str "macos-" arch ".zip")
         (str "windows-" arch ".zip"))))

(def bin (let [b (System/getenv "BIN")
               ext (case os
                     "Windows" ".exe"
                     "")]
           (Path/of b (into-array String [(str "clojure-lsp" ext)]))))

(doseq
 [proc (ProcessBuilder/startPipeline
        [(-> (ProcessBuilder. ["get.sh", uri])
             (.redirectError ProcessBuilder$Redirect/INHERIT))
         (->
          (ProcessBuilder. ["unpack.sh", (.toString tmp)])
          (.redirectOutput ProcessBuilder$Redirect/INHERIT)
          (.redirectError ProcessBuilder$Redirect/INHERIT))])]
  (-> proc .waitFor zero? assert))

(def src (.resolve tmp "clojure-lsp"))

(->> "rwxrwxr-x"
     (PosixFilePermissions/fromString)
     (Files/setPosixFilePermissions src))

(try
  (Files/createDirectory (.getParent bin) (into-array FileAttribute []))
  (catch FileAlreadyExistsException _))

(Files/move src bin (into-array [StandardCopyOption/REPLACE_EXISTING]))
