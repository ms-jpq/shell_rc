#!/usr/bin/env -S -- clojure.sh -M

(import '[java.lang ProcessBuilder ProcessBuilder$Redirect]
        '[java.nio.file FileAlreadyExistsException Files Path StandardCopyOption]
        '[java.nio.file.attribute FileAttribute PosixFilePermissions])
(require
 '[clojure.string :refer [join] :as s]
 '[clojure.java.shell :refer [sh]])

(def arch (System/getProperty "os.arch"))
(def tmp (-> "RUN"
             System/getenv
             (Path/of (into-array String []))))

(def repo "clj-kondo/clj-kondo")
(def base (str "https://github.com/" repo "/releases/latest/download/clj-kondo"))
(def version
  (let [{:keys [exit err out]} (sh "gh-latest.sh" "." repo)]
    (print err)
    (assert (zero? exit))
    (s/replace out #"^v" "")))

(def uri
  (join "-" [base version
             (case (System/getProperty "os.name")
               "Linux" (str "linux-static-" arch ".zip")
               "Mac OS X" (str "macos-" arch ".zip")
               (str "windows-" arch ".zip"))]))

(def bin (let [b (System/getenv "BIN")
               ext (case (System/getProperty "os.name")
                     "Windows" ".exe"
                     "")]
           (Path/of b (into-array String [(str "clj-kondo" ext)]))))

(def src (.resolve tmp "clj-kondo"))

(doseq
 [proc (ProcessBuilder/startPipeline
        [(-> (ProcessBuilder. ["get.sh", uri])
             (.redirectError ProcessBuilder$Redirect/INHERIT))
         (->
          (ProcessBuilder. ["unpack.sh", (.toString tmp)])
          (.redirectOutput ProcessBuilder$Redirect/INHERIT)
          (.redirectError ProcessBuilder$Redirect/INHERIT))])]
  (-> proc .waitFor zero? assert))

(->> "rwxrwxr-x"
     (PosixFilePermissions/fromString)
     (Files/setPosixFilePermissions src))

(try
  (Files/createDirectory (.getParent bin) (into-array FileAttribute []))
  (catch FileAlreadyExistsException _))

(Files/move src bin (into-array [StandardCopyOption/REPLACE_EXISTING]))
