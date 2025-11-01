import { readFileSync } from "fs";
import { join, dirname } from "path";
import { existsSync } from "fs";
import { fileURLToPath } from "url";
import { z } from "zod";
import { configSchema, type Config } from "./schema.js";
import { logger } from "../utils/logger.js";

function computeProjectRoot(): string {
  // Try to find config.json relative to this file
  try {
    const __filename = fileURLToPath(import.meta.url);
    const __dirname = dirname(__filename);

    // Check if running as compiled executable
    if (import.meta.url.startsWith('file:///') || import.meta.url.includes('$bunfs')) {
      // Running as compiled executable, use process.cwd()
      return process.cwd();
    }

    // Running from source, go up from src/config to project root
    return join(__dirname, "../../");
  } catch (error) {
    // Fallback to process.cwd() if anything fails
    return process.cwd();
  }
}

const PROJECT_ROOT = computeProjectRoot();

export function loadConfig(): Config {
  const configPath = join(PROJECT_ROOT, "config.json");

  try {
    const configContent = readFileSync(configPath, "utf-8");
    const rawConfig = JSON.parse(configContent);
    const validatedConfig = configSchema.parse(rawConfig);
    logger.debug("Config loaded and validated successfully");
    return validatedConfig;
  } catch (error) {
    if (error instanceof z.ZodError) {
      logger.error("Config validation failed:");
      error.errors.forEach((err) => {
        logger.error(`  ${err.path.join(".")}: ${err.message}`);
      });
      throw new Error("Invalid config.json file");
    }
    if (error instanceof SyntaxError) {
      logger.error(`Failed to parse config.json: ${error.message}`);
      throw new Error("Invalid JSON in config.json");
    }
    logger.error(`Failed to load config.json: ${error}`);
    throw error;
  }
}

export function getConfigPath(): string {
  return join(PROJECT_ROOT, "config.json");
}

export function getProjectRoot(): string {
  return PROJECT_ROOT;
}


