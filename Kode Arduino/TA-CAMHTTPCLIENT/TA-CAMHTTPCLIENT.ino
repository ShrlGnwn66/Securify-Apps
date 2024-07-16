#include <WiFi.h>
#include <NTPClient.h>
#include <WiFiUdp.h>
#include <ctime>
#include <ArduinoJson.h>
#include <HTTPClient.h>
#include "Arduino.h"
#include "esp_camera.h"
#include "soc/soc.h"
#include "soc/rtc_cntl_reg.h"
#include "base64.h"

// WiFi credentials
const char* ssid = "LAPTOPKEREN";
const char* password = "akuharusbisa";

// Perintah untuk Capture
#define AksesPintu 14
#define DeteksiAncaman 15
#define LED 4

// Firebase project reference URL
const char* CodeRegistration = "Home-270624";
const char* baseURL = "https://securify-apps-default-rtdb.firebaseio.com/";
String DATABASE_URL = String(baseURL) + CodeRegistration + ".json";

// Define OV2640 camera
#define PWDN_GPIO_NUM 32
#define RESET_GPIO_NUM -1
#define XCLK_GPIO_NUM 0
#define SIOD_GPIO_NUM 26
#define SIOC_GPIO_NUM 27
#define Y9_GPIO_NUM 35
#define Y8_GPIO_NUM 34
#define Y7_GPIO_NUM 39
#define Y6_GPIO_NUM 36
#define Y5_GPIO_NUM 21
#define Y4_GPIO_NUM 19
#define Y3_GPIO_NUM 18
#define Y2_GPIO_NUM 5
#define VSYNC_GPIO_NUM 25
#define HREF_GPIO_NUM 23
#define PCLK_GPIO_NUM 22

camera_config_t config;

// NTP Client
WiFiUDP ntpUDP;
NTPClient timeClient(ntpUDP, "pool.ntp.org");
time_t epochTime = 0;  // variable to store UNIX timestamp

void initCamera() {
  // OV2640 camera module
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;
  config.pin_d0 = Y2_GPIO_NUM;
  config.pin_d1 = Y3_GPIO_NUM;
  config.pin_d2 = Y4_GPIO_NUM;
  config.pin_d3 = Y5_GPIO_NUM;
  config.pin_d4 = Y6_GPIO_NUM;
  config.pin_d5 = Y7_GPIO_NUM;
  config.pin_d6 = Y8_GPIO_NUM;
  config.pin_d7 = Y9_GPIO_NUM;
  config.pin_xclk = XCLK_GPIO_NUM;
  config.pin_pclk = PCLK_GPIO_NUM;
  config.pin_vsync = VSYNC_GPIO_NUM;
  config.pin_href = HREF_GPIO_NUM;
  config.pin_sscb_sda = SIOD_GPIO_NUM;
  config.pin_sscb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn = PWDN_GPIO_NUM;
  config.pin_reset = RESET_GPIO_NUM;
  config.xclk_freq_hz = 20000000;
  config.pixel_format = PIXFORMAT_JPEG;
  config.frame_size = FRAMESIZE_QVGA;
  config.jpeg_quality = 20;  // Set image quality 0 - 64
  config.fb_count = 1;

  // Camera init
  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    Serial.printf("Camera init failed with error 0x%x", err);
    ESP.restart();
  }
}

void setup() {
  Serial.begin(115200);

  pinMode(AksesPintu, INPUT);
  digitalWrite(AksesPintu, LOW);
  pinMode(DeteksiAncaman, INPUT);
  digitalWrite(DeteksiAncaman, LOW);
  pinMode(LED, OUTPUT);

  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.println("Connecting to WiFi...");
  }
  Serial.println("Connected to WiFi.");
  Serial.println(WiFi.localIP());

  // Initialize camera
  initCamera();

  // Initialize NTP client
  timeClient.begin();
  timeClient.setTimeOffset(25200);  //(GMT+7:00)

  while (epochTime == 0) {
    timeClient.update();
    epochTime = timeClient.getEpochTime();
    delay(100);  
  }
}

void captureAndSendPhoto(String keterangan) {
  // Memastikan Buffer dibersihkan
  camera_fb_t* fb = NULL;
  fb = esp_camera_fb_get();
  if (fb) {
    esp_camera_fb_return(fb);
  }

  delay(500);

  // Capture photo
  fb = esp_camera_fb_get();
  if (!fb) {
    Serial.println("Camera capture failed");
    return;
  }

  digitalWrite(LED, HIGH);
  delay(30);
  digitalWrite(LED, LOW);

  // Mengubah image to base64
  String base64Image = base64::encode(fb->buf, fb->len);

  // Bersihkan frame buffer kembali
  esp_camera_fb_return(fb);

  // Get current time
  timeClient.update();
  epochTime = timeClient.getEpochTime();

  // Convert UNIX timestamp to local time and date
  struct tm* localTime = localtime(&epochTime);

  // Format Waktu dan Tanggal
  char timeStr[9];
  sprintf(timeStr, "%02d:%02d:%02d", localTime->tm_hour, localTime->tm_min, localTime->tm_sec);
  char dateStr[11];
  sprintf(dateStr, "%02d-%02d-%04d", localTime->tm_mday, localTime->tm_mon + 1, localTime->tm_year + 1900);

  // Create a JSON object to hold your data
  DynamicJsonDocument jsonDoc(200);

  // Add data to the JSON object
  jsonDoc["img"] = base64Image;
  jsonDoc["keterangan"] = keterangan;
  jsonDoc["Tanggal"] = dateStr;
  jsonDoc["waktu"] = timeStr;

  // Convert JSON object to string
  String jsonData;
  serializeJson(jsonDoc, jsonData);

  // Send JSON data to Firebase using HTTP POST
  HTTPClient http;
  http.begin(DATABASE_URL);
  http.addHeader("Content-Type", "application/json");
  int httpResponseCode = http.POST(jsonData);

  if (httpResponseCode > 0) {
    Serial.print("HTTP Response code: ");
    Serial.println(httpResponseCode);
    Serial.println("Data sent to Firebase.");
  } else {
    Serial.print("Error sending data to Firebase. HTTP error code: ");
    Serial.println(httpResponseCode);
  }

  http.end();
}

// Deklarasi variabel status
bool statusAksesPintu = false;
bool statusDeteksiAncaman = false;

void loop() {
  // Membaca status pin
  int aksesPintuStat = digitalRead(AksesPintu);
  int deteksiAncamanStat = digitalRead(DeteksiAncaman);

  // Cek perubahan status pada kedua pin
  bool aksesPintuChanged = (aksesPintuStat == HIGH && !statusAksesPintu);
  bool deteksiAncamanChanged = (deteksiAncamanStat == HIGH && !statusDeteksiAncaman);

  // Jika salah satu atau kedua pin berubah menjadi HIGH
  if (aksesPintuChanged || deteksiAncamanChanged) {
    String keterangan;
    if (aksesPintuChanged) {
      keterangan = "Pintu Terbuka";
    } else if (deteksiAncamanChanged) {
      keterangan = "Peringatan Ancaman";
    }
    captureAndSendPhoto(keterangan);
  }

  // Perbarui status pin
  statusAksesPintu = (aksesPintuStat == HIGH);
  statusDeteksiAncaman = (deteksiAncamanStat == HIGH);
  
  delay(10);
}
