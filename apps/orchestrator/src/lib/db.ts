import 'dotenv/config';
import { Pool } from 'pg';
import { EventType } from './types';

export const pool = new Pool({ 
  connectionString: process.env.POSTGRES_DSN 
});

export async function withTx<T>(fn: (client: any) => Promise<T>): Promise<T> {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await fn(client);
    await client.query('COMMIT');
    return result;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

export async function emitEvent(
  runId: string,
  phase: string,
  type: EventType,
  payload: any
): Promise<number> {
  return withTx(async (client) => {
    // Get next sequence number
    const { rows } = await client.query(
      'SELECT COALESCE(MAX(seq), 0) as max_seq FROM run_events WHERE run_id = $1',
      [runId]
    );
    const nextSeq = Number(rows[0].max_seq) + 1;
    
    // Insert event
    await client.query(
      `INSERT INTO run_events (run_id, seq, phase, type, payload, ts) 
       VALUES ($1, $2, $3, $4, $5::jsonb, NOW())
       ON CONFLICT DO NOTHING`,
      [runId, nextSeq, phase, type, JSON.stringify(payload)]
    );
    
    console.log(`[Event] run=${runId} seq=${nextSeq} phase=${phase} type=${type}`);
    return nextSeq;
  });
}

export async function setRunStatus(
  runId: string,
  status: 'PENDING' | 'RUNNING' | 'FAILED' | 'COMPLETED'
): Promise<void> {
  const finishedAt = (status === 'COMPLETED' || status === 'FAILED') 
    ? ', finished_at = NOW()' 
    : '';
    
  await pool.query(
    `UPDATE runs SET status = $2${finishedAt} WHERE id = $1`,
    [runId, status]
  );
  console.log(`[Status] run=${runId} => ${status}`);
}