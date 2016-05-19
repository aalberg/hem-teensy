// Code for an Arduino Uno used to continuity test the teensy driver.
// Speed results can be found in the comments with the delays.
#include <SPI.h>

// Pin constants.
constexpr int slave_pin = 9;
constexpr int led_pin = 8;

// Settings for SPI speed, data order and data mode.
SPISettings spi_settings(1000000, MSBFIRST, SPI_MODE0); 

// Data storage
uint8_t rec_byte = 0;
uint8_t send_byte = 0;
constexpr int buffer_size = 1000;
uint8_t buf[buffer_size];

void setup() {
  // Set up data
  for (int i = 0; i < buffer_size; i ++) {
    buf[i] = i % 250;
  }
  
  // Set up pins.
  pinMode(slave_pin, OUTPUT);
  pinMode(led_pin, OUTPUT);

  // Initialize Serial.
  Serial.begin(115200);

  // Initialize SPI.
  SPI.begin();

  // Post setup verification.
  for (int i = 0; i < 5; i ++) {
    digitalWrite(led_pin, HIGH);
    delay(100);
    digitalWrite(led_pin, LOW);
    delay(100); 
  }
  Serial.print("started\n");
}

void loop() {
  // Send and read a byte from SPI.
  SPI.beginTransaction(spi_settings);
  digitalWrite(slave_pin, LOW);
  //rec_byte = SPI.transfer(send_byte);
  SPI.transfer(buf, buffer_size);
  digitalWrite(slave_pin, HIGH);
  SPI.endTransaction();

  /*send_byte++;
  if (send_byte >= 250) send_byte = 0;*/

  // Uart echo code, slows things down
  /*for (int i = 0; i < 40000; i ++);
   Echo the byte out UART.
  Serial.print(rec_byte, HEX);
  Serial.print('\n');*/

  // One byte at a time.
  //delayMicroseconds(65); // 11.1kBps
  //delayMicroseconds(25); // 20.265kBps
  //delayMicroseconds(1); // 39.5kBps
  // No delay: 40.7kBps

  // 1000 bytes at a time.
  delayMicroseconds(6000); // 68kBps
  // Upper bound of teensy: 71.5kBps
}
