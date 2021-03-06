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
int iStdDevHandle;

input group "Configurações gerais"
input ulong Magic = 133713131; // Número mágico
input int Volume = 1; // Volume 
input group "Configurações de horários"
input bool   longBias = false;
input bool   dayTrade = false; // Apenas Operações de daytrade?
input string inicio = "17:00"; // Horário de Início de scan (entradas)
input string termino = "17:45"; // Horário de Término 
input group "Configuraçoes do modelo"
input double intercep = -0.00041886750108757764 ; // intercep sem vol 0.0006960661482156406 com vol -0.00041886750108757764
input double x1 = 0; // x1 sem vol -0.00666454 com vol 0
input double x2 = 0; // x2 sem vol -0.03085042 com vol 0
input double x3 = 0; // x3 sem vol -0.06179788 com vol 0
input double x4 = 0; // x4 sem vol -0.01415134 com vol 0
input double x5 = 0.00123125; // x5 sem vol -0.00464262 com vol 0.00123125
input double x6 = 0.05162232; // x6 sem vol 0 com vol 0.05162232

input double intercepNoVol = 0.0006960661482156406 ; // intercep sem vol 0.0006960661482156406 com vol -0.00041886750108757764
input double x1NoVol = -0.00666454; // x1 sem vol -0.00666454 com vol 0
input double x2NoVol = -0.03085042; // x2 sem vol -0.03085042 com vol 0
input double x3NoVol = -0.06179788; // x3 sem vol -0.06179788 com vol 0
input double x4NoVol = -0.01415134; // x4 sem vol -0.01415134 com vol 0
input double x5NoVol = -0.00464262; // x5 sem vol -0.00464262 com vol 0.00123125


MqlDateTime horario_inicio, horario_termino, horario_atual;

int OnInit () {
    iStdDevHandle = iStdDev(_Symbol,_Period,5,0,MODE_EMA,PRICE_CLOSE);
    negocio.SetExpertMagicNumber (Magic);
    TimeToStruct (StringToTime (inicio), horario_inicio);
    TimeToStruct (StringToTime (termino), horario_termino);
    
    if(iStdDevHandle== INVALID_HANDLE) {
         Print("Erro na criação dos manipuladores");
         return INIT_FAILED;
    }
    
    
    return (INIT_SUCCEEDED);
}

void OnDeinit (const int reason) {
   IndicatorRelease(iStdDevHandle);
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
      if(dayTrade){
         Fechar();
      }
    }
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

void executar (int codExec) {
    int lots = Volume;
    if (Volume == 0) {
        double tamanhoConta = AccountInfoDouble (ACCOUNT_BALANCE) - PosicaoDoBot ();
        lots = (tamanhoConta / SymbolInfoDouble (_Symbol, SYMBOL_ASK)) - ((int) (tamanhoConta / SymbolInfoDouble (_Symbol, SYMBOL_ASK)) % 100);
    }
    if (codExec == 1) {
        negocio.Buy (lots);
    }
    if (codExec == -1 && longBias == false) {
        negocio.Sell (lots);
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

    CopyRates (symbol, _Period, 0, 10, pricesData);

    return (pricesData[diasAtras-1].close - pricesData[diasAtras].close) / pricesData[diasAtras-1].close;

}

double GetPercentageVolatility() {
   double volatility[];
   MqlRates pricesData[];
   ArraySetAsSeries (pricesData, true);
   ArraySetAsSeries(volatility,true);
   
   CopyBuffer(iStdDevHandle,0,0,3,volatility);
   CopyRates (_Symbol, _Period, 0, 10, pricesData);
   
   return volatility[0]/pricesData[0].close;
}


int SinalEntrada () {
    double modeloComVol = intercep + (x1 * GetPctChange (_Symbol,1)) + (x2 * GetPctChange (_Symbol,2)) + (x3 * GetPctChange (_Symbol,3)) + (x4 * GetPctChange (_Symbol,4)) + (x5 * GetPctChange(_Symbol,5)) + (x6 * GetPercentageVolatility());
    double modeloSemVol = intercepNoVol + (x1NoVol * GetPctChange (_Symbol,1)) + (x2NoVol * GetPctChange (_Symbol,2)) + (x3NoVol * GetPctChange (_Symbol,3)) + (x4NoVol * GetPctChange (_Symbol,4)) + (x5NoVol * GetPctChange(_Symbol,5));
    
    int sinalModelVol = modeloComVol > 0 ? 1 : -1;
    int sinalModelSemVol = modeloSemVol > 0 ? 1 : -1;
    
    if(sinalModelVol == sinalModelSemVol) {
       return sinalModelVol;
      } else {
      return 0;
     }
    
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