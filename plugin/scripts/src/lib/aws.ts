// AWS CLI wrapper functions

import { execSync } from 'child_process';

export interface AwsProfile {
  name: string;
  region?: string;
}

export interface AwsIdentity {
  account: string;
  arn: string;
  userId: string;
}

export interface AwsCredentials {
  accessKeyId: string;
  secretAccessKey: string;
  sessionToken?: string;
  expiration?: string;
}

export interface InferenceProfile {
  profileId: string;
  profileName: string;
  modelId: string;
}

/**
 * List all configured AWS profiles
 */
export function listProfiles(): string[] {
  try {
    const output = execSync('aws configure list-profiles 2>/dev/null', { encoding: 'utf-8' });
    return output.trim().split('\n').filter(p => p.length > 0);
  } catch {
    return [];
  }
}

/**
 * Get the caller identity for a profile (validates credentials work)
 */
export function getCallerIdentity(profile: string): AwsIdentity | null {
  try {
    const output = execSync(
      `aws sts get-caller-identity --profile ${profile} --output json 2>/dev/null`,
      { encoding: 'utf-8' }
    );
    const data = JSON.parse(output);
    return {
      account: data.Account,
      arn: data.Arn,
      userId: data.UserId
    };
  } catch {
    return null;
  }
}

/**
 * Export credentials for a profile (checks if session is valid)
 */
export function exportCredentials(profile: string): AwsCredentials | null {
  try {
    const output = execSync(
      `aws configure export-credentials --profile ${profile} --format env-no-export 2>/dev/null`,
      { encoding: 'utf-8' }
    );

    const creds: Partial<AwsCredentials> = {};
    for (const line of output.split('\n')) {
      const [key, ...valueParts] = line.split('=');
      const value = valueParts.join('=');
      if (key === 'AWS_ACCESS_KEY_ID') creds.accessKeyId = value;
      if (key === 'AWS_SECRET_ACCESS_KEY') creds.secretAccessKey = value;
      if (key === 'AWS_SESSION_TOKEN') creds.sessionToken = value;
      if (key === 'AWS_CREDENTIAL_EXPIRATION') creds.expiration = value;
    }

    if (creds.accessKeyId && creds.secretAccessKey) {
      return creds as AwsCredentials;
    }
    return null;
  } catch {
    return null;
  }
}

/**
 * Get a config value for a profile
 */
export function getConfigValue(profile: string, key: string): string | null {
  try {
    const output = execSync(
      `aws configure get ${key} --profile ${profile} 2>/dev/null`,
      { encoding: 'utf-8' }
    );
    return output.trim() || null;
  } catch {
    return null;
  }
}

/**
 * List Bedrock inference profiles in a region
 */
export function listInferenceProfiles(profile: string, region: string): InferenceProfile[] {
  try {
    const output = execSync(
      `aws bedrock list-inference-profiles --profile ${profile} --region ${region} --output json 2>/dev/null`,
      { encoding: 'utf-8' }
    );
    const data = JSON.parse(output);
    return (data.inferenceProfileSummaries || []).map((p: any) => ({
      profileId: p.inferenceProfileId,
      profileName: p.inferenceProfileName,
      modelId: p.models?.[0]?.modelArn?.split('/').pop() || 'unknown'
    }));
  } catch {
    return [];
  }
}

/**
 * Check if profile has Bedrock access in a region
 */
export function hasBedrockAccess(profile: string, region: string): boolean {
  const profiles = listInferenceProfiles(profile, region);
  return profiles.length > 0;
}

/**
 * Run SSO login for a profile (returns success/failure, user sees browser)
 */
export function ssoLogin(profile: string): boolean {
  try {
    execSync(`aws sso login --profile ${profile}`, {
      encoding: 'utf-8',
      stdio: 'inherit' // Show output to user
    });
    return true;
  } catch {
    return false;
  }
}
