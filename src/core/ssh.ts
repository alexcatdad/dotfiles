/**
 * SSH Config Migration
 * Handles safe migration of existing SSH config to the local override file
 */

import { readFile, writeFile, stat, lstat } from "node:fs/promises";
import { resolve } from "node:path";
import { getHomeDir, contractPath } from "./os";
import { logger } from "./logger";

const SSH_CONFIG_PATH = ".ssh/config";
const SSH_CONFIG_LOCAL_PATH = ".ssh/config.local";

/**
 * Check if a file exists and is not a symlink
 */
async function isRegularFile(path: string): Promise<boolean> {
  try {
    const stats = await lstat(path);
    return stats.isFile() && !stats.isSymbolicLink();
  } catch {
    return false;
  }
}

/**
 * Extract Host blocks and custom settings from SSH config
 * Returns content that should be preserved in config.local
 */
function extractCustomContent(content: string): string {
  const lines = content.split("\n");
  const customLines: string[] = [];
  let inHostBlock = false;
  let currentBlock: string[] = [];

  // Settings that are already in our base config (skip these)
  const baseSettings = new Set([
    "addkeystoagent",
    "usekeychain",
    "identitiesonly",
    "serveraliveinterval",
    "serveralivecountmax",
    "controlmaster",
    "controlpath",
    "controlpersist",
  ]);

  for (const line of lines) {
    const trimmed = line.trim().toLowerCase();

    // Check for Host block start
    if (trimmed.startsWith("host ") && trimmed !== "host *") {
      // Save previous block if any
      if (currentBlock.length > 0) {
        customLines.push(...currentBlock, "");
        currentBlock = [];
      }
      inHostBlock = true;
      currentBlock.push(line);
      continue;
    }

    // Check for Include directive (preserve these)
    if (trimmed.startsWith("include ") && !trimmed.includes("config.local")) {
      customLines.push(line);
      continue;
    }

    // Inside a Host block - collect all lines
    if (inHostBlock) {
      // New Host block or Host * ends current block
      if (trimmed.startsWith("host ")) {
        if (currentBlock.length > 0) {
          customLines.push(...currentBlock, "");
        }
        currentBlock = [];
        if (trimmed === "host *") {
          inHostBlock = false;
        } else {
          currentBlock.push(line);
        }
      } else if (trimmed === "" || trimmed.startsWith("#")) {
        // Empty line or comment might end block or be part of it
        if (trimmed === "" && currentBlock.length > 0) {
          customLines.push(...currentBlock, "");
          currentBlock = [];
          inHostBlock = false;
        } else {
          currentBlock.push(line);
        }
      } else {
        currentBlock.push(line);
      }
    }
  }

  // Don't forget the last block
  if (currentBlock.length > 0) {
    customLines.push(...currentBlock);
  }

  return customLines.join("\n").trim();
}

/**
 * Migrate existing SSH config to config.local
 * Returns true if migration was performed
 */
export async function migrateSSHConfig(options: { dryRun?: boolean }): Promise<boolean> {
  const homeDir = getHomeDir();
  const sshConfigPath = resolve(homeDir, SSH_CONFIG_PATH);
  const sshConfigLocalPath = resolve(homeDir, SSH_CONFIG_LOCAL_PATH);

  // Check if SSH config exists and is a regular file (not already a symlink)
  if (!await isRegularFile(sshConfigPath)) {
    return false;
  }

  // Read existing config
  let existingContent: string;
  try {
    existingContent = await readFile(sshConfigPath, "utf-8");
  } catch {
    return false;
  }

  // Extract custom content (Host blocks, Include directives)
  const customContent = extractCustomContent(existingContent);

  if (!customContent) {
    logger.info("No custom SSH hosts found to migrate");
    return false;
  }

  // Check if config.local already exists
  let localContent = "";
  try {
    localContent = await readFile(sshConfigLocalPath, "utf-8");
  } catch {
    // File doesn't exist, that's fine
  }

  // Check if we already migrated (avoid duplicates)
  if (localContent.includes("# Migrated from existing config")) {
    logger.skip("SSH hosts already migrated to config.local");
    return false;
  }

  // Build new config.local content
  const timestamp = new Date().toISOString().split("T")[0];
  const migrationHeader = `# ─────────────────────────────────────────────────────────────────────────────
# Migrated from existing config on ${timestamp}
# ─────────────────────────────────────────────────────────────────────────────`;

  let newLocalContent: string;
  if (localContent.trim()) {
    // Append to existing
    newLocalContent = `${localContent.trimEnd()}\n\n${migrationHeader}\n${customContent}\n`;
  } else {
    // Create new file with header
    newLocalContent = `# ══════════════════════════════════════════════════════════════════════════════
# SSH Configuration - Local/Machine-Specific
# ══════════════════════════════════════════════════════════════════════════════
# This file is gitignored. Add your personal/work hosts here.

${migrationHeader}
${customContent}
`;
  }

  if (options.dryRun) {
    logger.dryRun(`Would migrate SSH hosts to ${contractPath(sshConfigLocalPath)}`);
    logger.info("Hosts to migrate:");
    // Extract just host names for display
    const hostMatches = customContent.match(/^Host\s+(.+)$/gm);
    if (hostMatches) {
      hostMatches.forEach(h => logger.info(`  - ${h.replace(/^Host\s+/, "")}`));
    }
    return true;
  }

  // Write the migrated config
  await writeFile(sshConfigLocalPath, newLocalContent);

  logger.success(`Migrated SSH hosts to ${contractPath(sshConfigLocalPath)}`);

  // Log what was migrated
  const hostMatches = customContent.match(/^Host\s+(.+)$/gm);
  if (hostMatches) {
    logger.info("Migrated hosts:");
    hostMatches.forEach(h => logger.info(`  - ${h.replace(/^Host\s+/, "")}`));
  }

  return true;
}
