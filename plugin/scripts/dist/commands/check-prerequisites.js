// Check that required tools are installed
import { execSync } from 'child_process';
import { success } from '../lib/output.js';
function checkTool(command, versionArg = '--version') {
    try {
        const output = execSync(`${command} ${versionArg} 2>&1`, { encoding: 'utf-8' }).trim();
        // Extract just the version number from the first line
        const firstLine = output.split('\n')[0];
        return { installed: true, version: firstLine };
    }
    catch {
        return { installed: false, version: null };
    }
}
export function checkPrerequisites() {
    const result = {
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
