// contracts/shared/index.ts
// Barrel export for all shared contracts and utilities

// Core types
export * from './types.js';

// Validation utilities
export * from './validators.js';

// Re-export zod for convenience
export { z } from 'zod';

// Version and metadata
export const CONTRACTS_VERSION = '1.0.0';
export const CONTRACTS_LAST_UPDATED = '2024-08-27';

// Compatibility info
export const SUPPORTED_API_VERSIONS = ['v1'] as const;
export const MINIMUM_NODE_VERSION = '20.0.0';
export const MINIMUM_TYPESCRIPT_VERSION = '5.0.0';

// Common constants
export const COMMON_CONSTANTS = {
  MAX_PROMPT_LENGTH: 4000,
  DEFAULT_TIMEOUT_MS: 120000, // 2 minutes
  MAX_BACKTEST_YEARS: 10,
  MIN_BACKTEST_TRADES: 10,
  MAX_PORTFOLIO_ASSETS: 50,
  MAX_EVENT_BATCH_SIZE: 100,
} as const;

// Error codes
export const ERROR_CODES = {
  // Validation errors
  INVALID_TRACE_ID: 'INVALID_TRACE_ID',
  INVALID_EVENT_FORMAT: 'INVALID_EVENT_FORMAT', 
  INVALID_STRATEGY_FORMAT: 'INVALID_STRATEGY_FORMAT',
  INVALID_BACKTEST_FORMAT: 'INVALID_BACKTEST_FORMAT',
  
  // Business logic errors
  STRATEGY_TOO_COMPLEX: 'STRATEGY_TOO_COMPLEX',
  INSUFFICIENT_TRADES: 'INSUFFICIENT_TRADES',
  PORTFOLIO_ALLOCATION_INVALID: 'PORTFOLIO_ALLOCATION_INVALID',
  RISK_CONSTRAINTS_VIOLATED: 'RISK_CONSTRAINTS_VIOLATED',
  
  // System errors
  DATABASE_CONNECTION_FAILED: 'DATABASE_CONNECTION_FAILED',
  BROKER_CONNECTION_FAILED: 'BROKER_CONNECTION_FAILED',
  LLM_REQUEST_FAILED: 'LLM_REQUEST_FAILED',
  STORAGE_ACCESS_FAILED: 'STORAGE_ACCESS_FAILED',
  
  // Rate limiting
  RATE_LIMIT_EXCEEDED: 'RATE_LIMIT_EXCEEDED',
  QUOTA_EXCEEDED: 'QUOTA_EXCEEDED',
  
  // Authentication/Authorization
  AUTHENTICATION_FAILED: 'AUTHENTICATION_FAILED',
  AUTHORIZATION_FAILED: 'AUTHORIZATION_FAILED',
  API_KEY_INVALID: 'API_KEY_INVALID',
  
  // Resource errors
  RESOURCE_NOT_FOUND: 'RESOURCE_NOT_FOUND',
  RESOURCE_ALREADY_EXISTS: 'RESOURCE_ALREADY_EXISTS',
  RESOURCE_LOCKED: 'RESOURCE_LOCKED',
  
} as const;

// HTTP status codes mapping
export const STATUS_CODE_MAPPING = {
  [ERROR_CODES.INVALID_TRACE_ID]: 400,
  [ERROR_CODES.INVALID_EVENT_FORMAT]: 400,
  [ERROR_CODES.INVALID_STRATEGY_FORMAT]: 400,
  [ERROR_CODES.INVALID_BACKTEST_FORMAT]: 400,
  [ERROR_CODES.STRATEGY_TOO_COMPLEX]: 422,
  [ERROR_CODES.INSUFFICIENT_TRADES]: 422,
  [ERROR_CODES.PORTFOLIO_ALLOCATION_INVALID]: 422,
  [ERROR_CODES.RISK_CONSTRAINTS_VIOLATED]: 422,
  [ERROR_CODES.DATABASE_CONNECTION_FAILED]: 503,
  [ERROR_CODES.BROKER_CONNECTION_FAILED]: 503,
  [ERROR_CODES.LLM_REQUEST_FAILED]: 503,
  [ERROR_CODES.STORAGE_ACCESS_FAILED]: 503,
  [ERROR_CODES.RATE_LIMIT_EXCEEDED]: 429,
  [ERROR_CODES.QUOTA_EXCEEDED]: 429,
  [ERROR_CODES.AUTHENTICATION_FAILED]: 401,
  [ERROR_CODES.AUTHORIZATION_FAILED]: 403,
  [ERROR_CODES.API_KEY_INVALID]: 401,
  [ERROR_CODES.RESOURCE_NOT_FOUND]: 404,
  [ERROR_CODES.RESOURCE_ALREADY_EXISTS]: 409,
  [ERROR_CODES.RESOURCE_LOCKED]: 423,
} as const;

// Helper type for error responses
export interface ErrorResponse {
  error: {
    code: keyof typeof ERROR_CODES;
    message: string;
    details?: Record<string, any>;
    timestamp: string;
    trace_id?: string;
  };
}

// Helper type for success responses
export interface SuccessResponse<T = any> {
  data: T;
  timestamp: string;
  trace_id?: string;
}

// Pagination types
export interface PaginationParams {
  page?: number;
  limit?: number;
  cursor?: string;
}

export interface PaginatedResponse<T> extends SuccessResponse<T[]> {
  pagination: {
    page: number;
    limit: number;
    total: number;
    has_next: boolean;
    has_prev: boolean;
    next_cursor?: string;
    prev_cursor?: string;
  };
}

// Utility functions for common operations
export const createErrorResponse = (
  code: keyof typeof ERROR_CODES,
  message: string,
  details?: Record<string, any>,
  trace_id?: string
): ErrorResponse => ({
  error: {
    code,
    message,
    details,
    timestamp: new Date().toISOString(),
    trace_id,
  },
});

export const createSuccessResponse = <T>(
  data: T,
  trace_id?: string
): SuccessResponse<T> => ({
  data,
  timestamp: new Date().toISOString(),
  trace_id,
});

// Type guards for response types
export const isErrorResponse = (response: any): response is ErrorResponse => {
  return response && typeof response === 'object' && 'error' in response;
};

export const isSuccessResponse = (response: any): response is SuccessResponse => {
  return response && typeof response === 'object' && 'data' in response;
};

// Utility for safe JSON parsing with types
export const safeJsonParse = <T>(
  json: string,
  schema: z.ZodSchema<T>
): { success: true; data: T } | { success: false; error: string } => {
  try {
    const parsed = JSON.parse(json);
    const validated = schema.parse(parsed);
    return { success: true, data: validated };
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown parsing error';
    return { success: false, error: message };
  }
};

// Utility for safe async operations with error handling
export const safeAsync = async <T>(
  operation: () => Promise<T>
): Promise<{ success: true; data: T } | { success: false; error: string }> => {
  try {
    const data = await operation();
    return { success: true, data };
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown async error';
    return { success: false, error: message };
  }
};

// Default configurations for different environments
export const DEFAULT_CONFIGS = {
  development: {
    api_timeout_ms: 30000,
    max_retries: 3,
    log_level: 'debug',
    enable_mock_brokers: true,
  },
  staging: {
    api_timeout_ms: 60000,
    max_retries: 5,
    log_level: 'info',
    enable_mock_brokers: false,
  },
  production: {
    api_timeout_ms: 120000,
    max_retries: 3,
    log_level: 'warn',
    enable_mock_brokers: false,
  },
} as const;

// Runtime environment detection
export const detectEnvironment = (): keyof typeof DEFAULT_CONFIGS => {
  const env = process?.env?.NODE_ENV || 'development';
  return env === 'production' || env === 'staging' ? env : 'development';
};

export const getCurrentConfig = () => {
  const env = detectEnvironment();
  return DEFAULT_CONFIGS[env];
};

// Type-safe event emitter types for the system
export interface HelioxEvents {
  'run.created': { trace_id: string; request: any };
  'run.started': { trace_id: string; phase: string };
  'run.progress': { trace_id: string; progress: number; phase: string };
  'run.completed': { trace_id: string; result: any };
  'run.failed': { trace_id: string; error: string; phase?: string };
  'strategy.generated': { trace_id: string; blueprint: any };
  'backtest.completed': { trace_id: string; results: any };
  'portfolio.updated': { portfolio_id: string; changes: any };
  'broker.connected': { account_id: string; broker: string };
  'broker.disconnected': { account_id: string; broker: string; reason?: string };
  'order.placed': { order_id: string; account_id: string };
  'order.filled': { order_id: string; fill_details: any };
}

// Export all types for external use
export type {
  // Core types
  TraceIdT,
  PhaseT,
  RunStatusT,
  RiskTierT,
  HelioxEventT,
  CreateRunRequestT,
  CreateRunResponseT,
  GetRunResponseT,
  BlueprintT,
  BacktestResultT,
  BacktestMetricsT,
  HSPManifestT,
  PortfolioT,
  PortfolioAssetT,
  BrokerAccountT,
  OrderT,
  TradeT,
  
  // Validation types
  ValidationResult,
  
  // Component types from individual schemas
} from './types.js';

export type {
  ValidationError,
  BusinessRuleError,
} from './validators.js';