import { Command } from "commander";
import { execSync } from "child_process";
import { logger } from "../utils/logger.js";
import { getPlatformInfo } from "../core/platform.js";

export const syncCommand = new Command("sync")
  .description("Update all tools and sync dotfiles")
  .action(async () => {
    logger.info("Syncing dotfiles settings...");

    const platform = getPlatformInfo();

    // Update system packages
    if (platform.os === "macos") {
      logger.info("Updating Homebrew packages...");
      try {
        execSync("brew update && brew upgrade", { stdio: "inherit" });
      } catch (error) {
        logger.warn("Failed to update Homebrew packages");
      }
    } else if (platform.os === "ubuntu") {
      logger.info("Updating APT packages...");
      try {
        execSync("sudo apt update && sudo apt upgrade -y", { stdio: "inherit" });
      } catch (error) {
        logger.warn("Failed to update APT packages");
      }
    }

    // Update Node.js if using NVM
    try {
      execSync("nvm install --lts --reinstall-packages-from=current", { stdio: "inherit" });
      execSync("nvm alias default lts/*", { stdio: "inherit" });
    } catch (error) {
      logger.debug("NVM update skipped (may not be installed)");
    }

    // Update global npm packages
    try {
      logger.info("Updating global npm packages...");
      execSync("npm update -g", { stdio: "inherit" });
    } catch (error) {
      logger.warn("Failed to update npm packages");
    }

    // Update Bun if available
    try {
      logger.info("Updating Bun...");
      execSync("bun upgrade", { stdio: "inherit" });
    } catch (error) {
      logger.debug("Bun update skipped (may not be installed)");
    }

    logger.success("Sync completed!");
    logger.info("Run 'source ~/.zshrc' to apply any shell changes");
  });


