-- Remember to connect GPIO16 (D0) and RST for deep sleep function,
-- better though a SB diode anode to RST cathode to GPIO16 (D0).

print("bme280m")

--# Settings #
dofile("nodevars.lua")
--# END settings #


function slp()
  print(tmr.now())
  node.dsleep(meas_period*1000000-tmr.now()+2258100,2)             
end

function get_sensor_Data()
  temperature,pressure,humidity,qnh=s:read(altitude)
  temperature=string.format("%.1f",temperature)
  humidity=string.format("%.1f",humidity)
  qnh=qnh+qnh_offs
  qnh=string.format("%.1f",qnh)
  print("Temperature: "..temperature.." deg C")
  print("Humidity: "..humidity.."%")
  print("QNH: "..qnh.." hPa")
end

function swf()
--  print("wifi_SSID: "..wifi_SSID)
--  print("wifi_password: "..wifi_password)
  wifi.eventmon.register(wifi.eventmon.STA_GOT_IP,smq)
  wifi.setmode(wifi.STATION) 
  wifi.setphymode(wifi_signal_mode)
  if client_ip ~= "" then
    wifi.sta.setip({ip=client_ip,netmask=client_netmask,gateway=client_gateway})
  end
  wifi.sta.sethostname(wifi_hostname)
  wifi.sta.config({ssid=wifi_SSID,pwd=wifi_password})
  print("swf done...")
end

function smq()
print(tmr.now())
  print("wifi.sta.status()",wifi.sta.status())
  if wifi.sta.status() ~= 5 then
    print("No Wifi connection...")
  else
    get_sensor_Data()
    m=mqtt.Client(client_id,120,username,password)
    print("  IP: ".. mqtt_broker_ip)
    print("  Port: ".. mqtt_broker_port)
    print("WiFi connected...")
    m:on("offline",slp)
--m:on("connect", function(client) print ("connected") end)
--m:on("offline", function(client) print ("offline") end)
    m:connect(mqtt_broker_ip,mqtt_broker_port,false,
      function(conn)
        print("Connected to MQTT")
        print("  IP: ".. mqtt_broker_ip)
        print("  Port: ".. mqtt_broker_port)
        print("  Client ID: ".. mqtt_client_id)
        print("  Username: ".. mqtt_username)
        if temperature~=nil then
          topic,payload=mqreq(1)
        else  
          topic,payload=mqreq(2)
        end  
        m:publish(topic,payload, 0, 0,
          function(conn)
            print("Published.")
            m:close()
            t1:alarm(1000,tmr.ALARM_SINGLE,slp)
        end)
      end,
      function(conn,reason)
        print("MQTT connect failed",reason)
      end)
  end
  print("smq done...")
end

print("app starting...")
temperature = 0
humidity = 0
qnh=0
t1=tmr.create()
i2c.setup(0,pin_sda,pin_scl,i2c.SLOW)
s=require('bme280').setup(0,nil,nil,nil,nil,nil,BME280_FORCED_MODE)
--print(s)
if s==nil then
  print("Failed BME280 setup.")
  cbslp()
else
  swf()
end
-- Watchdog loop, will force deep sleep if the operation somehow takes to long
tmr.create():alarm(30000,1,function() node.dsleep(meas_period*1000000) end)
