#ifndef SMARTPROJECT_H
#define SMARTPROJECT_H

//message used during the paring phase for sending the key 
typedef nx_struct pairing_msg {

  	nx_uint8_t rand_key[20];
  	
} pairing_msg_t;

//definition of the message used after the paring phase 
typedef nx_struct infoMessage {
  	nx_uint8_t data[20];
  	nx_uint16_t X;
  	nx_uint16_t Y;
} info_message;


//definition of the object returned by the fakeSensor
typedef struct sensorStatus {
  uint16_t X;
  uint16_t Y;
  uint8_t action[10];
} braceletReading;



enum {
  AM_MY_MSG = 6,
};

#endif
