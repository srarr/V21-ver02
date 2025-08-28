import blueprintData from '../fixtures/blueprint.json';
import { Blueprint } from '../lib/types';
import { status, artifact } from '../lib/bus';

export async function nodeArchitect(runId: string): Promise<Blueprint> {
  console.log(`[Architect] Starting for run ${runId}`);
  
  // Emit status event
  await status(runId, 'architect', 'Analyzing requirements and creating blueprint');
  
  // Simulate some processing time
  await new Promise(resolve => setTimeout(resolve, 500));
  
  // Use fixture data as blueprint
  const blueprint = blueprintData as Blueprint;
  
  // Emit artifact event with blueprint
  await artifact(runId, 'architect', { blueprint });
  
  console.log(`[Architect] Blueprint created:`, blueprint);
  return blueprint;
}