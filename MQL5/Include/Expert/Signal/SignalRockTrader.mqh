//+------------------------------------------------------------------+
//|                                           SignalRockTrader.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"

#ifndef EXPERT_SIGNAL_SIGNALROCKTRADER_MQH
#define EXPERT_SIGNAL_SIGNALROCKTRADER_MQH

#include "ExpertSignal.mqh"
#include <Math/Stat/Math.mqh>

//+------------------------------------------------------------------+
//| CSignalRockTrader class                                          |
//| Purpose: Class for generation of trade signals based on          |
//|          the Rock Trader Neuro strategy (Bollinger Bands Neuron).|
//+------------------------------------------------------------------+
class CSignalRockTrader : public CExpertSignal
  {
protected:
   //--- indicator handles
   int               m_bb_handle;
   //--- indicator buffers
   double            m_bb_base_buffer[];
   double            m_bb_upper_buffer[];
   double            m_bb_lower_buffer[];
   //--- input parameters for Bollinger Bands
   int               m_bb_period;
   int               m_bb_shift;
   double            m_bb_deviation;
   //--- input parameters for neuron weights
   double            m_weights[14];
   //--- internal state
   bool              m_initialized;

public:
                     CSignalRockTrader();
                    ~CSignalRockTrader();
   //--- settings
   void              SetBbPeriod(int period)         { m_bb_period=period;       }
   void              SetBbShift(int shift)           { m_bb_shift=shift;         }
   void              SetBbDeviation(double dev)      { m_bb_deviation=dev;       }
   void              SetWeights(const double &arr[]);
   //--- validation and initialization
   virtual bool      ValidationSettings();
   virtual bool      InitIndicators(CIndicators *indicators);
   //--- signal checks
   virtual int       LongCondition(const int shift);
   virtual int       ShortCondition(const int shift);

protected:
   bool              InitBB(CIndicators *indicators);
   double            CalculateNeuron(const int shift);
   double            ActivateNeuron(double x);
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSignalRockTrader::CSignalRockTrader() :
   m_bb_handle(INVALID_HANDLE),
   m_bb_period(20),
   m_bb_shift(0),
   m_bb_deviation(2.0),
   m_initialized(false)
  {
   //--- Initialize default weights from the original EA
   m_weights[0]=0.8;   m_weights[1]=0.4;   m_weights[2]=-0.9;
   m_weights[3]=0.0;   m_weights[4]=0.7;   m_weights[5]=-0.2;
   m_weights[6]=0.9;   m_weights[7]=0.7;   m_weights[8]=-1.0;
   m_weights[9]=0.3;   m_weights[10]=0.5;  m_weights[11]=0.5;
   m_weights[12]=0.0;  m_weights[13]=1.0;
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSignalRockTrader::~CSignalRockTrader()
  {
  }
//+------------------------------------------------------------------+
//| Set neuron weights                                               |
//+------------------------------------------------------------------+
void CSignalRockTrader::SetWeights(const double &arr[])
  {
   for(int i=0; i<14; i++)
      m_weights[i] = arr[i];
  }
//+------------------------------------------------------------------+
//| Validation of settings                                           |
//+------------------------------------------------------------------+
bool CSignalRockTrader::ValidationSettings()
  {
   if(!CExpertSignal::ValidationSettings())
      return(false);
   return(true); // No specific settings to validate here yet
  }
//+------------------------------------------------------------------+
//| Initialize indicators                                            |
//+------------------------------------------------------------------+
bool CSignalRockTrader::InitIndicators(CIndicators *indicators)
  {
   if(indicators==NULL)
      return(false);
//--- initialization of indicators and series
   if(!CExpertSignal::InitIndicators(indicators))
      return(false);
//--- create and initialize Bollinger Bands
   if(!InitBB(indicators))
      return(false);
//--- ok
   m_initialized=true;
   return(true);
  }
//+------------------------------------------------------------------+
//| Initialize Bollinger Bands indicator                             |
//+------------------------------------------------------------------+
bool CSignalRockTrader::InitBB(CIndicators *indicators)
  {
//--- add indicator
   m_bb_handle=indicators.Add(m_symbol.Name(),m_period,IND_BB,m_bb_period,m_bb_shift,m_bb_deviation,PRICE_CLOSE);
   if(m_bb_handle==INVALID_HANDLE)
     {
      printf("Error: failed to create Bollinger Bands indicator");
      return(false);
     }
//--- set arrays as series
   ArraySetAsSeries(m_bb_base_buffer,true);
   ArraySetAsSeries(m_bb_upper_buffer,true);
   ArraySetAsSeries(m_bb_lower_buffer,true);
   return(true);
  }
//+------------------------------------------------------------------+
//| Check for long position opening                                  |
//+------------------------------------------------------------------+
int CSignalRockTrader::LongCondition(const int shift)
  {
   if(!m_initialized || m_rates.Total() < 60)
      return(0);

   double neuron_output = CalculateNeuron(shift);

   if(neuron_output < 0)
      return(100);

   return(0);
  }
//+------------------------------------------------------------------+
//| Check for short position opening                                 |
//+------------------------------------------------------------------+
int CSignalRockTrader::ShortCondition(const int shift)
  {
   if(!m_initialized || m_rates.Total() < 60)
      return(0);

   double neuron_output = CalculateNeuron(shift);

   if(neuron_output > 0)
      return(100);

   return(0);
  }
//+------------------------------------------------------------------+
//| Neuron calculation function                                      |
//+------------------------------------------------------------------+
double CSignalRockTrader::CalculateNeuron(const int shift)
  {
   int inputs_size = ArraySize(m_weights); // Should be 14
   int buffer_size = inputs_size;          // Use 14 bars of data for 14 inputs

   //--- Ensure we have enough history
   if(m_rates.Total() < buffer_size + shift) return 0.0;

   //--- Resize arrays to fit the data if needed
   if(ArraySize(m_bb_base_buffer) < buffer_size) ArrayResize(m_bb_base_buffer, buffer_size);
   if(ArraySize(m_bb_upper_buffer) < buffer_size) ArrayResize(m_bb_upper_buffer, buffer_size);
   if(ArraySize(m_bb_lower_buffer) < buffer_size) ArrayResize(m_bb_lower_buffer, buffer_size);

   //--- Copy data from indicator buffers
   if(CopyBuffer(m_bb_handle,0,shift,buffer_size,m_bb_base_buffer)<buffer_size) return(0);
   if(CopyBuffer(m_bb_handle,1,shift,buffer_size,m_bb_upper_buffer)<buffer_size) return(0);
   if(CopyBuffer(m_bb_handle,2,shift,buffer_size,m_bb_lower_buffer)<buffer_size) return(0);

   double inputs[14] = {0.0};

   //--- Normalization constants (as in original EA)
   double d1 = -1.0;
   double d2 = 1.0;

   //--- Find min/max over the buffer range for normalization
   double min_lower = m_bb_lower_buffer[ArrayMinimum(m_bb_lower_buffer,0,buffer_size)];
   double min_upper = m_bb_upper_buffer[ArrayMinimum(m_bb_upper_buffer,0,buffer_size)];
   double x_min = MathMin(min_lower, min_upper);

   double x_minn = m_bb_base_buffer[ArrayMinimum(m_bb_base_buffer,0,buffer_size)];

   double max_lower = m_bb_lower_buffer[ArrayMaximum(m_bb_lower_buffer,0,buffer_size)];
   double max_upper = m_bb_upper_buffer[ArrayMaximum(m_bb_upper_buffer,0,buffer_size)];
   double x_max = MathMax(max_lower, max_upper);

   double x_maxx = m_bb_base_buffer[ArrayMaximum(m_bb_base_buffer,0,buffer_size)];

   double range_denom = (x_maxx + x_max) - (x_min + x_minn);
   if(range_denom == 0) return 0.0; // Avoid division by zero

   //--- Fill in the array of inputs with normalized indicator values
   for(int i=0; i < buffer_size; i++)
     {
      double val = (m_bb_upper_buffer[i] - m_bb_lower_buffer[i]) / m_bb_base_buffer[i];
      // Correctly populate all 14 inputs
      inputs[i] = ((((val)-(x_min+x_minn))*(d2-d1))/range_denom)+d1;
     }

   //--- Calculate weighted sum of inputs
   double net = 0.0;
   for(int n=0; n < inputs_size; n++)
     {
      net += inputs[n] * m_weights[n];
     }

   net *= 2;

   return(ActivateNeuron(net));
  }
//+------------------------------------------------------------------+
//| Activation function                                              |
//+------------------------------------------------------------------+
double CSignalRockTrader::ActivateNeuron(double x)
  {
   //--- hyperbolic tangent function
   return((exp(x)-exp(-x))/(exp(x)+exp(-x)));
  }
//+------------------------------------------------------------------+
#endif // EXPERT_SIGNAL_SIGNALROCKTRADER_MQH
