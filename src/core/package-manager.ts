import { execSync, spawn } from "child_process";
import { existsSync } from "fs";
import { join } from "path";
import { logger } from "../utils/logger.js";
import { Spinner } from "../utils/spinner.js";
import { getPlatformInfo, getHomeDir, type OS, type PackageManager as PM } from "./platform.js";
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

  async isInstalled(packageName: string, isCask: boolean = false): Promise<boolean> {
    try {
      if (this.pm === "brew") {
        if (isCask) {
          execSync(`brew list --cask ${packageName}`, { stdio: "ignore" });
        } else {
          execSync(`brew list --formula ${packageName}`, { stdio: "ignore" });
        }
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

  async install(packageName: string, isCask: boolean = false): Promise<InstallResult> {
    const spinner = new Spinner(`Installing ${packageName}...`);
    spinner.start();

    try {
      if (this.pm === "brew") {
        const brewCmd = isCask ? `brew install --cask ${packageName}` : `brew install ${packageName}`;
        execSync(brewCmd, { stdio: "inherit" });
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

  async installBatch(packageNames: string[], isCask: boolean = false): Promise<InstallResult> {
    if (packageNames.length === 0) {
      return { success: true, packageName: "batch" };
    }

    const spinner = new Spinner(`Installing ${packageNames.length} packages...`);
    spinner.start();

    try {
      if (this.pm === "brew") {
        const packageList = packageNames.join(" ");
        const brewCmd = isCask ? `brew install --cask ${packageList}` : `brew install ${packageList}`;
        execSync(brewCmd, { stdio: "inherit" });
        spinner.stop(true);
        return { success: true, packageName: "batch" };
      } else if (this.pm === "apt") {
        const packageList = packageNames.join(" ");
        execSync(`sudo apt install -y ${packageList}`, { stdio: "inherit" });
        spinner.stop(true);
        return { success: true, packageName: "batch" };
      }
      spinner.stop(false);
      return { success: false, packageName: "batch", error: "Unsupported package manager" };
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      spinner.stop(false);
      logger.error(`Failed to install packages: ${errorMsg}`);
      return { success: false, packageName: "batch", error: errorMsg };
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

    // For apt, check if already installed to avoid unnecessary sudo prompts
    // Homebrew handles this gracefully on its own
    if (this.pm === "apt") {
      const installed = await this.isInstalled(packageName);
      if (installed) {
        logger.info(`${pkg.name} already installed`);
        return { success: true, packageName: pkg.name };
      }
    }

    // Check if this is a Homebrew cask (GUI application)
    const isCask = pkg.cask === true;
    return await this.install(packageName, isCask);
  }

  async installNpmPackage(pkg: PackageDefinition): Promise<InstallResult> {
    if (!pkg.global_npm) {
      return { success: false, packageName: pkg.name, error: "No npm package specified" };
    }

    const spinner = new Spinner(`Installing npm package ${pkg.global_npm}...`);
    spinner.start();

    try {
      // Check if NVM is available and Node.js was installed via NVM
      const homeDir = getHomeDir();
      const nvmPath = join(homeDir, ".nvm/nvm.sh");
      
      let installCmd: string;
      if (existsSync(nvmPath)) {
        // Use NVM to source npm
        let npmCmd = `npm install -g`;
        if (pkg.version_constraint) {
          npmCmd += ` ${pkg.global_npm}@${pkg.version_constraint}`;
        } else {
          npmCmd += ` ${pkg.global_npm}`;
        }
        installCmd = `source ${nvmPath} && ${npmCmd}`;
      } else {
        // Fallback to system npm
        installCmd = `npm install -g`;
        if (pkg.version_constraint) {
          installCmd += ` ${pkg.global_npm}@${pkg.version_constraint}`;
        } else {
          installCmd += ` ${pkg.global_npm}`;
        }
      }

      execSync(installCmd, { 
        stdio: "inherit",
        shell: existsSync(nvmPath) ? "/bin/bash" : undefined
      });
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
        // Check if command redirects output to a file and ensure parent directory exists
        const outputMatch = cmd.match(/>\s*([^\s]+)/);
        if (outputMatch) {
          const { mkdirSync } = await import("fs");
          const { dirname } = await import("path");
          const outputPath = outputMatch[1].replace(/^~/, getHomeDir());
          try {
            mkdirSync(dirname(outputPath), { recursive: true });
          } catch {
            // Directory might already exist, ignore
          }
        }
        execSync(cmd, { stdio: "inherit", shell: "/bin/bash" });
      } catch (error) {
        logger.warn(`Post-install command failed: ${cmd}`);
      }
    }
  }
}

/**
 * Install NVM (Node Version Manager)
 */
export async function installNVM(): Promise<InstallResult> {
  const homeDir = getHomeDir();
  const nvmDir = join(homeDir, ".nvm");
  const nvmPath = join(nvmDir, "nvm.sh");

  try {
    // Check if NVM is already installed
    if (existsSync(nvmPath)) {
      logger.info("NVM already installed");
      return { success: true, packageName: "nvm" };
    }

    logger.info("Installing NVM...");
    execSync("curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash", {
      stdio: "inherit",
    });
    logger.success("NVM installed");
    return { success: true, packageName: "nvm" };
  } catch (error) {
    const errorMsg = error instanceof Error ? error.message : String(error);
    logger.warn(`NVM installation may require a new terminal session. Error: ${errorMsg}`);
    return { success: false, packageName: "nvm", error: errorMsg };
  }
}

/**
 * Install Oh My Zsh
 */
export async function installOhMyZsh(): Promise<InstallResult> {
  const homeDir = getHomeDir();
  const ohMyZshDir = join(homeDir, ".oh-my-zsh");
  const zshCustom = join(homeDir, ".oh-my-zsh/custom");

  try {
    // Check if Oh My Zsh is already installed
    if (!existsSync(ohMyZshDir)) {
      logger.info("Installing Oh My Zsh...");
      // KEEP_ZSHRC=yes prevents the installer from modifying .zshrc
      // We'll manage .zshrc ourselves via the sourceable file approach
      execSync('KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended', {
        stdio: "inherit",
        env: { ...process.env, KEEP_ZSHRC: "yes" },
      });
      logger.success("Oh My Zsh installed");
    } else {
      logger.info("Oh My Zsh already installed");
    }

    // Install Oh My Zsh plugins
    logger.info("Installing Oh My Zsh plugins...");
    const plugins = [
      "zsh-users/zsh-autosuggestions",
      "zsh-users/zsh-syntax-highlighting",
      "zsh-users/zsh-completions",
    ];

    for (const plugin of plugins) {
      const pluginName = plugin.split("/").pop();
      const pluginPath = join(zshCustom, "plugins", pluginName!);
      if (!existsSync(pluginPath)) {
        try {
          execSync(`git clone https://github.com/${plugin}.git "${pluginPath}"`, { stdio: "ignore" });
          logger.success(`Installed plugin: ${pluginName}`);
        } catch (error) {
          logger.warn(`Failed to install plugin ${pluginName}`);
        }
      } else {
        logger.debug(`Plugin ${pluginName} already installed`);
      }
    }

    // Install Powerlevel10k theme
    const themePath = join(zshCustom, "themes/powerlevel10k");
    if (!existsSync(themePath)) {
      try {
        execSync(`git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${themePath}"`, { stdio: "ignore" });
        logger.success("Installed Powerlevel10k theme");
      } catch (error) {
        logger.debug("Powerlevel10k may already be installed");
      }
    }

    return { success: true, packageName: "oh-my-zsh" };
  } catch (error) {
    const errorMsg = error instanceof Error ? error.message : String(error);
    logger.error(`Failed to install Oh My Zsh: ${errorMsg}`);
    return { success: false, packageName: "oh-my-zsh", error: errorMsg };
  }
}

/**
 * Install Node.js via NVM instead of package manager
 */
export async function installNodeViaNVM(): Promise<InstallResult> {
  const homeDir = getHomeDir();
  const nvmDir = join(homeDir, ".nvm");
  const nvmPath = join(nvmDir, "nvm.sh");

  try {
    // Ensure NVM is installed first
    if (!existsSync(nvmPath)) {
      const nvmResult = await installNVM();
      if (!nvmResult.success) {
        return { success: false, packageName: "node", error: "NVM installation failed" };
      }
    }

    // Install Node.js LTS via NVM
    if (existsSync(nvmPath)) {
      logger.info("Installing Node.js LTS via NVM...");
      execSync(`source ${nvmPath} && nvm install --lts && nvm alias default lts/*`, {
        shell: "/bin/bash",
        stdio: "inherit",
      });
      logger.success("Node.js LTS installed via NVM");
      return { success: true, packageName: "node" };
    } else {
      return { success: false, packageName: "node", error: "NVM installation failed" };
    }
  } catch (error) {
    const errorMsg = error instanceof Error ? error.message : String(error);
    logger.warn(`NVM/Node.js installation may require a new terminal session. Error: ${errorMsg}`);
    return { success: false, packageName: "node", error: errorMsg };
  }
}


