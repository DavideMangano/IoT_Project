#include "Timer.h"
#include "SmartProject.h"
#include <stdio.h>

module SmartProjectC {
  uses {
    interface Boot;
    
    interface AMSend;
    interface Receive;
    interface SplitControl as SplitC;
    interface Packet;
    interface AMPacket;
    interface PacketAcknowledgements as Ack;
    
    interface Timer<TMilli> as PairTimer;
    interface Timer<TMilli> as InfoTimer;
    interface Timer<TMilli> as MissingTimer;
    interface Read<braceletReading> as FakeSensor;
  
  }
}


implementation {

  bool endedPairing1 = FALSE;
  bool endedPairing2 = FALSE;
  bool locked = FALSE;
  message_t packet;
  char keys[10][20];
  
  void sendPairing();
  void sendRespPairing();
  void send_info_message();
  
  // variables concerning the sensor
  bool sensorRead = FALSE;  
  braceletReading braceletState;

  
  
  // Booting
  event void Boot.booted() {
    call SplitC.start();
  }

  // Immediately after booting
  event void SplitC.startDone(error_t err) {
    if (err == SUCCESS) {
      
      dbg("Pairing", "Pairing timer is now on\n");
      
      call PairTimer.startPeriodic(1000);
      
      sendPairing();
      
    } else {
      call SplitC.start();
    }
  }
  
  event void SplitC.stopDone(error_t err) {
  	dbg("boot","The process stopped.\n");
  }
  
 
void sendPairing(){
	//if still in pairing for MOTES 0-1
	if(endedPairing1 == FALSE && (TOS_NODE_ID == 1 || TOS_NODE_ID == 2)){
		dbg("PairingSent1", "PairingSent: pairing message for first couple sent at time %s\n", sim_time_string());
    	if (locked == FALSE) {
      		pairing_msg_t* pairing_msg = (pairing_msg_t*)call Packet.getPayload(&packet, sizeof(pairing_msg_t));
      		strcpy(pairing_msg->rand_key, "AAAAAAAAAAAAAAAAAAAA");
      
      		if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(pairing_msg_t)) == SUCCESS) {
	      		dbg("Radio", "Radio: sending pairing packet, key=%s\n", "AAAAAAAAAAAAAAAAAAAA");	
	      		locked = TRUE;
      		}
		}
	}	
	//if still in pairing for MOTES 2-3
	else if(endedPairing2 == FALSE && (TOS_NODE_ID == 3 || TOS_NODE_ID == 4)){
		dbg("PairingSent2", "PairingSent: pairing message for second couple sent at time %s\n", sim_time_string());
    	if (locked == FALSE) {
      		pairing_msg_t* pairing_msg = (pairing_msg_t*)call Packet.getPayload(&packet, sizeof(pairing_msg_t));
      		strcpy(pairing_msg->rand_key, "BBBBBBBBBBBBBBBBBBBB");
      
      		if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(pairing_msg_t)) == SUCCESS) {
	      		dbg("Radio", "Radio: sending pairing packet, key=%s\n", "BBBBBBBBBBBBBBBBBBBB");	
	      		locked = TRUE;
      		}
		}
	}
}

event void PairTimer.fired() {
	//call Pairing each time the timer fires if pairing phase still not resolved
	if(endedPairing1 == FALSE || endedPairing2 == FALSE) sendPairing();
}

 // Timer for info updates
 event void InfoTimer.fired() {
    dbg("InfoTimer", "InfoTimer: timer fired at time %s\n", sim_time_string());
    call FakeSensor.read();
  }

  // Timer for missing status 
  event void MissingTimer.fired() {
    dbg("MissingTimer", "\n\n\nMissingTimer: timer fired at time %s\n", sim_time_string());
    dbg("Info", "ALERT: MISSING\n");
    dbg("Info","Last known location: %hhu, Y: %hhu\n\n", braceletState.X, braceletState.Y);

   

  }

void sendRespPairing(){
	//CALLED AFTER RECEIVING A BROADCAST PAIRING MESSAGE SENT BY NODE 0 TO NODE 1 OR BY NODE 2 TO NODE 3.
	//NO NEED OF PARTICULAR MESSAGE CONTENT. THE CONTROL IS MADE BY THE CHILD BRACELET, ONCE IT HAS CHECKED THE RAND_KEY IT CAN JUST REPLY WITH A STANDARD MESSAGE.
	pairing_msg_t* pairRespMessage = (pairing_msg_t*)call Packet.getPayload(&packet, sizeof(pairing_msg_t));
	 
    call Ack.requestAck( &packet );
    	
	
	if((TOS_NODE_ID == 2 || TOS_NODE_ID == 1) && locked == FALSE){
    	if (call AMSend.send(TOS_NODE_ID%2+1, &packet, sizeof(pairing_msg_t)) == SUCCESS) {
        		
        	locked = TRUE;
      	}
	}
	else if((TOS_NODE_ID == 4 || TOS_NODE_ID == 3) && locked == FALSE){
    	if (call AMSend.send(TOS_NODE_ID%2+3, &packet, sizeof(pairing_msg_t)) == SUCCESS) {
        		
        	locked = TRUE;
      	}
	}
}


  
  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr && error == SUCCESS) {
      dbg("Sent", "Packet sent\n");
      locked = FALSE;
	
	if (endedPairing1 == FALSE && call Ack.wasAcked(bufPtr) && (call AMPacket.source( bufPtr ) == 1 || call AMPacket.source( bufPtr ) == 2)){
		
		if(TOS_NODE_ID == 1 || TOS_NODE_ID == 2) {
			call PairTimer.stop();
        	endedPairing1 = TRUE;
        	dbg("PairingCompleted","endend paring 1 now true\n");
        	dbg("PairingCompleted","Pairing 1/2 completed.\n\n");
        }
        //we finished paring phase we start the normal communication phase
        if (TOS_NODE_ID % 2 == 0){
          // Parent bracelet
          dbg("OperationalMode","We start the parent bracelet missing timer\n");
          call MissingTimer.startOneShot(60000);
        } else {
          // Child bracelet
          dbg("OperationalMode","We start the child bracelet info timer\n");
          call InfoTimer.startPeriodic(10000);
        }
    }
        
    if (endedPairing2 == FALSE && call Ack.wasAcked(bufPtr) && (call AMPacket.source( bufPtr ) == 3 || call AMPacket.source( bufPtr ) == 4)){
    	
    	if(TOS_NODE_ID == 3 || TOS_NODE_ID == 4) {
    	call PairTimer.stop();
    	endedPairing2 = TRUE;
    	dbg("PairingCompleted","endend paring 2 now true\n");
    	dbg("PairingCompleted","Pairing 3/4 completed.\n\n");
    	
    	}
    	if (TOS_NODE_ID % 2 == 0){
          // Parent bracelet
          dbg("OperationalMode","We start the parent bracelet missing timer\n");
          call MissingTimer.startOneShot(60000);
        } else if(TOS_NODE_ID % 2 == 1) {
          // Child bracelet
          dbg("OperationalMode","We start the child bracelet info timer\n");
          call InfoTimer.startPeriodic(10000);
        }        
    }
    
  }
}
   
  event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
          //dbg("try","I tried %d\n",endedPairing2);
    //if a message is received when not both couple are pared then we check if the received message is a pearing message
    
    if(endedPairing1 == FALSE && endedPairing2 == FALSE) {   	
		pairing_msg_t* recMess = (pairing_msg_t*)payload;
    
    	if (endedPairing1 == FALSE && (strcmp(recMess->rand_key,"AAAAAAAAAAAAAAAAAAAA") == 0) && (TOS_NODE_ID == 2 || TOS_NODE_ID == 1)){
    	
    		    	
    		dbg("Receive", "Received  a paring message from %hhu with content %s\n", call AMPacket.source( bufPtr ), recMess->rand_key);
      		dbg("pairingEnd1","Message for pairing of motes 1,2 received.\n");
      		sendRespPairing();
    
    	} 
    	if (endedPairing2 == FALSE && (strcmp(recMess->rand_key,"BBBBBBBBBBBBBBBBBBBB") == 0) && (TOS_NODE_ID == 4 || TOS_NODE_ID == 3)){
    	
				
    		dbg("Receive", "Received  a paring message from %hhu with content %s\n", call AMPacket.source( bufPtr ), recMess->rand_key);
      		dbg("pairingEnd2","Message for pairing of motes 3,4 received.\n");
      		sendRespPairing();
    	} 
  	}
  	
  	else{
  	
  	//this part handles message after the paring phase 
  	//TODO:to decide how to behave in case one couple is pared and sending messages and the other is still in the paring phase 
  	info_message* recMess = (info_message*)payload;
  	if (strcmp(recMess->data,"AAAAAAAAAAAAAAAAAAAA") == 0 || strcmp(recMess->data,"BBBBBBBBBBBBBBBBBBBB") == 0){
  		dbg("Radio_pack","message ignored paring already done\n");
  		return bufPtr;
  	}
  	if (call AMPacket.destination( bufPtr ) == TOS_NODE_ID) {
      dbg("Radio_pack","INFO message received\n");
      dbg("Info", "Position X: %hhu, Y: %hhu\n", recMess->X, recMess->Y);
      dbg("Info", "Sensor status: %s\n\n", recMess->data);
      braceletState.X = recMess->X;
      braceletState.Y = recMess->Y;
      call MissingTimer.startOneShot(60000);
      
      // if the satus of the bracialet is Falling we send an ALERT
      if (strcmp(recMess->data, "FALLING") == 0){
        dbg("Info", "ALERT: FALLING!\n\n\n");
 	
      }
    }
    }
    return bufPtr;
  	
  }
  
  event void FakeSensor.readDone(error_t result, braceletReading reading) {
    braceletState = reading;														
    dbg("Sensors", "The state of the bracelet is: %s\n", reading.action);  
    
    if (sensorRead == FALSE){
      
      sensorRead = TRUE;
    } else {
      sensorRead = FALSE;
      send_info_message();
    }


	dbg("Sensors", "Position X: %hhu, Y: %hhu\n", reading.X, reading.Y);
    
    
    // Controlla che entrambe le letture siano state fatte
    if (sensorRead == FALSE){
      // Solo una lettura è stata fatta
      sensorRead = TRUE;
    } else {
      // Entrambe le letture sono state fatte quindi possiamo inviare l'INFO packet
      sensorRead = FALSE;
      send_info_message();
    }
  }
  
  //AM_RADIO_TYPE
  
  
  
  // Send INFO message from child's bracelet
  void send_info_message(){
  	
  	if (locked == FALSE) {
    	info_message* message = (info_message*)call Packet.getPayload(&packet, sizeof(info_message));
        //building of the message
        message->X = braceletState.X;
        message->Y = braceletState.Y;
        strcpy(message->data, braceletState.action);   
        call Ack.requestAck( &packet );
        
        if(TOS_NODE_ID == 1 && locked == FALSE){
        	
			if (call AMSend.send(2, &packet, sizeof(message)) == SUCCESS) {
		    	dbg("Radio", "Radio: sending INFO packet to node %d\n", 2);	
		    	locked = TRUE;
		  	}
		}
		else if(TOS_NODE_ID == 3 && locked == FALSE){
			
			if (call AMSend.send(4, &packet, sizeof(message)) == SUCCESS) {
		    	dbg("Radio", "Radio: sending INFO packet to node %d\n", 4);	
		    	locked = TRUE;
		  	}
		}
      }
    } 
}



  




