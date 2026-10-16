//go:build linux

// Linux-only standard-library PTY probe; runs solely in the disposable test home.
package main

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"regexp"
	"syscall"
	"time"
	"unsafe"
)

func ioctl(fd uintptr, request uintptr, value unsafe.Pointer) error {
	_, _, errno := syscall.Syscall(syscall.SYS_IOCTL, fd, request, uintptr(value))
	if errno != 0 {
		return errno
	}
	return nil
}
func probe() error {
	master, err := os.OpenFile("/dev/ptmx", os.O_RDWR|syscall.O_NOCTTY, 0)
	if err != nil {
		return err
	}
	defer master.Close()
	var unlock int32
	if err = ioctl(master.Fd(), 0x40045431, unsafe.Pointer(&unlock)); err != nil {
		return err
	}
	var number uint32
	if err = ioctl(master.Fd(), 0x80045430, unsafe.Pointer(&number)); err != nil {
		return err
	}
	slave, err := os.OpenFile(fmt.Sprintf("/dev/pts/%d", number), os.O_RDWR|syscall.O_NOCTTY, 0)
	if err != nil {
		return err
	}
	defer slave.Close()
	dimensions := [4]uint16{30, 120, 0, 0}
	if err = ioctl(master.Fd(), syscall.TIOCSWINSZ, unsafe.Pointer(&dimensions[0])); err != nil {
		return err
	}
	cmd := exec.Command("zsh", "-il")
	cmd.Stdin, cmd.Stdout, cmd.Stderr = slave, slave, slave
	cmd.SysProcAttr = &syscall.SysProcAttr{Setsid: true, Setctty: true, Ctty: 0}
	if err = cmd.Start(); err != nil {
		return err
	}
	// Interactive shells may ignore SIGTERM. Reap the owned fixture process
	// group reliably on both success and failure.
	defer func() { _ = syscall.Kill(-cmd.Process.Pid, syscall.SIGKILL); _ = cmd.Wait() }()
	chunks := make(chan []byte, 32)
	stop := make(chan struct{})
	defer close(stop)
	go func() {
		defer close(chunks)
		for {
			buffer := make([]byte, 65536)
			n, err := master.Read(buffer)
			if n > 0 {
				select {
				case chunks <- buffer[:n]:
				case <-stop:
					return
				}
			}
			if err != nil {
				return
			}
		}
	}()
	var transcript []byte
	ansi := regexp.MustCompile("\x1b\\[[0-?]*[ -/]*[@-~]")
	readUntil := func(needle []byte, offset int) bool {
		timeout := time.NewTimer(10 * time.Second)
		defer timeout.Stop()
		for {
			if bytes.Contains(transcript[offset:], needle) || bytes.Contains(ansi.ReplaceAll(transcript[offset:], nil), needle) {
				return true
			}
			select {
			case part, ok := <-chunks:
				if !ok {
					return false
				}
				transcript = append(transcript, part...)
			case <-timeout.C:
				return false
			}
		}
	}
	if _, err = master.Write([]byte("print PTY_READY\r")); err != nil {
		return err
	}
	marker := []byte("\r\nPTY_READY\r\n")
	if !readUntil(marker, 0) {
		return fmt.Errorf("shell did not become ready")
	}
	after := bytes.LastIndex(transcript, marker) + len(marker)
	if !readUntil([]byte("\x1b[?2004h"), after) {
		return fmt.Errorf("Zsh line editor did not become ready")
	}
	transcript = nil
	if _, err = master.Write([]byte("\x12fixture-repeated")); err != nil {
		return err
	}
	if !readUntil([]byte("fixture-repeated-command"), 0) {
		start := len(transcript) - 6000
		if start < 0 {
			start = 0
		}
		return fmt.Errorf("Ctrl-R did not show seeded Atuin history: %s", transcript[start:])
	}
	// Escape cancels search; Ctrl-C clears input, so no history item is executed.
	if _, err = master.Write([]byte("\x1b")); err != nil {
		return err
	}
	if _, err = master.Write([]byte("\x03exit\r")); err != nil {
		return err
	}
	return nil
}
func main() {
	if err := probe(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	fmt.Println("PTY history search passed")
}
