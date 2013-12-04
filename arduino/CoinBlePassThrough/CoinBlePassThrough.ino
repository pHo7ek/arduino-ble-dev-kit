#include <SoftwareSerial.h>

char c;

SoftwareSerial mySerial(2, 3); // RX, TX

void setup()  
{
   // Open serial communications and wait for port to open:
   Serial.begin(57600);
   while (!Serial) 
   {
     ; // wait for serial port to connect.
   }

   // set the data rate for the SoftwareSerial port
   mySerial.begin(57600);
}

void loop() // run over and over
{
   if (mySerial.available())
   {
     c = mySerial.read();
     if (c != NULL)
     {
       Serial.print(c);  // pass through
      }
   }
}
