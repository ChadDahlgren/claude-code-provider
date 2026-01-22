// Check that required tools are installed

import { execSync } from 'child_process';
import { success, failure } from '../lib/output.js';

interface ToolStatus {
  installed: boolean;
  version: string | null;
}

interface PrerequisitesResult {
  aws_cli: ToolStatus;
  node: ToolStatus;
  ready: boolean;
  missing: string[];
}

function checkTool(command: string, versionArg: string = '--version'): ToolStatus {
  try {
    const output = execSync(`${command} ${versionArg} 2>&1`, { encoding: 'utf-8' }).trim();
    // Extract just the version number from the first line
    const firstLine = output.split('\n')[0];
    return { installed: true, version: firstLine };
  } catch {
    return { installed: false, version: null };
  }
}

export function checkPrerequisites(): void {
  const result: PrerequisitesResult = {
    aws_cli: checkTool('aws'),
    node: checkTool('node'),
    ready: false,
    missing: []
  };

  if (!result.aws_cli.installed) {
    result.missing.push('aws-cli');
  }
  if (!result.node.installed) {
    result.missing.push('node');
  }

  result.ready = result.missing.length === 0;

  success(result);
}
