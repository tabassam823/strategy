//+------------------------------------------------------------------+
//|                                            Combined_Trader.mq5 |
//|                             Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Expert\Expert.mqh>
#include <Expert\Money\MoneyNone.mqh>
#include "SignalCombined.mqh"

//--- Inputs
input int Inp_Signal_CCI_Period = 7;
input int Inp_Signal_CCI_Threshold = 110;
input int Inp_Signal_TakeProfit = 10;
input int Inp_Signal_StopLoss = 2;
input double Inp_Signal_Lot = 1.0;

//--- Neuro Weights
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

int OnInit()
{
    if (!ExtExpert.Init(Symbol(), Period(), false, 0))
        return (INIT_FAILED);

    CSignalCombined *signal = new CSignalCombined;
    if (signal == NULL)
        return (INIT_FAILED);
    if (!ExtExpert.InitSignal(signal))
        return (INIT_FAILED);

    double weights[14];
    weights[0]=w0;
    weights[1]=w1;
    weights[2]=w2;
    weights[3]=w3;
    weights[4]=w4;
    weights[5]=w5;
    weights[6]=w6;
    weights[7]=w7;
    weights[8]=w8;
    weights[9]=w9;
    weights[10]=w10;
    weights[11]=w11;
    weights[12]=w12;
    weights[13]=w13;

    signal->CCI_Period(Inp_Signal_CCI_Period);
    signal->CCI_Threshold(Inp_Signal_CCI_Threshold);
    signal->TakeLevel(Inp_Signal_TakeProfit);
    signal->StopLevel(Inp_Signal_StopLoss);
    signal->NeuroWeights(weights);

    if (!signal->ValidationSettings())
        return (INIT_FAILED);

    CMoneyNone *money = new CMoneyNone;
    if (money == NULL)
        return (INIT_FAILED);
    if (!ExtExpert.InitMoney(money))
        return (INIT_FAILED);

    money->Lot(Inp_Signal_Lot);

    if (!money->ValidationSettings())
        return (INIT_FAILED);

    if (!ExtExpert.InitIndicators())
        return (INIT_FAILED);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    ExtExpert.Deinit();
}

void OnTick(void)
{
    ExtExpert.OnTick();
}

void OnTrade(void)
{
    ExtExpert.OnTrade();
}

void OnTimer(void)
{
    ExtExpert.OnTimer();
}
//+------------------------------------------------------------------+