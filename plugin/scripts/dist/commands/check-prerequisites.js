// Check that required tools are installed
import { execFileSync } from 'child_process';
import { success } from '../lib/output.js';
/**
 * Check if a tool is installed by running it with --version
 * Uses execFileSync (not execSync) to prevent command injection
 */
function checkTool(command, versionArg = '--version') {
    try {
        const output = execFileSync(command, [versionArg], {
            encoding: 'utf-8',
            stdio: ['pipe', 'pipe', 'pipe'] // Capture stderr too
        }).trim();
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
