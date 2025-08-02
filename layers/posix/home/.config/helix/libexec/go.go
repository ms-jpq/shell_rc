// ; exec go run "$0" "$@"
package main

import (
	"log"
	"os"
	"os/exec"
	"path"
	"regexp"
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

	re := regexp.MustCompile(`^(?:[^/]+/)*([-\w]+)(?:@\w+)?$`)
	dir := re.FindAllStringSubmatch(pkg, 1)[0][1]
	home := path.Join(homedir, ".cache", "helix-rt", "go", dir)

	cmd := exec.Command("go", "install", "-modcacherw", "--", pkg)
	cmd.Stdout, cmd.Stderr = os.Stdout, os.Stderr
	cmd.Env = append(os.Environ(), "GOPATH="+home)

	if err := cmd.Run(); err != nil {
		log.Panicln(err)
	}
}
