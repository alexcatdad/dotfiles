import { Command } from "commander";
import { execSync } from "child_process";
import { logger } from "../utils/logger.js";
import { loadConfig } from "../config/loader.js";
import { installSymlinks } from "../core/symlinks.js";
import { checkAllDependencies } from "../core/dependencies.js";
import { confirm, input } from "../utils/prompt.js";
import { getPlatformInfo, getHomeDir } from "../core/platform.js";
import { join } from "path";
import { existsSync } from "fs";
import { PackageManager } from "../core/package-manager.js";

export const bootstrapCommand = new Command("bootstrap")
  .description("Complete development environment bootstrap for new machines")
  .action(async () => {
    logger.info("Bootstrapping development environment...");
    logger.info("This will set up your complete TypeScript development environment");

    const platform = getPlatformInfo();
    logger.info(`Detected: ${platform.os}`);

    // Confirm before proceeding
    const proceed = await confirm("Continue with bootstrap?", false);
    if (!proceed) {
      logger.info("Bootstrap cancelled");
      process.exit(0);
    }

    // Check and install dependencies
    logger.info("Checking dependencies...");
    const depsOk = await checkAllDependencies(false);
    if (!depsOk) {
      logger.error("Required dependencies are missing. Please install them and try again.");
      process.exit(1);
    }

    // Install system packages
    logger.info("Installing core development packages...");
    const pm = new PackageManager();
    const config = loadConfig();

    // Install packages from development category
    const devCategory = config.categories.development;
    if (devCategory) {
      for (const pkg of devCategory.packages) {
        if (pkg.required) {
          await pm.installPackage(pkg);
        }
      }
    }

    // Install TypeScript packages
    const tsCategory = config.categories.typescript;
    if (tsCategory) {
      for (const pkg of tsCategory.packages) {
        if (pkg.required) {
          await pm.installPackage(pkg);
          if (pkg.global_npm) {
            await pm.installNpmPackage(pkg);
          }
        }
      }
    }

    // Setup Oh My Zsh plugins
    logger.info("Setting up Zsh plugins...");
    const zshCustom = join(getHomeDir(), ".oh-my-zsh/custom");
    const plugins = [
      "zsh-users/zsh-autosuggestions",
      "zsh-users/zsh-syntax-highlighting",
      "zsh-users/zsh-completions",
    ];

    for (const plugin of plugins) {
      const pluginName = plugin.split("/").pop();
      const pluginPath = join(zshCustom, "plugins", pluginName!);
      try {
        execSync(`git clone https://github.com/${plugin}.git "${pluginPath}"`, { stdio: "ignore" });
        logger.success(`Installed ${pluginName}`);
      } catch {
        logger.debug(`${pluginName} may already be installed`);
      }
    }

    // Install Powerlevel10k theme
    const themePath = join(zshCustom, "themes/powerlevel10k");
    try {
      execSync(`git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${themePath}"`, { stdio: "ignore" });
      logger.success("Installed Powerlevel10k theme");
    } catch {
      logger.debug("Powerlevel10k may already be installed");
    }

    // Install NVM and Node.js
    logger.info("Installing NVM and Node.js...");
    const nvmDir = join(getHomeDir(), ".nvm");
    try {
      if (!existsSync(nvmDir)) {
        execSync("curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash", {
          stdio: "inherit",
        });
        logger.success("NVM installed");
      }
    } catch (error) {
      logger.warn("NVM installation may have issues. You can install it manually.");
    }

    // Install dotfiles
    logger.info("Installing dotfiles...");
    await installSymlinks(config.symlinks);

    // Configure Git
    logger.info("Configuring Git...");
    try {
      execSync("git config --global core.excludesfile ~/.gitignore_global", { stdio: "inherit" });

      try {
        execSync("git config --global user.name", { encoding: "utf-8", stdio: "pipe" });
      } catch {
        const gitName = await input("Enter your name:");
        execSync(`git config --global user.name "${gitName}"`, { stdio: "inherit" });
      }

      try {
        execSync("git config --global user.email", { encoding: "utf-8", stdio: "pipe" });
      } catch {
        const gitEmail = await input("Enter your email:");
        execSync(`git config --global user.email "${gitEmail}"`, { stdio: "inherit" });
      }
    } catch (error) {
      logger.warn("Git configuration skipped");
    }

    logger.success("Bootstrap complete!");
    logger.info("Next steps:");
    logger.info("1. Restart your terminal or run: source ~/.zshrc");
    logger.info("2. Configure Powerlevel10k: p10k configure");
    logger.info("3. Start coding!");
  });


