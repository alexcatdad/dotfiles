import { Command } from "commander";
import { existsSync } from "fs";
import { execSync } from "child_process";
import { logger } from "../utils/logger.js";
import { loadConfig } from "../config/loader.js";
import { getHomeDir, expandPath, getPlatformInfo } from "../core/platform.js";
import { lstatSync } from "fs";

interface TestResult {
  name: string;
  passed: boolean;
  error?: string;
}

export const testCommand = new Command("test")
  .description("Run comprehensive test suite")
  .action(async () => {
    logger.info("Dotfiles Test Suite");
    logger.info("===================");

    const results: TestResult[] = [];
    const homeDir = getHomeDir();
    const config = loadConfig();

    // Test core files exist
    logger.info("Testing core dotfiles exist...");
    for (const [target] of Object.entries(config.symlinks.links)) {
      const targetPath = expandPath(target);
      const exists = existsSync(targetPath);
      results.push({
        name: `File exists: ${target}`,
        passed: exists,
        error: exists ? undefined : "File does not exist",
      });
    }

    // Test symlinks are correct
    logger.info("Testing symlinks...");
    for (const [target, source] of Object.entries(config.symlinks.links)) {
      const targetPath = expandPath(target);
      try {
        if (existsSync(targetPath)) {
          const stats = lstatSync(targetPath);
          const isSymlink = stats.isSymbolicLink();
          results.push({
            name: `Symlink correct: ${target}`,
            passed: isSymlink,
            error: isSymlink ? undefined : "Target exists but is not a symlink",
          });
        }
      } catch {}
    }

    // Test tools available
    logger.info("Testing required tools...");
    const tools = ["git", "zsh", "curl"];
    for (const tool of tools) {
      try {
        execSync(`command -v ${tool}`, { stdio: "ignore" });
        results.push({ name: `${tool} available`, passed: true });
      } catch {
        results.push({ name: `${tool} available`, passed: false, error: "Command not found" });
      }
    }

    // Test platform-specific tools
    const platform = getPlatformInfo();
    if (platform.os === "macos") {
      try {
        execSync("command -v brew", { stdio: "ignore" });
        results.push({ name: "brew available", passed: true });
      } catch {
        results.push({ name: "brew available", passed: false });
      }
    } else if (platform.os === "ubuntu") {
      try {
        execSync("command -v apt", { stdio: "ignore" });
        results.push({ name: "apt available", passed: true });
      } catch {
        results.push({ name: "apt available", passed: false });
      }
    }

    // Test Node.js setup
    logger.info("Testing Node.js setup...");
    try {
      execSync("command -v node", { stdio: "ignore" });
      results.push({ name: "node available", passed: true });
    } catch {
      results.push({ name: "node available", passed: false });
    }

    try {
      execSync("command -v npm", { stdio: "ignore" });
      results.push({ name: "npm available", passed: true });
    } catch {
      results.push({ name: "npm available", passed: false });
    }

    // Summary
    const passed = results.filter((r) => r.passed).length;
    const failed = results.filter((r) => !r.passed).length;
    const total = results.length;

    logger.info("\n=== Test Results ===");
    logger.info(`Tests run: ${total}`);
    logger.info(`Passed: ${passed}`);
    logger.info(`Failed: ${failed}`);

    if (failed > 0) {
      logger.error("\nFailed tests:");
      results
        .filter((r) => !r.passed)
        .forEach((r) => {
          logger.error(`  - ${r.name}: ${r.error || "Unknown error"}`);
        });
      process.exit(1);
    } else {
      logger.success("\nAll tests passed!");
      process.exit(0);
    }
  });


