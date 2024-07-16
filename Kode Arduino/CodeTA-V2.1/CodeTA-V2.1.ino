#include <Arduino.h>
#include <ESP8266WiFi.h>
#include "SinricPro.h"
#include "SinricProSwitch.h"

// INITIALISASI WIFI & SINRIC PRO & BAUD RATE
#define WIFI_SSID         "LAPTOPKEREN"  // WIFI_SSID
#define WIFI_PASS         "akuharusbisa"  // WIFI_PASS
#define APP_KEY           "01c3e7f5-43b6-41a3-946c-31e25cc64aa7"  // App Key Sinric Pro
#define APP_SECRET        "e46d9a8d-f31f-4b29-858f-9fd9ff90489b-b78405a9-f241-4a18-9fe4-77a6acd61b91"  // App Secret Sinric Pro
#define SWITCH_ID_1       "6630d9cabfef1b4f30c7514d"  // Device Id Sinric Pro
#define BAUD_RATE         115200  

// INITIALISASI PERANGKAT
#define RELAYPIN_1 5 //D1
#define pinAlarm  12 //D6
#define pinGetar 14 //D5

// Pin for communication with ESP32CAM
const int AksesPintu = 4; // D2
const int DeteksiAncaman = 13; // D7

void setup() {
  Serial.begin(BAUD_RATE); 
  setupWiFi();
  setupSinricPro();
  pinMode(pinGetar, INPUT);
  pinMode(pinAlarm, OUTPUT);

  // Komunikasi Cam
  pinMode(AksesPintu, OUTPUT);
  digitalWrite(AksesPintu, LOW);
  
  pinMode(DeteksiAncaman, OUTPUT);
  digitalWrite(DeteksiAncaman, LOW);
}

bool onPowerState1(const String &deviceId, bool &state) {
  Serial.printf("Device 1 turned %s", state ? "on" : "off");
  digitalWrite(RELAYPIN_1, state ? LOW : HIGH);
  if (state) { // Jika relay ON
    digitalWrite(AksesPintu, HIGH);
    delay(10);
    digitalWrite(AksesPintu, LOW);
  } 
  return true;
}



// setup function for WiFi connection
void setupWiFi() {
  Serial.printf("\r\n[Wifi]: Connecting");

  WiFi.setSleepMode(WIFI_NONE_SLEEP); 
  WiFi.setAutoReconnect(true);
  WiFi.begin(WIFI_SSID, WIFI_PASS);

  while (WiFi.status() != WL_CONNECTED) {
    Serial.printf(".");
    delay(250);
  }

  Serial.printf("connected!\r\n[WiFi]: IP-Address is %s\r\n", WiFi.localIP().toString().c_str());
}

// setup function for SinricPro
void setupSinricPro() {
  // add devices and callbacks to SinricPro
  pinMode(RELAYPIN_1, OUTPUT);
    
  SinricProSwitch& mySwitch1 = SinricPro[SWITCH_ID_1];
  mySwitch1.onPowerState(onPowerState1);
    
  // setup SinricPro
  SinricPro.onConnected([](){ Serial.printf("Connected to SinricPro\r\n"); }); 
  SinricPro.onDisconnected([](){ Serial.printf("Disconnected from SinricPro\r\n"); });
   
  SinricPro.begin(APP_KEY, APP_SECRET);
}


void loop() {
  // Sinric Pro
  SinricPro.handle();

  // Membaca nilai Sensor Getar
  int PinValue = digitalRead(pinGetar);

  // Mengecek kondisi Relay
  bool relayOff = digitalRead(RELAYPIN_1);

  // Jalankan Sensor Getar Jika Relay OFF
if (relayOff) {
  if (PinValue == HIGH) {
    digitalWrite(pinAlarm, HIGH);
    digitalWrite(DeteksiAncaman, HIGH);

    Serial.println("Peringatan Ancaman!!!");
    delay(5000); //Durasi bunyi buzzer

    digitalWrite(DeteksiAncaman, LOW);
    digitalWrite(pinAlarm, LOW);
  } else {
    digitalWrite(pinAlarm, LOW);
    Serial.println("Tidak ada Ancaman");
    digitalWrite(DeteksiAncaman, LOW); 
  }
} else {
  // Jika Relay ON maka hentikan Sensor Getar
  digitalWrite(pinAlarm, LOW);
  digitalWrite(DeteksiAncaman, LOW);
}


  delay(100);
}

