import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import { buildGraph } from './graph';
import { begin, finish, error as emitError } from './lib/bus';
import { pool } from './lib/db';

const app = express();
app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/healthz', (_req, res) => {
  res.json({ 
    ok: true, 
    service: 'orchestrator',
    version: '1.0.0'
  });
});

// Main orchestration endpoint
app.post('/v1/orchestrate', async (req, res) => {
  const runId: string = req.body?.runId;
  
  if (!runId) {
    return res.status(400).json({ 
      error: 'runId required in request body' 
    });
  }

  // Check if run exists
  try {
    const { rows } = await pool.query(
      'SELECT id, status FROM runs WHERE id = $1',
      [runId]
    );
    
    if (rows.length === 0) {
      return res.status(404).json({ 
        error: 'Run not found',
        runId 
      });
    }
    
    if (rows[0].status !== 'PENDING') {
      return res.status(409).json({ 
        error: 'Run already processed',
        status: rows[0].status 
      });
    }
  } catch (err) {
    console.error('Database error:', err);
    return res.status(500).json({ 
      error: 'Database error' 
    });
  }

  // Accept the orchestration request
  res.status(202).json({ 
    accepted: true, 
    runId,
    message: 'Orchestration started in background' 
  });

  // Fire and forget - process in background
  (async () => {
    try {
      console.log(`[Orchestrator] Starting orchestration for run ${runId}`);
      
      // Mark run as started
      await begin(runId);
      
      // Build and execute the graph
      const graph = buildGraph();
      const result = await graph.invoke({ runId }) as any;
      
      console.log(`[Orchestrator] Completed run ${runId}`, {
        hasBlueprint: !!result?.blueprint,
        strategies: result?.strategies?.length || 0,
        hasMetrics: !!result?.metrics,
        hasManifest: !!result?.manifest
      });
      
      // Mark run as completed
      await finish(runId, true);
      
    } catch (err: any) {
      console.error(`[Orchestrator] Error in run ${runId}:`, err);
      
      // Emit error event
      await emitError(runId, 'orchestrator', 'Orchestration failed', {
        error: err.message,
        stack: err.stack
      });
      
      // Mark run as failed
      await finish(runId, false);
    }
  })();
});

// Get orchestration status
app.get('/v1/orchestrate/:runId', async (req, res) => {
  const { runId } = req.params;
  
  try {
    const { rows } = await pool.query(
      `SELECT r.id, r.status, r.started_at, r.finished_at,
              COUNT(e.seq) as event_count, MAX(e.seq) as last_seq
       FROM runs r
       LEFT JOIN run_events e ON r.id = e.run_id
       WHERE r.id = $1
       GROUP BY r.id`,
      [runId]
    );
    
    if (rows.length === 0) {
      return res.status(404).json({ error: 'Run not found' });
    }
    
    res.json({
      runId: rows[0].id,
      status: rows[0].status,
      startedAt: rows[0].started_at,
      finishedAt: rows[0].finished_at,
      eventCount: parseInt(rows[0].event_count) || 0,
      lastSeq: parseInt(rows[0].last_seq) || 0
    });
    
  } catch (err) {
    console.error('Database error:', err);
    res.status(500).json({ error: 'Database error' });
  }
});

// Start server
const port = Number(process.env.PORT || 7071);
app.listen(port, () => {
  console.log(`🚀 Orchestrator listening on port ${port}`);
  console.log(`📦 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🗄️  Database: ${process.env.POSTGRES_DSN?.split('@')[1] || 'not configured'}`);
});