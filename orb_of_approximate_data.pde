/*
 * Orbs of Approximate Data 
 *
 * This code supports the "Bring Information To Light" article in the 
 * June 2010 issue of Popular Science.  The article deals with using 
 * subtle glowing Orbs (or cubes) to visualize the trends in a data 
 * stream.  This mapping of a data feed into two variables - color and 
 * intensity - provides a way to preattentively identify trends
 * in the data.  These orbs are something that one can unobtrusively 
 * embed in their environment.
 *
 * In this version of the code, data streams are pulled from a server
 * which has pre-digested the data and parsed it into a format suited
 * for these Orbs.  That output is hosted on my server, 2552.com. 
 * If you'd like to use a data feed that is not available there, you 
 * can either suggest it to me or create your own feed and point 
 * your Orb at it.
 *
 * This code will need a certain amount of configuration to work.  Look 
 * in the Configuration section below.
 *
 * 
 * Copyright (c) 2010 Vin Marshall (vlm@2552.com, www.2552.com)
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE. 
 */

#include <string.h>
#include <WiServer.h>

#define DEBUG 1

/*
 * CONFIGURATION
 *
 * At a minimum, you'll need to set up the WiFi configuration to make 
 * your Orb work on your local network.  
 * 
 */


//
// WIFI CONFIGURATION
//

// Pick an unused IP address that is in your local subnet to use
// as the IP address of the Orb
unsigned char local_ip[] = {192,168,1,150};

// Set the Gateway IP and Subnet Mask for your local network.  If you don't
// know what this is, look in the network configuration for your computer,
// which will have had these assigned when it came online.
unsigned char gateway_ip[] = {192,168,1,1};
unsigned char subnet_mask[] = {255,255,255,0};

// Set the SSID, or broadcast name, or your wireless router or access point
// here.  Your computer reports this name when it connects to the wifi.
const prog_char ssid[] PROGMEM = {"yourssid"};		// max 32 bytes

// Select the type of security your wireless network uses.
unsigned char security_type = 2;	// 0 - open; 1 - WEP; 2 - WPA; 3 - WPA2

// If you're using WPA or WPA2, set the passphrase here
const prog_char security_passphrase[] PROGMEM = {"yourpass"};// max 64 characters

// If you're using WEP, set the key here.
// The following are some sample WEP 128-bit keys
prog_uchar wep_keys[] PROGMEM = { 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d,	// Key 0
				  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,	// Key 1
				  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,	// Key 2
				  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	// Key 3
				};

// Set the type of wireless access mode you'll be using here.  For most people
// this will be the Infrastructure mode - that means you're connecting to an 
// access point or a wireless router.  Options are in the #defines below.  

#define WIRELESS_MODE_INFRA	1
#define WIRELESS_MODE_ADHOC	2
unsigned char wireless_mode = WIRELESS_MODE_INFRA;


//
// SERVER CONFIGURATION
//

// Server Name is the name of the server you'll be connecting to for Orb
// data updates.  Unless you've set up your own server for the orb, leave 
// this pointed at 2552.com

char *server_name = "www.2552.com";

// Server IP is the IP address corresponding to the server name given above.
// The library we're using doesn't have DNS support at present.

uint8 server_ip[] = {67,23,14,230};


//
// DATA SOURCE CONFIGURATION
//

#define DS_DJI "/orb/dji.txt"

// Data Source sets the data feed the Orb will display.  
// Valid options are listed in the #defines above

char *data_source = DS_DJI;

// Update Minutes controls how often in minutes the Orb calls 
// the mothershipfor more data.  Be reasonable and keep this 
// around 5 minutes or more.
unsigned long update_minutes = 1;


//
// COLOR CONFIGURATION
//

struct rgbColor {
	int red;
	int green;
	int blue;
};

// The colors available to the system are defined here.  As of this 
// version of the Orb code, the parser will translate data into a palette 
// of 5 colors.  This could be expanded of course were you to make
// or customize your own parser to prepare data for your Orb.
//
// The colors are defined in terms of { red, green, blue } with values
// ranging from 0% to 100% for each component.

struct rgbColor colors[] = 
{
	{100, 0, 0},	// Red
	{0, 100, 0},	// Green
	{0, 0, 100}, 	// Blue
	{70, 0, 100},	// red-blue-thing
	{0, 100, 70}	// green-blue-thing
};



/*
 * END OF CONFIGURATION SECTION 
 */


/*
 * Global Variables
 */

int redPin   = 3;   // Red LED,   connected to digital pin 9
int greenPin = 6;  // Green LED, connected to digital pin 10
int bluePin  = 5;  // Blue LED,  connected to digital pin 11
int indicatorPin = 13;	// On board LED as indicator

unsigned char ssid_len;
unsigned char security_passphrase_len;
GETrequest getFeed(server_ip, 80, server_name, data_source);
bool headers = false;
bool request_initiated = false;
int data_color;
int data_intensity;
unsigned long next_update = 0;



/*
 * Setup method - This initializes the Arduino and the WiFi module
 */

void setup() {

#ifdef DEBUG
	Serial.begin(57600);
	Serial.print("Orb of Approximate Data\n");
	Serial.print("Initializing...\n\n");
#endif

	// Setup the RGB LED output pins
	pinMode(redPin,   OUTPUT);
	pinMode(greenPin, OUTPUT);   
	pinMode(bluePin,  OUTPUT); 
	digitalWrite(redPin, LOW);
	digitalWrite(greenPin, LOW);
	digitalWrite(bluePin, LOW);

	pinMode(indicatorPin, OUTPUT);

	// Initialize the WiServer
 	WiServer.init(NULL);

	// Disable verbose mode
  	WiServer.enableVerboseMode(false);

	// Set up the readData method to get called with the results of 
	// the feed page requets.
  	getFeed.setReturnFunc(readData);

#ifdef DEBUG
	Serial.println("Ready.");
#endif

}



/*
 * Main loop() - This is where the magic happens. For small values of magic.
 */

void loop(){

	// Periodically grab updates from the data feed
	if ( (millis() > next_update) && (!getFeed.isActive()) ) {

#ifdef DEBUG
		Serial.print("\nRequesting new data\n");
#endif

		// Update flags
		digitalWrite(indicatorPin, HIGH);
		request_initiated = true;
		headers = false;

		// Set up the time for the next request
		next_update = millis() + (update_minutes * 60 * 1000);

		// And initiate the request.
		getFeed.submit();
	}


	// Run the WiServer.server_task() each time through the main loop()
	// so that it can do it's thing. 
	WiServer.server_task();

	// Determine if the most recent request has finished processing
	// And update the output if so.
	if ( request_initiated && (! getFeed.isActive()) ) {

		// Update flags
		digitalWrite(indicatorPin, LOW);
		request_initiated = false;

#ifdef DEBUG
		Serial.print("\n\nUpdating LEDs\n");
		Serial.print("Color: ");
		Serial.println(data_color);
		Serial.print("Intensity: ");
		Serial.print(data_intensity);
		Serial.print("\n\n");
#endif

		//
		// Update the RGB LEDs

		// Sanity check on the color we read from the data feed.  
		// Remember to change this if you add more colors to the palette
		// of your own data feed.
		if (data_color < 0 || data_color > 4) {
			data_color = 0;
		}

		// Quickly blink the LEDs for outlier intensity values
		if (data_intensity < 0) {
			blinkRGB(colors[data_color]);
			data_intensity = 0;
		} else if (data_intensity > 100) {
			blinkRGB(colors[data_color]);
			data_intensity = 100;
		}

		// And display our current color and intensity
		displayRGB(colors[data_color], data_intensity);

	}

	// Don't beat the poor server_task() to death.
	delay(10);
}


/*
 * void readData(char* data, int len)
 *
 * This is the callback function for the web request.  As chunks of data 
 * are read in from the remote web server, this function is called.  It 
 * will be called multiple times for each web request/response.  This
 * function scans to the end of the Headers and then looks for the 
 * Orb Data Format:  
 * $<color code>,<intensity (0 - 101)>
 *
 * If modifying this, keep in mind the comments that AsyncLabs, the people 
 * who made the Blackwidow Arduino + wifi that this project uses, provided
 * in their example code:
 *
 * Note that the data is not null-terminated, 
 * may be broken up into smaller packets, and 
 * includes the HTTP header. 
 *
 */

void readData(char* data, int len) {
	
	// Scan past the headers to the start of the body.  The start
	// of the data feed is marked by a $
	if (!headers) {
		while (len-- > 0) {
			if (*(data++) == '$') {
				headers = true;
				break;
			}
		}
	}

	// Once we're past the headers, parse the "color" and "intensity"
	// fields in the data feed into the corresponding variables
	if (headers && len > 0) {
		sscanf(data, "%i,%i ", &data_color, &data_intensity);
	}

}


/*
 * void displayRGB(struct rgbColor color, int intensity)
 *
 * RGB color values and an overall intensity passed to this function 
 * control the output of the attached LEDs.  Acceptable values for 
 * Red, Green, and Blue within the struct and for intensity are 0 - 100.
 */

void displayRGB(struct rgbColor color, int intensity) {

	// Scale the color's Red, Green, and Blue by the required intensity
	// and map these percentage values onto a scale of 0 - 255 to drive
	// the PWM output channels.
	//
	// The 0.0255 number used is 255 divided by 100 * 100, since both
	// the RGB values and the intensity are percentage values that need
	// to be divided by 100 before we use them here.

	// Use this version of the code if you're using the Adafruit 3 color
	// LED wherein the long lead is the anode.  Connect the anode to +5V
	// and the cathodes for each color to the PWM pins on the Arduino.
	// These values are inverted - subtracted from the PWM full power on
	// of 255 - since the LEDs are actually lit when the PWM signal is LOW,
	// rather than HIGH in this wiring configuration.
	int redVal = 255 - (0.0255 * color.red * intensity);
	int greenVal = 255 - (0.0255 * color.green * intensity);
	int blueVal = 255 - (0.0255 * color.blue * intensity);

	// Use this version of the code if you're using 3 separate LEDs for 
	// the RGB output with their cathodes connected to ground and their
	// anodes connected to the PWM pins on the Arduino. 
    //int redVal = 0.0255 * color.red * intensity;
    //int greenVal = 0.0255 * color.green * intensity;
    //int blueVal = 0.0255 * color.blue * intensity;	

	// Do the output
	analogWrite(redPin, redVal);
	analogWrite(greenPin, greenVal);
	analogWrite(bluePin, blueVal);
}


/*
 * void blinkRGB(struct rgbColor color)
 *
 * Quickly blinks a color to indicate values outside of the normal range
 * or operation.  We're doing it here rather than setting a timer so as 
 * not to have to juggle the timer interrupts and the Arduino PWM 
 * functionality.  If you modify the timings here, just make sure it
 * executs quickly so as not to tie up processing here for too long.
 */

void blinkRGB(struct rgbColor color) {
	for (int i=0; i < 5; i++) {
		displayRGB(color, 100);
		delay(25);
		displayRGB(color, 0);
		delay(25);
	}
	displayRGB(color, 100);
}
