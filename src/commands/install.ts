import { Command } from "commander";
import { existsSync } from "fs";
import { logger } from "../utils/logger.js";
import { loadConfig } from "../config/loader.js";
import { installSymlinks } from "../core/symlinks.js";
import { checkbox, confirm, input } from "../utils/prompt.js";
import { getPlatformInfo, getHomeDir } from "../core/platform.js";
import { execSync } from "child_process";
import { join } from "path";

export const installCommand = new Command("install")
  .description("Install dotfiles (safe mode for existing systems)")
  .option("--safe", "Interactive installation that preserves existing configs")
  .action(async (options) => {
    const config = loadConfig();
    const platform = getPlatformInfo();

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
        logger.info("These will be backed up before installation");
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


