/**
 *  Source file for implementation of module Middleware
 *  which provides the main logic for middleware message management
 *
 */
#include <stdio.h>
generic module FakeSensorP() {

	provides interface Read<braceletReading>;
	uses interface Random;
	

}

implementation {

	task void reading();

	//***************** reading method  interface ********************//
	command error_t Read.read(){
		post reading( );
		return SUCCESS;
	}

	//***************** reading method definition ********************//
	task void reading() {
		braceletReading bracialetStatus;
		int random_number = (call Random.rand16() % 10);
		bracialetStatus.X = call Random.rand16();
	  	bracialetStatus.Y = call Random.rand16();
	  	
		
		if (random_number>=0 && random_number <= 2){
		  strcpy(bracialetStatus.action, "STANDING");
		} else if (random_number>2 && random_number <= 5){
		  strcpy(bracialetStatus.action, "WALKING");
		} else if (random_number>5 &&random_number <= 8){
		  strcpy(bracialetStatus.action, "RUNNING");
		} else {
		  strcpy(bracialetStatus.action, "FALLING");
		}
		
		signal Read.readDone( SUCCESS, bracialetStatus);
	  	
	}
}
