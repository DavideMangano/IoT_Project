# Project 1: Smart Bracelets

In this project, you are tasked with designing, implementing, and testing a software prototype for a smart bracelet system. These bracelets are worn by both a child and their parent to keep track of the child's position and trigger alerts when the child goes too far. Similar commercially available prototypes are already on the market.

## Operation of the Smart Bracelet System

The operation of the smart bracelet system consists of three main phases:

### 1. Pairing Phase

- At startup, both the parent's bracelet and the child's bracelet broadcast a 20-character random key used to uniquely pair the two devices.
- The same random key is pre-loaded at production time on both devices.
- Upon receiving a random key, a device checks whether it matches the stored one.
- If there is a match, the device stores the address of the source device in memory.
- A special message is transmitted in unicast to the source device to stop the pairing phase and move to the next step.

### 2. Operation Mode

- In this phase, the parent's bracelet listens for messages on the radio and accepts only messages coming from the child's bracelet.
- The child's bracelet periodically transmits INFO messages (one message every 10 seconds) containing the child's position (X; Y) and an estimate of their kinematic status (STANDING, WALKING, RUNNING, FALLING).

### 3. Alert Mode

- Upon receiving an INFO message, the parent's bracelet reads its content.
- If the kinematic status is FALLING, the parent's bracelet sends a FALL alarm, reporting the child's position (X; Y).
- If the parent's bracelet does not receive any message for one minute, it sends a MISSING alarm, reporting the last received position.

## Requirements

1. Implement the prototype with your choice of operating system (including application logic, message formats, etc.). The X; Y coordinates can be random numbers, and the kinematic status should be randomly selected according to the following probability distribution:
   - P(STANDING) = P(WALKING) = P(RUNNING) = 0.3
   - P(FALLING) = 0.1

2. Simulate your implementation with two couples of bracelets simultaneously. Ensure that your code follows the design requirements. For simulation, you can emulate a node going out of range by turning it off (e.g., using `mote.turnOff()` in Python for TOSSIM). In Cooja, you can move a node out of the communication range of the other one.

3. Attach your simulation to Tossim-live or Node-Red. Alarm messages should be transmitted on the serial port, and their output should be readable on the terminal or the Node-Red dashboard.

Please note that this markdown representation is missing any specific code examples or technical details and serves as a high-level summary of the project's requirements and objectives.
