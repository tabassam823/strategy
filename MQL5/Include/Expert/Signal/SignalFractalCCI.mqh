//+------------------------------------------------------------------+
//|                                           SignalFractalCCI.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"

#ifndef EXPERT_SIGNAL_SIGNALFRACTALCCI_MQH
#define EXPERT_SIGNAL_SIGNALFRACTALCCI_MQH

#include "ExpertSignal.mqh"

//+------------------------------------------------------------------+
//| CSignalFractalCCI class                                          |
//| Purpose: Class for generation of trade signals based on          |
//|          the 'Fractals' and 'CCI' indicators.                    |
//+------------------------------------------------------------------+
class CSignalFractalCCI : public CExpertSignal
  {
protected:
   //--- indicator handles
   int               m_cci_handle;
   //--- indicator buffers
   double            m_cci_buffer[];
   //--- input parameters
   int               m_cci_period;      // CCI Period
   double            m_cci_threshold;   // CCI Threshold
   //--- internal state
   bool              m_initialized;

public:
                     CSignalFractalCCI();
                    ~CSignalFractalCCI();
   //--- settings
   void              SetCciPeriod(int period)              { m_cci_period=period;       }
   void              SetCciThreshold(double threshold)     { m_cci_threshold=threshold; }
   //--- validation and initialization
   virtual bool      ValidationSettings();
   virtual bool      InitIndicators(CIndicators *indicators);
   //--- signal checks
   virtual int       LongCondition(const int shift);
   virtual int       ShortCondition(const int shift);

protected:
   bool              InitCCI(CIndicators *indicators);
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSignalFractalCCI::CSignalFractalCCI() :
   m_cci_handle(INVALID_HANDLE),
   m_cci_period(7),
   m_cci_threshold(110.0),
   m_initialized(false)
  {
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSignalFractalCCI::~CSignalFractalCCI()
  {
  }
//+------------------------------------------------------------------+
//| Validation of settings                                           |
//+------------------------------------------------------------------+
bool CSignalFractalCCI::ValidationSettings()
  {
   if(!CExpertSignal::ValidationSettings())
      return(false);
//--- validation of inputs
   if(m_cci_period<=0)
     {
      printf("Error: CCI Period in SignalFractalCCI must be greater than 0.");
      return(false);
     }
   if(m_cci_threshold<=0)
     {
      printf("Error: CCI Threshold in SignalFractalCCI must be greater than 0.");
      return(false);
     }
   return(true);
  }
//+------------------------------------------------------------------+
//| Initialize indicators                                            |
//+------------------------------------------------------------------+
bool CSignalFractalCCI::InitIndicators(CIndicators *indicators)
  {
   if(indicators==NULL)
      return(false);
//--- initialization of indicators and series
   if(!CExpertSignal::InitIndicators(indicators))
      return(false);
//--- create and initialize CCI
   if(!InitCCI(indicators))
      return(false);
//--- ok
   m_initialized=true;
   return(true);
  }
//+------------------------------------------------------------------+
//| Initialize CCI indicator                                         |
//+------------------------------------------------------------------+
bool CSignalFractalCCI::InitCCI(CIndicators *indicators)
  {
//--- add indicator
   m_cci_handle=indicators.Add(m_symbol.Name(),m_period,IND_CCI,m_cci_period,PRICE_WEIGHTED);
   if(m_cci_handle==INVALID_HANDLE)
     {
      printf("Error: failed to create CCI indicator");
      return(false);
     }
//--- set array as series and copy data
   ArraySetAsSeries(m_cci_buffer,true);
   return(true);
  }
//+------------------------------------------------------------------+
//| Check for long position opening                                  |
//+------------------------------------------------------------------+
int CSignalFractalCCI::LongCondition(const int shift)
  {
   if(!m_initialized)
      return(0);

   //--- A fractal signal is confirmed on the bar two periods after the peak/trough.
   //--- To avoid acting on a repainting signal, we check for a fractal pattern
   //--- centered at 'shift + 2'.
   int signal_shift = shift + 2;

   //--- Not enough bars for fractal check
   if(signal_shift >= m_rates.Total()-2)
      return(0);

   //--- Check for Lower Fractal
   bool is_lower_fractal = m_rates.low[signal_shift] < m_rates.low[signal_shift-1] &&
                           m_rates.low[signal_shift] < m_rates.low[signal_shift-2] &&
                           m_rates.low[signal_shift] < m_rates.low[signal_shift+1] &&
                           m_rates.low[signal_shift] < m_rates.low[signal_shift+2];

   if(!is_lower_fractal)
      return(0);

   //--- Copy CCI data
   if(CopyBuffer(m_cci_handle,0,shift,5,m_cci_buffer)<5)
      return(0);

   //--- Check CCI condition
   if(m_cci_buffer[2] < -m_cci_threshold) // m_cci_buffer[2] corresponds to signal_shift
      return(100); // Signal confirmed

   return(0);
  }
//+------------------------------------------------------------------+
//| Check for short position opening                                 |
//+------------------------------------------------------------------+
int CSignalFractalCCI::ShortCondition(const int shift)
  {
   if(!m_initialized)
      return(0);

   //--- A fractal signal is confirmed on the bar two periods after the peak/trough.
   int signal_shift = shift + 2;

   //--- Not enough bars for fractal check
   if(signal_shift >= m_rates.Total()-2)
      return(0);

   //--- Check for Upper Fractal
   bool is_upper_fractal = m_rates.high[signal_shift] > m_rates.high[signal_shift-1] &&
                           m_rates.high[signal_shift] > m_rates.high[signal_shift-2] &&
                           m_rates.high[signal_shift] > m_rates.high[signal_shift+1] &&
                           m_rates.high[signal_shift] > m_rates.high[signal_shift+2];

   if(!is_upper_fractal)
      return(0);

   //--- Copy CCI data
   if(CopyBuffer(m_cci_handle,0,shift,5,m_cci_buffer)<5)
      return(0);

   //--- Check CCI condition
   if(m_cci_buffer[2] > m_cci_threshold) // m_cci_buffer[2] corresponds to signal_shift
      return(100); // Signal confirmed

   return(0);
  }
//+------------------------------------------------------------------+
#endif // EXPERT_SIGNAL_SIGNALFRACTALCCI_MQH
