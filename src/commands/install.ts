import { Command } from "commander";
import { existsSync } from "fs";
import { logger } from "../utils/logger.js";
import { loadConfig } from "../config/loader.js";
import { installSymlinks } from "../core/symlinks.js";
import { checkbox, confirm, input } from "../utils/prompt.js";
import { getPlatformInfo, getHomeDir, expandPath } from "../core/platform.js";
import { execSync } from "child_process";
import { join } from "path";
import { createBackup } from "./backup.js";

export const installCommand = new Command("install")
  .description("Install dotfiles (safe mode for existing systems)")
  .option("--safe", "Interactive installation that preserves existing configs")
  .option("--dry-run", "Show what would be installed without making changes")
  .action(async (options) => {
    const config = loadConfig();
    const platform = getPlatformInfo();

    if (options.dryRun) {
      logger.info("🔍 DRY RUN MODE - No changes will be made");
      
      // Check for existing files
      const existingConfigs: string[] = [];
      for (const target of Object.keys(config.symlinks.links)) {
        const targetPath = expandPath(target);
        if (existsSync(targetPath)) {
          existingConfigs.push(targetPath);
        }
      }
      
      if (existingConfigs.length > 0) {
        logger.info("\n[DRY RUN] Would backup existing files:");
        for (const filePath of existingConfigs) {
          const fileName = filePath.split("/").pop() || "unknown";
          logger.info(`  - ${fileName}`);
        }
      }
      
      logger.info("\n[DRY RUN] Would create symlinks:");
      for (const [target, source] of Object.entries(config.symlinks.links)) {
        logger.info(`  ${target} -> ${source}`);
      }
      logger.info("\n[DRY RUN] Would run shell commands:");
      for (const cmd of config.symlinks.shell_commands) {
        logger.info(`  - ${cmd.description}: ${cmd.command}`);
      }
      logger.info("\n[DRY RUN] Installation preview complete!");
      logger.info("Run without --dry-run to actually perform these actions.");
      return;
    }

    if (options.safe) {
      logger.info("Safe installation mode - preserving existing configurations");

      // Check existing configs
      const existingConfigs: string[] = [];
      for (const target of Object.keys(config.symlinks.links)) {
        const targetPath = target.replace("~", getHomeDir());
        if (existsSync(targetPath)) {
          existingConfigs.push(target);
        }
      }

      if (existingConfigs.length > 0) {
        logger.warn(`Found ${existingConfigs.length} existing configurations`);
        logger.info("Backing up existing files before installation...");
        const filesToBackup = existingConfigs.map(target => expandPath(target));
        await createBackup(filesToBackup);
      }

      // Interactive selection
      const installShell = await confirm("Install shell configuration (.zshrc, aliases)?", true);
      const installGit = await confirm("Install git configuration (.gitconfig)?", true);
      const installDev = await confirm("Install development tools (npm, tmux configs)?", false);

      // Create selective symlink config
      const selectedLinks: Record<string, string> = {};

      if (installShell) {
        Object.entries(config.symlinks.links).forEach(([target, source]) => {
          if (
            target.includes(".zshrc") ||
            target.includes(".aliases") ||
            target.includes(".modern-aliases") ||
            target.includes(".dev-automations") ||
            target.includes(".env-detection") ||
            target.includes(".project-templates")
          ) {
            selectedLinks[target] = source;
          }
        });
      }

      if (installGit) {
        Object.entries(config.symlinks.links).forEach(([target, source]) => {
          if (target.includes(".gitconfig") || target.includes(".gitignore")) {
            selectedLinks[target] = source;
          }
        });
      }

      if (installDev) {
        Object.entries(config.symlinks.links).forEach(([target, source]) => {
          if (target.includes(".npmrc") || target.includes(".tmux") || target.includes(".vimrc") || target.includes("micro")) {
            selectedLinks[target] = source;
          }
        });
      }

      // Install selective symlinks
      const selectiveConfig = {
        ...config.symlinks,
        links: selectedLinks,
      };

      await installSymlinks(selectiveConfig);

      // Configure Git if needed
      if (installGit) {
        try {
          execSync("git config --global core.excludesfile ~/.gitignore_global", { stdio: "inherit" });
        } catch {}

        try {
          execSync("git config --global user.name", { encoding: "utf-8", stdio: "pipe" });
        } catch {
          const gitName = await input("Enter your Git user name:");
          execSync(`git config --global user.name "${gitName}"`, { stdio: "inherit" });
        }

        try {
          execSync("git config --global user.email", { encoding: "utf-8", stdio: "pipe" });
        } catch {
          const gitEmail = await input("Enter your Git email:");
          execSync(`git config --global user.email "${gitEmail}"`, { stdio: "inherit" });
        }
      }

      logger.success("Safe installation complete!");
    } else {
      // Full installation
      // Check for existing files and backup them
      const existingConfigs: string[] = [];
      for (const target of Object.keys(config.symlinks.links)) {
        const targetPath = expandPath(target);
        if (existsSync(targetPath)) {
          existingConfigs.push(targetPath);
        }
      }

      if (existingConfigs.length > 0) {
        logger.warn(`Found ${existingConfigs.length} existing configurations`);
        logger.info("Backing up existing files before installation...");
        await createBackup(existingConfigs);
      }

      logger.info("Installing all dotfiles...");
      await installSymlinks(config.symlinks);

      // Execute shell commands
      for (const cmd of config.symlinks.shell_commands) {
        try {
          execSync(cmd.command, { stdio: "inherit" });
        } catch (error) {
          logger.warn(`Failed to execute: ${cmd.description}`);
        }
      }

      logger.success("Installation complete!");
    }
  });


