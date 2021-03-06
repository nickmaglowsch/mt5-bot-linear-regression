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

input group "Configurações gerais"
input ulong Magic = 133713131; // Número mágico
input int Volume = 1; // Volume 
input double sl = 0.0; // stoploss
input group "Configurações de horários"
input bool   longBias = false;
input bool   dayTrade = false; // Apenas Operações de daytrade?
input string inicio = "9:00"; // Horário de Início de scan (entradas)
input string termino = "17:30"; // Horário de Término 
input string fecharDayTrade = "17:45"; // Horário de Término 
input group "Configuraçoes do modelo"
input double intercep =  1.860345368036748e-05; // intercep 
input double x1 = -0.01593253 ; 
input double buy_treashHold = 0.01593253 ; 
input double sell_treashHold = -0.01593253 ; 





MqlDateTime horario_inicio, horario_termino, horario_atual, horario_fecharDaytrade;

int OnInit () {
    negocio.SetExpertMagicNumber (Magic);
    TimeToStruct (StringToTime (inicio), horario_inicio);
    TimeToStruct (StringToTime (termino), horario_termino);
    TimeToStruct (StringToTime (fecharDayTrade), horario_fecharDaytrade);
    
    return (INIT_SUCCEEDED);
}

void OnDeinit (const int reason) {
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
               Fechar ();
               executar(SinalEntrada());
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

void executar (int codExec) {
    int lots = Volume;
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


double GetDailyChange() {
   MqlRates pricesData[];
   ArraySetAsSeries (pricesData, true);
   
   CopyRates (_Symbol, PERIOD_CURRENT, 0, 10, pricesData);
   
   return (pricesData[0].open - pricesData[0].close)/pricesData[0].close;
}

int SinalEntrada () {
    
    double residuo = GetPctChange(_Symbol,1) - (intercep + x1 * GetPctChange(_Symbol,2));
    
    if(residuo  > sell_treashHold)
      {
       return -1;
      }
    if(residuo < buy_treashHold)
      {
       return 1;
      }
    return 0;
    
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