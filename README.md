# MT5 ML Trader — MQL5 Expert Advisors with ONNX Integration

A suite of MetaTrader 5 Expert Advisors combining classical technical analysis 
with machine learning models via ONNX runtime.

## Files

### EURUSD_AI_Trader.mq5
The most advanced EA — loads an external ONNX model directly into MT5 for 
real-time prediction. Features:
- ONNX model integration (OnnxCreate, OnnxRun)
- 7 input features: log returns, RSI, ATR, MA50/200, ATR ratio
- Probability threshold filter (>0.65) for signal quality
- Connects Python-trained ML model to live MT5 execution

### TurboStrike Suite
Multi-file EA architecture:
- **TurboStrike_Signal.mq5** — Custom indicator generating bull/bear signals
- **TurboStrike_Adaptive.mq5** — Adaptive version with dynamic parameters  
- **TurboStrike_EA.mq5** — Main EA with ADX + RSI filter + trailing stop

### SurgicalStrike.mq5
Precision entry EA with strict signal filtering for lower trade frequency 
but higher quality entries.

## Key Technical Features
- ONNX runtime integration (rare in retail MT5 development)
- ADX trend strength filter
- RSI overbought/oversold confirmation
- Trailing stop management
- Trading session time filter (configurable hours)
- Multi-buffer custom indicator reading

## Stack
- MQL5 (MetaTrader 5)
- ONNX Runtime (MT5 built-in)
- Python (for model training, exported to .onnx)

## Note
ONNX integration in MT5 is notoriously difficult — 
input shape configuration and OnnxRun parameter handling 
required significant debugging to resolve.
