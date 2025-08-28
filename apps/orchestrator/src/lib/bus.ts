import { emitEvent, setRunStatus } from './db';

export async function status(runId: string, phase: string, msg: string): Promise<number> {
  return emitEvent(runId, phase, 'status', { msg, progress: 0.5 });
}

export async function artifact(runId: string, phase: string, data: any): Promise<number> {
  return emitEvent(runId, phase, 'artifact', data);
}

export async function metric(runId: string, phase: string, name: string, value: number): Promise<number> {
  return emitEvent(runId, phase, 'metric', { name, value });
}

export async function error(runId: string, phase: string, msg: string, details?: any): Promise<number> {
  return emitEvent(runId, phase, 'error', { msg, details });
}

export async function final(runId: string, phase: string, data: any): Promise<number> {
  return emitEvent(runId, phase, 'final', data);
}

export async function begin(runId: string): Promise<void> {
  await setRunStatus(runId, 'RUNNING');
}

export async function finish(runId: string, ok: boolean = true): Promise<void> {
  await setRunStatus(runId, ok ? 'COMPLETED' : 'FAILED');
}