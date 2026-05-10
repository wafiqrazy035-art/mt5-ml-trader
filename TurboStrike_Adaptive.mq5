#include <Trade\Trade.mqh>
CTrade trade;

// --- Input Parameters ---
input string AdaptiveIndicator = "TurboStrike_Adaptive.ex5";
input double LotSize           = 0.1;
input int    StopLoss_Pips     = 25;
input int    TakeProfit_Pips   = 75;
input int    ADX_Threshold     = 20;
input int    StartHour         = 8;
input int    EndHour           = 20;

int handleAdaptive, handleADX, handleRSI;

int OnInit() {
   handleAdaptive = iCustom(_Symbol, _Period, AdaptiveIndicator);
   handleADX      = iADX(_Symbol, _Period, 14);
   handleRSI      = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);
   
   if(handleAdaptive == INVALID_HANDLE) return(INIT_FAILED);
   return(INIT_SUCCEEDED);
}

void OnTick() {
   if(PositionsTotal() > 0) return; // Hanya 1 posisi aktif
   if(!IsTradingTime()) return;

   double bull[], bear[], adx[], rsi[];
   ArraySetAsSeries(bull, true); 
   ArraySetAsSeries(bear, true);
   ArraySetAsSeries(adx, true);
   ArraySetAsSeries(rsi, true);

   // Ambil data candle saat ini [0] dan candle sebelumnya [1]
   if(CopyBuffer(handleAdaptive, 0, 0, 2, bull) < 2) return;
   if(CopyBuffer(handleAdaptive, 1, 0, 2, bear) < 2) return;
   CopyBuffer(handleADX, 0, 0, 1, adx);
   CopyBuffer(handleRSI, 0, 0, 1, rsi);

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double pt = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   int mult = (SymbolInfoInteger(_Symbol, SYMBOL_DIGITS) == 5) ? 10 : 1;

   // --- LOGIKA CROSSOVER (SINKRON DENGAN INDIKATOR ANDA) ---
   
   // Syarat BUY: 
   // 1. Sekarang Bullish (bull[0] ada nilainya)
   // 2. SEBELUMNYA Bearish (bull[1] adalah EMPTY_VALUE) -> Ini berarti baru saja crossing!
   bool isBuySignal = (bull[0] != EMPTY_VALUE && bull[1] == EMPTY_VALUE);
   
   // Syarat SELL:
   // 1. Sekarang Bearish (bear[0] ada nilainya)
   // 2. SEBELUMNYA Bullish (bear[1] adalah EMPTY_VALUE)
   bool isSellSignal = (bear[0] != EMPTY_VALUE && bear[1] == EMPTY_VALUE);

   // Eksekusi dengan Filter Tambahan
   if(isBuySignal && adx[0] > ADX_Threshold && rsi[0] < 65) {
      double sl = ask - (StopLoss_Pips * pt * mult);
      double tp = ask + (TakeProfit_Pips * pt * mult);
      trade.Buy(LotSize, _Symbol, ask, sl, tp, "Crossover Buy");
   }
   else if(isSellSignal && adx[0] > ADX_Threshold && rsi[0] > 35) {
      double sl = bid + (StopLoss_Pips * pt * mult);
      double tp = bid - (TakeProfit_Pips * pt * mult);
      trade.Sell(LotSize, _Symbol, bid, sl, tp, "Crossover Sell");
   }
}

bool IsTradingTime() {
   MqlDateTime dt;
   TimeCurrent(dt);
   return (dt.hour >= StartHour && dt.hour < EndHour);
}