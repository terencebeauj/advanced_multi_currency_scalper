//+------------------------------------------------------------------+
//|                                                     MC_BB_03.mq5 |
//|                                                 Terence Beaujour |
//|                                            beaujour.t@hotmail.fr |
//+------------------------------------------------------------------+
#property copyright "Terence Beaujour"
#property link      "beaujour.t@hotmail.fr"
#property version   "1.00"

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>

//INPUTS
input string         TradeSymbols         = "GBPUSD.r|AUDCAD.r|AUDJPY.r|AUDNZD.r|AUDUSD.r|EURUSD.r";   //Symbol(s) or ALL or CURRENT
input int            BBandsPeriods        = 20;       //Bollinger Bands Periods
input double         BBandsDeviations     = 1.0;      //Bollinger Bands Deviations
input long           my_magic_number=666;
input int            my_slippage;
input double         my_volume=0.01;

//PAIR_01
input unsigned int   my_sl_buy_01;
input unsigned int   my_tp_buy_01;
input unsigned int   my_sl_sell_01;
input unsigned int   my_tp_sell_01;
input double         TrailStopBuy_01 = 100;
input double         TrailStepBuy_01 = 50;
input double         TrailStopSell_01 = 100;
input double         TrailStepSell_01 = 50;

//PAIR_02
input unsigned int   my_sl_buy_02;
input unsigned int   my_tp_buy_02;
input unsigned int   my_sl_sell_02;
input unsigned int   my_tp_sell_02;
input double         TrailStopBuy_02 = 100;
input double         TrailStepBuy_02 = 50;
input double         TrailStopSell_02 = 100;
input double         TrailStepSell_02 = 50;

//PAIR_03
input unsigned int   my_sl_buy_03;
input unsigned int   my_tp_buy_03;
input unsigned int   my_sl_sell_03;
input unsigned int   my_tp_sell_03;
input double         TrailStopBuy_03 = 100;
input double         TrailStepBuy_03 = 50;
input double         TrailStopSell_03 = 100;
input double         TrailStepSell_03 = 50;

//PAIR_04
input unsigned int   my_sl_buy_04;
input unsigned int   my_tp_buy_04;
input unsigned int   my_sl_sell_04;
input unsigned int   my_tp_sell_04;
input double         TrailStopBuy_04= 100;
input double         TrailStepBuy_04 = 50;
input double         TrailStopSell_04 = 100;
input double         TrailStepSell_04 = 50;

//PAIR_05
input unsigned int   my_sl_buy_05;
input unsigned int   my_tp_buy_05;
input unsigned int   my_sl_sell_05;
input unsigned int   my_tp_sell_05;
input double         TrailStopBuy_05 = 100;
input double         TrailStepBuy_05 = 50;
input double         TrailStopSell_05 = 100;
input double         TrailStepSell_05 = 50;

//PAIR_06
input unsigned int   my_sl_buy_06;
input unsigned int   my_tp_buy_06;
input unsigned int   my_sl_sell_06;
input unsigned int   my_tp_sell_06;
input double         TrailStopBuy_06 = 100;
input double         TrailStepBuy_06 = 50;
input double         TrailStopSell_06 = 100;
input double         TrailStepSell_06 = 50;

//GENERAL GLOBALS
string   AllSymbolsString           = "AUDCAD|AUDJPY|AUDNZD|AUDUSD|CADJPY|EURAUD|EURCAD|EURGBP|EURJPY|EURNZD|EURUSD|GBPAUD|GBPCAD|GBPJPY|GBPNZD|GBPUSD|NZDCAD|NZDJPY|NZDUSD|USDCAD|USDCHF|USDJPY";
int      NumberOfTradeableSymbols;
string   SymbolArray[];
int      TicksReceivedCount         = 0;

//INDICATOR HANDLES
int handle_BollingerBands[];
//Place additional indicator handles here as required
//OPEN TRADE ARRAYS
ulong    OpenTradeOrderTicket[];    //To store 'order' ticket for trades
//Place additional trade arrays here as required to assist with open trade management

CTrade my_trade;
CPositionInfo my_position;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(TradeSymbols == "CURRENT")  //Override TradeSymbols input variable and use the current chart symbol only
     {
      NumberOfTradeableSymbols = 1;

      ArrayResize(SymbolArray, 1);
      SymbolArray[0] = Symbol();
      Print("EA will process ", SymbolArray[0], " only");
     }
   else
     {
      string TradeSymbolsToUse = "";

      if(TradeSymbols == "ALL")
         TradeSymbolsToUse = AllSymbolsString;
      else
         TradeSymbolsToUse = TradeSymbols;

      //CONVERT TradeSymbolsToUse TO THE STRING ARRAY SymbolArray
      NumberOfTradeableSymbols = StringSplit(TradeSymbolsToUse, '|', SymbolArray);

      Print("EA will process: ", TradeSymbolsToUse);
     }

//RESIZE OPEN TRADE ARRAYS (based on how many symbols are being traded)
   ResizeCoreArrays();

//RESIZE INDICATOR HANDLE ARRAYS
   ResizeIndicatorHandleArrays();

   Print("All arrays sized to accomodate ", NumberOfTradeableSymbols, " symbols");

//INITIALIZE ARAYS
   for(int SymbolLoop=0; SymbolLoop < NumberOfTradeableSymbols; SymbolLoop++)
      OpenTradeOrderTicket[SymbolLoop] = 0;

//INSTANTIATE INDICATOR HANDLES
   if(!SetUpIndicatorHandles())
      return(INIT_FAILED);

   my_trade.SetDeviationInPoints(my_slippage);
   my_trade.SetExpertMagicNumber(my_magic_number);
   my_trade.SetAsyncMode(false);

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Comment("\n\rMulti-Symbol EA Stopped");
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   TicksReceivedCount++;
   string indicatorMetrics = "";

//LOOP THROUGH EACH SYMBOL TO CHECK FOR ENTRIES AND EXITS, AND THEN OPEN/CLOSE TRADES AS APPROPRIATE
   for(int SymbolLoop = 0; SymbolLoop < NumberOfTradeableSymbols; SymbolLoop++)
     {
      string CurrentIndicatorValues; //passed by ref below

      //GET OPEN SIGNAL (BOLLINGER BANDS SIMPLY USED AS AN EXAMPLE)
      string OpenSignalStatus = GetBBandsOpenSignalStatus(SymbolLoop, CurrentIndicatorValues);
      StringConcatenate(indicatorMetrics, indicatorMetrics, SymbolArray[SymbolLoop], "  |  ", CurrentIndicatorValues, "  |  OPEN_STATUS=", OpenSignalStatus, "  |  ");

      //PROCESS TRADE OPENS
      if((OpenSignalStatus == "LONG" || OpenSignalStatus == "SHORT") && OpenTradeOrderTicket[SymbolLoop] == 0)
         ProcessTradeOpen(SymbolLoop, OpenSignalStatus);

      ProcessTrailingStop(SymbolLoop);
     }

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ResizeCoreArrays()
  {
   ArrayResize(OpenTradeOrderTicket, NumberOfTradeableSymbols);
//Add other trade arrays here as required
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ResizeIndicatorHandleArrays()
  {
//Indicator Handles
   ArrayResize(handle_BollingerBands, NumberOfTradeableSymbols);
//Add other indicators here as required by your EA
  }

//SET UP REQUIRED INDICATOR HANDLES (arrays because of multi-symbol capability in EA)
bool SetUpIndicatorHandles()
  {
//Bollinger Bands
   for(int SymbolLoop=0; SymbolLoop < NumberOfTradeableSymbols; SymbolLoop++)
     {
      //Reset any previous error codes so that only gets set if problem setting up indicator handle
      ResetLastError();

      handle_BollingerBands[SymbolLoop] = iBands(SymbolArray[SymbolLoop], Period(), BBandsPeriods, 0, BBandsDeviations, PRICE_CLOSE);

      if(handle_BollingerBands[SymbolLoop] == INVALID_HANDLE)
        {
         string outputMessage = "";

         if(GetLastError() == 4302)
            outputMessage = "Symbol needs to be added to the MarketWatch";
         else
            StringConcatenate(outputMessage, "(error code ", GetLastError(), ")");

         MessageBox("Failed to create handle of the iBands indicator for " + SymbolArray[SymbolLoop] + "/" + EnumToString(Period()) + "\n\r\n\r" +
                    outputMessage +
                    "\n\r\n\rEA will now terminate.");

         //Don't proceed
         return false;
        }

      Print("Handle for iBands / ", SymbolArray[SymbolLoop], " / ", EnumToString(Period()), " successfully created");
     }

//All completed without errors so return true
   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string GetBBandsOpenSignalStatus(int SymbolLoop, string& signalDiagnosticMetrics)
  {
   string CurrentSymbol = SymbolArray[SymbolLoop];

//Need to copy values from indicator buffers to local buffers
   int      numValuesNeeded = 3;
   double   bufferUpper[];
   double   bufferLower[];
   MqlRates MyCandle[];

   bool fillSuccessUpper =    tlamCopyBuffer(handle_BollingerBands[SymbolLoop], UPPER_BAND, bufferUpper, numValuesNeeded, CurrentSymbol, "BBANDS");
   bool fillSuccessLower =    tlamCopyBuffer(handle_BollingerBands[SymbolLoop], LOWER_BAND, bufferLower, numValuesNeeded, CurrentSymbol, "BBANDS");
   bool fillSuccessCandles =  tlamCopyRates(10, MyCandle, CurrentSymbol, "Candle");

   if(fillSuccessUpper == false  ||  fillSuccessLower == false || fillSuccessCandles == false)
      return("FILL_ERROR");     //No need to log error here. Already done from tlamCopyBuffer() function

   double CurrentBBandsUpper = bufferUpper[0];
   double CurrentBBandsLower = bufferLower[0];
   double Candle_1_ago_Close = MyCandle[1].close;
   double Candle_1_ago_Open = MyCandle[1].open;
   double Candle_2_ago_Close = MyCandle[2].close;
   double Candle_2_ago_Open = MyCandle[2].open;

   double CurrentClose = iClose(CurrentSymbol, Period(), 0);

//SET METRICS FOR BBANDS WHICH GET RETURNED TO CALLING FUNCTION BY REF FOR OUTPUT TO CHART
   StringConcatenate(signalDiagnosticMetrics, "UPPER=", DoubleToString(CurrentBBandsUpper, (int)SymbolInfoInteger(CurrentSymbol, SYMBOL_DIGITS)), "  |  LOWER=", DoubleToString(CurrentBBandsLower, (int)SymbolInfoInteger(CurrentSymbol, SYMBOL_DIGITS)), "  |  CLOSE=" + DoubleToString(CurrentClose, (int)SymbolInfoInteger(CurrentSymbol, SYMBOL_DIGITS)));


//INSERT YOUR OWN ENTRY LOGIC HERE
   if((Candle_2_ago_Open>=bufferLower[2] && Candle_2_ago_Close<bufferLower[2]) && (Candle_1_ago_Open<=bufferLower[1] && Candle_1_ago_Close>bufferLower[1]))
      return "LONG";
   if((Candle_2_ago_Open<=bufferUpper[2] && Candle_2_ago_Close>bufferUpper[2]) && (Candle_1_ago_Open>=bufferUpper[1] && Candle_1_ago_Close<bufferUpper[1]))
      return "SHORT";

   return("NO_TRADE");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool tlamCopyBuffer(int ind_handle,            // handle of the indicator
                    int buffer_num,            // for indicators with multiple buffers
                    double &localArray[],      // local array
                    int numBarsRequired,       // number of values to copy
                    string symbolDescription,
                    string indDesc)
  {

   int availableBars;
   bool success = false;
   int failureCount = 0;

//Sometimes a delay in prices coming through can cause failure, so allow 3 attempts
   while(!success)
     {
      availableBars = BarsCalculated(ind_handle);

      if(availableBars < numBarsRequired)
        {
         failureCount++;

         if(failureCount >= 3)
           {
            Print("Failed to calculate sufficient bars in tlamCopyBuffer() after ", failureCount, " attempts (", symbolDescription, "/", indDesc, " - Required=", numBarsRequired, " Available=", availableBars, ")");
            return(false);
           }

         Print("Attempt ", failureCount, ": Insufficient bars calculated for ", symbolDescription, "/", indDesc, "(Required=", numBarsRequired, " Available=", availableBars, ")");

         //Sleep for 0.1s to allow time for price data to become usable
         Sleep(100);
        }
      else
        {
         success = true;

         if(failureCount > 0) //only write success message if previous failures registered
            Print("Succeeded on attempt ", failureCount+1);
        }
     }

   ResetLastError();

   int numAvailableBars = CopyBuffer(ind_handle, buffer_num, 0, numBarsRequired, localArray);

   if(numAvailableBars != numBarsRequired)
     {
      Print("Failed to copy data from indicator with error code ", GetLastError(), ". Bars required = ", numBarsRequired, " but bars copied = ", numAvailableBars);
      return(false);
     }

//Ensure that elements indexed like in a timeseries (with index 0 being the current, 1 being one bar back in time etc.)
   ArraySetAsSeries(localArray, true);

   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool tlamCopyRates(int numBarsRequired, MqlRates &localArray[], string symbolDescription, string indDesc)
  {
   int availableBars;
   bool success = false;

   int failureCount = 0;

   while(!success)
     {
      availableBars = Bars(symbolDescription,PERIOD_CURRENT);

      if(availableBars < numBarsRequired)
        {
         failureCount++;

         if(failureCount >= 3)
           {
            Print("Failed to calculate sufficient bars in tlamCopyRates() after ", failureCount, " attempts (", symbolDescription, "/", indDesc, " - Required=", numBarsRequired, " Available=", availableBars, ")");
            return(false);
           }

         Print("Attempt ", failureCount, ": Insufficient bars calculated for ", symbolDescription, "/", indDesc, "(Required=", numBarsRequired, " Available=", availableBars, ")");

         //Sleep for 0.1s to allow time for price data to become usable
         Sleep(100);
        }
      else
        {
         success = true;

         if(failureCount > 0) //only write success message if previous failures registered
            Print("Succeeded on attempt ", failureCount+1);
        }
     }

   ResetLastError();

   int numAvailableBars = CopyRates(symbolDescription,PERIOD_CURRENT,0,numBarsRequired,localArray);

   if(numAvailableBars != numBarsRequired)
     {
      Print("Failed to copy data from indicator with error code ", GetLastError(), ". Bars required = ", numBarsRequired, " but bars copied = ", numAvailableBars);
      return(false);
     }

//Ensure that elements indexed like in a timeseries (with index 0 being the current, 1 being one bar back in time etc.)
   ArraySetAsSeries(localArray, true);

   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ProcessTradeOpen(int SymbolLoop, string TradeDirection)
  {
   string CurrentSymbol = SymbolArray[SymbolLoop];
   int total = PositionsTotal();
   double my_ask = SymbolInfoDouble(CurrentSymbol,SYMBOL_ASK);
   double my_bid = SymbolInfoDouble(CurrentSymbol,SYMBOL_BID);
   double tick_point = SymbolInfoDouble(CurrentSymbol,SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(CurrentSymbol,SYMBOL_DIGITS);
   double buy_sl, buy_tp, sell_sl, sell_tp;

   for(int i=total-1; i>=0; i--)
     {
      string symb = PositionGetSymbol(i);
      if(symb==CurrentSymbol)
        {
         ulong ticket = PositionGetTicket(i);
         if(ticket>0)
           {
            if(TradeDirection == "LONG" && my_position.PositionType()==POSITION_TYPE_SELL)
               my_trade.PositionClose(ticket,my_slippage);
            if(TradeDirection == "SHORT" && my_position.PositionType()==POSITION_TYPE_BUY)
               my_trade.PositionClose(ticket,my_slippage);
           }
        }
     }

   if(TradeDirection == "LONG" && NewCandle(CurrentSymbol))
     {
      if(CurrentSymbol==SymbolArray[0])
        {
         buy_sl = NormalizeDouble(my_bid-tick_point*my_sl_buy_01,digits);
         buy_tp = NormalizeDouble(my_bid+tick_point*my_tp_buy_01,digits);
         my_trade.Buy(my_volume,CurrentSymbol,my_ask,buy_sl,buy_tp);
        }

      if(CurrentSymbol==SymbolArray[1])
        {
         buy_sl = NormalizeDouble(my_bid-tick_point*my_sl_buy_02,digits);
         buy_tp = NormalizeDouble(my_bid+tick_point*my_tp_buy_02,digits);
         my_trade.Buy(my_volume,CurrentSymbol,my_ask,buy_sl,buy_tp);
        }

      if(CurrentSymbol==SymbolArray[2])
        {
         buy_sl = NormalizeDouble(my_bid-tick_point*my_sl_buy_03,digits);
         buy_tp = NormalizeDouble(my_bid+tick_point*my_tp_buy_03,digits);
         my_trade.Buy(my_volume,CurrentSymbol,my_ask,buy_sl,buy_tp);
        }

      if(CurrentSymbol==SymbolArray[3])
        {
         buy_sl = NormalizeDouble(my_bid-tick_point*my_sl_buy_04,digits);
         buy_tp = NormalizeDouble(my_bid+tick_point*my_tp_buy_04,digits);
         my_trade.Buy(my_volume,CurrentSymbol,my_ask,buy_sl,buy_tp);
        }

      if(CurrentSymbol==SymbolArray[4])
        {
         buy_sl = NormalizeDouble(my_bid-tick_point*my_sl_buy_05,digits);
         buy_tp = NormalizeDouble(my_bid+tick_point*my_tp_buy_05,digits);
         my_trade.Buy(my_volume,CurrentSymbol,my_ask,buy_sl,buy_tp);
        }

      if(CurrentSymbol==SymbolArray[5])
        {
         buy_sl = NormalizeDouble(my_bid-tick_point*my_sl_buy_06,digits);
         buy_tp = NormalizeDouble(my_bid+tick_point*my_tp_buy_06,digits);
         my_trade.Buy(my_volume,CurrentSymbol,my_ask,buy_sl,buy_tp);
        }

     }
   if(TradeDirection == "SHORT" && NewCandle(CurrentSymbol))
     {
      if(CurrentSymbol==SymbolArray[0])
        {
         sell_sl = NormalizeDouble(my_ask+tick_point*my_sl_sell_01,digits);
         sell_tp = NormalizeDouble(my_ask-tick_point*my_tp_sell_01,digits);
         my_trade.Sell(my_volume,CurrentSymbol,my_bid,sell_sl,sell_tp);
        }

      if(CurrentSymbol==SymbolArray[1])
        {
         sell_sl = NormalizeDouble(my_ask+tick_point*my_sl_sell_02,digits);
         sell_tp = NormalizeDouble(my_ask-tick_point*my_tp_sell_02,digits);
         my_trade.Sell(my_volume,CurrentSymbol,my_bid,sell_sl,sell_tp);
        }

      if(CurrentSymbol==SymbolArray[2])
        {
         sell_sl = NormalizeDouble(my_ask+tick_point*my_sl_sell_03,digits);
         sell_tp = NormalizeDouble(my_ask-tick_point*my_tp_sell_03,digits);
         my_trade.Sell(my_volume,CurrentSymbol,my_bid,sell_sl,sell_tp);
        }

      if(CurrentSymbol==SymbolArray[3])
        {
         sell_sl = NormalizeDouble(my_ask+tick_point*my_sl_sell_04,digits);
         sell_tp = NormalizeDouble(my_ask-tick_point*my_tp_sell_04,digits);
         my_trade.Sell(my_volume,CurrentSymbol,my_bid,sell_sl,sell_tp);
        }

      if(CurrentSymbol==SymbolArray[4])
        {
         sell_sl = NormalizeDouble(my_ask+tick_point*my_sl_sell_05,digits);
         sell_tp = NormalizeDouble(my_ask-tick_point*my_tp_sell_05,digits);
         my_trade.Sell(my_volume,CurrentSymbol,my_bid,sell_sl,sell_tp);
        }

      if(CurrentSymbol==SymbolArray[5])
        {
         sell_sl = NormalizeDouble(my_ask+tick_point*my_sl_sell_06,digits);
         sell_tp = (double)NormalizeDouble(my_ask-tick_point*my_tp_sell_06,digits);
         my_trade.Sell(my_volume,CurrentSymbol,my_bid,sell_sl,sell_tp);
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool NewCandle(string CurrentSymbol)
  {
   static int BarsOnChart=0;
   if(Bars(CurrentSymbol,PERIOD_CURRENT) == BarsOnChart)
      return (false);
   BarsOnChart = Bars(CurrentSymbol,PERIOD_CURRENT);
   return(true);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ProcessTrailingStop(int SymbolLoop)
  {
   Sleep(500);
   string CurrentSymbol = SymbolArray[SymbolLoop];
   int total = PositionsTotal();
   double my_ask = SymbolInfoDouble(CurrentSymbol,SYMBOL_ASK);
   double my_bid = SymbolInfoDouble(CurrentSymbol,SYMBOL_BID);
   double tick_point = SymbolInfoDouble(CurrentSymbol,SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(CurrentSymbol,SYMBOL_DIGITS);

   for(int i=total-1; i>=0; i--)
     {
      string symb = PositionGetSymbol(i);
      if(symb==CurrentSymbol)
        {
         ulong ticket = PositionGetTicket(i);
         if(PositionSelectByTicket(ticket))
           {
            if(CurrentSymbol==SymbolArray[0] && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY && my_bid-PositionGetDouble(POSITION_PRICE_OPEN)>TrailStopBuy_01*tick_point && my_bid-(TrailStepBuy_01*tick_point)>PositionGetDouble(POSITION_SL))
              {
               double tp = PositionGetDouble(POSITION_TP);
               double sl = NormalizeDouble(my_bid-(TrailStepBuy_01*tick_point),digits);
               if(TrailStepBuy_01*tick_point>=SymbolInfoInteger(CurrentSymbol,SYMBOL_TRADE_STOPS_LEVEL) && SymbolInfoInteger(CurrentSymbol,SYMBOL_SPREAD)<=NormalizeDouble(MathAbs(my_bid-sl),digits)*MathPow(10,digits))
                  my_trade.PositionModify(ticket,sl,tp);
              }

            if(CurrentSymbol==SymbolArray[1] && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY && my_bid-PositionGetDouble(POSITION_PRICE_OPEN)>TrailStopBuy_02*tick_point && my_bid-(TrailStepBuy_02*tick_point)>PositionGetDouble(POSITION_SL))
              {
               double tp = PositionGetDouble(POSITION_TP);
               double sl = NormalizeDouble(my_bid-(TrailStepBuy_02*tick_point),digits);
               if(TrailStepBuy_02*tick_point>=SymbolInfoInteger(CurrentSymbol,SYMBOL_TRADE_STOPS_LEVEL) && SymbolInfoInteger(CurrentSymbol,SYMBOL_SPREAD)<=NormalizeDouble(MathAbs(my_bid-sl),digits)*MathPow(10,digits))
                  my_trade.PositionModify(ticket,sl,tp);
              }

            if(CurrentSymbol==SymbolArray[2] && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY && my_bid-PositionGetDouble(POSITION_PRICE_OPEN)>TrailStopBuy_03*tick_point && my_bid-(TrailStepBuy_03*tick_point)>PositionGetDouble(POSITION_SL))
              {
               double tp = PositionGetDouble(POSITION_TP);
               double sl = NormalizeDouble(my_bid-(TrailStepBuy_03*tick_point),digits);
               if(TrailStepBuy_03*tick_point>=SymbolInfoInteger(CurrentSymbol,SYMBOL_TRADE_STOPS_LEVEL) && SymbolInfoInteger(CurrentSymbol,SYMBOL_SPREAD)<=NormalizeDouble(MathAbs(my_bid-sl),digits)*MathPow(10,digits))
                  my_trade.PositionModify(ticket,sl,tp);
              }

            if(CurrentSymbol==SymbolArray[3] && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY && my_bid-PositionGetDouble(POSITION_PRICE_OPEN)>TrailStopBuy_04*tick_point && my_bid-(TrailStepBuy_04*tick_point)>PositionGetDouble(POSITION_SL))
              {
               double tp = PositionGetDouble(POSITION_TP);
               double sl = NormalizeDouble(my_bid-(TrailStepBuy_04*tick_point),digits);
               if(TrailStepBuy_04*tick_point>=SymbolInfoInteger(CurrentSymbol,SYMBOL_TRADE_STOPS_LEVEL) && SymbolInfoInteger(CurrentSymbol,SYMBOL_SPREAD)<=NormalizeDouble(MathAbs(my_bid-sl),digits)*MathPow(10,digits))
                  my_trade.PositionModify(ticket,sl,tp);
              }

            if(CurrentSymbol==SymbolArray[4] && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY && my_bid-PositionGetDouble(POSITION_PRICE_OPEN)>TrailStopBuy_05*tick_point && my_bid-(TrailStepBuy_05*tick_point)>PositionGetDouble(POSITION_SL))
              {
               double tp = PositionGetDouble(POSITION_TP);
               double sl = NormalizeDouble(my_bid-(TrailStepBuy_05*tick_point),digits);
               if(TrailStepBuy_05*tick_point>=SymbolInfoInteger(CurrentSymbol,SYMBOL_TRADE_STOPS_LEVEL) && SymbolInfoInteger(CurrentSymbol,SYMBOL_SPREAD)<=NormalizeDouble(MathAbs(my_bid-sl),digits)*MathPow(10,digits))
                  my_trade.PositionModify(ticket,sl,tp);
              }

            if(CurrentSymbol==SymbolArray[5] && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY && my_bid-PositionGetDouble(POSITION_PRICE_OPEN)>TrailStopBuy_06*tick_point && my_bid-(TrailStepBuy_06*tick_point)>PositionGetDouble(POSITION_SL))
              {
               double tp = PositionGetDouble(POSITION_TP);
               double sl = NormalizeDouble(my_bid-(TrailStepBuy_06*tick_point),digits);
               if(TrailStepBuy_06*tick_point>=SymbolInfoInteger(CurrentSymbol,SYMBOL_TRADE_STOPS_LEVEL) && SymbolInfoInteger(CurrentSymbol,SYMBOL_SPREAD)<=NormalizeDouble(MathAbs(my_bid-sl),digits)*MathPow(10,digits))
                  my_trade.PositionModify(ticket,sl,tp);
              }

            if(CurrentSymbol==SymbolArray[0] && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL && PositionGetDouble(POSITION_PRICE_OPEN)-my_ask>TrailStopSell_01*tick_point && my_ask+(TrailStepSell_01*tick_point)<PositionGetDouble(POSITION_SL))
              {
               double tp = PositionGetDouble(POSITION_TP);
               double sl = NormalizeDouble(my_ask+(TrailStepSell_01*tick_point),digits);
               if(TrailStepSell_01*tick_point>=SymbolInfoInteger(CurrentSymbol,SYMBOL_TRADE_STOPS_LEVEL) && SymbolInfoInteger(CurrentSymbol,SYMBOL_SPREAD)<=NormalizeDouble(MathAbs(my_ask-sl),Digits())*MathPow(10,digits))
                  my_trade.PositionModify(ticket,sl,tp);
              }

            if(CurrentSymbol==SymbolArray[1] && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL && PositionGetDouble(POSITION_PRICE_OPEN)-my_ask>TrailStopSell_02*Point() && my_ask+(TrailStepSell_02*tick_point)<PositionGetDouble(POSITION_SL))
              {
               double tp = PositionGetDouble(POSITION_TP);
               double sl = NormalizeDouble(my_ask+(TrailStepSell_02*tick_point),digits);
               if(TrailStepSell_02*tick_point>=SymbolInfoInteger(CurrentSymbol,SYMBOL_TRADE_STOPS_LEVEL) && SymbolInfoInteger(CurrentSymbol,SYMBOL_SPREAD)<=NormalizeDouble(MathAbs(my_ask-sl),Digits())*MathPow(10,digits))
                  my_trade.PositionModify(ticket,sl,tp);
              }

            if(CurrentSymbol==SymbolArray[2] && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL && PositionGetDouble(POSITION_PRICE_OPEN)-my_ask>TrailStopSell_03*Point() && my_ask+(TrailStepSell_03*tick_point)<PositionGetDouble(POSITION_SL))
              {
               double tp = PositionGetDouble(POSITION_TP);
               double sl = NormalizeDouble(my_ask+(TrailStepSell_03*tick_point),digits);
               if(TrailStepSell_03*tick_point>=SymbolInfoInteger(CurrentSymbol,SYMBOL_TRADE_STOPS_LEVEL) && SymbolInfoInteger(CurrentSymbol,SYMBOL_SPREAD)<=NormalizeDouble(MathAbs(my_ask-sl),Digits())*MathPow(10,digits))
                  my_trade.PositionModify(ticket,sl,tp);
              }

            if(CurrentSymbol==SymbolArray[3] && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL && PositionGetDouble(POSITION_PRICE_OPEN)-my_ask>TrailStopSell_04*Point() && my_ask+(TrailStepSell_04*tick_point)<PositionGetDouble(POSITION_SL))
              {
               double tp = PositionGetDouble(POSITION_TP);
               double sl = NormalizeDouble(my_ask+(TrailStepSell_04*tick_point),digits);
               if(TrailStepSell_04*tick_point>=SymbolInfoInteger(CurrentSymbol,SYMBOL_TRADE_STOPS_LEVEL) && SymbolInfoInteger(CurrentSymbol,SYMBOL_SPREAD)<=NormalizeDouble(MathAbs(my_ask-sl),Digits())*MathPow(10,digits))
                  my_trade.PositionModify(ticket,sl,tp);
              }

            if(CurrentSymbol==SymbolArray[4] && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL && PositionGetDouble(POSITION_PRICE_OPEN)-my_ask>TrailStopSell_05*Point() && my_ask+(TrailStepSell_05*tick_point)<PositionGetDouble(POSITION_SL))
              {
               double tp = PositionGetDouble(POSITION_TP);
               double sl = NormalizeDouble(my_ask+(TrailStepSell_05*tick_point),digits);
               if(TrailStepSell_05*tick_point>=SymbolInfoInteger(CurrentSymbol,SYMBOL_TRADE_STOPS_LEVEL) && SymbolInfoInteger(CurrentSymbol,SYMBOL_SPREAD)<=NormalizeDouble(MathAbs(my_ask-sl),Digits())*MathPow(10,digits))
                  my_trade.PositionModify(ticket,sl,tp);
              }

            if(CurrentSymbol==SymbolArray[5] && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL && PositionGetDouble(POSITION_PRICE_OPEN)-my_ask>TrailStopSell_06*Point() && my_ask+(TrailStepSell_06*tick_point)<PositionGetDouble(POSITION_SL))
              {
               double tp = PositionGetDouble(POSITION_TP);
               double sl = NormalizeDouble(my_ask+(TrailStepSell_06*tick_point),digits);
               if(TrailStepSell_06*tick_point>=SymbolInfoInteger(CurrentSymbol,SYMBOL_TRADE_STOPS_LEVEL) && SymbolInfoInteger(CurrentSymbol,SYMBOL_SPREAD)<=NormalizeDouble(MathAbs(my_ask-sl),Digits())*MathPow(10,digits))
                  my_trade.PositionModify(ticket,sl,tp);
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
