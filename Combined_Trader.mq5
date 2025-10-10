//+------------------------------------------------------------------+
//|                                            Combined_Trader.mq5 |
//|                             Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property expert_version "1.0"
#property description "Combines a Bollinger Bands based neuro-signal with a Fractal CCI filter."

#include <Expert\Expert.mqh>
#include <Expert\Money\MoneyFixedLot.mqh>
#include <Expert\Trailing\TrailingNone.mqh>
#include "SignalCombined.mqh"

//--- Inputs for Signal
input_group "Signal Settings"
input int Inp_Signal_CCI_Period = 7;
input int Inp_Signal_CCI_Threshold = 110;

//--- Inputs for Money
input_group "Money Management"
input double Inp_Money_Lot = 0.1;

//--- Inputs for Trading
input_group "Trading Settings"
input int Inp_Signal_TakeProfit = 100; // In points
input int Inp_Signal_StopLoss = 20;   // In points
input int Inp_Magic_Number = 12345;

//--- Neuro Weights
input_group "Neuro Weights"
input double w0=0.8;
input double w1=0.4;
input double w2=-0.9;
input double w3=0.0;
input double w4=0.7;
input double w5=-0.2;
input double w6=0.9;
input double w7=0.7;
input double w8=-1.0;
input double w9=0.3;
input double w10=0.5;
input double w11=0.5;
input double w12=0.0;
input double w13=1.0;

CExpert ExtExpert;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    if (!ExtExpert.Init(Symbol(), Period(), false, Inp_Magic_Number))
    {
        printf("Error initializing Expert");
        return (INIT_FAILED);
    }

    //--- Create and initialize the signal
    CSignalCombined *signal = new CSignalCombined;
    if (signal == NULL)
    {
        printf("Error creating CSignalCombined object");
        return (INIT_FAILED);
    }
    if (!ExtExpert.InitSignal(signal))
    {
        printf("Error initializing signal object");
        delete signal;
        return (INIT_FAILED);
    }

    double weights[14];
    weights[0]=w0; weights[1]=w1; weights[2]=w2; weights[3]=w3;
    weights[4]=w4; weights[5]=w5; weights[6]=w6; weights[7]=w7;
    weights[8]=w8; weights[9]=w9; weights[10]=w10; weights[11]=w11;
    weights[12]=w12; weights[13]=w13;

    signal.CCI_Period(Inp_Signal_CCI_Period);
    signal.CCI_Threshold(Inp_Signal_CCI_Threshold);
    signal.NeuroWeights(weights);
    ExtExpert.SetSignal(signal); // Pass ownership to the expert

    //--- Create and initialize money management
    CMoneyFixedLot *money = new CMoneyFixedLot;
    if (money == NULL)
    {
        printf("Error creating CMoneyFixedLot object");
        return(INIT_FAILED);
    }
    money.Lot(Inp_Money_Lot);
    if (!ExtExpert.InitMoney(money))
    {
        printf("Error initializing money object");
        delete money;
        return(INIT_FAILED);
    }
    ExtExpert.SetMoney(money); // Pass ownership to the expert

    //--- Create and initialize trailing stop
    CTrailingNone *trailing = new CTrailingNone;
    if (trailing == NULL)
    {
        printf("Error creating CTrailingNone object");
        return(INIT_FAILED);
    }
    if (!ExtExpert.InitTrailing(trailing))
    {
        printf("Error initializing trailing object");
        delete trailing;
        return(INIT_FAILED);
    }
    ExtExpert.SetTrailing(trailing); // Pass ownership to the expert

    //--- Set trading parameters
    ExtExpert.SetTakeProfit(Inp_Signal_TakeProfit);
    ExtExpert.SetStopLoss(Inp_Signal_StopLoss);

    //--- Finalize initialization
    if (!ExtExpert.InitCheck())
    {
        printf("Final expert initialization check failed");
        return(INIT_FAILED);
    }

    return (INIT_SUCCEEDED);
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
void OnTick(void)
{
    ExtExpert.OnTick();
}

//+------------------------------------------------------------------+
//| Expert trade function                                            |
//+------------------------------------------------------------------+
void OnTrade(void)
{
    ExtExpert.OnTrade();
}

//+------------------------------------------------------------------+
//| Expert timer function                                            |
//+------------------------------------------------------------------+
void OnTimer(void)
{
    ExtExpert.OnTimer();
}
//+------------------------------------------------------------------+