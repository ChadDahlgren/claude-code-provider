export interface BedrockConfig {
    profile: string | null;
    region: string | null;
    model: string | null;
}
export interface ClaudeSettings {
    env?: Record<string, string>;
    awsAuthRefresh?: string;
    [key: string]: unknown;
}
/**
 * Read the current Claude settings
 */
export declare function readSettings(): ClaudeSettings;
/**
 * Write Claude settings (merges with existing)
 */
export declare function writeSettings(updates: Partial<ClaudeSettings>): void;
/**
 * Get current Bedrock configuration from settings
 */
export declare function getBedrockConfig(): BedrockConfig | null;
/**
 * Apply Bedrock configuration to settings
 */
export declare function applyBedrockConfig(config: {
    profile: string;
    region: string;
    model: string;
}): void;
/**
 * Remove Bedrock configuration from settings
 */
export declare function removeBedrockConfig(): void;
/**
 * Check if Bedrock is configured
 */
export declare function isBedrockConfigured(): boolean;
/**
 * Get the settings file path
 */
export declare function getSettingsPath(): string;
