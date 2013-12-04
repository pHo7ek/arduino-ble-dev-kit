#include <SoftwareSerial.h>

char c;

SoftwareSerial mySerial(2, 3); // Rx, Tx

void setup()  
{
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
         mySerial.write(c);  // loop back iOS
      }
   }
}

