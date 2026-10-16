//go:build !windows

package deploy

// POSIX state privacy is checked using ownership and mode bits in prepareState.
func privateState(string) error       { return nil }
func fileACL(string) (string, error)  { return "", nil }
func restoreACL(string, string) error { return nil }
