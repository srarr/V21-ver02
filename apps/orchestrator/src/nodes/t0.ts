import metricsData from '../fixtures/metrics.json';
import { Metrics, Strategy } from '../lib/types';
import { status, artifact } from '../lib/bus';

export async function nodeT0(runId: string, strategies: Strategy[]): Promise<Metrics> {
  console.log(`[T0] Starting backtest for run ${runId} with ${strategies.length} strategies`);
  
  // Emit status event
  await status(runId, 't0', 'Running fast backtest on synthetic data');
  
  // Simulate backtest processing time
  await new Promise(resolve => setTimeout(resolve, 1200));
  
  // Use fixture data as metrics
  const metrics = metricsData as Metrics;
  
  // Skip individual metric events (not in DB check constraint)
  // Would emit metric events here if supported by schema
  
  // Emit artifact event with complete metrics
  await artifact(runId, 't0', { 
    metrics,
    equity: [100000, 101500, 103200, 105000, 108000, 118000],
    trades: metrics.trades || 45
  });
  
  console.log(`[T0] Backtest completed with Sharpe=${metrics.sharpe}`);
  return metrics;
}