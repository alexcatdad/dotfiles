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
	set := advapi.NewProc("SetNamedSecurityInfoW")
	var descriptor uintptr
	ok, _, callErr := convert.Call(uintptr(unsafe.Pointer(sddl)), 1, uintptr(unsafe.Pointer(&descriptor)), 0)
	if ok == 0 {
		return fmt.Errorf("cannot construct private state ACL: %w", callErr)
	}
	defer syscall.NewLazyDLL("kernel32.dll").NewProc("LocalFree").Call(descriptor)
	const daclSecurityInformation = 0x4
	var present, defaulted uint32
	var dacl uintptr
	ok, _, callErr = advapi.NewProc("GetSecurityDescriptorDacl").Call(descriptor, uintptr(unsafe.Pointer(&present)), uintptr(unsafe.Pointer(&dacl)), uintptr(unsafe.Pointer(&defaulted)))
	if ok == 0 || present == 0 {
		return fmt.Errorf("cannot extract reviewed state DACL: %w", callErr)
	}
	protection := uintptr(0x20000000) // UNPROTECTED_DACL_SECURITY_INFORMATION
	if strings.HasPrefix(acl, "D:P") {
		protection = 0x80000000
	} else {
		// SetNamedSecurityInfo regenerates inherited ACEs from the parent.
		// Supplying inherited entries too would duplicate them on restoration.
		var size struct{ Count, Used, Free uint32 }
		ok, _, callErr = advapi.NewProc("GetAclInformation").Call(dacl, uintptr(unsafe.Pointer(&size)), unsafe.Sizeof(size), 2)
		if ok == 0 {
			return fmt.Errorf("cannot inspect original DACL: %w", callErr)
		}
		for n := int(size.Count) - 1; n >= 0; n-- {
			var ace *struct {
				Type, Flags byte
				Size        uint16
			}
			ok, _, callErr = advapi.NewProc("GetAce").Call(dacl, uintptr(n), uintptr(unsafe.Pointer(&ace)))
			if ok == 0 {
				return fmt.Errorf("cannot inspect DACL entry: %w", callErr)
			}
			if ace.Flags&0x10 != 0 {
				ok, _, callErr = advapi.NewProc("DeleteAce").Call(dacl, uintptr(n))
				if ok == 0 {
					return fmt.Errorf("cannot normalize inherited DACL entries: %w", callErr)
				}
			}
		}
	}
	const seFileObject = 1
	result, _, _ := set.Call(uintptr(unsafe.Pointer(p)), seFileObject, daclSecurityInformation|protection, 0, 0, dacl, 0)
	if result != 0 {
		return fmt.Errorf("cannot apply reviewed file DACL: %w", syscall.Errno(result))
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
