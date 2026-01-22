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
export declare function listProfiles(): string[];
/**
 * Get the caller identity for a profile (validates credentials work)
 */
export declare function getCallerIdentity(profile: string): AwsIdentity | null;
/**
 * Export credentials for a profile (checks if session is valid)
 */
export declare function exportCredentials(profile: string): AwsCredentials | null;
/**
 * Get a config value for a profile
 */
export declare function getConfigValue(profile: string, key: string): string | null;
/**
 * List Bedrock inference profiles in a region
 */
export declare function listInferenceProfiles(profile: string, region: string): InferenceProfile[];
/**
 * Check if profile has Bedrock access in a region
 */
export declare function hasBedrockAccess(profile: string, region: string): boolean;
/**
 * Run SSO login for a profile (returns success/failure, user sees browser)
 */
export declare function ssoLogin(profile: string): boolean;
