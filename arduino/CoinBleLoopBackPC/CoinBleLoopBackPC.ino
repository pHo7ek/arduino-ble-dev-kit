char c;

void setup()  
{
   // set the data rate for the SoftwareSerial port
   Serial.begin(57600);
}

void loop() // run over and over
{
   if (Serial.available())
   {
      c = Serial.read();
      if (c != NULL)
      {
         Serial.print(c);  // loop back PC
      }
   }
}

