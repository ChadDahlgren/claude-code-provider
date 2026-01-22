// AWS CLI wrapper functions
import { execSync } from 'child_process';
/**
 * List all configured AWS profiles
 */
export function listProfiles() {
    try {
        const output = execSync('aws configure list-profiles 2>/dev/null', { encoding: 'utf-8' });
        return output.trim().split('\n').filter(p => p.length > 0);
    }
    catch {
        return [];
    }
}
/**
 * Get the caller identity for a profile (validates credentials work)
 */
export function getCallerIdentity(profile) {
    try {
        const output = execSync(`aws sts get-caller-identity --profile ${profile} --output json 2>/dev/null`, { encoding: 'utf-8' });
        const data = JSON.parse(output);
        return {
            account: data.Account,
            arn: data.Arn,
            userId: data.UserId
        };
    }
    catch {
        return null;
    }
}
/**
 * Export credentials for a profile (checks if session is valid)
 */
export function exportCredentials(profile) {
    try {
        const output = execSync(`aws configure export-credentials --profile ${profile} --format env-no-export 2>/dev/null`, { encoding: 'utf-8' });
        const creds = {};
        for (const line of output.split('\n')) {
            const [key, ...valueParts] = line.split('=');
            const value = valueParts.join('=');
            if (key === 'AWS_ACCESS_KEY_ID')
                creds.accessKeyId = value;
            if (key === 'AWS_SECRET_ACCESS_KEY')
                creds.secretAccessKey = value;
            if (key === 'AWS_SESSION_TOKEN')
                creds.sessionToken = value;
            if (key === 'AWS_CREDENTIAL_EXPIRATION')
                creds.expiration = value;
        }
        if (creds.accessKeyId && creds.secretAccessKey) {
            return creds;
        }
        return null;
    }
    catch {
        return null;
    }
}
/**
 * Get a config value for a profile
 */
export function getConfigValue(profile, key) {
    try {
        const output = execSync(`aws configure get ${key} --profile ${profile} 2>/dev/null`, { encoding: 'utf-8' });
        return output.trim() || null;
    }
    catch {
        return null;
    }
}
/**
 * List Bedrock inference profiles in a region
 */
export function listInferenceProfiles(profile, region) {
    try {
        const output = execSync(`aws bedrock list-inference-profiles --profile ${profile} --region ${region} --output json 2>/dev/null`, { encoding: 'utf-8' });
        const data = JSON.parse(output);
        return (data.inferenceProfileSummaries || []).map((p) => ({
            profileId: p.inferenceProfileId,
            profileName: p.inferenceProfileName,
            modelId: p.models?.[0]?.modelArn?.split('/').pop() || 'unknown'
        }));
    }
    catch {
        return [];
    }
}
/**
 * Check if profile has Bedrock access in a region
 */
export function hasBedrockAccess(profile, region) {
    const profiles = listInferenceProfiles(profile, region);
    return profiles.length > 0;
}
/**
 * Run SSO login for a profile (returns success/failure, user sees browser)
 */
export function ssoLogin(profile) {
    try {
        execSync(`aws sso login --profile ${profile}`, {
            encoding: 'utf-8',
            stdio: 'inherit' // Show output to user
        });
        return true;
    }
    catch {
        return false;
    }
}
