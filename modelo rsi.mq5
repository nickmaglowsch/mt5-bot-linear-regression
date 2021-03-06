//+------------------------------------------------------------------+
//|                                                    if2sniper.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
//---
#include <Trade\Trade.mqh> // Get code from other places
CTrade negocio;
int iStdDevHandle, iRsi25Handle, iStdDevRSIHandle, iAdxHandle;

input group "Configurações gerais"
input ulong Magic = 133713131; // Número mágico
input int Volume = 1; // Volume 
input double sl = 0.0; // stoploss
input group "Configurações de horários"
input bool   longBias = false;
input bool   dayTrade = false; // Apenas Operações de daytrade?
input string inicio = "17:00"; // Horário de Início de scan (entradas)
input string termino = "17:00"; // Horário de Término 
input string fecharDayTrade = "17:45"; // Horário de Término 
input group "Configuraçoes do modelo"
input double intercep =  0.000306542; // intercep 0.014136315711545317
input double x1 = 3.79E-02 ; // x1 vol_pct 
input double x2 = -4.48E-02; // x2 BVSP_shift
input double x3 = 2.18E-04; // x3 alta_baixa
input double x4 = -2.10E-05 ; // x4 std_rsi 
input double x5 =2.10E-05 ; // x5 adx 




MqlDateTime horario_inicio, horario_termino, horario_atual, horario_fecharDaytrade;

int OnInit () {
    iStdDevHandle = iStdDev(_Symbol,PERIOD_CURRENT,5,0,MODE_SMA,PRICE_CLOSE);
    iRsi25Handle = iRSI(_Symbol,PERIOD_CURRENT,14,PRICE_CLOSE);
    iStdDevRSIHandle = iStdDev(_Symbol,PERIOD_CURRENT,5,0,MODE_SMA,iRsi25Handle);
    iAdxHandle = iADX(_Symbol,PERIOD_CURRENT,14);
    negocio.SetExpertMagicNumber (Magic);
    TimeToStruct (StringToTime (inicio), horario_inicio);
    TimeToStruct (StringToTime (termino), horario_termino);
    TimeToStruct (StringToTime (fecharDayTrade), horario_fecharDaytrade);
    
    if(iStdDevHandle== INVALID_HANDLE || iStdDevRSIHandle == INVALID_HANDLE || iRsi25Handle == INVALID_HANDLE || iAdxHandle == INVALID_HANDLE) {
         Print("Erro na criação dos manipuladores");
         return INIT_FAILED;
    }
    
    
    return (INIT_SUCCEEDED);
}

void OnDeinit (const int reason) {
   IndicatorRelease(iStdDevHandle);
   IndicatorRelease(iRsi25Handle);
   IndicatorRelease(iStdDevRSIHandle);
}

void OnTick () {
    
    if (HorarioEntrada ()) {
        // EA não está posicionado
         if(!isNewBar()){
         return;
         }
         if (SemPosicao ()) {
            // Estratégia indicou
            executar (SinalEntrada ());
      
         } else {
            // EA está posicionado verificar saida
            if (SinalEntrada() != TipoPosicaoDoBot()) {
               executar(SinalEntrada(),2);
            }   
            
        }
    } else {
      if((dayTrade && HorarioFecharDaytrade()) || (SinalEntrada() != TipoPosicaoDoBot())){
         Fechar();
      }
    }
}

bool HorarioFecharDaytrade() {
   TimeToStruct (TimeCurrent (), horario_atual);
   
   if (horario_atual.hour == horario_fecharDaytrade.hour) {
      if (horario_atual.min <= horario_fecharDaytrade.min) {
          return true;
      } else {
          return false;
      }
   }
   return false;
}

bool HorarioEntrada () {
    TimeToStruct (TimeCurrent (), horario_atual);

    if (horario_atual.hour >= horario_inicio.hour && horario_atual.hour <= horario_termino.hour) {
        if (horario_atual.hour == horario_inicio.hour) {
            if (horario_atual.min >= horario_inicio.min) {
                return true;
            } else {
                return false;
            }
        }

        if (horario_atual.hour == horario_termino.hour) {
            if (horario_atual.min <= horario_termino.min) {
                return true;
            } else {
                return false;
            }
        }
        return true;
    }
    return false;
}

double floorWithSignficance(double number, int signficance) {
   return floor(number) - MathMod(floor(number),signficance);
}

double ceilingWithSignficance(double number, int signficance) {
   return ceil(number) - MathMod(ceil(number),signficance);
}

void executar (int codExec, int mult = 1) {
    int lots = Volume * mult;
    double sl_buy = 1 - sl;
    double sl_sell = 1 + sl;
    
    if (Volume == 0) {
        double tamanhoConta = AccountInfoDouble (ACCOUNT_BALANCE) - PosicaoDoBot ();
        lots = (tamanhoConta / SymbolInfoDouble (_Symbol, SYMBOL_ASK)) - ((int) (tamanhoConta / SymbolInfoDouble (_Symbol, SYMBOL_ASK)) % 100);
    }
    if (codExec == 1) {
        negocio.Buy (lots,_Symbol,0.0,floorWithSignficance(SymbolInfoDouble (_Symbol, SYMBOL_ASK)*sl_buy,5));
    }
    if (codExec == -1 && longBias == false) {
        negocio.Sell (lots,_Symbol,0.0,floorWithSignficance(SymbolInfoDouble (_Symbol, SYMBOL_ASK)*sl_sell,5));
    }
    if (codExec == 0) {
        Fechar ();
    }
}

void Fechar () {
    int total = PositionsTotal ();
    for (int i = total - 1; i >= 0; i--) {
        ulong ticket = PositionGetTicket (i);
        if (!PositionSelectByTicket (ticket))
            continue;
        if (PositionGetString (POSITION_SYMBOL) != _Symbol || PositionGetInteger (POSITION_MAGIC) != Magic)
            continue;
        negocio.PositionClose (ticket);
    }
}

bool SemPosicao () {
    int total = PositionsTotal ();
    for (int i = total - 1; i >= 0; i--) {
        ulong ticket = PositionGetTicket (i);
        if (!PositionSelectByTicket (ticket))
            continue;
        if (PositionGetString (POSITION_SYMBOL) != _Symbol || PositionGetInteger (POSITION_MAGIC) != Magic)
            continue;
        return false;
    }

    return true;
}

double PosicaoDoBot () {
    int total = PositionsTotal ();
    double tamanhoPosicaoBot = 0.0;
    for (int i = total - 1; i >= 0; i--) {
        ulong ticket = PositionGetTicket (i);
        if (!PositionSelectByTicket (ticket))
            continue;
        if (PositionGetInteger (POSITION_MAGIC) == Magic)
            tamanhoPosicaoBot = tamanhoPosicaoBot + (PositionGetDouble (POSITION_PRICE_OPEN) * PositionGetDouble (POSITION_VOLUME));
    }

    return tamanhoPosicaoBot;
}

int TipoPosicaoDoBot () {
    int total = PositionsTotal ();
    double tamanhoPosicaoBot = 0.0;
    for (int i = total - 1; i >= 0; i--) {
        ulong ticket = PositionGetTicket (i);
        if (!PositionSelectByTicket (ticket))
            continue;
        if (PositionGetInteger (POSITION_MAGIC) == Magic) {
            int positionType = PositionGetInteger(POSITION_TYPE);
           

            if(positionType == POSITION_TYPE_SELL) {
               return -1;
            }
            
            if(positionType == POSITION_TYPE_BUY) {
               return 1;
            }
        
        }
             
    }

    return tamanhoPosicaoBot;
}

double GetPctChange (string symbol, int diasAtras) {
    MqlRates pricesData[];
    ArraySetAsSeries (pricesData, true);

    CopyRates (symbol, PERIOD_CURRENT, 0, 10, pricesData);

    return (pricesData[diasAtras-1].close - pricesData[diasAtras].close) / pricesData[diasAtras-1].close;

}

bool isGreenDay(int day) {
   return GetPctChange(_Symbol,day) > 0;
}

double GetPercentageVolatility(int day) {
   double volatility[];
   MqlRates pricesData[];
   ArraySetAsSeries (pricesData, true);
   ArraySetAsSeries(volatility,true);
   
   CopyBuffer(iStdDevHandle,0,0,3,volatility);
   CopyRates (_Symbol, PERIOD_CURRENT, 0, 10, pricesData);
   
   return volatility[day]/pricesData[day].close;
}

double GetVolatility() {
   double volatility[];
   
   ArraySetAsSeries(volatility,true);
   
   CopyBuffer(iStdDevHandle,0,0,3,volatility);
   
   return volatility[0];
}

double GetDailyChange() {
   MqlRates pricesData[];
   ArraySetAsSeries (pricesData, true);
   
   CopyRates (_Symbol, PERIOD_CURRENT, 0, 10, pricesData);
   
   return (pricesData[0].open - pricesData[0].close)/pricesData[0].close;
}

double GetAdx(int day) {
   double adx[];
   
   ArraySetAsSeries(adx,true);
   
   CopyBuffer(iAdxHandle,0,0,3,adx);
   
   return adx[day];
}

double GetRsiStdDev(int day) {
   double rsiStdDev[];
   
   ArraySetAsSeries(rsiStdDev,true);
   
   CopyBuffer(iStdDevRSIHandle,0,0,3,rsiStdDev);
   
   return rsiStdDev[day];
}

int SinalEntrada () {
    
    double model1 = intercep + (x1 * GetPercentageVolatility(0)) + (x2 * GetPctChange(_Symbol,1)) + (x3 * isGreenDay(1)) + (x4 * GetRsiStdDev(0)) + (x5 * GetAdx(0));
    double model2 = intercep + (x1 * GetPercentageVolatility(1)) + (x2 * GetPctChange(_Symbol,2)) + (x3 * isGreenDay(2)) + (x4 * GetRsiStdDev(1)) + (x5 * GetAdx(1));
    double model3 = intercep + (x1 * GetPercentageVolatility(2)) + (x2 * GetPctChange(_Symbol,3)) + (x3 * isGreenDay(3)) + (x4 * GetRsiStdDev(2)) + (x5 * GetAdx(2));
    int sinal = model1 > model2 > model3 ? 1 : -1;
    
    return sinal;
    
}

bool NewDay () {
    static datetime PrevDay;

    if (PrevDay < iTime (NULL, PERIOD_D1, 0)) {
        PrevDay = iTime (NULL, PERIOD_D1, 0);
        return (true);
    } else {
        return (false);
    }
}

bool isNewBar () {
    static datetime last_time = 0;

    datetime lastbar_time = (datetime) SeriesInfoInteger (Symbol (), Period (), SERIES_LASTBAR_DATE);

    if (last_time == 0) {
        last_time = lastbar_time;
        return (false);
    }

    if (last_time != lastbar_time) {
        last_time = lastbar_time;
        return (true);
    }
    return (false);
}