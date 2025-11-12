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
  .option("--dry-run", "Show what would be done without making changes")
  .action(async (options) => {
    if (options.dryRun) {
      logger.info("🔍 DRY RUN MODE - No changes will be made");
      logger.info("Bootstrapping development environment...");
      logger.info("This will set up your complete TypeScript development environment");
    } else {
      logger.info("Bootstrapping development environment...");
      logger.info("This will set up your complete TypeScript development environment");
    }

    const platform = getPlatformInfo();
    logger.info(`Detected: ${platform.os}`);

    // Confirm before proceeding (skip in dry-run)
    if (!options.dryRun) {
      const proceed = await confirm("Continue with bootstrap?", false);
      if (!proceed) {
        logger.info("Bootstrap cancelled");
        process.exit(0);
      }
    }

    const config = loadConfig();
    const pm = new PackageManager();

    if (options.dryRun) {
      logger.info("\n[DRY RUN] Would check dependencies...");
      
      // Show what packages would be installed
      logger.info("\n[DRY RUN] Would install core development packages:");
      const devCategory = config.categories.development;
      if (devCategory) {
        for (const pkg of devCategory.packages) {
          if (pkg.required) {
            const platformPkg = platform.os === "macos" ? pkg.macos : pkg.ubuntu;
            if (platformPkg && platformPkg !== "null") {
              logger.info(`  - ${pkg.name} (${platformPkg})`);
            }
          }
        }
      }
    } else {
      // Check and install dependencies
      logger.info("Checking dependencies...");
      const depsOk = await checkAllDependencies(false);
      if (!depsOk) {
        logger.error("Required dependencies are missing. Please install them and try again.");
        process.exit(1);
      }

      // Install system packages
      logger.info("Installing core development packages...");

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
    }

    // Setup Oh My Zsh plugins
    if (options.dryRun) {
      logger.info("\n[DRY RUN] Would set up Zsh plugins:");
      const plugins = [
        "zsh-users/zsh-autosuggestions",
        "zsh-users/zsh-syntax-highlighting",
        "zsh-users/zsh-completions",
      ];
      for (const plugin of plugins) {
        logger.info(`  - ${plugin}`);
      }
      logger.info("  - powerlevel10k theme");
    } else {
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
    }

    // Install NVM and Node.js
    if (options.dryRun) {
      logger.info("\n[DRY RUN] Would install NVM and Node.js LTS");
      
      // Show what symlinks would be created
      logger.info("\n[DRY RUN] Would create symlinks:");
      for (const [target] of Object.entries(config.symlinks.links)) {
        logger.info(`  - ${target}`);
      }
      
      logger.info("\n[DRY RUN] Would configure Git:");
      logger.info("  - Set core.excludesfile to ~/.gitignore_global");
      logger.info("  - Prompt for user.name and user.email if not set");
      
      logger.info("\n[DRY RUN] Bootstrap preview complete!");
      logger.info("Run without --dry-run to actually perform these actions.");
    } else {
      logger.info("Installing NVM and Node.js...");
      const nvmDir = join(getHomeDir(), ".nvm");
      try {
        if (!existsSync(nvmDir)) {
          execSync("curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash", {
            stdio: "inherit",
          });
          logger.success("NVM installed");
        }
        
        // Source NVM and install Node.js LTS
        const nvmPath = join(nvmDir, "nvm.sh");
        if (existsSync(nvmPath)) {
          try {
            // Load NVM in this process
            execSync(`source ${nvmPath} && nvm install --lts && nvm alias default lts/*`, {
              shell: "/bin/bash",
              stdio: "inherit",
            });
            logger.success("Node.js LTS installed via NVM");
          } catch (error) {
            logger.warn("Node.js installation via NVM may require a new terminal session. Run: nvm install --lts");
          }
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
    }
  });


