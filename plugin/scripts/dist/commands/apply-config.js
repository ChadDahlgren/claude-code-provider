// Apply Bedrock configuration to Claude settings
import { success, failure } from '../lib/output.js';
import { applyBedrockConfig, removeBedrockConfig, getSettingsPath } from '../lib/config.js';
import { getCallerIdentity, listInferenceProfiles } from '../lib/aws.js';
function parseArgs() {
    const args = process.argv.slice(3);
    const result = {};
    for (const arg of args) {
        if (arg === '--remove') {
            result.remove = true;
        }
        else if (arg.startsWith('--profile=')) {
            result.profile = arg.split('=')[1];
        }
        else if (arg.startsWith('--region=')) {
            result.region = arg.split('=')[1];
        }
        else if (arg.startsWith('--model=')) {
            result.model = arg.split('=')[1];
        }
    }
    return result;
}
export function applyConfig() {
    const args = parseArgs();
    // Handle remove
    if (args.remove) {
        removeBedrockConfig();
        success({
            removed: true,
            settingsPath: getSettingsPath()
        });
        return;
    }
    // Validate required args
    if (!args.profile) {
        failure('Missing required argument: --profile=<profile-name>');
    }
    if (!args.region) {
        failure('Missing required argument: --region=<aws-region>');
    }
    if (!args.model) {
        failure('Missing required argument: --model=<model-id>');
    }
    const { profile, region, model } = args;
    // Validate profile exists and has valid credentials
    const identity = getCallerIdentity(profile);
    if (!identity) {
        failure(`Profile '${profile}' does not exist or has expired credentials. Run 'aws sso login --profile ${profile}' first.`);
    }
    // Validate Bedrock access
    const inferenceProfiles = listInferenceProfiles(profile, region);
    if (inferenceProfiles.length === 0) {
        failure(`Profile '${profile}' does not have Bedrock access in region '${region}'. Check IAM permissions.`);
    }
    // Validate model exists
    const modelExists = inferenceProfiles.some(p => p.profileId === model ||
        p.profileId.includes(model) ||
        p.profileName.toLowerCase().includes(model.toLowerCase()));
    if (!modelExists) {
        const available = inferenceProfiles.map(p => p.profileId).join(', ');
        failure(`Model '${model}' not found. Available: ${available}`);
    }
    // Apply configuration
    applyBedrockConfig({ profile, region, model });
    success({
        applied: true,
        config: { profile, region, model },
        settingsPath: getSettingsPath(),
        requiresRestart: true
    });
}
