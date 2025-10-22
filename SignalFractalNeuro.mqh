//+------------------------------------------------------------------+
//|                                       SignalFractalNeuro.mqh |
//|                             Copyright 2025, Your Name.           |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Your Name."
#property link      "https://www.mql5.com"

#include <Expert\Signal\ExpertSignal.mqh>
#include <Indicators\Oscilators.mqh>

//+------------------------------------------------------------------+
//| CSinalFractalNeuro class                                         |
//| Purpose: Generation of trading signals based on the combined     |
//| logic of Fractal_CCI and a neural network.                       |
//+------------------------------------------------------------------+
class CSignalFractalNeuro : public CExpertSignal
  {
private:
   //--- Neural network weights
   double            m_weights[14];
   //--- Indicator handles
   int               m_fractal_cci_handle;
   int               m_ibands_handle;
   //--- Indicator buffers
   double            m_upper_fractal_buffer[];
   double            m_lower_fractal_buffer[];
   double            m_ibands_base_buf[];
   double            m_ibands_upper_buf[];
   double            m_ibands_lower_buf[];

public:
                     CSignalFractalNeuro();
                    ~CSignalFractalNeuro();
   //--- virtual methods
   virtual bool      InitIndicators(CIndicators *indicators);
   virtual bool      CheckOpenLong(double &price,double &sl,double &tp,datetime &expiration);
   virtual bool      CheckOpenShort(double &price,double &sl,double &tp,datetime &expiration);
   virtual int       LongCondition();
   virtual int       ShortCondition();

protected:
   double            CalculateNeuron();
   double            ActivateNeuron(double x);
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSignalFractalNeuro::CSignalFractalNeuro()
  {
   //--- Initialize weights
   m_weights[0] = 0.8;
   m_weights[1] = 0.4;
   m_weights[2] = -0.9;
   m_weights[3] = 0.0;
   m_weights[4] = 0.7;
   m_weights[5] = -0.2;
   m_weights[6] = 0.9;
   m_weights[7] = 0.7;
   m_weights[8] = -1.0;
   m_weights[9] = 0.3;
   m_weights[10] = 0.5;
   m_weights[11] = 0.5;
   m_weights[12] = 0.0;
   m_weights[13] = 1.0;
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSignalFractalNeuro::~CSignalFractalNeuro()
  {
  }
//+------------------------------------------------------------------+
//| Initialize indicators                                            |
//+------------------------------------------------------------------+
bool CSignalFractalNeuro::InitIndicators(CIndicators *indicators)
  {
   if(indicators==NULL)
      return(false);
//---
   m_fractal_cci_handle=iCustom(_Symbol,_Period,"Fractal_CCI_utf8",7,110);
   if(m_fractal_cci_handle==INVALID_HANDLE)
     {
      printf("Error creating Fractal_CCI indicator");
      return(false);
     }
//---
   m_ibands_handle=iBands(_Symbol,_Period,20,0,2.0,PRICE_CLOSE);
   if(m_ibands_handle==INVALID_HANDLE)
     {
      printf("Error creating Bollinger Bands indicator");
      return(false);
     }
//---
   if(!m_indicators.Add(m_fractal_cci_handle))
      return(false);
   if(!m_indicators.Add(m_ibands_handle))
      return(false);
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Check for long position opening                                  |
//+------------------------------------------------------------------+
bool CSignalFractalNeuro::CheckOpenLong(double &price,double &sl,double &tp,datetime &expiration)
  {
   price=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   sl=price-m_stop_loss*_Point;
   tp=price+m_take_profit*_Point;
   return(true);
  }
//+------------------------------------------------------------------+
//| Check for short position opening                                 |
//+------------------------------------------------------------------+
bool CSignalFractalNeuro::CheckOpenShort(double &price,double &sl,double &tp,datetime &expiration)
  {
   price=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   sl=price+m_stop_loss*_Point;
   tp=price-m_take_profit*_Point;
   return(true);
  }
//+------------------------------------------------------------------+
//| Long condition                                                   |
//+------------------------------------------------------------------+
int CSignalFractalNeuro::LongCondition()
  {
   //--- Fractal_CCI signal
   ArrayResize(m_lower_fractal_buffer,1);
   CopyBuffer(m_fractal_cci_handle,1,1,1,m_lower_fractal_buffer);
   bool fractal_signal=(m_lower_fractal_buffer[0]!=EMPTY_VALUE);
   //--- Neural network signal
   double neuron_output=CalculateNeuron();
   bool neuro_signal=(neuron_output<0);
   //--- Combined signal
   if(fractal_signal && neuro_signal)
      return(100);
   return(0);
  }
//+------------------------------------------------------------------+
//| Short condition                                                  |
//+------------------------------------------------------------------+
int CSignalFractalNeuro::ShortCondition()
  {
   //--- Fractal_CCI signal
   ArrayResize(m_upper_fractal_buffer,1);
   CopyBuffer(m_fractal_cci_handle,0,1,1,m_upper_fractal_buffer);
   bool fractal_signal=(m_upper_fractal_buffer[0]!=EMPTY_VALUE);
   //--- Neural network signal
   double neuron_output=CalculateNeuron();
   bool neuro_signal=(neuron_output>0);
   //--- Combined signal
   if(fractal_signal && neuro_signal)
      return(100);
   return(0);
  }
//+------------------------------------------------------------------+
//| Neuron calculation function                                      |
//+------------------------------------------------------------------+
double CSignalFractalNeuro::CalculateNeuron()
  {
   double inputs[14];
   ArrayInitialize(inputs,0.0);
   int size_inputs_half=ArraySize(inputs)/2;
   ArrayResize(m_ibands_upper_buf,size_inputs_half);
   ArrayResize(m_ibands_lower_buf,size_inputs_half);
   ArrayResize(m_ibands_base_buf,size_inputs_half);
   CopyBuffer(m_ibands_handle,1,0,size_inputs_half,m_ibands_upper_buf);
   CopyBuffer(m_ibands_handle,2,0,size_inputs_half,m_ibands_lower_buf);
   CopyBuffer(m_ibands_handle,0,0,size_inputs_half,m_ibands_base_buf);
   double d1=-1;
   double d2=1;
   double x_min=MathMin(m_ibands_lower_buf[ArrayMinimum(m_ibands_lower_buf)],m_ibands_upper_buf[ArrayMinimum(m_ibands_upper_buf)]);
   double x_minn=m_ibands_base_buf[ArrayMinimum(m_ibands_base_buf)];
   double x_max=MathMax(m_ibands_lower_buf[ArrayMaximum(m_ibands_lower_buf)],m_ibands_upper_buf[ArrayMaximum(m_ibands_upper_buf)]);
   double x_maxx=m_ibands_base_buf[ArrayMaximum(m_ibands_base_buf)];
   for(int i=0;i<size_inputs_half;i++)
     {
      inputs[i*2]=((((m_ibands_upper_buf[i]-m_ibands_lower_buf[i])/m_ibands_base_buf[i])-(x_min+x_minn)*(d2-d1))/((x_maxx+x_max)-(x_min+x_minn)))+d1;
     }
   double NET=0.0;
   for(int n=0;n<ArraySize(inputs);n++)
     {
      NET+=inputs[n]*m_weights[n];
     }
   NET*=2;
   return(ActivateNeuron(NET));
  }
//+------------------------------------------------------------------+
//| Activation function                                              |
//+------------------------------------------------------------------+
double CSignalFractalNeuro::ActivateNeuron(double x)
  {
   double Out;
   Out=(exp(x)-exp(-x))/(exp(x)+exp(-x));
   return(Out);
  }
//+------------------------------------------------------------------+
