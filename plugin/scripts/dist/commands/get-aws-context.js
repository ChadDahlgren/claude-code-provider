// Get AWS context: profiles, validity, Bedrock access
import { success } from '../lib/output.js';
import { listProfiles, getCallerIdentity, exportCredentials, getConfigValue, listInferenceProfiles } from '../lib/aws.js';
import { getBedrockConfig } from '../lib/config.js';
// Bedrock regions to check
const BEDROCK_REGIONS = ['us-west-2', 'us-east-1', 'eu-west-1', 'ap-northeast-1'];
export function getAwsContext() {
    const args = process.argv.slice(3);
    const checkBedrockFlag = args.includes('--check-bedrock');
    const regionArg = args.find(a => a.startsWith('--region='));
    const specificRegion = regionArg ? regionArg.split('=')[1] : null;
    const profiles = listProfiles();
    if (profiles.length === 0) {
        success({
            profiles: [],
            validProfiles: [],
            bedrockProfiles: [],
            recommended: null,
            currentConfig: getBedrockConfig(),
            needsSsoSetup: true
        });
        return;
    }
    const profileInfos = [];
    for (const name of profiles) {
        const region = getConfigValue(name, 'region');
        const identity = getCallerIdentity(name);
        const creds = identity ? exportCredentials(name) : null;
        const info = {
            name,
            region,
            valid: identity !== null,
            identity,
            sessionExpires: creds?.expiration || null,
            bedrockAccess: false,
            inferenceProfiles: []
        };
        // Only check Bedrock if profile is valid and flag is set
        if (info.valid && checkBedrockFlag) {
            const regionsToCheck = specificRegion ? [specificRegion] : (region ? [region] : BEDROCK_REGIONS);
            for (const r of regionsToCheck) {
                const inferenceProfiles = listInferenceProfiles(name, r);
                if (inferenceProfiles.length > 0) {
                    info.bedrockAccess = true;
                    info.inferenceProfiles = inferenceProfiles;
                    if (!info.region) {
                        info.region = r; // Set region if we found Bedrock access
                    }
                    break;
                }
            }
        }
        profileInfos.push(info);
    }
    const validProfiles = profileInfos.filter(p => p.valid).map(p => p.name);
    const bedrockProfiles = profileInfos.filter(p => p.bedrockAccess).map(p => p.name);
    // Determine recommendation
    let recommended = null;
    if (bedrockProfiles.length > 0) {
        recommended = bedrockProfiles[0];
    }
    else if (validProfiles.length === 1) {
        recommended = validProfiles[0];
    }
    success({
        profiles: profileInfos,
        validProfiles,
        bedrockProfiles,
        recommended,
        currentConfig: getBedrockConfig(),
        needsSsoSetup: validProfiles.length === 0
    });
}
