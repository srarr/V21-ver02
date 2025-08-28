// contracts/shared/types.ts
// Shared TypeScript types for the entire Heliox system

import { z } from 'zod';

// ========== Core Domain Types ==========

export const TraceId = z.string().regex(/^tr_\d{8}_[a-z0-9]{6}$/, "Invalid trace ID format");
export type TraceIdT = z.infer<typeof TraceId>;

export const Phase = z.enum(['PHASE0', 'T0', 'T1', 'T2', 'T3', 'PACK']);
export type PhaseT = z.infer<typeof Phase>;

export const RunStatus = z.enum(['QUEUED', 'RUNNING', 'COMPLETE', 'FAILED', 'CANCELLED']);
export type RunStatusT = z.infer<typeof RunStatus>;

export const RiskTier = z.enum(['conservative', 'balanced', 'aggressive']);
export type RiskTierT = z.infer<typeof RiskTier>;

// ========== Events ==========

export const BaseEvent = z.object({
  trace_id: TraceId,
  timestamp: z.string().datetime(),
  seq: z.number().int().min(0),
});

export const StatusEvent = BaseEvent.extend({
  type: z.literal('status'),
  payload: z.object({
    stage: z.string(),
    progress: z.number().min(0).max(1),
    message: z.string().optional(),
    phase: Phase.optional(),
  }),
});

export const MetricEvent = BaseEvent.extend({
  type: z.literal('metric'),
  payload: z.object({
    name: z.string(),
    value: z.number(),
    unit: z.string().optional(),
    category: z.enum(['performance', 'risk', 'trades', 'portfolio']).optional(),
  }),
});

export const ArtifactEvent = BaseEvent.extend({
  type: z.literal('artifact'),
  payload: z.object({
    name: z.string(),
    uri: z.string().url(),
    size: z.number().int().min(0),
    mime_type: z.string(),
    checksum: z.string().optional(),
  }),
});

export const ErrorEvent = BaseEvent.extend({
  type: z.literal('error'),
  payload: z.object({
    code: z.string(),
    message: z.string(),
    phase: Phase.optional(),
    retry_count: z.number().int().min(0).optional(),
    details: z.record(z.any()).optional(),
  }),
});

export const FinalEvent = BaseEvent.extend({
  type: z.literal('final'),
  phase: Phase,
  payload: z.object({
    hsp_uri: z.string().url(),
    metrics: z.record(z.number()),
    success: z.boolean(),
    duration_ms: z.number().int().min(0),
  }),
});

export const HelioxEvent = z.discriminatedUnion('type', [
  StatusEvent,
  MetricEvent,
  ArtifactEvent,
  ErrorEvent,
  FinalEvent,
]);

export type HelioxEventT = z.infer<typeof HelioxEvent>;

// ========== API Requests/Responses ==========

export const CreateRunRequest = z.object({
  prompt: z.string().min(1).max(4000),
  scenario_set_id: z.string().optional(),
  risk_tier: RiskTier.default('balanced'),
  options: z.object({
    max_iterations: z.number().int().min(1).max(100).default(10),
    temperature: z.number().min(0).max(2).default(0.7),
    model: z.string().default('claude-3-opus'),
    timeout_minutes: z.number().int().min(1).max(60).default(30),
  }).optional(),
});

export type CreateRunRequestT = z.infer<typeof CreateRunRequest>;

export const CreateRunResponse = z.object({
  trace_id: TraceId,
  status: RunStatus,
  created_at: z.string().datetime(),
  estimated_time_seconds: z.number().int().min(0),
  phases_planned: z.array(Phase),
});

export type CreateRunResponseT = z.infer<typeof CreateRunResponse>;

export const GetRunResponse = z.object({
  trace_id: TraceId,
  status: RunStatus,
  current_phase: Phase.optional(),
  progress: z.number().min(0).max(1),
  created_at: z.string().datetime(),
  updated_at: z.string().datetime(),
  started_at: z.string().datetime().optional(),
  completed_at: z.string().datetime().optional(),
  error_message: z.string().optional(),
  metrics: z.record(z.number()).optional(),
});

export type GetRunResponseT = z.infer<typeof GetRunResponse>;

// ========== Strategy Domain ==========

export const Indicator = z.object({
  name: z.string(),
  type: z.enum(['MA', 'EMA', 'RSI', 'MACD', 'BB', 'STOCH', 'ADX', 'CUSTOM']),
  params: z.record(z.union([z.string(), z.number(), z.boolean()])),
  timeframe: z.string().optional(), // e.g., '1h', '1d', '4h'
});

export const TradingRule = z.object({
  id: z.string(),
  condition: z.string(), // DSL expression
  action: z.enum(['BUY', 'SELL', 'HOLD', 'CLOSE_LONG', 'CLOSE_SHORT']),
  size: z.number().min(0).max(1).optional(), // Position size as fraction
  priority: z.number().int().min(1).max(10).default(5),
});

export const RiskConstraints = z.object({
  max_position_size: z.number().min(0).max(1), // Fraction of portfolio
  stop_loss: z.number().min(0).max(1).optional(), // Fraction loss
  take_profit: z.number().min(0).optional(), // Fraction gain
  max_daily_loss: z.number().min(0).max(1).optional(),
  max_drawdown: z.number().min(0).max(1).optional(),
  position_timeout_hours: z.number().int().min(1).optional(),
});

export const Blueprint = z.object({
  id: z.string(),
  name: z.string(),
  description: z.string(),
  version: z.string().default('1.0.0'),
  created_at: z.string().datetime(),
  
  // Strategy components
  indicators: z.array(Indicator),
  rules: z.array(TradingRule),
  constraints: RiskConstraints,
  
  // Market configuration
  assets: z.array(z.string()), // Asset symbols
  timeframes: z.array(z.string()), // Trading timeframes
  market_sessions: z.array(z.string()).optional(),
  
  // Metadata
  tags: z.array(z.string()).optional(),
  complexity_score: z.number().min(1).max(10).optional(),
  confidence_score: z.number().min(0).max(1).optional(),
});

export type BlueprintT = z.infer<typeof Blueprint>;

export const Trade = z.object({
  id: z.string(),
  entry_time: z.string().datetime(),
  exit_time: z.string().datetime().optional(),
  symbol: z.string(),
  side: z.enum(['LONG', 'SHORT']),
  quantity: z.number().positive(),
  entry_price: z.number().positive(),
  exit_price: z.number().positive().optional(),
  pnl: z.number(),
  pnl_percent: z.number(),
  fees: z.number().min(0).optional(),
  slippage: z.number().min(0).optional(),
  rule_triggered: z.string().optional(), // Which rule caused the trade
});

export type TradeT = z.infer<typeof Trade>;

export const BacktestMetrics = z.object({
  // Return metrics
  total_return: z.number(),
  annualized_return: z.number(),
  sharpe_ratio: z.number(),
  sortino_ratio: z.number(),
  calmar_ratio: z.number(),
  
  // Risk metrics
  max_drawdown: z.number().min(0).max(1),
  volatility: z.number().min(0),
  var_95: z.number(), // Value at Risk
  
  // Trading metrics
  total_trades: z.number().int().min(0),
  win_rate: z.number().min(0).max(1),
  profit_factor: z.number().min(0),
  avg_win: z.number(),
  avg_loss: z.number(),
  largest_win: z.number(),
  largest_loss: z.number(),
  
  // Time metrics
  avg_trade_duration_hours: z.number().min(0),
  time_in_market: z.number().min(0).max(1), // Fraction of time with open positions
});

export type BacktestMetricsT = z.infer<typeof BacktestMetrics>;

export const BacktestResult = z.object({
  phase: Phase,
  period_start: z.string().datetime(),
  period_end: z.string().datetime(),
  initial_capital: z.number().positive(),
  final_capital: z.number().positive(),
  
  metrics: BacktestMetrics,
  
  equity_curve: z.array(z.object({
    timestamp: z.string().datetime(),
    value: z.number().positive(),
    drawdown: z.number().min(0).max(1),
  })),
  
  trades: z.array(Trade),
  
  // Performance by asset/timeframe
  performance_breakdown: z.record(z.object({
    trades: z.number().int().min(0),
    pnl: z.number(),
    win_rate: z.number().min(0).max(1),
  })).optional(),
});

export type BacktestResultT = z.infer<typeof BacktestResult>;

// ========== HSP (Heliox Strategy Package) ==========

export const HSPMetadata = z.object({
  prompt: z.string(),
  model: z.string(),
  temperature: z.number().min(0).max(2),
  iterations: z.number().int().min(1),
  total_time_seconds: z.number().int().min(0),
  created_by: z.string().optional(),
  tags: z.array(z.string()).optional(),
});

export const HSPManifest = z.object({
  version: z.string(),
  format_version: z.string().default('1.0'),
  strategy_id: z.string(),
  created_at: z.string().datetime(),
  
  blueprint: Blueprint,
  backtest_results: z.array(BacktestResult),
  metadata: HSPMetadata,
  
  // File references within the HSP package
  files: z.object({
    strategy_code: z.string().optional(), // Path to generated code
    research_notes: z.string().optional(), // Path to analysis notes
    performance_charts: z.array(z.string()).optional(), // Chart files
  }).optional(),
  
  // Integrity
  checksum: z.string(),
});

export type HSPManifestT = z.infer<typeof HSPManifest>;

// ========== Portfolio Management ==========

export const PortfolioAsset = z.object({
  id: z.string(),
  hsp_uri: z.string().url(),
  name: z.string(),
  added_at: z.string().datetime(),
  last_updated: z.string().datetime(),
  
  // Allocation
  allocation_percent: z.number().min(0).max(100),
  max_allocation_percent: z.number().min(0).max(100).optional(),
  
  // Performance tracking
  performance: z.object({
    live_return: z.number().optional(),
    paper_return: z.number().optional(),
    backtest_sharpe: z.number(),
    backtest_max_drawdown: z.number().min(0).max(1),
    trades_count: z.number().int().min(0).optional(),
    last_trade_at: z.string().datetime().optional(),
  }),
  
  // Status and controls
  status: z.enum(['active', 'paused', 'archived', 'error']),
  auto_rebalance: z.boolean().default(true),
  notes: z.string().optional(),
});

export type PortfolioAssetT = z.infer<typeof PortfolioAsset>;

export const Portfolio = z.object({
  id: z.string(),
  name: z.string(),
  description: z.string().optional(),
  created_at: z.string().datetime(),
  updated_at: z.string().datetime(),
  
  // Assets in the portfolio
  assets: z.array(PortfolioAsset),
  
  // Portfolio-level settings
  base_currency: z.string().default('USD'),
  rebalance_frequency: z.enum(['daily', 'weekly', 'monthly', 'quarterly']).default('monthly'),
  risk_tolerance: RiskTier.default('balanced'),
  
  // Performance
  total_value: z.number().positive(),
  total_return: z.number(),
  sharpe_ratio: z.number().optional(),
  max_drawdown: z.number().min(0).max(1).optional(),
});

export type PortfolioT = z.infer<typeof Portfolio>;

// ========== Broker Integration ==========

export const BrokerConnectionStatus = z.enum(['connected', 'disconnected', 'error', 'authenticating']);

export const BrokerAccount = z.object({
  id: z.string(),
  broker: z.enum(['PAPER', 'OANDA', 'BINANCE', 'INTERACTIVE_BROKERS']),
  account_id: z.string(),
  name: z.string(),
  type: z.enum(['paper', 'demo', 'live']),
  status: BrokerConnectionStatus,
  
  // Account details
  base_currency: z.string(),
  balance: z.number().min(0),
  available_balance: z.number().min(0),
  margin_used: z.number().min(0).optional(),
  
  // Connection details
  connected_at: z.string().datetime().optional(),
  last_updated: z.string().datetime(),
  
  // Capabilities
  supports_streaming: z.boolean(),
  supports_options: z.boolean().optional(),
  supports_crypto: z.boolean().optional(),
  
  // Rate limits
  requests_per_minute: z.number().int().min(0).optional(),
  requests_remaining: z.number().int().min(0).optional(),
});

export type BrokerAccountT = z.infer<typeof BrokerAccount>;

export const OrderSide = z.enum(['BUY', 'SELL']);
export const OrderType = z.enum(['MARKET', 'LIMIT', 'STOP', 'STOP_LIMIT']);
export const OrderStatus = z.enum(['PENDING', 'FILLED', 'PARTIALLY_FILLED', 'CANCELLED', 'REJECTED']);

export const Order = z.object({
  id: z.string(),
  client_order_id: z.string().optional(),
  broker_order_id: z.string().optional(),
  account_id: z.string(),
  
  // Order details
  symbol: z.string(),
  side: OrderSide,
  type: OrderType,
  quantity: z.number().positive(),
  price: z.number().positive().optional(), // For limit orders
  stop_price: z.number().positive().optional(), // For stop orders
  
  // Status and execution
  status: OrderStatus,
  filled_quantity: z.number().min(0).default(0),
  average_fill_price: z.number().positive().optional(),
  
  // Timestamps
  created_at: z.string().datetime(),
  updated_at: z.string().datetime(),
  filled_at: z.string().datetime().optional(),
  
  // Additional info
  commission: z.number().min(0).optional(),
  slippage: z.number().min(0).optional(),
  error_message: z.string().optional(),
});

export type OrderT = z.infer<typeof Order>;

// ========== Helper Functions ==========

export function generateTraceId(): TraceIdT {
  const date = new Date().toISOString().slice(0, 10).replace(/-/g, '');
  const random = Math.random().toString(36).substring(2, 8);
  return `tr_${date}_${random}`;
}

export function validateEvent(event: unknown): HelioxEventT {
  return HelioxEvent.parse(event);
}

export function isValidTraceId(id: string): boolean {
  return TraceId.safeParse(id).success;
}

export function createStatusEvent(
  trace_id: TraceIdT,
  seq: number,
  stage: string,
  progress: number,
  message?: string,
  phase?: PhaseT
): HelioxEventT {
  return {
    type: 'status',
    trace_id,
    timestamp: new Date().toISOString(),
    seq,
    payload: { stage, progress, message, phase }
  };
}

export function createMetricEvent(
  trace_id: TraceIdT,
  seq: number,
  name: string,
  value: number,
  unit?: string,
  category?: 'performance' | 'risk' | 'trades' | 'portfolio'
): HelioxEventT {
  return {
    type: 'metric',
    trace_id,
    timestamp: new Date().toISOString(),
    seq,
    payload: { name, value, unit, category }
  };
}

export function createErrorEvent(
  trace_id: TraceIdT,
  seq: number,
  code: string,
  message: string,
  phase?: PhaseT,
  details?: Record<string, any>
): HelioxEventT {
  return {
    type: 'error',
    trace_id,
    timestamp: new Date().toISOString(),
    seq,
    payload: { code, message, phase, details }
  };
}

// ========== Validation Utilities ==========

export function validateBlueprint(blueprint: unknown): BlueprintT {
  return Blueprint.parse(blueprint);
}

export function validateBacktestResult(result: unknown): BacktestResultT {
  return BacktestResult.parse(result);
}

export function validateHSPManifest(manifest: unknown): HSPManifestT {
  return HSPManifest.parse(manifest);
}

// ========== Type Guards ==========

export function isStatusEvent(event: HelioxEventT): event is z.infer<typeof StatusEvent> {
  return event.type === 'status';
}

export function isMetricEvent(event: HelioxEventT): event is z.infer<typeof MetricEvent> {
  return event.type === 'metric';
}

export function isErrorEvent(event: HelioxEventT): event is z.infer<typeof ErrorEvent> {
  return event.type === 'error';
}

export function isFinalEvent(event: HelioxEventT): event is z.infer<typeof FinalEvent> {
  return event.type === 'final';
}

// ========== Constants ==========

export const SUPPORTED_PHASES: PhaseT[] = ['PHASE0', 'T0', 'T1', 'T2', 'T3', 'PACK'];
export const SUPPORTED_BROKERS = ['PAPER', 'OANDA', 'BINANCE', 'INTERACTIVE_BROKERS'] as const;
export const SUPPORTED_RISK_TIERS: RiskTierT[] = ['conservative', 'balanced', 'aggressive'];

export const DEFAULT_BACKTEST_CONFIG = {
  initial_capital: 100000,
  commission_rate: 0.001, // 0.1%
  slippage_bps: 5, // 5 basis points
  max_positions: 10,
} as const;

export const PHASE_DESCRIPTIONS: Record<PhaseT, string> = {
  'PHASE0': 'Initial strategy validation',
  'T0': 'Quick backtest (1 year)',
  'T1': 'Full backtest (5 years)',
  'T2': 'Walk-forward analysis',
  'T3': 'Monte Carlo simulation',
  'PACK': 'Package creation'
} as const;