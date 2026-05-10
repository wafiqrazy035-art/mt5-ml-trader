#include <Trade\Trade.mqh>
CTrade trade;

// --- Input Parameters ---
input string AdaptiveIndicator = "TurboStrike_Adaptive.ex5";
input double LotSize           = 0.1;
input int    StopLoss_Pips     = 25;
input int    TakeProfit_Pips   = 75;
input int    TrailingStop_Pips = 40;
input int    ADX_Threshold     = 20; // Ditingkatkan sedikit
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

bool IsTradingTime() {
   MqlDateTime dt;
   TimeCurrent(dt);
   return (dt.hour >= StartHour && dt.hour < EndHour);
}

void OnTick() {
   // 1. Manage Trailing Stop tetap jalan
   ManageTrailingStop();
   
   // 2. Filter Waktu & Cek Posisi (Maksimal 1 posisi)
   if(!IsTradingTime()) return;
   if(PositionsTotal() > 0) return;
   
   double bull[], bear[], adx[], rsi[];
   ArraySetAsSeries(bull, true); ArraySetAsSeries(bear, true);
   ArraySetAsSeries(adx, true);  ArraySetAsSeries(rsi, true);
   
   // Ambil 2 bar untuk memastikan sinyal stabil
   if(CopyBuffer(handleAdaptive, 0, 0, 2, bull) < 2) return;
   if(CopyBuffer(handleAdaptive, 1, 0, 2, bear) < 2) return;
   CopyBuffer(handleADX, 0, 0, 2, adx);
   CopyBuffer(handleRSI, 0, 0, 2, rsi);

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double pt = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   int mult = (SymbolInfoInteger(_Symbol, SYMBOL_DIGITS) == 5) ? 10 : 1;

   // --- LOGIKA ENTRY YANG DIPERBAIKI ---
   // Cek apakah trend kuat (ADX) DAN RSI mendukung
   bool isTrendStrong = (adx[0] > ADX_Threshold);
   
   // Sinyal Buy: Buffer bull biasanya berisi harga (bukan sekedar > 0)
   // Kita cek apakah nilainya valid (bukan EMPTY_VALUE atau 0)
   if(bull[0] != 0 && bull[0] != EMPTY_VALUE) {
      if(isTrendStrong && rsi[0] < 65) { // Gunakan AND (&&), bukan OR (||)
         double sl = ask - (StopLoss_Pips * pt * mult);
         double tp = ask + (TakeProfit_Pips * pt * mult);
         trade.Buy(LotSize, _Symbol, ask, sl, tp, "Smart Buy");
      }
   }
   
   // Sinyal Sell
   else if(bear[0] != 0 && bear[0] != EMPTY_VALUE) {
      if(isTrendStrong && rsi[0] > 35) { // Gunakan AND (&&)
         double sl = bid + (StopLoss_Pips * pt * mult);
         double tp = bid - (TakeProfit_Pips * pt * mult);
         trade.Sell(LotSize, _Symbol, bid, sl, tp, "Smart Sell");
      }
   }
}

void ManageTrailingStop() {
   for(int i=PositionsTotal()-1; i>=0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket)) {
         if(PositionGetInteger(POSITION_MAGIC) != 0) continue; // Hanya urus posisi EA ini
         
         double pt = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
         int mult = (SymbolInfoInteger(_Symbol, SYMBOL_DIGITS) == 5) ? 10 : 1;
         double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         double currentSL = PositionGetDouble(POSITION_SL);
         double tp = PositionGetDouble(POSITION_TP);
         
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
            double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            if(bid - openPrice > (TrailingStop_Pips * pt * mult)) {
               double newSL = bid - (TrailingStop_Pips * pt * mult);
               if(newSL > currentSL) trade.PositionModify(ticket, newSL, tp);
            }
         }
         else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
            double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            if(openPrice - ask > (TrailingStop_Pips * pt * mult)) {
               double newSL = ask + (TrailingStop_Pips * pt * mult);
               if(newSL < currentSL || currentSL == 0) trade.PositionModify(ticket, newSL, tp);
            }
         }
      }
   }
}