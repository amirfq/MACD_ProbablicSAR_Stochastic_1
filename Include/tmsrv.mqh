//+------------------------------------------------------------------+
//|                                                        tmsrv.mqh |
//|                                                      Aleksandr M |
//|                                                 https://tmsrv.pw |
//+------------------------------------------------------------------+
#property copyright "Aleksandr M"
#property link      "https://tmsrv.pw"
#property strict

datetime _tms_last_time_messaged;
bool tms_send(string message, string token="66363878:849659c7"){  
   const string url = "https://tmsrv.pw/send/v1";   
   
   string response,headers; 
   int result;
   char post[],res[]; 
   
   if(IsTesting() || IsOptimization()) return true;
   
   //if(_tms_last_time_messaged == Time[0]) return false; // do not send twice at the same candle;  

   string spost = StringFormat("message=%s&token=%s&code=MQL",message,token);
   

   ArrayResize(post,StringToCharArray(spost,post,0,WHOLE_ARRAY,CP_UTF8)-1);

   result = WebRequest("POST",url,"",NULL,3000,post,ArraySize(post),res,headers);
   _tms_last_time_messaged = Time[0];
       
   if(result==-1) {
         if(GetLastError() == 4060) {
            printf("tms_send() | Add the address %s in the list of allowed URLs on tab 'Expert Advisors'",url);
         } else {
            printf("tms_send() | webrequest filed - error № %i", GetLastError());
         }
         return false;
   } else { 
      response = CharArrayToString(res,0,WHOLE_ARRAY);
     
      if(StringFind(response,"\"ok\":true")==-1) {

         printf("tms_send() return an error - %s",response);
         return false;
      }
   }
  
  Sleep(1000); //to prevent sending more than 1 message per seccond
  return true;
}