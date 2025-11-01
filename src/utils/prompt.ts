import { confirm as inqConfirm, input as inqInput, select as inqSelect, checkbox as inqCheckbox } from "@inquirer/prompts";

export async function confirm(message: string, defaultValue = false): Promise<boolean> {
  return await inqConfirm({
    message,
    default: defaultValue,
  });
}

export async function input(message: string, defaultValue?: string): Promise<string> {
  return await inqInput({
    message,
    default: defaultValue,
  });
}

export async function select<T>(
  message: string,
  choices: Array<{ name: string; value: T }>
): Promise<T> {
  return await inqSelect<T>({
    message,
    choices,
  });
}

export async function checkbox<T>(
  message: string,
  choices: Array<{ name: string; value: T; checked?: boolean }>
): Promise<T[]> {
  return await inqCheckbox<T>({
    message,
    choices: choices.map((c) => ({
      name: c.name,
      value: c.value,
      checked: c.checked,
    })),
  });
}

