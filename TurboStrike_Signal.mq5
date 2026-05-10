//+------------------------------------------------------------------+
//|                                     TurboStrike_Trend_Radar.mq5  |
//+------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2

#property indicator_label1  "Bullish Trend"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrLime
#property indicator_width1  2

#property indicator_label2  "Bearish Trend"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrRed
#property indicator_width2  2

input int MAPeriod = 50; 

double BuyBuffer[], SellBuffer[];

int OnInit() {
   SetIndexBuffer(0, BuyBuffer, INDICATOR_DATA);
   PlotIndexSetInteger(0, PLOT_ARROW, 233); // Panah ke atas
   
   SetIndexBuffer(1, SellBuffer, INDICATOR_DATA);
   PlotIndexSetInteger(1, PLOT_ARROW, 234); // Panah ke bawah
   
   return(INIT_SUCCEEDED);
}

int OnCalculate(const int rates_total, const int prev_calculated, const int begin, const double &price[]) {
   int handleMA = iMA(_Symbol, _Period, MAPeriod, 0, MODE_SMA, PRICE_CLOSE);
   double maBuffer[];
   
   // Mengambil data MA
   CopyBuffer(handleMA, 0, 0, rates_total, maBuffer);
   
   for(int i = 0; i < rates_total; i++) {
      // Selama harga DI ATAS MA, munculkan panah hijau (Tren Naik)
      if(price[i] > maBuffer[i]) {
         BuyBuffer[i] = price[i] + (50 * _Point); // Panah sedikit di atas candle
      }
      // Selama harga DI BAWAH MA, munculkan panah merah (Tren Turun)
      else if(price[i] < maBuffer[i]) {
         SellBuffer[i] = price[i] - (50 * _Point); // Panah sedikit di bawah candle
      }
   }
   return(rates_total);
}