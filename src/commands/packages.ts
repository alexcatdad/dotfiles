import { Command } from "commander";
import { execSync } from "child_process";
import { existsSync } from "fs";
import { join } from "path";
import { logger } from "../utils/logger.js";
import { loadConfig } from "../config/loader.js";
import { PackageManager, installNodeViaNVM, installNVM, installOhMyZsh } from "../core/package-manager.js";
import { getPlatformInfo, getHomeDir } from "../core/platform.js";
import { checkbox } from "../utils/prompt.js";
import type { PackageDefinition, Category } from "../config/schema.js";

export const packagesCommand = new Command("packages")
  .description("Install packages from specified categories")
  .option("--optional", "Include optional packages")
  .option("--dry-run", "Show what would be installed without installing")
  .option("--list", "List all available package categories")
  .argument("[categories...]", "Package categories to install")
  .action(async (categories: string[], options) => {
    const config = loadConfig();
    const platform = getPlatformInfo();

    // List categories if --list flag is set
    if (options.list) {
      logger.info("Available package categories:");
      logger.info(`Package manager: ${platform.packageManager === "brew" ? "Homebrew" : platform.packageManager === "apt" ? "APT" : "Unknown"} (${platform.os})`);
      logger.info("");
      
      for (const [categoryName, category] of Object.entries(config.categories)) {
        const packageCount = category.packages.length;
        const requiredCount = category.packages.filter(p => p.required !== false).length;
        const optionalCount = packageCount - requiredCount;
        
        let categoryInfo = `  ${categoryName.padEnd(20)} - ${category.description}`;
        categoryInfo += ` (${packageCount} packages`;
        if (optionalCount > 0) {
          categoryInfo += `, ${optionalCount} optional`;
        }
        categoryInfo += ")";
        
        if (category.condition === "desktop_environment" && !platform.hasDesktop) {
          categoryInfo += " [requires desktop environment]";
        }
        
        logger.info(categoryInfo);
        
        // List packages in this category
        for (const pkg of category.packages) {
          let packageInfo = `    • ${pkg.name}`;
          
          // Special handling for NVM - installed via script
          if (pkg.name === "nvm") {
            packageInfo += " [installed via NVM script]";
          }
          // Special handling for Oh My Zsh - installed via installer script
          else if (pkg.name === "oh-my-zsh") {
            packageInfo += " [installed via Oh My Zsh installer]";
          }
          // Special handling for Node.js - installed via NVM
          else if (pkg.name === "node") {
            packageInfo += " [installed via NVM]";
          }
          // Mark Homebrew casks
          else if (pkg.cask) {
            packageInfo += " [Homebrew cask]";
          }
          // Show platform-specific package names if different
          else if (pkg.platform_specific) {
            const platformPkg = platform.os === "macos" ? pkg.macos : pkg.ubuntu;
            if (platformPkg && platformPkg !== pkg.name) {
              packageInfo += ` (${platformPkg} on ${platform.os})`;
            }
          }
          // Show package manager package name if available and different from name
          else if (pkg.macos || pkg.ubuntu) {
            const platformPkg = platform.os === "macos" ? pkg.macos : pkg.ubuntu;
            if (platformPkg && platformPkg !== pkg.name) {
              packageInfo += ` (${platformPkg})`;
            }
          }
          
          // Show npm package if present
          if (pkg.global_npm) {
            packageInfo += ` [npm: ${pkg.global_npm}]`;
          }
          
          // Mark optional packages
          if (pkg.optional) {
            packageInfo += " (optional)";
          }
          
          // Show description if available
          if (pkg.description) {
            packageInfo += ` - ${pkg.description}`;
          }
          
          logger.info(packageInfo);
        }
        
        logger.info("");
      }
      
      logger.info("Usage examples:");
      logger.info("  ./dotfiles packages --dry-run development  # Preview packages in a category");
      logger.info("  ./dotfiles packages development typescript  # Install packages from categories");
      logger.info("  ./dotfiles packages --optional modern_cli   # Include optional packages");
      
      process.exit(0);
    }

    const pm = new PackageManager();

    // Determine which categories to process
    let categoriesToProcess: string[] = categories;

    if (categoriesToProcess.length === 0) {
      // Default categories
      categoriesToProcess = ["development", "typescript", "modern_cli", "developer_tools", "docker", "productivity"];
      if (platform.hasDesktop) {
        categoriesToProcess.push("gui_applications");
      }
    }

    logger.info(`Processing categories: ${categoriesToProcess.join(", ")}`);

    let totalPackages = 0;
    let installedPackages = 0;
    let failedPackages = 0;
    let skippedPackages = 0;

    for (const categoryName of categoriesToProcess) {
      const category = config.categories[categoryName];
      if (!category) {
        logger.warn(`Category '${categoryName}' not found, skipping`);
        continue;
      }

      // Check condition
      if (category.condition === "desktop_environment" && !platform.hasDesktop) {
        logger.warn(`Skipping category '${categoryName}' - requires desktop environment`);
        continue;
      }

      logger.info(`Processing category: ${categoryName} - ${category.description}`);

      // Collect packages for batch installation
      const brewFormulae: PackageDefinition[] = [];
      const brewCasks: PackageDefinition[] = [];
      const aptPackages: PackageDefinition[] = [];
      const npmPackages: PackageDefinition[] = [];
      const specialPackages: PackageDefinition[] = [];

      for (const pkg of category.packages) {
        totalPackages++;

        // Skip optional packages if flag not set
        if (pkg.optional && !options.optional) {
          logger.info(`Skipping optional package: ${pkg.name}`);
          skippedPackages++;
          continue;
        }

        // Check platform compatibility
        if (pkg.platform_specific) {
          const platformPkg = platform.os === "macos" ? pkg.macos : pkg.ubuntu;
          if (!platformPkg || platformPkg === "null") {
            logger.warn(`Package ${pkg.name} not available for ${platform.os}, skipping`);
            skippedPackages++;
            continue;
          }
        }

        if (options.dryRun) {
          logger.info(`[DRY RUN] Would install: ${pkg.name}`);
          installedPackages++;
          continue;
        }

        // Special handling for NVM, Node.js, and Oh My Zsh - install separately
        if (pkg.name === "nvm" || pkg.name === "node" || pkg.name === "oh-my-zsh") {
          specialPackages.push(pkg);
          continue;
        }

        // Collect package names for batch installation
        if (platform.os === "macos" && pkg.macos && pkg.macos !== "null") {
          if (pkg.cask) {
            brewCasks.push(pkg);
          } else {
            brewFormulae.push(pkg);
          }
        } else if (platform.os === "ubuntu" && pkg.ubuntu && pkg.ubuntu !== "null") {
          aptPackages.push(pkg);
        }

        // Collect npm packages for batch installation
        if (pkg.global_npm) {
          npmPackages.push(pkg);
        }
      }

      // Batch install Homebrew formulae
      if (brewFormulae.length > 0 && !options.dryRun) {
        const packageNames = brewFormulae.map(p => p.macos!).filter(Boolean);
        logger.info(`Installing ${packageNames.length} Homebrew formulae...`);
        const result = await pm.installBatch(packageNames, false);
        if (result.success) {
          installedPackages += packageNames.length;
          // Run post-install commands for successfully installed packages
          for (const pkg of brewFormulae) {
            if (pkg.post_install && pkg.post_install.length > 0) {
              await pm.runPostInstall(pkg.post_install);
            }
          }
        } else {
          failedPackages += packageNames.length;
          logger.error(`Failed to install Homebrew formulae: ${result.error}`);
        }
      }

      // Batch install Homebrew casks
      if (brewCasks.length > 0 && !options.dryRun) {
        const packageNames = brewCasks.map(p => p.macos!).filter(Boolean);
        logger.info(`Installing ${packageNames.length} Homebrew casks...`);
        const result = await pm.installBatch(packageNames, true);
        if (result.success) {
          installedPackages += packageNames.length;
          // Run post-install commands for casks
          for (const pkg of brewCasks) {
            if (pkg.post_install && pkg.post_install.length > 0) {
              await pm.runPostInstall(pkg.post_install);
            }
          }
        } else {
          failedPackages += packageNames.length;
          logger.error(`Failed to install Homebrew casks: ${result.error}`);
        }
      }

      // Batch install APT packages
      if (aptPackages.length > 0 && !options.dryRun) {
        const packageNames = aptPackages.map(p => p.ubuntu!).filter(Boolean);
        logger.info(`Installing ${packageNames.length} APT packages...`);
        const result = await pm.installBatch(packageNames, false);
        if (result.success) {
          installedPackages += packageNames.length;
          // Run post-install commands
          for (const pkg of aptPackages) {
            if (pkg.post_install && pkg.post_install.length > 0) {
              await pm.runPostInstall(pkg.post_install);
            }
          }
        } else {
          failedPackages += packageNames.length;
          logger.error(`Failed to install APT packages: ${result.error}`);
        }
      }

      // Install special packages (NVM, Node.js, Oh My Zsh) one by one
      for (const pkg of specialPackages) {
        if (pkg.name === "nvm") {
          const result = await installNVM();
          if (result.success) {
            installedPackages++;
          } else {
            failedPackages++;
            logger.error(`Failed to install NVM: ${result.error}`);
          }
        } else if (pkg.name === "oh-my-zsh") {
          const result = await installOhMyZsh();
          if (result.success) {
            installedPackages++;
          } else {
            failedPackages++;
            logger.error(`Failed to install Oh My Zsh: ${result.error}`);
          }
        } else if (pkg.name === "node") {
          const result = await installNodeViaNVM();
          if (result.success) {
            installedPackages++;
            // Run post-install commands if specified
            if (pkg.post_install && pkg.post_install.length > 0) {
              const homeDir = getHomeDir();
              const nvmPath = join(homeDir, ".nvm/nvm.sh");
              if (existsSync(nvmPath)) {
                for (const cmd of pkg.post_install) {
                  try {
                    execSync(`source ${nvmPath} && ${cmd}`, {
                      shell: "/bin/bash",
                      stdio: "inherit",
                    });
                  } catch (error) {
                    logger.warn(`Post-install command failed: ${cmd}`);
                  }
                }
              }
            }
          } else {
            failedPackages++;
            logger.error(`Failed to install Node.js via NVM: ${result.error}`);
          }
        }
      }

      // Install npm packages one by one (they may have version constraints)
      for (const pkg of npmPackages) {
        const result = await pm.installNpmPackage(pkg);
        if (result.success) {
          installedPackages++;
        } else {
          failedPackages++;
          logger.error(`Failed to install npm package ${pkg.global_npm}: ${result.error}`);
        }
      }
    }

    // Summary
    logger.info("=== Installation Summary ===");
    logger.info(`Total packages: ${totalPackages}`);
    logger.info(`Installed: ${installedPackages}`);
    logger.info(`Failed: ${failedPackages}`);
    logger.info(`Skipped: ${skippedPackages}`);

    if (failedPackages > 0) {
      process.exit(1);
    }
  });


