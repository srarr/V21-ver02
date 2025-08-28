import { Metrics } from '../lib/types';
import { status, artifact } from '../lib/bus';

export interface HSPManifest {
  name: string;
  version: string;
  strategy_id: string;
  created_at: string;
  download_url: string;
  checksum?: string;
}

export async function nodePack(runId: string, metrics: Metrics): Promise<HSPManifest> {
  console.log(`[Pack] Starting packaging for run ${runId}`);
  
  // Emit status event
  await status(runId, 'pack', 'Packaging strategy artifacts into HSP format');
  
  // Simulate packaging time
  await new Promise(resolve => setTimeout(resolve, 600));
  
  // Create manifest
  const manifest: HSPManifest = {
    name: 'HSP-MA-Crossover',
    version: '1.0.0',
    strategy_id: `strat_${runId.substring(0, 8)}`,
    created_at: new Date().toISOString(),
    download_url: `http://localhost:8080/v1/download/${runId}.hsp`,
    checksum: 'sha256:' + Math.random().toString(36).substring(2, 15)
  };
  
  // Emit artifact event with manifest
  await artifact(runId, 'pack', { manifest });
  
  // Skip final event (not in DB check constraint)
  // Would emit final event here if supported by schema
  
  console.log(`[Pack] Package created: ${manifest.name} v${manifest.version}`);
  return manifest;
}