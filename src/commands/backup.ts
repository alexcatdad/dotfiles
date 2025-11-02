import { Command } from "commander";
import { mkdir, copyFile, readdir } from "fs/promises";
import { existsSync } from "fs";
import { join } from "path";
import { logger } from "../utils/logger.js";
import { getHomeDir, expandPath } from "../core/platform.js";
import { loadConfig } from "../config/loader.js";

/**
 * Create a backup of existing configuration files
 * @param filesToBackup Array of file paths to backup
 * @param backupDir Optional backup directory (will create timestamped one if not provided)
 * @returns Path to backup directory
 */
export async function createBackup(filesToBackup: string[], backupDir?: string): Promise<string> {
  const homeDir = getHomeDir();
  if (!backupDir) {
    const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
    backupDir = join(homeDir, `.dotfiles-backup-${timestamp}`);
  }

  logger.info(`Creating backup directory: ${backupDir}`);
  await mkdir(backupDir, { recursive: true });

  logger.info(`Backing up ${filesToBackup.length} configuration files...`);

  let backupCount = 0;
  for (const filePath of filesToBackup) {
    try {
      const fileName = filePath.split("/").pop() || "unknown";
      const backupPath = join(backupDir, fileName);
      await copyFile(filePath, backupPath);
      logger.success(`Backed up: ${fileName}`);
      backupCount++;
    } catch (error) {
      logger.warn(`Failed to backup ${filePath}: ${error}`);
    }
  }

  logger.success(`Backup completed in: ${backupDir}`);
  logger.info(`Backed up ${backupCount} files`);
  logger.info(`To restore: cp ${backupDir}/* ~/`);
  
  return backupDir;
}

export const backupCommand = new Command("backup")
  .description("Backup existing configurations before installing dotfiles")
  .option("--dry-run", "Show what would be backed up without creating backup")
  .action(async (options) => {
    const config = loadConfig();
    const filesToBackup: string[] = [];

    // Collect all config files from symlinks config
    for (const target of Object.keys(config.symlinks.links)) {
      const targetPath = expandPath(target);
      if (existsSync(targetPath)) {
        filesToBackup.push(targetPath);
      }
    }

    if (options.dryRun) {
      const homeDir = getHomeDir();
      const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
      const backupDir = join(homeDir, `.dotfiles-backup-${timestamp}`);
      
      logger.info("🔍 DRY RUN MODE - No backup will be created");
      logger.info(`\n[DRY RUN] Would create backup directory: ${backupDir}`);
      logger.info(`[DRY RUN] Would backup ${filesToBackup.length} configuration files:`);
      for (const filePath of filesToBackup) {
        const fileName = filePath.split("/").pop() || "unknown";
        logger.info(`  - ${fileName} -> ${backupDir}/${fileName}`);
      }
      logger.info("\n[DRY RUN] Backup preview complete!");
      logger.info("Run without --dry-run to actually create the backup.");
      return;
    }

    await createBackup(filesToBackup);
  });


