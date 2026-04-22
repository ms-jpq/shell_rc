// ; exec go run "$0" "$@"
package main

import (
	"fmt"
	"io"
	"log"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"runtime"
	"strings"
	"sync"
)

func init() {
	log.SetFlags(log.Lshortfile)
}

const repo = "golangci/golangci-lint"

func main() {
	base := fmt.Sprintf("https://github.com/%s/releases/latest/download/golangci-lint", repo)

	binDir, ok := os.LookupEnv("BIN")
	if !ok {
		log.Panicln()
	}
	bin, ext := path.Join(binDir, "golangci-lint"), "tar.gz"
	if runtime.GOOS == "windows" {
		bin += ".exe"
		ext = "zip"
	}

	run, ok := os.LookupEnv("RUN")
	if !ok {
		log.Panicln()
	}

	cmd := exec.Command("env", "--", "gh-latest.sh", ".", repo)
	cmd.Stderr = os.Stderr
	output, err := cmd.Output()
	if err != nil {
		log.Panicln(err)
	}
	version, _ := strings.CutPrefix(string(output), "v")

	uri := fmt.Sprintf("%s-%s-%s-%s.%s", base, version, runtime.GOOS, runtime.GOARCH, ext)

	get := exec.Command("env", "--", "get.sh", uri)
	unpack := exec.Command("env", "--", "unpack.sh", run)
	get.Stderr, unpack.Stderr = os.Stderr, os.Stderr
	r, w := io.Pipe()
	unpack.Stdin, get.Stdout = r, w

	wg := sync.WaitGroup{}

	go func() {
		defer wg.Done()
		defer w.Close()
		if err := get.Run(); err != nil {
			log.Panicln(err)
		}
	}()
	go func() {
		defer wg.Done()
		if err := unpack.Run(); err != nil {
			log.Panicln(err)
		}
	}()
	wg.Add(2)
	wg.Wait()

	pat := filepath.Join(run, "*", "golangci-lint*")
	globbed, err := filepath.Glob(pat)
	if err != nil {
		log.Panicln(err)
	}

	if err = os.MkdirAll(binDir, 0755); err != nil {
		log.Panicln(err)
	}

	install := exec.Command("install", "-v", "-b", "--", globbed[0], bin)
	install.Stdout, install.Stderr = os.Stdout, os.Stderr
	if err = install.Run(); err != nil {
		log.Panicln(err)
	}
}
