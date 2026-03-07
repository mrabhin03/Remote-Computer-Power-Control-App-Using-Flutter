#include <ESP8266WiFi.h>
#include <ESP8266HTTPClient.h>
#include <WiFiUdp.h>
#include <ArduinoJson.h>
#include <WiFiClientSecure.h>
#include <ESP8266Ping.h>

WiFiClientSecure secureClient;

/* ================= CONFIG ================= */

const char* ssid     = "MY WIFI-2.4G";
const char* password = "87654321";

const char* WAIT_URL = "https://palegreen-chough-695018.hostingersite.com/Wake/wait.php";

IPAddress broadcastIP(192,168,20,255);
const int PC_PORT = 3389;
WiFiUDP udp;

bool failWake=false;
int failWakeCount=0;

byte pcMAC[6];
IPAddress pcIP(192,168,20,6);   // last known IP (default)

int lastStatus = -1;

/* ---------- WIFI ---------- */

void ensureWiFi() {

  if (WiFi.status() == WL_CONNECTED) return;

  Serial.println("Reconnecting WiFi...");

  WiFi.begin(ssid,password);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
  }

  Serial.println("WiFi connected");
}

/* ---------- FIND PC BY RDP ---------- */

bool findPcIP() {
  if(isPcOnline()) return true;

  WiFiClient client;
  IPAddress local = WiFi.localIP();

  Serial.println("Searching PC IP...");

  for(int i=1;i<=20;i++) {

    IPAddress test(local[0],local[1],local[2],i);

    if(client.connect(test,PC_PORT)) {

      client.stop();

      pcIP = test;

      Serial.print("PC found at ");
      Serial.println(pcIP);

      return true;
    }

    delay(30);
  }

  Serial.println("PC not found");

  return false;
}

/* ---------- CHECK PC ONLINE ---------- */

bool isPcOnline() {
  WiFiClient pcClient;
  pcClient.setTimeout(1000);
  bool ok = pcClient.connect(pcIP, PC_PORT);
  pcClient.stop();
  return ok;
}


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

  memset(packet,0xFF,6);

  for(int i=1;i<=16;i++)
    memcpy(&packet[i*6],pcMAC,6);

  udp.beginPacket(broadcastIP,9);
  udp.write(packet,sizeof(packet));
  udp.endPacket();

  Serial.println("Wake-on-LAN sent");
}

/* ---------- UPDATE STATUS ---------- */

void updateStatusHTTPS(int status,int Mode=0) {
  if(status == lastStatus && Mode==0) return;
  lastStatus = status;

  ensureWiFi();

  HTTPClient http;
  String url = "https://palegreen-chough-695018.hostingersite.com/Wake/update.php?status=" + String(status)+"&ipaddress="+pcIP.toString();
  if (http.begin(secureClient, url)) {
    int httpCode = http.GET();
    if (httpCode > 0) {
      Serial.printf("Status %d sent! Server response: %d\n", status, httpCode);
    } else {
      Serial.printf("Error: %s\n", http.errorToString(httpCode).c_str());
    }
    http.end();
  } else {
    Serial.println("Connection failed at http.begin");
  }

  delay(200);
  yield();
}

/* ---------- PARSE SERVER JSON ---------- */

void parseServer(String json) {
  if(failWakeCount>4){
    failWakeCount=0;
    return;
  }

  StaticJsonDocument<256> doc;

  if(deserializeJson(doc,json)) return;

  if(doc["mac"]) {

    const char* macStr = doc["mac"];

    int values[6];

    if(6==sscanf(macStr,"%x:%x:%x:%x:%x:%x",
      &values[0],&values[1],&values[2],
      &values[3],&values[4],&values[5])) {

      for(int i=0;i<6;i++)
        pcMAC[i] = (byte)values[i];

    }
  }

  const char* status = doc["status"];

  if((status && String(status)=="1")) {
    wakeUpProcess();
  }else if(String(status)=="0" && isPcOnline()){
    Serial.println("System Already online");
    findPcIP();
    updateStatusHTTPS(3,1);
    
  }
}


void wakeUpProcess(){
  updateStatusHTTPS(2);
    Serial.println("Wake command received");

    
    delay(200);
    for(int i=0;i<4;i++){
      sendWakeOnLan();
      Serial.println("Check Status");
      if(waitForPcOnline(25000)){
        updateStatusHTTPS(3);
        Serial.println("Waked");
        findPcIP();
        return;
      }
      Serial.println("Wrong address");
      findPcIP();
    }
}
/* ---------- SERVER LONG POLL ---------- */

void waitForCommand() {
  String response;
  WiFiClientSecure client;
  client.setInsecure();

  HTTPClient http;
  Serial.println("Server request sended...");
  http.setTimeout(30000);

  if(!http.begin(client,WAIT_URL))
    return;

  int code = http.GET();

  if(code == HTTP_CODE_OK) {
    Serial.println("Server responded...");
    response = http.getString();

    Serial.println(response);

    
  }

  http.end();
  parseServer(response);
}

/* ================= SETUP ================= */

void setup() {

  Serial.begin(115200);

  WiFi.setSleepMode(WIFI_NONE_SLEEP);

  WiFi.begin(ssid,password);

  udp.begin(9);

  secureClient.setInsecure();
  secureClient.setBufferSizes(512, 512);

  Serial.println("NodeMCU started");
}
/* ================= LOOP ================= */

void loop() {

  ensureWiFi();

  bool online = isPcOnline();

  if(online){
    updateStatusHTTPS(3);
    Serial.println("System Online");
  }
  else{
    updateStatusHTTPS(0);
    Serial.println("System Offline");
  }

  waitForCommand();

  delay(1200);
}