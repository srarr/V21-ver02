export type Blueprint = {
  universe: string[];
  features: string[];
  constraints: {
    risk_bp: number;
  };
};

export type Strategy = {
  name: string;
  rules: string[];
};

export type Metrics = {
  cagr: number;
  sharpe: number;
  maxdd: number;
  trades?: number;
  winRate?: number;
  profitFactor?: number;
};

export type RunStatus = 'PENDING' | 'RUNNING' | 'FAILED' | 'COMPLETED';

export type EventType = 'status' | 'artifact' | 'error' | 'final' | 'metric';

export type OrchestratorEvent = {
  run_id: string;
  seq: number;
  phase: string;
  type: EventType;
  payload: any;
  ts?: Date;
};