/**
 * Auto-Update Checking
 * Handles version checking against GitHub releases with rate limiting
 */

import { resolve } from "node:path";
import { $ } from "bun";
import type { UpdateState, GitHubRelease } from "../types";
import { logger } from "./logger";
import { getHomeDir, contractPath, getPlatform } from "./os";

/** GitHub API endpoint for latest release */
const GITHUB_API_URL = "https://api.github.com/repos/alexcatdad/dotfiles/releases/latest";

/** State file name in home directory */
const UPDATE_STATE_FILE = ".paw-update-state.json";

/** Minimum interval between update checks (24 hours) */
const CHECK_INTERVAL_MS = 24 * 60 * 60 * 1000;

/** Request timeout for GitHub API (5 seconds) */
const FETCH_TIMEOUT_MS = 5000;

// ANSI color codes for the update banner
const COLORS = {
  reset: "\x1b[0m",
  bold: "\x1b[1m",
  dim: "\x1b[2m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  cyan: "\x1b[36m",
  gray: "\x1b[90m",
  bgYellow: "\x1b[43m",
  black: "\x1b[30m",
  underline: "\x1b[4m",
} as const;

/**
 * Get the path to the update state file
 */
function getUpdateStatePath(): string {
  return resolve(getHomeDir(), UPDATE_STATE_FILE);
}

/**
 * Load the update state from disk
 */
export async function loadUpdateState(): Promise<UpdateState | null> {
  const path = getUpdateStatePath();
  const file = Bun.file(path);

  if (!(await file.exists())) {
    return null;
  }

  try {
    const content = await file.text();
    return JSON.parse(content) as UpdateState;
  } catch {
    // Corrupted state file, will be reset on next check
    return null;
  }
}

/**
 * Save the update state to disk
 */
export async function saveUpdateState(state: UpdateState): Promise<void> {
  const path = getUpdateStatePath();
  await Bun.write(path, JSON.stringify(state, null, 2));
  logger.debug(`Saved update state to ${contractPath(path)}`, true);
}

/**
 * Check if we should perform an update check (rate limiting)
 */
export function shouldCheckForUpdates(state: UpdateState | null): boolean {
  // Always check if no state exists
  if (!state) return true;

  // Check if enough time has passed since last check
  const lastCheck = new Date(state.lastCheck).getTime();
  const now = Date.now();
  return now - lastCheck >= CHECK_INTERVAL_MS;
}

/**
 * Fetch the latest release from GitHub API
 * Returns null on network error (fails silently)
 */
export async function getLatestVersion(): Promise<GitHubRelease | null> {
  try {
    const response = await fetch(GITHUB_API_URL, {
      headers: {
        Accept: "application/vnd.github.v3+json",
        "User-Agent": "paw-cli",
      },
      signal: AbortSignal.timeout(FETCH_TIMEOUT_MS),
    });

    if (!response.ok) return null;

    const data = (await response.json()) as GitHubRelease;
    return data;
  } catch {
    // Network error, timeout, etc. - fail silently
    return null;
  }
}

/**
 * Compare semantic versions
 * Returns: 1 if a > b, -1 if a < b, 0 if equal
 */
export function compareVersions(a: string, b: string): number {
  // Strip leading 'v' if present
  const cleanA = a.replace(/^v/, "");
  const cleanB = b.replace(/^v/, "");

  const partsA = cleanA.split(".").map(Number);
  const partsB = cleanB.split(".").map(Number);

  for (let i = 0; i < 3; i++) {
    const numA = partsA[i] || 0;
    const numB = partsB[i] || 0;
    if (numA > numB) return 1;
    if (numA < numB) return -1;
  }
  return 0;
}

/**
 * Send a native desktop notification (non-blocking, fire-and-forget)
 */
export async function sendDesktopNotification(title: string, message: string): Promise<void> {
  const platform = getPlatform();

  try {
    if (platform === "darwin") {
      // macOS: Use osascript for native notifications
      await $`osascript -e ${"display notification \"" + message + "\" with title \"" + title + "\""}`.quiet().nothrow();
    } else if (platform === "linux") {
      // Linux: Use notify-send if available
      await $`notify-send ${title} ${message}`.quiet().nothrow();
    }
  } catch {
    // Ignore notification errors - non-critical
  }
}

/**
 * Print update notification banner
 */
export function notifyUpdateAvailable(
  currentVersion: string,
  latestVersion: string,
  releaseUrl: string
): void {
  console.log(); // blank line separator
  console.log(`${COLORS.bgYellow}${COLORS.black}${COLORS.bold} UPDATE AVAILABLE ${COLORS.reset}`);
  console.log(`  Current: ${COLORS.gray}v${currentVersion}${COLORS.reset}`);
  console.log(`  Latest:  ${COLORS.green}v${latestVersion}${COLORS.reset}`);
  console.log();
  console.log(`  Run ${COLORS.cyan}paw update${COLORS.reset} or visit:`);
  console.log(`  ${COLORS.underline}${releaseUrl}${COLORS.reset}`);
  console.log();
}

/**
 * Main entry point: Check for updates and notify if available
 * Should be called at the end of main() after command execution
 */
export async function checkForUpdatesAndNotify(currentVersion: string): Promise<void> {
  // Check opt-out environment variable
  if (process.env.PAW_NO_UPDATE_CHECK === "1") {
    return;
  }

  // Load existing state
  const state = await loadUpdateState();

  // Check if we should perform a network request
  if (!shouldCheckForUpdates(state)) {
    // Use cached version if available and newer
    if (state && compareVersions(state.latestVersion, currentVersion) > 0) {
      notifyUpdateAvailable(
        currentVersion,
        state.latestVersion,
        `https://github.com/alexcatdad/dotfiles/releases/tag/v${state.latestVersion}`
      );
    }
    return;
  }

  // Fetch latest version from GitHub
  const release = await getLatestVersion();
  if (!release) return; // Network error, fail silently

  const latestVersion = release.tag_name.replace(/^v/, "");

  // Save new state
  await saveUpdateState({
    lastCheck: new Date().toISOString(),
    latestVersion,
    currentVersion,
  });

  // Notify if update available
  if (compareVersions(latestVersion, currentVersion) > 0) {
    notifyUpdateAvailable(currentVersion, latestVersion, release.html_url);
  }
}

/**
 * Silent background check with desktop notification
 * Used by shell hook for terminal startup checks
 */
export async function checkForUpdatesSilent(currentVersion: string): Promise<void> {
  // Check opt-out environment variable
  if (process.env.PAW_NO_UPDATE_CHECK === "1") {
    return;
  }

  // Load existing state
  const state = await loadUpdateState();

  // Check if we should perform a network request
  if (!shouldCheckForUpdates(state)) {
    // Use cached version if newer - send desktop notification
    if (state && compareVersions(state.latestVersion, currentVersion) > 0) {
      await sendDesktopNotification(
        "paw update available",
        `v${state.latestVersion} is available. Run 'paw update' to upgrade.`
      );
    }
    return;
  }

  // Fetch latest version from GitHub
  const release = await getLatestVersion();
  if (!release) return; // Network error, fail silently

  const latestVersion = release.tag_name.replace(/^v/, "");

  // Save new state
  await saveUpdateState({
    lastCheck: new Date().toISOString(),
    latestVersion,
    currentVersion,
  });

  // Send desktop notification if update available
  if (compareVersions(latestVersion, currentVersion) > 0) {
    await sendDesktopNotification(
      "paw update available",
      `v${latestVersion} is available. Run 'paw update' to upgrade.`
    );
  }
}
