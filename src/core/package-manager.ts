import { execSync, spawn } from "child_process";
import { logger } from "../utils/logger.js";
import { Spinner } from "../utils/spinner.js";
import { getPlatformInfo, type OS, type PackageManager as PM } from "./platform.js";
import type { PackageDefinition } from "../config/schema.js";

export interface InstallResult {
  success: boolean;
  packageName: string;
  error?: string;
}

export class PackageManager {
  private os: OS;
  private pm: PM;

  constructor() {
    const platform = getPlatformInfo();
    this.os = platform.os;
    this.pm = platform.packageManager;
  }

  async isInstalled(packageName: string): Promise<boolean> {
    try {
      if (this.pm === "brew") {
        execSync(`brew list --formula ${packageName}`, { stdio: "ignore" });
        return true;
      } else if (this.pm === "apt") {
        execSync(`dpkg -l | grep "^ii  ${packageName} "`, { stdio: "ignore" });
        return true;
      }
      return false;
    } catch {
      return false;
    }
  }

  async install(packageName: string): Promise<InstallResult> {
    const spinner = new Spinner(`Installing ${packageName}...`);
    spinner.start();

    try {
      if (this.pm === "brew") {
        execSync(`brew install ${packageName}`, { stdio: "inherit" });
        spinner.stop(true);
        return { success: true, packageName };
      } else if (this.pm === "apt") {
        execSync(`sudo apt install -y ${packageName}`, { stdio: "inherit" });
        spinner.stop(true);
        return { success: true, packageName };
      }
      spinner.stop(false);
      return { success: false, packageName, error: "Unsupported package manager" };
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      spinner.stop(false);
      logger.error(`Failed to install ${packageName}: ${errorMsg}`);
      return { success: false, packageName, error: errorMsg };
    }
  }

  async installPackage(pkg: PackageDefinition): Promise<InstallResult> {
    let packageName: string | undefined;

    if (this.os === "macos") {
      packageName = pkg.macos || undefined;
    } else if (this.os === "ubuntu") {
      packageName = pkg.ubuntu || undefined;
    }

    if (!packageName || packageName === "null") {
      return { success: false, packageName: pkg.name, error: "Package not available for this platform" };
    }

    // Check if already installed
    const installed = await this.isInstalled(packageName);
    if (installed) {
      logger.info(`${pkg.name} already installed`);
      return { success: true, packageName: pkg.name };
    }

    return await this.install(packageName);
  }

  async installNpmPackage(pkg: PackageDefinition): Promise<InstallResult> {
    if (!pkg.global_npm) {
      return { success: false, packageName: pkg.name, error: "No npm package specified" };
    }

    const spinner = new Spinner(`Installing npm package ${pkg.global_npm}...`);
    spinner.start();

    try {
      let installCmd = `npm install -g`;
      if (pkg.version_constraint) {
        installCmd += ` ${pkg.global_npm}@${pkg.version_constraint}`;
      } else {
        installCmd += ` ${pkg.global_npm}`;
      }

      execSync(installCmd, { stdio: "inherit" });
      spinner.stop(true);
      return { success: true, packageName: pkg.name };
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      spinner.stop(false);
      logger.error(`Failed to install npm package ${pkg.global_npm}: ${errorMsg}`);
      return { success: false, packageName: pkg.name, error: errorMsg };
    }
  }

  async runPostInstall(commands: string[]): Promise<void> {
    for (const cmd of commands) {
      logger.info(`Running post-install: ${cmd}`);
      try {
        execSync(cmd, { stdio: "inherit" });
      } catch (error) {
        logger.warn(`Post-install command failed: ${cmd}`);
      }
    }
  }
}


