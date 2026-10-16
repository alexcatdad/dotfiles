// dotfiles previews and applies a finite inventory of configuration files.
package main

import (
	"fmt"
	"os"

	"github.com/alexcatdad/dotfiles/internal/deploy"
)

func main() {
	if err := deploy.Run(os.Args[1:], os.Stdout); err != nil {
		fmt.Fprintln(os.Stderr, "dotfiles:", err)
		os.Exit(1)
	}
}
