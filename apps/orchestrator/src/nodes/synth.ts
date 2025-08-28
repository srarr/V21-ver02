import candidatesData from '../fixtures/strategies.json';
import { Strategy, Blueprint } from '../lib/types';
import { status, artifact } from '../lib/bus';

export async function nodeSynth(runId: string, blueprint: Blueprint): Promise<Strategy[]> {
  console.log(`[Synth] Starting for run ${runId} with blueprint:`, blueprint);
  
  // Emit status event
  await status(runId, 'synth', 'Generating candidate strategies from blueprint');
  
  // Simulate processing time
  await new Promise(resolve => setTimeout(resolve, 800));
  
  // Use fixture data as strategies
  const strategies = candidatesData as Strategy[];
  
  // Emit artifact event with strategies
  await artifact(runId, 'synth', { 
    candidates: strategies,
    count: strategies.length 
  });
  
  console.log(`[Synth] Generated ${strategies.length} strategies`);
  return strategies;
}