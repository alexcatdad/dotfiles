import chalk from "chalk";

const spinners = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];

export class Spinner {
  private interval?: ReturnType<typeof setInterval>;
  private frame = 0;
  private message: string;

  constructor(message: string) {
    this.message = message;
  }

  start() {
    this.interval = setInterval(() => {
      const spinner = spinners[this.frame % spinners.length];
      process.stdout.write(`\r${chalk.cyan(spinner)} ${this.message}`);
      this.frame++;
    }, 80);
  }

  update(message: string) {
    this.message = message;
  }

  stop(success = true) {
    if (this.interval) {
      clearInterval(this.interval);
      this.interval = undefined;
    }
    process.stdout.write(`\r${success ? chalk.green("✓") : chalk.red("✗")} ${this.message}\n`);
  }
}


