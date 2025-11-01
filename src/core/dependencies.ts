import { execSync } from "child_process";
import { logger } from "../utils/logger.js";
import { Spinner } from "../utils/spinner.js";
import { confirm } from "../utils/prompt.js";
import { getPlatformInfo, type OS } from "./platform.js";
import { readFileSync } from "fs";
import { join } from "path";
import { fileURLToPath } from "url";
import { dirname } from "path";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const PROJECT_ROOT = join(__dirname, "../../");

export interface DependencyCheck {
  name: string;
  command: string;
  installInstructions: string;
  required: boolean;
  check?: () => boolean;
}

// Tier 1: Core system tools
const TIER_1_DEPS: DependencyCheck[] = [
  {
    name: "Git",
    command: "git --version",
    installInstructions: "Install Git: https://git-scm.com/downloads",
    required: true,
  },
  {
    name: "curl",
    command: "curl --version",
    installInstructions: "Install curl via your package manager",
    required: true,
  },
  {
    name: "wget",
    command: "wget --version",
    installInstructions: "Install wget via your package manager",
    required: false,
  },
];

// Tier 2: Package managers
function getTier2Deps(os: OS): DependencyCheck[] {
  if (os === "macos") {
    return [
      {
        name: "Homebrew",
        command: "brew --version",
        installInstructions: '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"',
        required: true,
        check: () => {
          try {
            execSync("brew --version", { stdio: "ignore" });
            return true;
          } catch {
            return false;
          }
        },
      },
    ];
  }
  if (os === "ubuntu") {
    return [
      {
        name: "APT",
        command: "apt --version",
        installInstructions: "APT should be pre-installed on Ubuntu",
        required: true,
      },
    ];
  }
  return [];
}

// Tier 3: Language runtimes
const TIER_3_DEPS: DependencyCheck[] = [
  {
    name: "Node.js",
    command: "node --version",
    installInstructions: "Install Node.js via NVM: curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash",
    required: false,
  },
  {
    name: "Python 3",
    command: "python3 --version",
    installInstructions: "Install Python 3 via your package manager",
    required: false,
  },
];

async function checkDependency(dep: DependencyCheck): Promise<boolean> {
  try {
    if (dep.check) {
      return dep.check();
    }
    execSync(dep.command, { stdio: "ignore" });
    return true;
  } catch {
    return false;
  }
}

async function installDependency(dep: DependencyCheck, os: OS): Promise<boolean> {
  const spinner = new Spinner(`Installing ${dep.name}...`);
  spinner.start();

  try {
    if (os === "macos" && dep.name === "Homebrew") {
      execSync(dep.installInstructions, { stdio: "inherit" });
      spinner.stop(true);
      return true;
    }
    if (os === "ubuntu") {
      if (dep.name === "APT") {
        logger.warn("APT should already be installed");
        spinner.stop(true);
        return true;
      }
      logger.info(`Please install ${dep.name} manually: ${dep.installInstructions}`);
      spinner.stop(false);
      return false;
    }
    logger.info(`Please install ${dep.name} manually: ${dep.installInstructions}`);
    spinner.stop(false);
    return false;
  } catch (error) {
    logger.error(`Failed to install ${dep.name}: ${error}`);
    spinner.stop(false);
    return false;
  }
}

export async function checkTier1(): Promise<boolean> {
  logger.info("Checking Tier 1: Core system tools...");
  let allPassed = true;

  for (const dep of TIER_1_DEPS) {
    const installed = await checkDependency(dep);
    if (installed) {
      logger.success(`${dep.name} is installed`);
    } else {
      if (dep.required) {
        logger.failure(`${dep.name} is missing (required)`);
        allPassed = false;
      } else {
        logger.warn(`${dep.name} is missing (optional)`);
      }
    }
  }

  return allPassed;
}

export async function checkTier2(os: OS): Promise<boolean> {
  logger.info(`Checking Tier 2: Package managers for ${os}...`);
  const deps = getTier2Deps(os);
  let allPassed = true;

  for (const dep of deps) {
    const installed = await checkDependency(dep);
    if (installed) {
      logger.success(`${dep.name} is installed`);
    } else {
      if (dep.required) {
        logger.failure(`${dep.name} is missing (required)`);
        allPassed = false;

        if (await confirm(`Would you like to install ${dep.name}?`, true)) {
          const installed = await installDependency(dep, os);
          if (installed) {
            allPassed = true;
          }
        }
      } else {
        logger.warn(`${dep.name} is missing (optional)`);
      }
    }
  }

  return allPassed;
}

export async function checkTier3(): Promise<boolean> {
  logger.info("Checking Tier 3: Language runtimes...");
  let allPassed = true;

  for (const dep of TIER_3_DEPS) {
    const installed = await checkDependency(dep);
    if (installed) {
      logger.success(`${dep.name} is installed`);
    } else {
      logger.warn(`${dep.name} is missing (optional)`);
    }
  }

  return allPassed;
}

export async function checkAllDependencies(autoInstall = false): Promise<boolean> {
  const platform = getPlatformInfo();
  logger.info(`Checking dependencies for ${platform.os}...`);

  // Check Tier 1
  const tier1Ok = await checkTier1();
  if (!tier1Ok) {
    logger.error("Required Tier 1 dependencies are missing");
    return false;
  }

  // Check Tier 2
  const tier2Ok = await checkTier2(platform.os);
  if (!tier2Ok) {
    logger.error("Required Tier 2 dependencies are missing");
    return false;
  }

  // Check Tier 3 (optional)
  await checkTier3();

  logger.success("All required dependencies are installed");
  return true;
}


