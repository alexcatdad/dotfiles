import chalk from "chalk";

export enum LogLevel {
  DEBUG = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3,
}

class Logger {
  private level: LogLevel = LogLevel.INFO;

  setLevel(level: LogLevel) {
    this.level = level;
  }

  debug(message: string, ...args: any[]) {
    if (this.level <= LogLevel.DEBUG) {
      console.log(chalk.blue(`[DEBUG]`), message, ...args);
    }
  }

  info(message: string, ...args: any[]) {
    if (this.level <= LogLevel.INFO) {
      console.log(chalk.green(`[INFO]`), message, ...args);
    }
  }

  warn(message: string, ...args: any[]) {
    if (this.level <= LogLevel.WARN) {
      console.log(chalk.yellow(`[WARN]`), message, ...args);
    }
  }

  error(message: string, ...args: any[]) {
    if (this.level <= LogLevel.ERROR) {
      console.error(chalk.red(`[ERROR]`), message, ...args);
    }
  }

  success(message: string, ...args: any[]) {
    console.log(chalk.green(`✓`), message, ...args);
  }

  failure(message: string, ...args: any[]) {
    console.error(chalk.red(`✗`), message, ...args);
  }
}

export const logger = new Logger();


