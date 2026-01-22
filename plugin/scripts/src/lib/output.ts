// Structured JSON output helpers

export interface CommandResult<T = unknown> {
  success: boolean;
  data?: T;
  error?: string;
}

export function success<T>(data: T): never {
  console.log(JSON.stringify({ success: true, data }, null, 2));
  process.exit(0);
}

export function failure(error: string): never {
  console.log(JSON.stringify({ success: false, error }, null, 2));
  process.exit(1);
}
