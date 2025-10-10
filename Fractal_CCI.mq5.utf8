//+------------------------------------------------------------------+
//|                 Fractal CCI Indicator for MetaTrader 5           |
//|                     Fixed & Enhanced by Joy & Qwen               |
//|                        https://www.mql5.com/en/users/jhoe125     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Joy & Qwen"
#property link      "https://www.mql5.com/en/users/jhoe125"
#property version   "1.0"
#property description "Fractal with CCI Filter"


//--- indicator settings
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2
#property indicator_type1   DRAW_ARROW
#property indicator_type2   DRAW_ARROW
#property indicator_color1  clrRed
#property indicator_color2  clrGreen
#property indicator_label1  "Fractal Up"
#property indicator_label2  "Fractal Down"

//--- input parameters
input int CCI_Period = 7;       // CCI Period
input int CCI_Threshold = 110;  // CCI Threshold for Fractal

//--- indicator buffers
double ExtUpperBuffer[];
double ExtLowerBuffer[];
double ExtCCIBuffer[];

//--- 10 pixels upper from high price
int    ExtArrowShift=-10;

//--- handles
int cciHandle;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- CCI Handle
   cciHandle = iCCI(_Symbol, _Period, CCI_Period, PRICE_WEIGHTED);
   if (cciHandle == INVALID_HANDLE)
   {
      Print("Error CCI Handle Create");
      return(INIT_FAILED);
   }

   //--- set indicator buffers
   SetIndexBuffer(0, ExtUpperBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, ExtLowerBuffer, INDICATOR_DATA);
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);

   //--- sets first bar from what index will be drawn
   PlotIndexSetInteger(0,PLOT_ARROW,218);
   PlotIndexSetInteger(1,PLOT_ARROW,217);

   //--- arrow shifts when drawing
   PlotIndexSetInteger(0,PLOT_ARROW_SHIFT,ExtArrowShift);
   PlotIndexSetInteger(1,PLOT_ARROW_SHIFT,-ExtArrowShift);

   //--- set empty value
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, EMPTY_VALUE);

   //--- initialization done
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   //--- check for minimum data
   int min_bars = 5;
   if (rates_total < min_bars)
      return(0);

   int start;
   //--- clean up arrays
   if(prev_calculated<7)
     {
      start=2;
      ArrayInitialize(ExtUpperBuffer,EMPTY_VALUE);
      ArrayInitialize(ExtLowerBuffer,EMPTY_VALUE);
     }
   else
      start=rates_total-5;

   //--- Copy CCI values
   if (CopyBuffer(cciHandle, 0, 0, rates_total, ExtCCIBuffer) <= 0)
   {
      Print("Error CCI copy values");
      return(0);
   }

   //--- main cycle
   for (int i = start; i < rates_total - 2 && !IsStopped(); i++)
   {
      //--- Upper Fractal
      if (i >= 2 && high[i] > high[i-1] && high[i] > high[i-2] && high[i] >= high[i+1] && high[i] >= high[i+2] && ExtCCIBuffer[i] > CCI_Threshold)
         ExtUpperBuffer[i] = high[i];
      else
         ExtUpperBuffer[i] = EMPTY_VALUE;

      //--- Lower Fractal
      if (i >= 2 && low[i] < low[i-1] && low[i] < low[i-2] && low[i] <= low[i+1] && low[i] <= low[i+2] && ExtCCIBuffer[i] < -CCI_Threshold)
         ExtLowerBuffer[i] = low[i];
      else
         ExtLowerBuffer[i] = EMPTY_VALUE;
   }

   //--- return value of prev_calculated for next call
   return(rates_total);
}
//+------------------------------------------------------------------+