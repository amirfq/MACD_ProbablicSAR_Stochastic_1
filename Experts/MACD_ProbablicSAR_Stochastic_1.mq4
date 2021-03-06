//+------------------------------------------------------------------+
//|                               MACD_ProbablicSAR_Stochastic_1.mq4 |
//|                        Copyright 2019, Amirfarrokh Ghanbar Pour  |
//|                                           https://www.amirfg.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, Amirfarrokh Ghanbar Pour"
#property link      "https://www.amirfg.com"
#property version   "1.00"
#property strict

#include <MACD_ProbablicSAR_Stochastic_1.mqh>

input ENUM_TIMEFRAMES BTF   = PERIOD_H4;
input ENUM_TIMEFRAMES MTF   = PERIOD_H1;
input ENUM_TIMEFRAMES LTF   = PERIOD_M15;
//input bool LOGFileActivated =  false;
input string LogFileName    = "MACD_ProbablicSAR_Stochastic_1_LogFile.csv";
input int TimerInterval     = 60;  

input double TakeProfit     = 50;
input double StopLoss       = 25;
input double Lots           = 0.01;
input int    Slippage       = 3;

datetime     TimeBegin = D'2000.01.01 00:00:00',
             TimeEnd   = D'2999.01.01 23:59:59'; 

int      LogFileHandle = INVALID_HANDLE;

struct TFDecisions
   {
      string BTFAction,
             MTFAction,
             LTFAction;
   };

#ifndef LOG
#define LOG(text) FileWrite(LogFileHandle, text);
#endif

#define CLOSEING_ARROW_COLOR  Violet
#define BUY_ARROW_COLOR       Green
#define SELL_ARROW_COLOR      Red
#define MIN_ACC_BALANCE       1500
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
     ResetLastError();
     
     LogFileHandle = FileOpen(LogFileName, FILE_WRITE|FILE_CSV);
     if (LogFileHandle != INVALID_HANDLE)
      {
         tms_send(StringFormat("MACD_ProbablicSAR_Stochastic_1 Expert Advisor Started: %s", TimeToStr(TimeLocal(), TIME_DATE|TIME_SECONDS)), TMSRV_TOKEN); 
         LOG("Started: " + TimeToStr(TimeLocal(), TIME_DATE|TIME_SECONDS));
         EventSetTimer(TimerInterval); 
         return(INIT_SUCCEEDED);
      }
     return(INIT_FAILED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
     tms_send(StringFormat("MACD_ProbablicSAR_Stochastic_1 Expert Advisor Stoped: %s", TimeToStr(TimeLocal(), TIME_DATE|TIME_SECONDS)), TMSRV_TOKEN); 
     EventKillTimer();
     LOG("\nStoped: " + TimeToStr(TimeLocal(), TIME_DATE|TIME_SECONDS))
     FileClose(LogFileHandle);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
   CHelper helper;
   MqlDateTime Now,
               Start,
               End;
   string      NameSymbol;            

   TimeToStruct(TimeLocal(), Now);
   TimeToStruct(TimeBegin, Start);
   TimeToStruct(TimeEnd, End);
   
   if (Now.day_of_week != 6 && Now.day_of_week != 0 &&  //اگر شنبه و یکشنبه نیست
       Now.hour >= Start.hour && Now.hour <= End.hour)  //در طول بیست و چهار ساعت - قابل تنظیم است
   {
      int    iRet,
             iOrderType,
             iTicketNumber;
      double dVolume,
             dBid,
             dAsk;    
      TFDecisions TFD;
      
      for(int iCntr = 0; iCntr < SymbolsTotal(true); iCntr++)
      {    
      
         NameSymbol    = SymbolName(iCntr, true);
         iTicketNumber = -1;
         dVolume       = 0.00;
         dBid          = 0.00;
         dAsk          = 0.00;
         iOrderType = IsAnOpenPosition(NameSymbol, iTicketNumber, dVolume, dBid, dAsk);
         
         TFD.BTFAction = "";
         TFD.MTFAction = "";
         TFD.LTFAction = "";
        
         TFD.BTFAction = helper.CheckTF(BTF, NameSymbol, LogFileHandle);
         TFD.MTFAction = helper.CheckTF(MTF, NameSymbol, LogFileHandle);
         TFD.LTFAction = helper.CheckTF(LTF, NameSymbol, LogFileHandle);

         LOG("---------------------------------------- Close Old Positions ---------------------------------------");
         if(iOrderType == OP_BUY || iOrderType == OP_SELL)
            iRet = CloseOldPosition(NameSymbol, iOrderType, TFD, iTicketNumber, dVolume, dBid, dAsk);  //اول امکان بستن پوزیشن های خرید و فروش احتمالی را بررسی می کنم
         LOG("--------------------------------------- Look For New Positions -------------------------------------");
         iTicketNumber = -1;
         dVolume       = 0.00;
         dBid          = 0.00;
         dAsk          = 0.00;
         iOrderType = IsAnOpenPosition(NameSymbol, iTicketNumber, dVolume, dBid, dAsk);
         if(iOrderType == -1)                              //چنانچه سمبول مورد نظر پوزیشن خرید يا فروش باز داشته باشد، دوباره روی آن وارد معامله نمی شوم، تا زمانی که پوزیشن قبلی بسته شود
            if(AccountFreeMargin() > (1000 * Lots) && AccountBalance() > MIN_ACC_BALANCE)        //اهرم 100 استفاده می کنم
                                                                                               //بعلاوه اگر مانده حسابم از حداقلی که تعيين کرده ام پايين تر برود، اجازه معامله نمی دهم
            
               iRet = FindNewPosition(NameSymbol, TFD);
            else
            {
               LOG("Insufficient Free Margin or MIN_ACC BALANCE reached! Check it immediately!");
               tms_send("Insufficient Free Margin or MIN_ACC BALANCE reached! Check it immediately!", TMSRV_TOKEN); 

            }
         LOG("----------------------------------------------------------------------------------------------------");
      }
   }
  }
//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
   double ret=0.0;
   return(ret);
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
  }
//+------------------------------------------------------------------+
//| Look for a new probable trade position on this Symbol.           |
//+------------------------------------------------------------------+
int FindNewPosition(string NameSymbol, const TFDecisions &TFD)
{
   int iRet = -1;

   if(TFD.BTFAction == TFD.MTFAction && TFD.BTFAction == TFD.LTFAction && TFD.BTFAction != "")
   {
      if (TFD.BTFAction == ACTION_BUY)
      {
         Alert("[" + NameSymbol + ", Buy]");
         LOG("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^");
         LOG("[" + NameSymbol + ", Buy]");
         LOG("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^");
         iRet = 1;
         tms_send(StringFormat("[%s, Buy]", NameSymbol), TMSRV_TOKEN); 
         if (CreateBuyPosition(NameSymbol))
         {
            LOG("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^");
            LOG("[" + NameSymbol + ", Buy Position Successfully Created!]");
            LOG("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^");
            tms_send(StringFormat("[%s, Buy Position Successfully Created!]", NameSymbol), TMSRV_TOKEN); 
         }
         else
         {
            LOG("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^");
            LOG("[" + NameSymbol + ", Failed to Create Buy Position!]");
            LOG("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^");
            tms_send(StringFormat("[%s, Failed to Create Buy Position!]", NameSymbol), TMSRV_TOKEN); 
         }
      }
      else if (TFD.BTFAction == ACTION_SELL)
      {
         Alert("[" + NameSymbol + ", Sell]");                                                                    
         LOG("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^");
         LOG("[" + NameSymbol + ", Sell]");
         LOG("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^");
         iRet = 2;
         tms_send(StringFormat("[%s, Sell]", NameSymbol), TMSRV_TOKEN); 
         if (CreateSellPosition(NameSymbol))
         {
            LOG("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^");
            LOG("[" + NameSymbol + ", Sell Position Successfully Created!]");
            LOG("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^");
            tms_send(StringFormat("[%s, Sell Position Successfully Created!]", NameSymbol), TMSRV_TOKEN); 
         }
         else
         {
            LOG("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^");
            LOG("[" + NameSymbol + ", Failed to Create Sell Position!]");
            LOG("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^");
            tms_send(StringFormat("[%s, Failed to Create Sell Position!]", NameSymbol), TMSRV_TOKEN); 
         }
      }
      PlaySound("OK.wav");
   }
   else
   {
      LOG(StringFormat("No chance to trade on %s!", NameSymbol));
      iRet = 0;
   }

   return (iRet);
}
//+------------------------------------------------------------------+
//| Look for a new probable trade position have to be closed.        |
//+------------------------------------------------------------------+
int CloseOldPosition(const string NameSymbol, const int iOrderType, const TFDecisions &TFD, const int Ticket, const double Size, const double dBid, const double dAsk)
{
   int iRet = 0;
   
   if (iOrderType == OP_BUY  && TFD.BTFAction != ACTION_BUY)
   {
      if ((TFD.MTFAction == ACTION_SELL && TFD.LTFAction == ACTION_SELL) ||
          (TFD.MTFAction == ""          && TFD.LTFAction == ACTION_SELL))
          {
            if (OrderClose(Ticket, Size, dBid, Slippage, CLOSEING_ARROW_COLOR))
               {
                  LOG("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^");
                  LOG("[" + NameSymbol + " - Buy Position, Closed]");
                  LOG("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^");
                  iRet = 1;
                  tms_send(StringFormat("[%s - Buy Position, Closed]", NameSymbol), TMSRV_TOKEN);
               }
          }
      else
      {
         LOG(StringFormat("It is not proper time to close BUY position on %s!", NameSymbol));
      }
   }
   else if (iOrderType == OP_SELL && TFD.BTFAction != ACTION_SELL)
   {
      if ((TFD.MTFAction == ACTION_BUY && TFD.LTFAction == ACTION_BUY) ||
          (TFD.MTFAction == ""         && TFD.LTFAction == ACTION_BUY))
          {
            if (OrderClose(Ticket, Size, dAsk, Slippage, CLOSEING_ARROW_COLOR))
               {
                  LOG("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^");
                  LOG("[" + NameSymbol + " - Sell Position, Closed]");
                  LOG("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^");
                  iRet = 2;
                  tms_send(StringFormat("[%s - Sell Position, Closed]", NameSymbol), TMSRV_TOKEN);
               }
          }
      else
      {
         LOG(StringFormat("It is not proper time to close SELL position on %s!", NameSymbol));
      }
   }
   else
   {
      LOG(StringFormat("There is no open position or the current open position is on trend on %s!", NameSymbol));
   }

   return (iRet);
}
//+------------------------------------------------------------------+
//| Is there an open position for this Symbol?                       |
//+------------------------------------------------------------------+
int IsAnOpenPosition(string NameSymbol, int &iTicketNo, double &dLotSize, double &dBid, double &dAsk)
{
   int OpenOrdersCnt = 0;  
   int iRet = -1;

   OpenOrdersCnt=OrdersTotal();
   for (int iCntr = 0; iCntr < OpenOrdersCnt; iCntr++)
   {
      if (OrderSelect(iCntr, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderSymbol() == NameSymbol)
            {
               iTicketNo = OrderTicket();
               if(iTicketNo)
               {
                  dLotSize  = OrderLots();
                  dBid = SymbolInfoDouble(NameSymbol, SYMBOL_BID);
                  dAsk = SymbolInfoDouble(NameSymbol, SYMBOL_ASK);
                  return (OrderType());
               }
            }
      }
   }
   return (iRet);
}
//+------------------------------------------------------------------+
//| Create a buy position for the symbol                             |
//+------------------------------------------------------------------+
bool CreateBuyPosition(string NameSymbol)
{
   bool   bRet   = false;
   double dBid   = SymbolInfoDouble(NameSymbol, SYMBOL_BID),
          dAsk   = SymbolInfoDouble(NameSymbol, SYMBOL_ASK),
          dPoint = SymbolInfoDouble(NameSymbol, SYMBOL_POINT);

   int ticket = OrderSend(NameSymbol, OP_BUY, Lots, dAsk, Slippage, dBid - StopLoss * dPoint, dAsk + TakeProfit * dPoint, "Automatically created based on MACD_ProbablicSAR_Stochastic algorithm.", 0, 0, BUY_ARROW_COLOR);
   if (ticket > 0)
      if(OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
         bRet = true;

   return (bRet);
}
//+------------------------------------------------------------------+
//| Create a sell position for the symbol                            |
//+------------------------------------------------------------------+
bool CreateSellPosition(string NameSymbol)
{
   bool   bRet = false;
   double dBid   = SymbolInfoDouble(NameSymbol, SYMBOL_BID),
          dAsk   = SymbolInfoDouble(NameSymbol, SYMBOL_ASK),
          dPoint = SymbolInfoDouble(NameSymbol, SYMBOL_POINT);

   int ticket = OrderSend(NameSymbol, OP_SELL, Lots, dBid, Slippage, dAsk + StopLoss * dPoint, dBid - TakeProfit * dPoint, "Automatically created based on MACD_ProbablicSAR_Stochastic algorithm.", 0, 0, SELL_ARROW_COLOR);
   if (ticket > 0)
      if(OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
         bRet = true;

   return (bRet);
}
//+------------------------------------------------------------------+
