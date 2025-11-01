import { Command } from "commander";
import { logger } from "../utils/logger.js";
import { loadConfig } from "../config/loader.js";
import { PackageManager } from "../core/package-manager.js";
import { getPlatformInfo } from "../core/platform.js";
import { checkbox } from "../utils/prompt.js";
import type { PackageDefinition, Category } from "../config/schema.js";

export const packagesCommand = new Command("packages")
  .description("Install packages from specified categories")
  .option("--optional", "Include optional packages")
  .option("--dry-run", "Show what would be installed without installing")
  .argument("[categories...]", "Package categories to install")
  .action(async (categories: string[], options) => {
    const config = loadConfig();
    const platform = getPlatformInfo();
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

        // Install system package
        if ((platform.os === "macos" && pkg.macos) || (platform.os === "ubuntu" && pkg.ubuntu)) {
          const result = await pm.installPackage(pkg);
          if (result.success) {
            installedPackages++;
            if (pkg.post_install && pkg.post_install.length > 0) {
              await pm.runPostInstall(pkg.post_install);
            }
          } else {
            failedPackages++;
            logger.error(`Failed to install ${pkg.name}: ${result.error}`);
          }
        }

        // Install npm package if specified
        if (pkg.global_npm) {
          const result = await pm.installNpmPackage(pkg);
          if (result.success) {
            installedPackages++;
          } else {
            failedPackages++;
            logger.error(`Failed to install npm package ${pkg.global_npm}: ${result.error}`);
          }
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


