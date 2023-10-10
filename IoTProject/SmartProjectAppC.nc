#include "SmartProject.h"

configuration SmartProjectAppC {}

implementation {
  //components MainC, SmartProjectC, RandomC as App;
  components MainC, SmartProjectC as App;
  components new AMSenderC(AM_MY_MSG);
  components new AMReceiverC(AM_MY_MSG);
  components ActiveMessageC ;
  
  components new TimerMilliC() as PairTimer;
  components new TimerMilliC() as InfoTimer;
  components new TimerMilliC() as MissingTimer;
  
  components new FakeSensorC();
  
  
  // Booting
  App.Boot -> MainC.Boot;
  
  // Sender and receiver
  App.AMSend -> AMSenderC;
  App.Receive -> AMReceiverC;
  
  //App.SplitControl -> ActiveMessageC;
  App.SplitC -> ActiveMessageC;
  //App.Random -> RandomC;
  App.Packet -> AMSenderC;
  App.AMPacket -> AMSenderC;
  //App.PacketAcknowledgements -> ActiveMessageC;
  App.Ack -> ActiveMessageC;
  App.PairTimer -> PairTimer;
  App.InfoTimer -> InfoTimer;
  App.MissingTimer -> MissingTimer;
  
  App.FakeSensor -> FakeSensorC;
  
  
}


