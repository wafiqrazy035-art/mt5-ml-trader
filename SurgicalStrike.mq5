//+------------------------------------------------------------------+
//|                                             SurgicalStrike.mq5   |
//|                                  Copyright 2026, Trading Bot     |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>

CTrade trade;

// Input Parameters
input int MA50_Period = 50;
input int MA200_Period = 200;
input int RSI_Period = 14;

int handleMA50, handleMA200, handleRSI;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    handleMA50 = iMA(_Symbol, _Period, MA50_Period, 0, MODE_SMA, PRICE_CLOSE);
    handleMA200 = iMA(_Symbol, _Period, MA200_Period, 0, MODE_SMA, PRICE_CLOSE);
    handleRSI = iRSI(_Symbol, _Period, RSI_Period, PRICE_CLOSE);
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
    double ma50[], ma200[], rsi[];
    ArraySetAsSeries(ma50, true);
    ArraySetAsSeries(ma200, true);
    ArraySetAsSeries(rsi, true);
    
    CopyBuffer(handleMA50, 0, 0, 1, ma50);
    CopyBuffer(handleMA200, 0, 0, 1, ma200);
    CopyBuffer(handleRSI, 0, 0, 1, rsi);

    // Logika Trading
    if(PositionsTotal() == 0) {
        if(ma50[0] > ma200[0] && rsi[0] < 35) {
            trade.Buy(0.1, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_ASK), 0, 0, "Buy Signal");
        }
        else if(ma50[0] < ma200[0] && rsi[0] > 65) {
            trade.Sell(0.1, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_BID), 0, 0, "Sell Signal");
        }
    }
}