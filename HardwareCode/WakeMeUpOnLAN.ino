#include <ESP8266WiFi.h>
#include <ESP8266HTTPClient.h>
#include <WiFiUdp.h>
#include <ArduinoJson.h>
#include <WiFiClientSecure.h>
/* ================= CONFIG ================= */

// WiFi
const char* ssid     = "MY WIFI-2.4G";
const char* password = "87654321";

// Server
const char* WAIT_URL = "https://palegreen-chough-695018.hostingersite.com/Wake/wait.php";

// PC (Ethernet)
IPAddress pcIP(192, 168, 20, 10);
byte pcMAC[] = {0x50, 0x81, 0x40, 0x2C, 0x11, 0xDE};

// Port to check PC online (Windows RDP)
const int PC_PORT = 3389;

/* ========================================== */

WiFiUDP udp;
void updatePcIpFromJson(String json) {

  StaticJsonDocument<256> doc;
  DeserializationError error = deserializeJson(doc, json);

  if (error) {
    Serial.println("JSON parse failed");
    return;
  }

  if (!doc.containsKey("pc_ip")) return;

  const char* newIpStr = doc["pc_ip"];

  IPAddress newIP;
  if (!newIP.fromString(newIpStr)) {
    Serial.println("Invalid IP from server");
    return;
  }

  if (newIP != pcIP) {
    Serial.print("PC IP changed → ");
    Serial.println(newIpStr);
    pcIP = newIP;
  }
}
/* ---------- WIFI ---------- */
void ensureWiFi() {
  if (WiFi.status() == WL_CONNECTED) return;

  Serial.println("WiFi disconnected. Reconnecting...");
  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("\nWiFi connected");
  Serial.print("NodeMCU IP: ");
  Serial.println(WiFi.localIP());
}

/* ---------- PC STATUS ---------- */
bool isPcOnline() {
  WiFiClient pcClient;
  pcClient.setTimeout(1000);
  bool ok = pcClient.connect(pcIP, PC_PORT);
  pcClient.stop();
  return ok;
}

/* ---------- WAIT FOR PC ---------- */
bool waitForPcOnline(unsigned long timeoutMs) {
  unsigned long start = millis();

  while (millis() - start < timeoutMs) {
    if (isPcOnline()) return true;
    delay(3000);
  }
  return false;
}

/* ---------- WAKE ON LAN ---------- */
void sendWakeOnLan() {
  byte packet[102];
  memset(packet, 0xFF, 6);

  for (int i = 1; i <= 16; i++) {
    memcpy(&packet[i * 6], pcMAC, 6);
  }

  udp.beginPacket(IPAddress(255,255,255,255), 9);
  udp.write(packet, sizeof(packet));
  udp.endPacket();

  Serial.println("Wake-on-LAN packet sent");
}
void updateStatusHTTPS(int status) {
  WiFiClientSecure client;
  client.setInsecure();

  HTTPClient http;
  String url = "https://palegreen-chough-695018.hostingersite.com/Wake/update.php?status=" + String(status);

  http.begin(client, url);
  http.GET();
  http.end();

  Serial.print("Status updated → ");
  Serial.println(status);
}

/* ---------- WAIT FOR COMMAND ---------- */
void waitForCommandFromServer() {
  
  Serial.println("\nWaiting for server command...");

  WiFiClientSecure client;
  client.setInsecure();  // 🔑 allow HTTPS without cert

  HTTPClient http;
  if (!isPcOnline()) {
    Serial.println("System Offline");
    updateStatusHTTPS(0);
  }else{
    Serial.println("System Online");
    updateStatusHTTPS(3);
  }

  http.setTimeout(30000);
  http.setReuse(false);   // do NOT reuse TLS socket
  // ❌ DO NOT use HTTP/1.0 over HTTPS

  if (!http.begin(client, WAIT_URL)) {
    Serial.println("HTTPS begin failed");
    return;
  }

  int code = http.GET();

  if (code == HTTP_CODE_OK) {
    String response = http.getString();
    Serial.print("Server response: ");
    Serial.println(response);

    // Update PC IP from JSON
    updatePcIpFromJson(response);

    // Check wake command
    StaticJsonDocument<256> doc;
    deserializeJson(doc, response);

    const char* status = doc["status"];

    if (status && String(status) == "1") {
      Serial.println("WAKE command received");

      if (!isPcOnline()) {
        updateStatusHTTPS(2);
        sendWakeOnLan();
        if (waitForPcOnline(60000)) {
          Serial.println("Waked");
        }
      }
    }

  } else {
    Serial.print("HTTP error: ");
    Serial.println(code);
  }

  http.end();
}



/* ================= SETUP ================= */

void setup() {
  Serial.begin(115200);
  delay(1000);

  WiFi.setSleepMode(WIFI_NONE_SLEEP); // important for long polling
  WiFi.begin(ssid, password);

  udp.begin(9);

  Serial.println("NodeMCU booted");
}

/* ================= LOOP ================= */

void loop() {
  ensureWiFi();                  // keep Wi-Fi alive
  waitForCommandFromServer();    // long poll server
  delay(1000);                   // small cooldown
}
