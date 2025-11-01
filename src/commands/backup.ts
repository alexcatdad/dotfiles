import { Command } from "commander";
import { mkdir, copyFile, readdir } from "fs/promises";
import { existsSync } from "fs";
import { join } from "path";
import { logger } from "../utils/logger.js";
import { getHomeDir, expandPath } from "../core/platform.js";
import { loadConfig } from "../config/loader.js";

export const backupCommand = new Command("backup")
  .description("Backup existing configurations before installing dotfiles")
  .action(async () => {
    const homeDir = getHomeDir();
    const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
    const backupDir = join(homeDir, `.dotfiles-backup-${timestamp}`);

    logger.info(`Creating backup directory: ${backupDir}`);
    await mkdir(backupDir, { recursive: true });

    const config = loadConfig();
    const filesToBackup: string[] = [];

    // Collect all config files from symlinks config
    for (const target of Object.keys(config.symlinks.links)) {
      const targetPath = expandPath(target);
      if (existsSync(targetPath)) {
        filesToBackup.push(targetPath);
      }
    }

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
  });


