//+------------------------------------------------------------------+
//|                                             SignalCombined.mqh |
//|                             Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"

#include <Expert\ExpertSignal.mqh>
#include <Indicators\Indicators.mqh>

class CSignalCombined : public CExpertSignal
{
private:
    //--- Neuro Trader members
    CIndicator m_neuro_bb;
    double m_neuro_weights[14];
    double m_neuro_inputs[14];

    //--- Fractal CCI members
    CIndicator m_fractal_cci;
    int m_cci_period;
    int m_cci_threshold;

    //--- Helper methods
    double CalculateNeuron(double &x[], double &w[]);
    double ActivateNeuron(double x);

public:
    CSignalCombined(void);
    ~CSignalCombined(void);

    //--- Settings
    void CCI_Period(int value) { m_cci_period = value; }
    void CCI_Threshold(int value) { m_cci_threshold = value; }
    void NeuroWeights(double &weights[])
    {
        for (int i = 0; i < 14; i++)
            m_neuro_weights[i] = weights[i];
    }

    //--- Validation and initialization
    virtual bool ValidationSettings(void);
    virtual bool InitIndicators(CIndicators *indicators);

    //--- Main methods
    virtual int LongCondition(void);
    virtual int ShortCondition(void);
};

CSignalCombined::CSignalCombined(void) : m_cci_period(7), m_cci_threshold(110)
{
    //--- initialize neuro inputs
    ArrayInitialize(m_neuro_inputs, 0);
}

CSignalCombined::~CSignalCombined(void)
{
}

bool CSignalCombined::ValidationSettings(void)
{
    if (m_cci_period <= 0 || m_cci_threshold <= 0)
        return (false);
    return (CExpertSignal::ValidationSettings());
}

bool CSignalCombined::InitIndicators(CIndicators *indicators)
{
    if (indicators == NULL)
        return (false);
    if (!CExpertSignal::InitIndicators(indicators))
        return (false);

    //--- Create Bollinger Bands indicator
    MqlParam bb_params[4];
    bb_params[0].type = TYPE_INT;    bb_params[0].integer_value = 20;        // period
    bb_params[1].type = TYPE_INT;    bb_params[1].integer_value = 0;         // shift
    bb_params[2].type = TYPE_DOUBLE; bb_params[2].double_value = 2.0;      // deviation
    bb_params[3].type = TYPE_INT;    bb_params[3].integer_value = PRICE_CLOSE; // price
    if (!m_neuro_bb.Create(_Symbol, _Period, IND_BB, 4, bb_params))
        return(false);
    if (!indicators->Add(&m_neuro_bb))
        return (false);

    //--- Create Fractal CCI custom indicator
    int handle = iCustom(_Symbol, _Period, "Fractal_CCI", m_cci_period, m_cci_threshold);
    if (handle == INVALID_HANDLE)
    {
        printf("Error creating Fractal_CCI indicator handle");
        return(false);
    }
    m_fractal_cci.SetIndicatorHandle(handle);
    if (!indicators->Add(&m_fractal_cci))
        return (false);

    return (true);
}

int CSignalCombined::LongCondition(void)
{
    //--- Neuro Buy Condition
    double upper_bb[7], lower_bb[7], base_bb[7];
    for (int i = 0; i < 7; i++)
    {
        upper_bb[i] = m_neuro_bb.GetData(1, i);
        lower_bb[i] = m_neuro_bb.GetData(2, i);
        base_bb[i] = m_neuro_bb.GetData(0, i);
    }

    double d1 = -1;
    double d2 = 1;
    double x_min = MathMin(ArrayMinimum(lower_bb), ArrayMinimum(upper_bb));
    double x_minn = ArrayMinimum(base_bb);
    double x_max = MathMax(ArrayMaximum(lower_bb), ArrayMaximum(upper_bb));
    double x_maxx = ArrayMaximum(base_bb);

    for (int i = 0; i < 7; i++)
    {
        if(base_bb[i] != 0 && (x_maxx + x_max) - (x_min + x_minn) != 0)
            m_neuro_inputs[i * 2] = (((((upper_bb[i] - lower_bb[i]) / base_bb[i]) - (x_min + x_minn) * (d2 - d1)) / ((x_maxx + x_max) - (x_min + x_minn))) + d1);
    }

    double neuro_out = CalculateNeuron(m_neuro_inputs, m_neuro_weights);
    bool neuro_buy_condition = (neuro_out < 0);

    //--- Fractal CCI Buy Condition
    bool fractal_buy_signal = false;
    for (int i = 2; i < 8; i++)
    {
        if (m_fractal_cci.GetData(1, i) != EMPTY_VALUE)
        {
            fractal_buy_signal = true;
            break;
        }
    }

    if (neuro_buy_condition && fractal_buy_signal)
        return (100);

    return (0);
}

int CSignalCombined::ShortCondition(void)
{
    //--- Neuro Sell Condition
    double upper_bb[7], lower_bb[7], base_bb[7];
    for (int i = 0; i < 7; i++)
    {
        upper_bb[i] = m_neuro_bb.GetData(1, i);
        lower_bb[i] = m_neuro_bb.GetData(2, i);
        base_bb[i] = m_neuro_bb.GetData(0, i);
    }

    double d1 = -1;
    double d2 = 1;
    double x_min = MathMin(ArrayMinimum(lower_bb), ArrayMinimum(upper_bb));
    double x_minn = ArrayMinimum(base_bb);
    double x_max = MathMax(ArrayMaximum(lower_bb), ArrayMaximum(upper_bb));
    double x_maxx = ArrayMaximum(base_bb);

    for (int i = 0; i < 7; i++)
    {
        if(base_bb[i] != 0 && (x_maxx + x_max) - (x_min + x_minn) != 0)
            m_neuro_inputs[i * 2] = (((((upper_bb[i] - lower_bb[i]) / base_bb[i]) - (x_min + x_minn) * (d2 - d1)) / ((x_maxx + x_max) - (x_min + x_minn))) + d1);
    }

    double neuro_out = CalculateNeuron(m_neuro_inputs, m_neuro_weights);
    bool neuro_sell_condition = (neuro_out > 0);

    //--- Fractal CCI Sell Condition
    bool fractal_sell_signal = false;
    for (int i = 2; i < 8; i++)
    {
        if (m_fractal_cci.GetData(0, i) != EMPTY_VALUE)
        {
            fractal_sell_signal = true;
            break;
        }
    }

    if (neuro_sell_condition && fractal_sell_signal)
        return (100);

    return (0);
}

double CSignalCombined::CalculateNeuron(double &x[], double &w[])
{
    double NET = 0.0;
    for (int n = 0; n < 14; n++)
    {
        NET += x[n] * w[n];
    }
    NET *= 2;
    return (ActivateNeuron(NET));
}

double CSignalCombined::ActivateNeuron(double x)
{
    // Hyperbolic tangent function, with check for large x to prevent overflow
    if (x > 100) return 1.0;
    if (x < -100) return -1.0;
    return ((exp(x) - exp(-x)) / (exp(x) + exp(-x)));
}
//+------------------------------------------------------------------+