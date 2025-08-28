-- Sample runs for testing
insert into runs (id, status, prompt)
values ('b6c00000-0000-0000-0000-000000000001', 'COMPLETED', 'Create MA crossover strategy')
on conflict (id) do nothing;

-- Sample events for timeline
insert into run_events (run_id, seq, phase, type, payload)
values
  ('b6c00000-0000-0000-0000-000000000001', 1, 'architect', 'status', '{"msg":"Starting blueprint analysis"}'),
  ('b6c00000-0000-0000-0000-000000000001', 2, 'architect', 'artifact', '{"blueprint":{"universe":["XAUUSD","EURUSD"],"features":["SMA","EMA","RSI"],"constraints":{"risk_bp":50}}}'),
  ('b6c00000-0000-0000-0000-000000000001', 3, 'synth', 'status', '{"msg":"Generating strategy candidates"}'),
  ('b6c00000-0000-0000-0000-000000000001', 4, 'synth', 'artifact', '{"strategies":[{"name":"MA Cross","rules":["SMA(20) > SMA(50)"]},{"name":"EMA Trend","rules":["EMA(12) > EMA(26)"]}]}'),
  ('b6c00000-0000-0000-0000-000000000001', 5, 't0', 'status', '{"msg":"Running fast backtest"}'),
  ('b6c00000-0000-0000-0000-000000000001', 6, 't0', 'artifact', '{"equity":[100000,101500,103200],"trades":15,"sharpe":1.25}'),
  ('b6c00000-0000-0000-0000-000000000001', 7, 'pack', 'artifact', '{"hsp_url":"http://localhost:8080/download/strategy.hsp","manifest":{"version":"1.0","created":"2024-08-27T10:00:00Z"}}')
on conflict do nothing;

-- Sample portfolio items
insert into portfolio_items (name, strategy)
values 
  ('MA Crossover', '{"name":"MA Crossover","rules":["if SMA(20) > SMA(50) then BUY","if SMA(20) < SMA(50) then SELL"],"params":{"fast":20,"slow":50}}'),
  ('RSI Mean Reversion', '{"name":"RSI Mean Reversion","rules":["if RSI < 30 then BUY","if RSI > 70 then SELL"],"params":{"period":14,"oversold":30,"overbought":70}}')
on conflict do nothing;