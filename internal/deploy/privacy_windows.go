//go:build windows

package deploy

import (
	"fmt"
	"os/user"
	"strings"
	"syscall"
	"unsafe"
)

// Protect the state root before writing backups. POSIX permission bits do not
// enforce privacy on NTFS. Descendants inherit this protected user/SYSTEM DACL.
func privateState(path string) error {
	u, err := user.Current()
	if err != nil {
		return err
	}
	return restoreACL(path, "D:P(A;OICI;FA;;;SY)(A;OICI;FA;;;"+u.Uid+")")
}
func restoreACL(path, acl string) error {
	if acl == "" {
		return nil
	}
	sddl, err := syscall.UTF16PtrFromString(acl)
	if err != nil {
		return err
	}
	p, err := syscall.UTF16PtrFromString(path)
	if err != nil {
		return err
	}
	advapi := syscall.NewLazyDLL("advapi32.dll")
	convert := advapi.NewProc("ConvertStringSecurityDescriptorToSecurityDescriptorW")
	set := advapi.NewProc("SetFileSecurityW")
	var descriptor uintptr
	ok, _, callErr := convert.Call(uintptr(unsafe.Pointer(sddl)), 1, uintptr(unsafe.Pointer(&descriptor)), 0)
	if ok == 0 {
		return fmt.Errorf("cannot construct private state ACL: %w", callErr)
	}
	defer syscall.NewLazyDLL("kernel32.dll").NewProc("LocalFree").Call(descriptor)
	const daclSecurityInformation = 0x4
	protection := uintptr(0x20000000) // UNPROTECTED_DACL_SECURITY_INFORMATION
	if strings.HasPrefix(acl, "D:P") {
		protection = 0x80000000
	}
	ok, _, callErr = set.Call(uintptr(unsafe.Pointer(p)), daclSecurityInformation|protection, descriptor)
	if ok == 0 {
		return fmt.Errorf("cannot protect private state directory: %w", callErr)
	}
	return nil
}
func fileACL(path string) (string, error) {
	p, err := syscall.UTF16PtrFromString(path)
	if err != nil {
		return "", err
	}
	advapi := syscall.NewLazyDLL("advapi32.dll")
	get := advapi.NewProc("GetFileSecurityW")
	var needed uint32
	get.Call(uintptr(unsafe.Pointer(p)), 4, 0, 0, uintptr(unsafe.Pointer(&needed)))
	if needed == 0 {
		return "", fmt.Errorf("cannot read file ACL")
	}
	buffer := make([]byte, needed)
	ok, _, callErr := get.Call(uintptr(unsafe.Pointer(p)), 4, uintptr(unsafe.Pointer(&buffer[0])), uintptr(needed), uintptr(unsafe.Pointer(&needed)))
	if ok == 0 {
		return "", fmt.Errorf("cannot read file ACL: %w", callErr)
	}
	var text *uint16
	var length uint32
	ok, _, callErr = advapi.NewProc("ConvertSecurityDescriptorToStringSecurityDescriptorW").Call(uintptr(unsafe.Pointer(&buffer[0])), 1, 4, uintptr(unsafe.Pointer(&text)), uintptr(unsafe.Pointer(&length)))
	if ok == 0 {
		return "", fmt.Errorf("cannot serialize file ACL: %w", callErr)
	}
	defer syscall.NewLazyDLL("kernel32.dll").NewProc("LocalFree").Call(uintptr(unsafe.Pointer(text)))
	return syscall.UTF16ToString(unsafe.Slice(text, length)), nil
}
