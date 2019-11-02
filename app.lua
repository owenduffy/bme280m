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
  sens_status=bme280.setup(1,1,1,1)
  if sens_status~=2 then
     print("Failed BME280 setup.")
  else
    repeat
      temperature,pressure,humidity,qnh=bme280.read(altitude)
      --temperature=bme280.temp()
    until temperature~=nil and humidity~=nil and pressure~=nil
--    repeat
--      humidity=bme280.humi()
--    until humidity~=nil
    temperature=string.format("%.1f",temperature/100)
    humidity=string.format("%.1f",humidity/1000)
    qnh=string.format("%.1f",qnh/1000)
    print("Temperature: "..temperature.." deg C")
    print("Humidity: "..humidity.."%")
  end
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
        if sens_status==2 then
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
sda,scl=3,4   --D3,D4 GPIO00,GPIO02?
i2c.setup(0,sda,scl,i2c.SLOW) -- call i2c.setup() only once
swf()
-- Watchdog loop, will force deep sleep if the operation somehow takes to long
tmr.create():alarm(30000,1,function() node.dsleep(meas_period*1000000) end)
