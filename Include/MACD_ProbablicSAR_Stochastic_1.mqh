//+------------------------------------------------------------------+
//|                               MACD_ProbablicSAR_Stochastic_1.mqh |
//|                         Copyright 2019, Amirfarrokh Ghanbar Pour |
//|                                           https://www.amirfg.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, Amirfarrokh Ghanbar Pour"
#property link      "https://www.amirfg.com"
#property strict

#include <tmsrv.mqh>

//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
#define ACTION_BUY  "BUY"
#define ACTION_SELL "SELL"

#define OVER_SELL_LEVEL 20
#define OVER_BUY_LEVEL  80

#ifndef LOG
#define LOG(text) FileWrite(LogFileHandle, text);
#endif 

string TMSRV_TOKEN = "66363878:849659c7";

//+------------------------------------------------------------------+
//| DLL imports                                                      |
//+------------------------------------------------------------------+
// #import "user32.dll"
//   int      SendMessageA(int hWnd,int Msg,int wParam,int lParam);
// #import "my_expert.dll"
//   int      ExpertRecalculate(int wParam,int lParam);
// #import
//+------------------------------------------------------------------+
//| EX5 imports                                                      |
//+------------------------------------------------------------------+
// #import "stdlib.ex5"
//   string ErrorDescription(int error_code);
// #import
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Class Helper.                                                    |
//| Purpose: Class of the trade strategy "Helper".                   |
//|          Implements required methods in strategy running.        |
//+------------------------------------------------------------------+
class CHelper
  {

   public:
   CHelper(void);
   ~CHelper(void);
   string CheckTF(ENUM_TIMEFRAMES, string, int);

   protected:
   struct Decesion_Data
   {
      double  MACDCurrent,
              MACDPrevious,
              MACDSignalCurrent,
              MACDSignalPrevious,
              SARCurrent,
              SARPrevious,
              StoxMainCurrent,
              StoxMainPrevious,
              StoxSignalCurrent,
              StoxSignalPrevious,
              OpenCurrent,
              OpenPrevious,
              CloseCurrent,
              ClosePrevious,
              HighCurrent,
              HighPrevious,
              LowCurrent,
              LowPrevious;
      MqlTick Last_Tick;
   };
   void CheckMACD(ENUM_TIMEFRAMES,string,int, Decesion_Data &);
   void CheckSAR(ENUM_TIMEFRAMES,string,int, Decesion_Data &);
   void CheckStochastic(ENUM_TIMEFRAMES,string,int, Decesion_Data &);
   bool MACDSellSignal(const Decesion_Data &);
   bool MACDBuySignal(const Decesion_Data &);
   bool STOXOverBuy(const Decesion_Data &);
   bool STOXOverSell(const Decesion_Data &);
   bool STOXUpward(const Decesion_Data &);
   bool STOXDownward(const Decesion_Data &);
   string Decide(const Decesion_Data &);
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CHelper::CHelper(void)
  {
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CHelper::~CHelper(void)
  {
  }
//+------------------------------------------------------------------+
//| Check chart in specifid Timeframe                                |
//+------------------------------------------------------------------+
string CHelper::CheckTF(ENUM_TIMEFRAMES TF, string NameSymbol, int LogFileHandle)
  {
   Decesion_Data   DecesionData  = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0};
   string Action = "";
   
   DecesionData.OpenCurrent  = iOpen(NameSymbol, TF, 0);
   DecesionData.OpenPrevious = iOpen(NameSymbol, TF, 1);
   
   DecesionData.CloseCurrent  = iClose(NameSymbol, TF, 0);
   DecesionData.ClosePrevious = iClose(NameSymbol, TF, 1);
   
   DecesionData.HighCurrent  = iHigh(NameSymbol, TF, 0);
   DecesionData.HighPrevious = iHigh(NameSymbol, TF, 1);
   
   DecesionData.LowCurrent  = iLow(NameSymbol, TF, 0);
   DecesionData.LowPrevious = iLow(NameSymbol, TF, 1);

   SymbolInfoTick(NameSymbol, DecesionData.Last_Tick);

   LOG("\nPrice Check: " + TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS) +
       "\nTF=" + EnumToString(TF) +
       " Symbol=" + NameSymbol +
       "\nCurrent  Open=" + DoubleToStr(DecesionData.OpenCurrent, 5) +
       " Close=" + DoubleToStr(DecesionData.CloseCurrent, 5) +
       " High=" + DoubleToStr(DecesionData.HighCurrent, 5) +
       " Low=" + DoubleToStr(DecesionData.LowCurrent, 5) +
       "\nPrevious Open=" + DoubleToStr(DecesionData.OpenPrevious, 5) +
       " Close=" + DoubleToStr(DecesionData.ClosePrevious, 5) +
       " High=" + DoubleToStr(DecesionData.HighPrevious, 5) +
       " Low=" + DoubleToStr(DecesionData.LowPrevious, 5));
   
   CheckMACD      (TF, NameSymbol, LogFileHandle, DecesionData);
   CheckSAR       (TF, NameSymbol, LogFileHandle, DecesionData);
   CheckStochastic(TF, NameSymbol, LogFileHandle, DecesionData);
   
   Action = Decide(DecesionData);

   return(Action);
  }
//+------------------------------------------------------------------+
//| Check MACD in specifid Timeframe                                 |
//+------------------------------------------------------------------+
void CHelper::CheckMACD(ENUM_TIMEFRAMES TF,string NameSymbol,int LogFileHandle, Decesion_Data &DecesionData)
  {
   int    Fast_EMA = 5,
          Slow_EMA = 13,
          MACD_SMA = 3;    //Signal Period

   LOG("\nMACD Check: " + TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS) +
       "\nTF=" + EnumToString(TF) +
       " Symbol=" + NameSymbol +
       " Fast EMA=" + IntegerToString(Fast_EMA) +
       " Slow EMA=" + IntegerToString(Slow_EMA) +
       " MACD SMA=" + IntegerToString(MACD_SMA));
 
   DecesionData.MACDCurrent    = NormalizeDouble(iMACD(NameSymbol, TF, Fast_EMA, Slow_EMA, MACD_SMA, PRICE_MEDIAN, MODE_MAIN, 0), 5);
   DecesionData.MACDPrevious   = NormalizeDouble(iMACD(NameSymbol, TF, Fast_EMA, Slow_EMA, MACD_SMA, PRICE_MEDIAN, MODE_MAIN, 1), 5);

   DecesionData.MACDSignalCurrent  = NormalizeDouble(iMACD(NameSymbol, TF, Fast_EMA, Slow_EMA, MACD_SMA, PRICE_MEDIAN, MODE_SIGNAL, 0), 5);
   DecesionData.MACDSignalPrevious = NormalizeDouble(iMACD(NameSymbol, TF, Fast_EMA, Slow_EMA, MACD_SMA, PRICE_MEDIAN, MODE_SIGNAL, 1), 5);

   LOG("Current  MACD=" + DoubleToStr(DecesionData.MACDCurrent, 5) +
       " Signal=" + DoubleToStr(DecesionData.MACDSignalCurrent, 5) +
       "\nPrevious MACD=" + DoubleToStr(DecesionData.MACDPrevious, 5) +
       " Signal=" + DoubleToStr(DecesionData.MACDSignalPrevious, 5));
  }
//+------------------------------------------------------------------+
//| Check Probablic SAR in specifid Timeframe                        |
//+------------------------------------------------------------------+
void CHelper::CheckSAR(ENUM_TIMEFRAMES TF,string NameSymbol,int LogFileHandle, Decesion_Data &DecesionData)
  {
   double Step     = 0.02,
          Maximum  = 0.2;   

   LOG("\nProbablicSAR Check: " + TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS) +
       "\nTF=" + EnumToString(TF) +
       " Symbol=" + NameSymbol +
       " Step=" + DoubleToStr(Step, 2) +
       " Maximum=" + DoubleToStr(Maximum, 1));
 
   DecesionData.SARCurrent    = NormalizeDouble(iSAR(NameSymbol, TF, Step, Maximum, 0), 5);
   DecesionData.SARPrevious   = NormalizeDouble(iSAR(NameSymbol, TF, Step, Maximum, 1), 5);

   LOG("Current=" + DoubleToStr(DecesionData.SARCurrent, 5) +
       "\nPrevious=" + DoubleToStr(DecesionData.SARPrevious, 5));
  }
//+------------------------------------------------------------------+
//| Check Stochastic in specifid Timeframe                           |
//+------------------------------------------------------------------+
void CHelper::CheckStochastic(ENUM_TIMEFRAMES TF,string NameSymbol,int LogFileHandle, Decesion_Data &DecesionData)
  {
   int    Kperiod = 5,
          Dperiod = 3,
          Slowing = 5;    

   double MainCurrent    = 0.0,
          MainPrevious   = 0.0,
          SignalCurrent  = 0.0,
          SignalPrevious = 0.0;

   LOG("\nStochastic Check: " + TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS) +
       "\nTF=" + EnumToString(TF) +
       " Symbol=" + NameSymbol +
       " Kperiod=" + IntegerToString(Kperiod) +
       " Dperiod=" + IntegerToString(Dperiod) +
       " Slowing=" + IntegerToString(Slowing));
 
   DecesionData.StoxMainCurrent    = NormalizeDouble(iStochastic(NameSymbol, TF, Kperiod, Dperiod, Slowing, MODE_SMA, 0, MODE_MAIN, 0), 5);
   DecesionData.StoxMainPrevious   = NormalizeDouble(iStochastic(NameSymbol, TF, Kperiod, Dperiod, Slowing, MODE_SMA, 0, MODE_MAIN, 1), 5);

   DecesionData.StoxSignalCurrent  = NormalizeDouble(iStochastic(NameSymbol, TF, Kperiod, Dperiod, Slowing, MODE_SMA, 0, MODE_SIGNAL, 0), 5);
   DecesionData.StoxSignalPrevious = NormalizeDouble(iStochastic(NameSymbol, TF, Kperiod, Dperiod, Slowing, MODE_SMA, 0, MODE_SIGNAL, 1), 5);

   LOG("Current  Main=" + DoubleToStr(DecesionData.StoxMainCurrent, 5) +
       " Signal=" + DoubleToStr(DecesionData.StoxSignalCurrent, 5) +
       "\nPrevious Main=" + DoubleToStr(DecesionData.StoxMainPrevious, 5) +
       " Signal=" + DoubleToStr(DecesionData.StoxSignalPrevious, 5));
   LOG("-------------------------------------------------------------");
  }
//+------------------------------------------------------------------+
//| Check if MACD signals SELL                                       |
//+------------------------------------------------------------------+
bool CHelper::MACDSellSignal(const Decesion_Data &DecesionData)
{
   if ((DecesionData.MACDCurrent < 0 && DecesionData.MACDPrevious > 0 &&     //هیستوگرام قبلی بالای خط و هیستوگرام فعلی زیر خط است. یعنی تلاقی دو تا میانگین متحرک رخ داده
        DecesionData.MACDSignalCurrent < DecesionData.MACDSignalPrevious &&  //منحنی سیگنال فعلی پایین تر از منحنی سیگنال قبلی است
        DecesionData.MACDCurrent < DecesionData.MACDSignalCurrent) ||        //به وضعيت هیستوگرام قبلی نسبت به منحنی سیگنال قبلی کاری ندارم. هیستوگرام فعلی باید از منحنی سیگنال رد شده باشد
        
       (DecesionData.MACDCurrent < 0 && DecesionData.MACDPrevious < 0 &&     //هر دو هیستوگرام زیر خط هستند
        DecesionData.MACDCurrent < DecesionData.MACDSignalCurrent &&         //هیستوگرام فعلی از منحنی سيگنال فعلی رد شده است
        DecesionData.MACDPrevious < DecesionData.MACDSignalPrevious &&       //هیستوگرام قبلی از منحنی سیگنال قبلی رد شده است
        DecesionData.MACDSignalCurrent < DecesionData.MACDSignalPrevious &&  //منحنی سیگنال فعلی پايين تراز منحنی سیگنال قبلی است
        DecesionData.MACDCurrent < DecesionData.MACDPrevious) ||             //هیستوگرام فعلی بلندتر هیستوگرام قبلی است
         
       (DecesionData.MACDCurrent > 0 && DecesionData.MACDPrevious > 0 &&     //هر دو هیستوگرام بالای خط هستند
        DecesionData.MACDCurrent < DecesionData.MACDSignalCurrent &&         //هیستوگرام فعلی زیر منحنی سیگنال فعلی است
        DecesionData.MACDPrevious < DecesionData.MACDSignalPrevious &&       //هیستوگرام قبلی زیر منحنی سیگنال قبلی است
        DecesionData.MACDSignalCurrent < DecesionData.MACDSignalPrevious &&  //منحنی سیگنال فعلی پايين تر از منحنی سیگنال قبلی است
        DecesionData.MACDCurrent < DecesionData.MACDPrevious) ||             //هیستوگرام فعلی کوتاه تراز هیستوگرام قبلی است
         
        (false))                                                              //حالتی که هیستوگرام فعلی بالای خط و هیستوگرام قبلی زیر خط است موضوعیت ندارد
   {
      return (true);
   }
   return (false);
}
//+------------------------------------------------------------------+
//| Check if MACD signals BUY                                        |
//+------------------------------------------------------------------+
bool CHelper::MACDBuySignal(const Decesion_Data &DecesionData)
{
   if ((DecesionData.MACDCurrent > 0 && DecesionData.MACDPrevious < 0 &&     //هیستوگرام قبلی زیر خط و هیستوگرام فعلی بالای خط است. یعنی تلاقی دو تا میانگین متحرک رخ داده است
        DecesionData.MACDSignalCurrent > DecesionData.MACDSignalPrevious &&  //منحنی سیگنال فعلی بالاتر از منحنی سیگنال قبلی است
        DecesionData.MACDCurrent > DecesionData.MACDSignalCurrent) ||        //به وضعيت هیستوگرام قبلی نسبت به منحنی سیگنال قبلی کاری ندارم. هیستوگرام فعلی باید از منحنی سیگنال رد شده باشد
        
       (DecesionData.MACDCurrent > 0 && DecesionData.MACDPrevious > 0 &&     //هر دو هیستوگرام روی خط هستند
        DecesionData.MACDCurrent > DecesionData.MACDSignalCurrent &&         //هیستوگرام فعلی از منحنی سيگنال فعلی رد شده است
        DecesionData.MACDPrevious > DecesionData.MACDSignalPrevious &&       //هیستوگرام قبلی از منحنی سیگنال قبلی رد شده است
        DecesionData.MACDSignalCurrent > DecesionData.MACDSignalPrevious &&  //منحنی سیگنال فعلی بالاتر از منحنی سیگنال قبلی است
        DecesionData.MACDCurrent > DecesionData.MACDPrevious) ||             //هیستوگرام فعلی بلندتر هیستوگرام قبلی است
         
       (DecesionData.MACDCurrent < 0 && DecesionData.MACDPrevious < 0 &&     //هر دو هیستوگرام زیر خط هستند
        DecesionData.MACDCurrent > DecesionData.MACDSignalCurrent &&         //هیستوگرام فعلی زیر منحنی سیگنال فعلی است
        DecesionData.MACDPrevious > DecesionData.MACDSignalPrevious &&       //هیستوگرام قبلی زیر منحنی سیگنال قبلی است
        DecesionData.MACDSignalCurrent > DecesionData.MACDSignalPrevious &&  //منحنی سیگنال فعلی بالاتر از منحنی سیگنال قبلی است
        DecesionData.MACDCurrent > DecesionData.MACDPrevious) ||             //هیستوگرام فعلی کوتاه تراز هیستوگرام قبلی است
         
        (false))                                                              //حالتی که هیستوگرام قعلی زیر خط و هیستوگرام قبلی روی خط است موضوعیت ندارد
   {
      return (true);
   }
   return (false);   
}
//+------------------------------------------------------------------+
//| Stochastic indicates over buy?                                   |
//+------------------------------------------------------------------+
bool CHelper::STOXOverBuy(const Decesion_Data &DecesionData)
{
   if (DecesionData.StoxMainCurrent < OVER_BUY_LEVEL &&
       DecesionData.StoxSignalCurrent < OVER_BUY_LEVEL)                     //هنوز وارد ناحیه اشباع خرید نشده است
      return (false);
   return (true);
}
//+------------------------------------------------------------------+
//| Stochastic indicates over sell?                                  |
//+------------------------------------------------------------------+
bool CHelper::STOXOverSell(const Decesion_Data &DecesionData)
{
   if (DecesionData.StoxMainCurrent > OVER_SELL_LEVEL &&
       DecesionData.StoxSignalCurrent > OVER_SELL_LEVEL)                    //هنوز وارد ناحیه اشباع فروش نشده است
      return (false);
   return (true);           
}
//+------------------------------------------------------------------+
//| Stochastic indicates upward main and signal?                     |
//+------------------------------------------------------------------+
bool CHelper::STOXUpward(const Decesion_Data &DecesionData)
{
   if (DecesionData.StoxMainCurrent > DecesionData.StoxMainPrevious &&
       DecesionData.StoxSignalCurrent > DecesionData.StoxSignalPrevious) //سرعت افزایش قیمت در حال بیشتر شدن است
      return (true);
   return (false);
}
//+------------------------------------------------------------------+
//| Stochastic indicates downward main and signal?                   |
//+------------------------------------------------------------------+
bool CHelper::STOXDownward(const Decesion_Data &DecesionData)
{
   if (DecesionData.StoxMainCurrent < DecesionData.StoxMainPrevious &&
       DecesionData.StoxSignalCurrent < DecesionData.StoxSignalPrevious) //سرعت کاهش قیمت در حال بیشتر شدن است
      return (true);
   return (false);
}
//+------------------------------------------------------------------+
//| Decide about opening of a new position based on values           |
//+------------------------------------------------------------------+
string CHelper::Decide(const Decesion_Data &DecesionData)
{
   if (DecesionData.SARCurrent > DecesionData.HighCurrent) //نقطه بالای شمع و سیگنال فروش
      if (!STOXOverSell(DecesionData))                     //هنوز وارد ناحیه اشباع فروش نشده است
         if (STOXDownward(DecesionData))                   //سرعت کاهش قیمت در حال بیشتر شدن است
            if (MACDSellSignal(DecesionData))
               return (ACTION_SELL);
            else
               return ("");                                //فروش موضوعیت ندارد
         else                                              //سرعت کاهش قیمت در حال کم شدن است
            if (MACDBuySignal(DecesionData))
               return (ACTION_BUY);
            else      
               return ("");                                //خرید موضوعیت ندارد
      else                                                 //وارد ناحیه اشباع فروش شده است
         if (STOXDownward(DecesionData))                   //سرعت کاهش قیمت در حال بیشتر شدن است
            return ("");                                   //فروش موضوعیت ندارد
         else                                              //سرعت کاهش قیمت در حال کم شدن است
            if (MACDBuySignal(DecesionData))
               return (ACTION_BUY);
            else      
               return ("");                                //خرید موضوعیت ندارد
   else                                                    //نقطه پایین شمع و سیگنال خرید
      if (!STOXOverBuy(DecesionData))                      //هنوز وارد ناحیه اشباع خرید نشده است
         if (STOXUpward(DecesionData))                     //سرعت افزایش قیمت در حال بیشتر شدن است
            if (MACDBuySignal(DecesionData))
               return (ACTION_BUY);
            else
               return ("");                                //خرید موضوعيت ندارد
         else                                              //سرعت افزایش قیمت در حال کم شدن است
            if (MACDSellSignal(DecesionData))
               return (ACTION_SELL);
            else      
               return ("");                                //فروش موضوعیت ندارد
      else                                                 //وارد ناحیه اشباع خرید شده است
         if (STOXUpward(DecesionData))                     //سرعت افزایش قیمت در حال بیشتر شدن است
            return ("");                                   //خرید موضوعیت ندارد
         else                                              //سرعت افزایش قیمت در حال کم شدن است
            if (MACDSellSignal(DecesionData))
               return (ACTION_SELL);
            else      
               return ("");                                //فروش موضوعیت ندارد
}
//+------------------------------------------------------------------+
