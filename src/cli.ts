#!/usr/bin/env bun

import { Command } from "commander";
import { logger } from "./utils/logger.js";
import { checkAllDependencies } from "./core/dependencies.js";

const program = new Command();

program
  .name("dotfiles")
  .description("TypeScript-based dotfiles management CLI")
  .version("2.0.0");

program
  .command("check-deps")
  .description("Check and verify all dependencies")
  .option("--auto-install", "Automatically install missing dependencies")
  .action(async (options) => {
    try {
      await checkAllDependencies(options.autoInstall);
      process.exit(0);
    } catch (error) {
      logger.error(`Dependency check failed: ${error}`);
      process.exit(1);
    }
  });

// Import and register commands
async function registerCommands() {
  try {
    const { bootstrapCommand } = await import("./commands/bootstrap.js");
    const { installCommand } = await import("./commands/install.js");
    const { packagesCommand } = await import("./commands/packages.js");
    const { syncCommand } = await import("./commands/sync.js");
    const { backupCommand } = await import("./commands/backup.js");
    const { testCommand } = await import("./commands/test.js");

    program.addCommand(bootstrapCommand);
    program.addCommand(installCommand);
    program.addCommand(packagesCommand);
    program.addCommand(syncCommand);
    program.addCommand(backupCommand);
    program.addCommand(testCommand);
  } catch (error) {
    logger.error(`Failed to load commands: ${error}`);
    throw error;
  }
}

async function main() {
  await registerCommands();

  program.parse();
}

if (import.meta.main) {
  main().catch((error) => {
    logger.error(`Fatal error: ${error}`);
    process.exit(1);
  });
}

export { program };


