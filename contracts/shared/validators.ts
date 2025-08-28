// contracts/shared/validators.ts
// Validation helpers and custom validators for Heliox system

import { z } from 'zod';
import type {
  TraceIdT,
  HelioxEventT,
  BlueprintT,
  BacktestResultT,
  HSPManifestT,
  CreateRunRequestT,
  OrderT,
  PortfolioT
} from './types.js';

// ========== Custom Validation Errors ==========

export class ValidationError extends Error {
  constructor(
    message: string,
    public field: string,
    public code: string,
    public details?: Record<string, any>
  ) {
    super(message);
    this.name = 'ValidationError';
  }
}

export class BusinessRuleError extends Error {
  constructor(
    message: string,
    public rule: string,
    public context?: Record<string, any>
  ) {
    super(message);
    this.name = 'BusinessRuleError';
  }
}

// ========== URL and URI Validators ==========

export const validateS3Uri = (uri: string): boolean => {
  const s3UriRegex = /^s3:\/\/[a-z0-9][a-z0-9.-]*[a-z0-9]\/.+$/;
  return s3UriRegex.test(uri);
};

export const validateMinioUri = (uri: string): boolean => {
  const minioUriRegex = /^minio:\/\/[a-z0-9][a-z0-9.-]*[a-z0-9]\/.+$/;
  return minioUriRegex.test(uri);
};

export const validateStorageUri = (uri: string): boolean => {
  return validateS3Uri(uri) || validateMinioUri(uri) || uri.startsWith('file://');
};

// ========== Financial Validators ==========

export const validateSymbol = (symbol: string): boolean => {
  // Basic validation for trading symbols
  const symbolRegex = /^[A-Z]{1,6}([_-][A-Z]{1,6})?$/;
  return symbolRegex.test(symbol);
};

export const validatePrice = (price: number): boolean => {
  return price > 0 && price < 1000000 && Number.isFinite(price);
};

export const validateQuantity = (quantity: number): boolean => {
  return quantity > 0 && Number.isFinite(quantity);
};

export const validatePercentage = (value: number): boolean => {
  return value >= 0 && value <= 1 && Number.isFinite(value);
};

// ========== Timeframe Validators ==========

export const VALID_TIMEFRAMES = [
  '1m', '5m', '15m', '30m', 
  '1h', '2h', '4h', '6h', '8h', '12h',
  '1d', '3d', '1w', '1M'
] as const;

export const validateTimeframe = (timeframe: string): boolean => {
  return VALID_TIMEFRAMES.includes(timeframe as any);
};

export const validateDateRange = (start: string, end: string): boolean => {
  const startDate = new Date(start);
  const endDate = new Date(end);
  return startDate.getTime() < endDate.getTime() && 
         endDate.getTime() <= Date.now();
};

// ========== Event Sequence Validators ==========

export const validateEventSequence = (events: HelioxEventT[]): boolean => {
  if (events.length === 0) return true;
  
  // Check same trace_id
  const traceId = events[0].trace_id;
  if (!events.every(e => e.trace_id === traceId)) {
    return false;
  }
  
  // Check sequence numbers are increasing
  for (let i = 1; i < events.length; i++) {
    if (events[i].seq <= events[i-1].seq) {
      return false;
    }
  }
  
  // Check timestamps are increasing
  for (let i = 1; i < events.length; i++) {
    const prev = new Date(events[i-1].timestamp);
    const curr = new Date(events[i].timestamp);
    if (curr.getTime() < prev.getTime()) {
      return false;
    }
  }
  
  return true;
};

// ========== Strategy Validators ==========

export const validateStrategyComplexity = (blueprint: BlueprintT): number => {
  let complexity = 1;
  
  // Add complexity based on number of indicators
  complexity += Math.min(blueprint.indicators.length * 0.5, 3);
  
  // Add complexity based on number of rules
  complexity += Math.min(blueprint.rules.length * 0.3, 2);
  
  // Add complexity for multiple timeframes
  if (blueprint.timeframes.length > 1) {
    complexity += blueprint.timeframes.length * 0.2;
  }
  
  // Add complexity for multiple assets
  if (blueprint.assets.length > 1) {
    complexity += Math.min(blueprint.assets.length * 0.1, 1);
  }
  
  // Cap at 10
  return Math.min(Math.round(complexity), 10);
};

export const validateRiskConstraints = (constraints: BlueprintT['constraints']): string[] => {
  const errors: string[] = [];
  
  if (constraints.max_position_size > 0.5) {
    errors.push('Maximum position size should not exceed 50% of portfolio');
  }
  
  if (constraints.stop_loss && constraints.stop_loss > 0.2) {
    errors.push('Stop loss should not exceed 20%');
  }
  
  if (constraints.max_daily_loss && constraints.max_daily_loss > 0.1) {
    errors.push('Maximum daily loss should not exceed 10%');
  }
  
  if (constraints.max_drawdown && constraints.max_drawdown > 0.3) {
    errors.push('Maximum drawdown should not exceed 30%');
  }
  
  return errors;
};

// ========== Backtest Validators ==========

export const validateBacktestMetrics = (metrics: BacktestResultT['metrics']): string[] => {
  const errors: string[] = [];
  
  if (metrics.sharpe_ratio < -5 || metrics.sharpe_ratio > 10) {
    errors.push('Sharpe ratio is outside reasonable range (-5 to 10)');
  }
  
  if (metrics.max_drawdown > 0.8) {
    errors.push('Maximum drawdown exceeds 80% - strategy may be too risky');
  }
  
  if (metrics.total_trades < 10) {
    errors.push('Insufficient trade sample size (< 10 trades)');
  }
  
  if (metrics.win_rate > 0.95) {
    errors.push('Win rate suspiciously high (> 95%) - check for data issues');
  }
  
  if (metrics.profit_factor > 50) {
    errors.push('Profit factor suspiciously high (> 50) - check for data issues');
  }
  
  return errors;
};

export const validateEquityCurve = (curve: BacktestResultT['equity_curve']): string[] => {
  const errors: string[] = [];
  
  if (curve.length < 2) {
    errors.push('Equity curve must have at least 2 data points');
  }
  
  // Check for negative values
  const negativeValues = curve.filter(point => point.value <= 0);
  if (negativeValues.length > 0) {
    errors.push(`Found ${negativeValues.length} negative or zero equity values`);
  }
  
  // Check for time sequence
  for (let i = 1; i < curve.length; i++) {
    const prevTime = new Date(curve[i-1].timestamp).getTime();
    const currTime = new Date(curve[i].timestamp).getTime();
    if (currTime <= prevTime) {
      errors.push(`Equity curve timestamps not in ascending order at index ${i}`);
      break;
    }
  }
  
  return errors;
};

// ========== Portfolio Validators ==========

export const validatePortfolioAllocation = (portfolio: PortfolioT): string[] => {
  const errors: string[] = [];
  
  const totalAllocation = portfolio.assets.reduce((sum, asset) => 
    sum + asset.allocation_percent, 0
  );
  
  if (Math.abs(totalAllocation - 100) > 0.01) {
    errors.push(`Portfolio allocation sums to ${totalAllocation.toFixed(2)}% instead of 100%`);
  }
  
  // Check individual allocations
  portfolio.assets.forEach((asset, index) => {
    if (asset.allocation_percent <= 0) {
      errors.push(`Asset ${index} has non-positive allocation`);
    }
    
    if (asset.allocation_percent > 50) {
      errors.push(`Asset ${index} allocation exceeds 50% - concentration risk`);
    }
    
    if (asset.max_allocation_percent && 
        asset.allocation_percent > asset.max_allocation_percent) {
      errors.push(`Asset ${index} allocation exceeds its maximum limit`);
    }
  });
  
  return errors;
};

// ========== Order Validators ==========

export const validateOrder = (order: OrderT): string[] => {
  const errors: string[] = [];
  
  if (!validateSymbol(order.symbol)) {
    errors.push('Invalid trading symbol format');
  }
  
  if (!validateQuantity(order.quantity)) {
    errors.push('Invalid order quantity');
  }
  
  if (order.price && !validatePrice(order.price)) {
    errors.push('Invalid order price');
  }
  
  if (order.stop_price && !validatePrice(order.stop_price)) {
    errors.push('Invalid stop price');
  }
  
  // Validate price relationships
  if (order.type === 'STOP_LIMIT' && order.price && order.stop_price) {
    if (order.side === 'BUY' && order.price < order.stop_price) {
      errors.push('For buy stop-limit orders, limit price must be >= stop price');
    }
    if (order.side === 'SELL' && order.price > order.stop_price) {
      errors.push('For sell stop-limit orders, limit price must be <= stop price');
    }
  }
  
  return errors;
};

// ========== HSP Validators ==========

export const validateHSPIntegrity = async (
  manifest: HSPManifestT, 
  calculateChecksum: (data: string) => Promise<string>
): Promise<boolean> => {
  try {
    // Create a copy without the checksum field
    const { checksum, ...manifestWithoutChecksum } = manifest;
    
    // Calculate checksum of the manifest data
    const manifestData = JSON.stringify(manifestWithoutChecksum, null, 2);
    const calculatedChecksum = await calculateChecksum(manifestData);
    
    return calculatedChecksum === checksum;
  } catch (error) {
    return false;
  }
};

// ========== Request Validators ==========

export const validateCreateRunRequest = (request: CreateRunRequestT): string[] => {
  const errors: string[] = [];
  
  if (request.prompt.trim().length < 10) {
    errors.push('Prompt must be at least 10 characters long');
  }
  
  if (request.prompt.length > 4000) {
    errors.push('Prompt exceeds maximum length of 4000 characters');
  }
  
  if (request.options) {
    if (request.options.temperature < 0 || request.options.temperature > 2) {
      errors.push('Temperature must be between 0 and 2');
    }
    
    if (request.options.max_iterations < 1 || request.options.max_iterations > 100) {
      errors.push('Max iterations must be between 1 and 100');
    }
    
    if (request.options.timeout_minutes < 1 || request.options.timeout_minutes > 60) {
      errors.push('Timeout must be between 1 and 60 minutes');
    }
  }
  
  return errors;
};

// ========== Safe Parsing Functions ==========

export const safeParseTraceId = (value: unknown): { success: true; data: TraceIdT } | { success: false; error: string } => {
  try {
    const result = z.string().regex(/^tr_\d{8}_[a-z0-9]{6}$/).parse(value);
    return { success: true, data: result };
  } catch (error) {
    return { success: false, error: error instanceof Error ? error.message : 'Invalid trace ID format' };
  }
};

export const safeParseEvent = (value: unknown): { success: true; data: HelioxEventT } | { success: false; error: string } => {
  try {
    // Import the HelioxEvent schema from types.ts
    const { HelioxEvent } = await import('./types.js');
    const result = HelioxEvent.parse(value);
    return { success: true, data: result };
  } catch (error) {
    return { success: false, error: error instanceof Error ? error.message : 'Invalid event format' };
  }
};

// ========== Validation Pipeline ==========

export interface ValidationResult {
  valid: boolean;
  errors: string[];
  warnings: string[];
  metadata?: Record<string, any>;
}

export const validateStrategy = async (blueprint: BlueprintT): Promise<ValidationResult> => {
  const errors: string[] = [];
  const warnings: string[] = [];
  
  // Basic structure validation (already done by Zod)
  
  // Business rule validation
  const riskErrors = validateRiskConstraints(blueprint.constraints);
  errors.push(...riskErrors);
  
  // Complexity analysis
  const complexity = validateStrategyComplexity(blueprint);
  if (complexity > 8) {
    warnings.push(`Strategy complexity is high (${complexity}/10) - consider simplifying`);
  }
  
  // Symbol validation
  blueprint.assets.forEach((symbol, index) => {
    if (!validateSymbol(symbol)) {
      errors.push(`Invalid symbol format at index ${index}: ${symbol}`);
    }
  });
  
  // Timeframe validation
  blueprint.timeframes.forEach((tf, index) => {
    if (!validateTimeframe(tf)) {
      errors.push(`Invalid timeframe at index ${index}: ${tf}`);
    }
  });
  
  return {
    valid: errors.length === 0,
    errors,
    warnings,
    metadata: {
      complexity,
      indicatorCount: blueprint.indicators.length,
      ruleCount: blueprint.rules.length
    }
  };
};

export const validateBacktest = async (result: BacktestResultT): Promise<ValidationResult> => {
  const errors: string[] = [];
  const warnings: string[] = [];
  
  // Metrics validation
  const metricErrors = validateBacktestMetrics(result.metrics);
  errors.push(...metricErrors);
  
  // Equity curve validation
  const curveErrors = validateEquityCurve(result.equity_curve);
  errors.push(...curveErrors);
  
  // Performance warnings
  if (result.metrics.sharpe_ratio < 0.5) {
    warnings.push('Low Sharpe ratio - strategy may not be profitable after risk adjustment');
  }
  
  if (result.metrics.max_drawdown > 0.2) {
    warnings.push('High maximum drawdown - consider additional risk controls');
  }
  
  if (result.metrics.total_trades < 50) {
    warnings.push('Low trade count - results may not be statistically significant');
  }
  
  return {
    valid: errors.length === 0,
    errors,
    warnings,
    metadata: {
      tradeDensity: result.metrics.total_trades / 
        ((new Date(result.period_end).getTime() - new Date(result.period_start).getTime()) / (1000 * 60 * 60 * 24)),
      avgTradeSize: result.metrics.total_trades > 0 ? 
        result.final_capital / result.initial_capital / result.metrics.total_trades : 0
    }
  };
};