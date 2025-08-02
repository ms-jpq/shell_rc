// ; exec go run "$0" "$@"
package main

import (
	"log"
	"os"
	"os/exec"
	"path"
	"strings"
)

func init() {
	log.SetFlags(log.Lshortfile)
}

func main() {
	homedir, err := os.UserHomeDir()
	if err != nil {
		log.Panicln(err)
	}
	pkg := os.Args[1]
	lib := path.Join(homedir, ".cache", "helix-rt", "go", strings.ReplaceAll(pkg, string(os.PathSeparator), "-"))

	cmd := exec.Command("go", "install", "-modcacherw", "--", pkg)
	cmd.Stdout, cmd.Stderr = os.Stdout, os.Stderr
	cmd.Env = append(os.Environ(), "GOPATH="+lib)

	if err := cmd.Run(); err != nil {
		log.Panicln(err)
	}
}
