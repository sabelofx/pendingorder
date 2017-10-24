//+------------------------------------------------------------------+
//|                                                    fxmachine.mq4 |
//|                           Copyright (c) 2017, sabelofx@gmail.com |
//|                                               sabelofx@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright (c) 2017, sabelofx@gmail.com"
#property link      "sabelofx@gmail.com"
#property version   "1.00"
#property strict

//imports
#import "digitFactorLib.ex4"
double calcDigitFactor(string);
#import "lotCalcLib.ex4"
double calculateLots(string,double,double,double);
#import "totalTradesLib.ex4"
int totalTradesBySymbMagicCmt(string,int,string,string);
#import

//+------------------------------------------------------------------+
//| External Variables                                               |
//+------------------------------------------------------------------+

extern string
_____Trade_Identifiers_____="---------- Trade Identifiers ----------";
extern int
MagicNumber=81188;
extern string
TicketComment="poea";
extern bool
BuyTrades=true,
SellTrades=true,
TrailPendingOrder=true,
TrailOrder=true;

extern string
_____Order_Settings_____="---------- Pending Order Settings ----------";
extern double
BuyStop=60.0,
SellStop=60.0,
TakeProfit=300.0,
StopLoss=300.0,
TrailingStop=300.0;

extern string
_____Risk_Settings_____="---------- Risk Settings (Set One) ----------";
extern double
Lots=0.0,
RiskPercent=1;

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+

string
TicketCmt,
msg,
msg2;

int
ticket,
count,
total,
Slippage=5;

double
LotSize,
TP,
SL,
MarketPrice,
BuyPrice,
SellPrice;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   TicketCmt=TicketComment+"_"+(string)MagicNumber;
   TP=0.0;
   SL=0.0;
   msg="";
   msg2="";

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
//---
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   Trade();
   Trail();
   CleanUp();
//---
  }
//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void Trade()
  {

   if(Lots!=0.0)
      LotSize=Lots;
   else
      LotSize=calculateLots(Symbol(),StopLoss,RiskPercent,calcDigitFactor(Symbol()));

   if(TakeProfit > 0.0 && TakeProfit<=TrailingStop)
      msg="(TP will hit before Trailing begins)";
   if(TrailingStop<=0.0)
      msg2="(OFF)";

   Comment("\n                                          Symbol        = "+Symbol()+
           "\n                                          LotSize         = "+(string)LotSize+
           "\n                                          BuyStop         = "+(string)(BuyStop)+
           "\n                                          SellStop      = "+(string)(SellStop)+
           "\n                                          TakeProfit    = "+(string)(TakeProfit)+" "+msg+
           "\n                                          StopLoss      = "+(string)(StopLoss)+
           "\n                                          Trailing Stop = "+(string)(TrailingStop)+" "+msg2
           );

   if(totalTradesBySymbMagicCmt(Symbol(),MagicNumber,TicketCmt,"ALL")==0)
     {

      if(BuyTrades) // But Stop
        {
         MarketPrice=MarketInfo(Symbol(),MODE_ASK);
         BuyPrice=MarketPrice+(BuyStop*calcDigitFactor(Symbol()));
         if(TakeProfit>0.0)
            TP=BuyPrice+(TakeProfit*calcDigitFactor(Symbol()));
         if(StopLoss>0.0)
            SL=BuyPrice-(StopLoss*calcDigitFactor(Symbol()));

         RefreshRates();
         ticket=OrderSend(Symbol(),OP_BUYSTOP,LotSize,BuyPrice,Slippage,SL,TP,TicketCmt,MagicNumber,0,clrNONE);
        }

      if(SellTrades) // Sell Stop
        {
         MarketPrice=MarketInfo(Symbol(),MODE_BID);
         SellPrice=MarketPrice-(SellStop*calcDigitFactor(Symbol()));
         if(StopLoss>0.0)
            SL=SellPrice+(StopLoss*calcDigitFactor(Symbol()));
         if(TakeProfit>0.0)
            TP=SellPrice-(TakeProfit*calcDigitFactor(Symbol()));

         RefreshRates();
         ticket=OrderSend(Symbol(),OP_SELLSTOP,LotSize,SellPrice,Slippage,SL,TP,TicketCmt,MagicNumber,0,clrNONE);
        }
     }
  }
//+------------------------------------------------------------------+
//| Trail function                                                   |
//+------------------------------------------------------------------+
void Trail()
  {
   if(TrailPendingOrder)
     {
      for(count=0;count<OrdersTotal();count++)
        {
         if(OrderSelect(count,SELECT_BY_POS,MODE_TRADES)==true)
           {
            if((OrderType()==OP_SELLSTOP || OrderType()==OP_BUYSTOP) && OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber)
              {
               switch(OrderType())
                 {
                  case OP_BUYSTOP  :
                     MarketPrice=MarketInfo(Symbol(),MODE_ASK);
                     BuyPrice=OrderOpenPrice();
                     if(BuyPrice-MarketPrice>BuyStop*calcDigitFactor(Symbol()))
                       {
                        BuyPrice=MarketPrice+(BuyStop*calcDigitFactor(Symbol()));
                        if(TakeProfit>0.0)
                           TP=BuyPrice+(TakeProfit*calcDigitFactor(Symbol()));
                        if(StopLoss>0.0)
                           SL=BuyPrice-(StopLoss*calcDigitFactor(Symbol()));
                        if(OrderOpenPrice()!=BuyPrice || OrderStopLoss()!=SL || OrderTakeProfit()!=TP)
                           if(OrderModify(OrderTicket(),BuyPrice,SL,TP,OrderExpiration(),clrNONE)==false)
                              GetLastError();
                       }
                  case OP_SELLSTOP :
                     MarketPrice=MarketInfo(Symbol(),MODE_BID);
                     SellPrice=OrderOpenPrice();
                     if(MarketPrice-SellPrice>SellStop*calcDigitFactor(Symbol()))
                       {
                        SellPrice=MarketPrice-(SellStop*calcDigitFactor(Symbol()));
                        if(StopLoss>0.0)
                           SL=SellPrice+(StopLoss*calcDigitFactor(Symbol()));
                        if(TakeProfit>0.0)
                           TP=SellPrice-(TakeProfit*calcDigitFactor(Symbol()));
                        if(OrderOpenPrice()!=SellPrice || OrderStopLoss()!=SL || OrderTakeProfit()!=TP)
                           if(OrderModify(OrderTicket(),SellPrice,SL,TP,OrderExpiration(),clrNONE)==false)
                              GetLastError();
                       }
                 }
              }
           }
        }
     }
   if(TrailOrder && TrailingStop>0.0)
     {
      for(count=0;count<OrdersTotal();count++)
        {
         if(OrderSelect(count,SELECT_BY_POS,MODE_TRADES)==true)
           {
            if((OrderType()==OP_SELL || OrderType()==OP_BUY) && OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber)
              {
               switch(OrderType())
                 {
                  case OP_BUY  :
                     MarketPrice=MarketInfo(Symbol(),MODE_ASK);
                     BuyPrice=OrderOpenPrice();
                     if(MarketPrice-BuyPrice>BuyStop*calcDigitFactor(Symbol()))
                       {
                        BuyPrice=MarketPrice+(BuyStop*calcDigitFactor(Symbol()));
                        SL=BuyPrice-(TrailingStop*calcDigitFactor(Symbol()));
                        if(OrderStopLoss()!=SL)
                           if(OrderModify(OrderTicket(),OrderOpenPrice(),SL,OrderTakeProfit(),OrderExpiration(),clrNONE)==false)
                              GetLastError();
                       }
                  case OP_SELL :
                     MarketPrice=MarketInfo(Symbol(),MODE_BID);
                     SellPrice=OrderOpenPrice();
                     if(SellPrice-MarketPrice>SellStop*calcDigitFactor(Symbol()))
                       {
                        SellPrice=MarketPrice-(SellStop*calcDigitFactor(Symbol()));
                        SL=SellPrice+(TrailingStop*calcDigitFactor(Symbol()));
                        if(OrderStopLoss()!=SL)
                           if(OrderModify(OrderTicket(),OrderOpenPrice(),SL,OrderTakeProfit(),OrderExpiration(),clrNONE)==false)
                              GetLastError();
                       }
                 }
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void CleanUp()
  {
   if(totalTradesBySymbMagicCmt(Symbol(),MagicNumber,TicketCmt,"PENDING")==1 && BuyTrades && SellTrades)
     {
      total=0;
      for(count=0;count<OrdersTotal();count++)
        {
         if(OrderSelect(count,SELECT_BY_POS,MODE_TRADES)==true)
            if((OrderType()==OP_SELLSTOP || OrderType()==OP_BUYSTOP) && OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber && OrderComment()==TicketCmt)
              {
               switch(OrderType())
                 {
                  case OP_BUYSTOP  :
                     if(OrderDelete(OrderTicket())==false)
                     GetLastError();
                  case OP_SELLSTOP :
                     if(OrderDelete(OrderTicket())==false)
                     GetLastError();
                 }
              }
        }
     }
  }
//+------------------------------------------------------------------+
