// Settings file helpers
import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'fs';
import { homedir } from 'os';
import { join, dirname } from 'path';
const SETTINGS_PATH = join(homedir(), '.claude', 'settings.json');
/**
 * Read the current Claude settings
 */
export function readSettings() {
    try {
        if (!existsSync(SETTINGS_PATH)) {
            return {};
        }
        const content = readFileSync(SETTINGS_PATH, 'utf-8');
        return JSON.parse(content);
    }
    catch {
        return {};
    }
}
/**
 * Write Claude settings (merges with existing)
 */
export function writeSettings(updates) {
    const current = readSettings();
    const merged = { ...current, ...updates };
    // Ensure directory exists
    const dir = dirname(SETTINGS_PATH);
    if (!existsSync(dir)) {
        mkdirSync(dir, { recursive: true });
    }
    writeFileSync(SETTINGS_PATH, JSON.stringify(merged, null, 2) + '\n');
}
/**
 * Get current Bedrock configuration from settings
 */
export function getBedrockConfig() {
    const settings = readSettings();
    const env = settings.env || {};
    if (env.CLAUDE_CODE_USE_BEDROCK !== '1') {
        return null;
    }
    return {
        profile: env.AWS_PROFILE || null,
        region: env.AWS_REGION || null,
        model: env.ANTHROPIC_MODEL || null
    };
}
/**
 * Apply Bedrock configuration to settings
 */
export function applyBedrockConfig(config) {
    const settings = readSettings();
    writeSettings({
        ...settings,
        env: {
            ...(settings.env || {}),
            CLAUDE_CODE_USE_BEDROCK: '1',
            AWS_PROFILE: config.profile,
            AWS_REGION: config.region,
            ANTHROPIC_MODEL: config.model
        },
        awsAuthRefresh: `aws sso login --profile ${config.profile}`
    });
}
/**
 * Check if a model ID is a Bedrock model (has provider prefix and version suffix)
 */
function isBedrockModel(modelId) {
    if (!modelId)
        return false;
    // Bedrock models have format like: us.anthropic.claude-xxx:0 or global.anthropic.claude-xxx:0
    return /^(us|eu|ap|global)\.anthropic\./.test(modelId) && modelId.includes(':');
}
/**
 * Remove Bedrock configuration from settings
 */
export function removeBedrockConfig() {
    const settings = readSettings();
    const env = { ...(settings.env || {}) };
    delete env.CLAUDE_CODE_USE_BEDROCK;
    delete env.AWS_PROFILE;
    delete env.AWS_REGION;
    delete env.ANTHROPIC_MODEL;
    const updated = { ...settings };
    delete updated.awsAuthRefresh;
    // Also remove root-level model if it's a Bedrock model
    if (isBedrockModel(updated.model)) {
        delete updated.model;
    }
    if (Object.keys(env).length > 0) {
        updated.env = env;
    }
    else {
        delete updated.env;
    }
    // Write directly to file (bypass merge in writeSettings since we're removing keys)
    const dir = dirname(SETTINGS_PATH);
    if (!existsSync(dir)) {
        mkdirSync(dir, { recursive: true });
    }
    writeFileSync(SETTINGS_PATH, JSON.stringify(updated, null, 2) + '\n');
}
/**
 * Check if Bedrock is configured
 */
export function isBedrockConfigured() {
    return getBedrockConfig() !== null;
}
/**
 * Get the settings file path
 */
export function getSettingsPath() {
    return SETTINGS_PATH;
}
