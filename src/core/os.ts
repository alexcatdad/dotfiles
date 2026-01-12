/**
 * OS Detection and Package Manager Utilities
 * Handles cross-platform detection and package manager discovery
 */

import { $ } from "bun";
import type { Platform } from "../types";

/**
 * Get the current platform
 */
export function getPlatform(): Platform {
  const platform = process.platform;
  if (platform === "darwin") return "darwin";
  if (platform === "linux") return "linux";
  throw new Error(`Unsupported platform: ${platform}. Only macOS and Linux are supported.`);
}

/**
 * Check if a command exists on the system
 */
export async function commandExists(cmd: string): Promise<boolean> {
  try {
    const result = await $`which ${cmd}`.quiet().nothrow();
    return result.exitCode === 0;
  } catch {
    return false;
  }
}

/**
 * Get the home directory
 */
export function getHomeDir(): string {
  const home = process.env.HOME ?? Bun.env.HOME;
  if (!home) {
    throw new Error("Could not determine home directory. HOME environment variable not set.");
  }
  return home;
}

/**
 * Get the repository directory (where this script lives)
 */
export function getRepoDir(): string {
  // import.meta.dir gives us the directory of this file
  // We need to go up from src/core to the repo root
  return import.meta.dir.replace(/\/src\/core$/, "");
}

/**
 * Standard Homebrew paths to check
 */
const BREW_PATHS = {
  darwin: [
    "/opt/homebrew/bin/brew",      // Apple Silicon
    "/usr/local/bin/brew",          // Intel Mac
  ],
  linux: [
    "/home/linuxbrew/.linuxbrew/bin/brew",
    `${process.env.HOME}/.linuxbrew/bin/brew`,
  ],
} as const;

/**
 * Find the Homebrew executable path
 */
export async function findBrewPath(): Promise<string | null> {
  // First, try the which command
  try {
    const result = await $`which brew`.quiet().nothrow();
    if (result.exitCode === 0) {
      return result.text().trim();
    }
  } catch {
    // Continue to path checking
  }

  // Check standard paths based on platform
  const platform = getPlatform();
  const pathsToCheck = BREW_PATHS[platform];

  for (const brewPath of pathsToCheck) {
    try {
      const file = Bun.file(brewPath);
      if (await file.exists()) {
        return brewPath;
      }
    } catch {
      // Path doesn't exist, continue
    }
  }

  return null;
}

export interface PackageManagerInfo {
  /** Whether Homebrew is available */
  hasBrew: boolean;
  /** Path to the brew executable */
  brewPath: string | null;
  /** Whether apt is available (Linux only) */
  hasApt: boolean;
}

/**
 * Detect available package managers
 */
export async function detectPackageManagers(): Promise<PackageManagerInfo> {
  const [brewPath, hasApt] = await Promise.all([
    findBrewPath(),
    commandExists("apt"),
  ]);

  return {
    hasBrew: brewPath !== null,
    brewPath,
    hasApt,
  };
}

/**
 * Get the CPU architecture
 */
export function getArch(): string {
  const arch = process.arch;
  switch (arch) {
    case "arm64":
      return "arm64";
    case "x64":
      return "x64";
    default:
      return arch;
  }
}

/**
 * Get a human-readable system description
 */
export function getSystemInfo(): string {
  const platform = getPlatform();
  const arch = getArch();
  const platformName = platform === "darwin" ? "macOS" : "Linux";
  return `${platformName} (${arch})`;
}

/**
 * Expand ~ to the home directory in a path
 */
export function expandPath(path: string): string {
  if (path.startsWith("~/")) {
    return path.replace("~", getHomeDir());
  }
  return path;
}

/**
 * Contract the home directory to ~ in a path (for display)
 */
export function contractPath(path: string): string {
  const home = getHomeDir();
  if (path.startsWith(home)) {
    return path.replace(home, "~");
  }
  return path;
}
