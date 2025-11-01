export type OS = "macos" | "ubuntu" | "unknown";
export type PackageManager = "brew" | "apt" | "unknown";

export interface PlatformInfo {
  os: OS;
  packageManager: PackageManager;
  hasDesktop: boolean;
}

export function detectOS(): OS {
  const platform = process.platform;
  if (platform === "darwin") return "macos";
  if (platform === "linux") return "ubuntu";
  return "unknown";
}

export function detectPackageManager(os: OS): PackageManager {
  if (os === "macos") return "brew";
  if (os === "ubuntu") return "apt";
  return "unknown";
}

export function hasDesktopEnvironment(): boolean {
  return (
    process.env.DISPLAY !== undefined ||
    process.env.WAYLAND_DISPLAY !== undefined ||
    process.platform === "darwin"
  );
}

export function getPlatformInfo(): PlatformInfo {
  const os = detectOS();
  return {
    os,
    packageManager: detectPackageManager(os),
    hasDesktop: hasDesktopEnvironment(),
  };
}

export function getHomeDir(): string {
  return process.env.HOME || process.env.USERPROFILE || "/home/user";
}

export function expandPath(path: string): string {
  if (path.startsWith("~")) {
    return path.replace("~", getHomeDir());
  }
  return path;
}


