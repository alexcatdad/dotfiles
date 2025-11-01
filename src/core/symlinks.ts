import { symlink, mkdir, readlink, lstat, unlink, writeFile, stat } from "fs/promises";
import { readFileSync } from "fs";
import { join, dirname } from "path";
import { existsSync } from "fs";
import { logger } from "../utils/logger.js";
import { expandPath } from "./platform.js";
import { getProjectRoot } from "../config/loader.js";
import type { SymlinkConfig } from "../config/schema.js";
import { execSync } from "child_process";

export async function createSymlink(source: string, target: string, force: boolean): Promise<boolean> {
  const sourcePath = join(getProjectRoot(), source);
  const targetPath = expandPath(target);

  // Ensure source exists
  if (!existsSync(sourcePath)) {
    logger.warn(`Source file does not exist: ${sourcePath}`);
    return false;
  }

  try {
    // Check if target already exists
    if (existsSync(targetPath)) {
      const stats = await lstat(targetPath);
      if (stats.isSymbolicLink()) {
        const currentTarget = await readlink(targetPath);
        const resolvedSource = join(getProjectRoot(), source);
        if (currentTarget === resolvedSource || currentTarget === source) {
          logger.info(`Symlink already correct: ${targetPath}`);
          return true;
        }
        // Existing symlink points to different location - check if it's managed by dotfiles
        if (currentTarget.includes(getProjectRoot())) {
          // This is another dotfiles managed symlink, safe to replace
          if (force) {
            logger.info(`Updating dotfiles symlink: ${targetPath}`);
            await unlink(targetPath);
          } else {
            logger.warn(`Target is a dotfiles symlink but points elsewhere: ${targetPath}`);
            return false;
          }
        } else {
          // This is NOT managed by dotfiles - DO NOT overwrite
          logger.warn(`Target exists but is NOT managed by dotfiles: ${targetPath}`);
          logger.warn(`Current target: ${currentTarget}`);
          logger.warn(`Skipping to avoid overwriting user/application managed configuration`);
          return false;
        }
      } else {
        // Target exists as a regular file - analyze if we should overwrite
        if (force) {
          // Check if this looks like an application-generated file
          const isApplicationManaged = await isApplicationGeneratedFile(targetPath, stats);
          if (isApplicationManaged) {
            logger.warn(`Target appears to be application-managed: ${targetPath}`);
            logger.warn(`Skipping to avoid overwriting application configuration`);
            return false;
          }

          logger.warn(`Target exists as regular file, backing up: ${targetPath}`);
          const backupPath = `${targetPath}.backup.${Date.now()}`;
          await writeFile(backupPath, readFileSync(targetPath));
          await unlink(targetPath);
        } else {
          logger.warn(`Target exists but is not a symlink: ${targetPath}`);
          return false;
        }
      }
    }

    // Create parent directories
    const targetDir = dirname(targetPath);
    if (!existsSync(targetDir)) {
      await mkdir(targetDir, { recursive: true });
    }

    // Create symlink
    const sourceAbsolute = join(getProjectRoot(), source);
    await symlink(sourceAbsolute, targetPath);
    logger.success(`Created symlink: ${targetPath} -> ${sourceAbsolute}`);
    return true;
  } catch (error) {
    logger.error(`Failed to create symlink ${targetPath}: ${error}`);
    return false;
  }
}

async function isApplicationGeneratedFile(filePath: string, stats: any): Promise<boolean> {
  // Check recent modification time - if very recent, likely application-generated
  const oneHourAgo = Date.now() - 60 * 60 * 1000;
  const fileModTime = stats.mtimeMs;

  if (fileModTime > oneHourAgo) {
    logger.debug(`File ${filePath} was recently modified (${Math.round((Date.now() - fileModTime) / 1000)}s ago)`);
    // Could be application-generated, be cautious
    return true;
  }

  // Check if file is in a .config directory
  if (filePath.includes('/.config/')) {
    logger.debug(`File ${filePath} is in .config directory`);
    return true;
  }

  return false;
}

export async function createDirectory(path: string): Promise<boolean> {
  const dirPath = expandPath(path);

  try {
    if (existsSync(dirPath)) {
      logger.info(`Directory already exists: ${dirPath}`);
      return true;
    }
    await mkdir(dirPath, { recursive: true });
    logger.success(`Created directory: ${dirPath}`);
    return true;
  } catch (error) {
    logger.error(`Failed to create directory ${dirPath}: ${error}`);
    return false;
  }
}

export async function executeShellCommand(cmd: string, description: string): Promise<boolean> {
  try {
    logger.info(`Running: ${description}`);
    execSync(cmd, { stdio: "inherit" });
    logger.success(`Completed: ${description}`);
    return true;
  } catch (error) {
    logger.error(`Failed to execute: ${description} - ${error}`);
    return false;
  }
}

export async function installSymlinks(config: SymlinkConfig): Promise<void> {
  logger.info("Installing symlinks...");

  // Create directories first
  for (const dir of config.directories) {
    await createDirectory(dir);
  }

  // Create symlinks
  let successCount = 0;
  let failCount = 0;

  for (const [target, source] of Object.entries(config.links)) {
    const success = await createSymlink(source, target, config.defaults.force);
    if (success) {
      successCount++;
    } else {
      failCount++;
    }
  }

  // Execute shell commands
  for (const cmd of config.shell_commands) {
    await executeShellCommand(cmd.command, cmd.description);
  }

  logger.info(`Symlinks: ${successCount} created, ${failCount} failed`);
}


