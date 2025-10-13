//+------------------------------------------------------------------+
//|                                       Expert_FractalNeuro.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property description "Expert Advisor combining Fractal_CCI and Rock-Trader-Neuro signals."

//--- include the main expert class
#include <Expert\Expert.mqh>
#include <Expert\Signal\SignalFractalCCI.mqh>
#include <Expert\Signal\SignalRockTrader.mqh>

//--- Input Parameters
//--- General Trading
sinput "Expert Advisor Settings"        = "--- Trading ---";
input int      InpTakeProfitPoints      = 10;          // Take Profit (in points)
input int      InpStopLossPoints        = 2;           // Stop Loss (in points)
input double   InpLots                  = 0.1;         // Trade Volume
input int      InpMagicNumber           = 12345;       // Magic Number

//--- Fractal CCI Signal
sinput "Fractal CCI Settings"           = "--- Fractal CCI ---";
input int      InpCciPeriod             = 7;           // CCI Period
input int      InpCciThreshold          = 110;         // CCI Threshold for Fractal

//--- Rock Trader Neuro Signal
sinput "Rock Trader Neuro Settings"     = "--- Rock Trader Neuro ---";
//--- Bollinger Bands
sinput "Bollinger Bands"                = "BB Settings";
input int      InpBbPeriod              = 20;          // BB Period
input int      InpBbShift               = 0;           // BB Shift
input double   InpBbDeviation           = 2.0;         // BB Deviation
//--- Neuron Weights
sinput "Neuron Weights"                 = "Neuron Weights";
input double InpW0=0.8; input double InpW1=0.4; input double InpW2=-0.9;
input double InpW3=0.0; input double InpW4=0.7; input double InpW5=-0.2;
input double InpW6=0.9; input double InpW7=0.7; input double InpW8=-1.0;
input double InpW9=0.3; input double InpW10=0.5; input double InpW11=0.5;
input double InpW12=0.0; input double InpW13=1.0;

//+------------------------------------------------------------------+
//| CExpert_FractalNeuro class                                       |
//| This is the main EA class derived from CExpert.                  |
//+------------------------------------------------------------------+
class CExpert_FractalNeuro : public CExpert
  {
protected:
   CSignalFractalCCI *m_signal_fractal_cci;
   CSignalRockTrader *m_signal_rock_trader;

public:
                     CExpert_FractalNeuro(void);
                    ~CExpert_FractalNeuro(void);
   virtual bool      Init(void);
  };
//+------------------------------------------------------------------+
//| Global instance of the EA                                        |
//+------------------------------------------------------------------+
CExpert_FractalNeuro ExtExpert;
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CExpert_FractalNeuro::CExpert_FractalNeuro(void) : m_signal_fractal_cci(NULL), m_signal_rock_trader(NULL)
  {
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CExpert_FractalNeuro::~CExpert_FractalNeuro(void)
  {
  }
//+------------------------------------------------------------------+
//| Initialization method                                            |
//+------------------------------------------------------------------+
bool CExpert_FractalNeuro::Init(void)
  {
//--- call the base class Init() method
   if(!CExpert::Init())
      return(false);

//--- Set Trading Parameters ---
   if(!m_trade.SetExpertMagicNumber(InpMagicNumber)) return(false);
   if(!m_trade.SetMarginMode()) return(false);
   if(!m_money.SetLot(InpLots)) return(false);
   //--- Set TP/SL in points
   m_trade.SetProfitInPoints(true);
   m_trade.SetStopInPoints(true);
   if(!m_trade.SetTakeProfit(InpTakeProfitPoints)) return(false);
   if(!m_trade.SetStopLoss(InpStopLossPoints)) return(false);


//--- Create and add signals ---
   m_signal_fractal_cci = new CSignalFractalCCI;
   if(m_signal_fractal_cci == NULL)
     {
      printf("Error: failed to create CSignalFractalCCI object");
      return(false);
     }
   m_signal_fractal_cci.SetCciPeriod(InpCciPeriod);
   m_signal_fractal_cci.SetCciThreshold(InpCciThreshold);
   if(!m_signal.Add(m_signal_fractal_cci))
     {
      printf("Error: failed to add FractalCCI signal");
      return(false);
     }

   m_signal_rock_trader = new CSignalRockTrader;
   if(m_signal_rock_trader == NULL)
     {
      printf("Error: failed to create CSignalRockTrader object");
      return(false);
     }
   m_signal_rock_trader.SetBbPeriod(InpBbPeriod);
   m_signal_rock_trader.SetBbShift(InpBbShift);
   m_signal_rock_trader.SetBbDeviation(InpBbDeviation);
   double weights[14] = {InpW0, InpW1, InpW2, InpW3, InpW4, InpW5, InpW6, InpW7, InpW8, InpW9, InpW10, InpW11, InpW12, InpW13};
   m_signal_rock_trader.SetWeights(weights);
   if(!m_signal.Add(m_signal_rock_trader))
     {
      printf("Error: failed to add RockTrader signal");
      return(false);
     }

//--- Configure the signal filter to require both signals to agree ---
   m_signal.FilterEnable(true);
   m_signal.FilterMethod(FILTER_AND);

   return(true);
  }
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- initialize the expert
   if(!ExtExpert.Init())
      return(INIT_FAILED);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ExtExpert.Deinit();
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   ExtExpert.OnTick();
  }
//+------------------------------------------------------------------+
//| Expert timer function                                            |
//+------------------------------------------------------------------+
void OnTimer()
  {
   ExtExpert.OnTimer();
  }
//+------------------------------------------------------------------+
//| Expert trade function                                            |
//+------------------------------------------------------------------+
void OnTrade()
  {
   ExtExpert.OnTrade();
  }
//+------------------------------------------------------------------+
//| Expert book event function                                       |
//+------------------------------------------------------------------+
void OnBookEvent(const string &symbol)
  {
   ExtExpert.OnBookEvent(symbol);
  }
//+------------------------------------------------------------------+
