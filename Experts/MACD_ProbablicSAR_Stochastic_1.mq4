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

input ENUM_TIMEFRAMES BTF   = PERIOD_W1;
input ENUM_TIMEFRAMES MTF   = PERIOD_D1;
input ENUM_TIMEFRAMES LTF   = PERIOD_H4;
//input bool LOGFileActivated =  false;
input string LogFileName    = "MACD_ProbablicSAR_Stochastic_1_LogFile.csv";
input int TimerInterval     = 60 * 5 ;  

datetime     TimeBegin = D'2000.01.01 00:00:00',
             TimeEnd   = D'2999.01.01 23:59:59'; 

int    LogFileHandle = INVALID_HANDLE;

#ifndef LOG
#define LOG(text) //FileWrite(LogFileHandle, text);
#endif

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
     CloseOldPosition();
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
   MqlDateTime Now,
               Start,
               End;            

   TimeToStruct(TimeLocal(), Now);
   TimeToStruct(TimeBegin, Start);
   TimeToStruct(TimeEnd, End);
   
   if (Now.day_of_week != 6 && Now.day_of_week != 7 &&  //اگر شنبه و یکشنبه نیست
       Now.hour >= Start.hour && Now.hour <= End.hour)  //در طول بیست و چهار ساعت - قابل تنظیم است
   {
      int iRet = 0;
      
      iRet = CloseOldPosition();
      iRet = FindNewPosition();
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
//| Look for a new probable trade position                           |
//+------------------------------------------------------------------+
int FindNewPosition()
{
   int     iRet = 0;
   CHelper helper;
   string  NameSymbol,
           BTFAction,
           MTFAction,
           LTFAction;
       
   for(int iCntr = 0; iCntr < SymbolsTotal(true); iCntr++)
   {    
      NameSymbol = SymbolName(iCntr, true);
   
      BTFAction = "";
      MTFAction = "";
      LTFAction = "";
     
      BTFAction = helper.CheckTF(BTF, NameSymbol, LogFileHandle);
      MTFAction = helper.CheckTF(MTF, NameSymbol, LogFileHandle);
      LTFAction = helper.CheckTF(LTF, NameSymbol, LogFileHandle);
   
      LOG("----------------------------------------------------------------------------------------------------");
      
      if(BTFAction == MTFAction && BTFAction == LTFAction && BTFAction != "")
      {
         if (BTFAction == ACTION_BUY)
         {
            Alert("[" + NameSymbol + ", Buy]");
            LOG("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^");
            LOG("[" + NameSymbol + ", Buy]");
            LOG("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^");
            iRet++;
            tms_send(StringFormat("[%s, Buy]", NameSymbol), TMSRV_TOKEN); 
         }
         else if (BTFAction == ACTION_SELL)
         {
            Alert("[" + NameSymbol + ", Sell]");                                                                    
            LOG("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^");
            LOG("[" + NameSymbol + ", Sell]");
            LOG("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^");
            iRet++;
            tms_send(StringFormat("[%s, Sell]", NameSymbol), TMSRV_TOKEN); 
         }
         PlaySound("OK.wav");
      }
   }
   return (iRet);
}
//+------------------------------------------------------------------+
//| Look for a new probable trade position                           |
//+------------------------------------------------------------------+
int CloseOldPosition()
{
   int     iRet = 0;

   return (iRet);
}
//+------------------------------------------------------------------+
