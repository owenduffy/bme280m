--copy to init.lua and edit cfgdefs below
--the values correspond to cfgvars
cfgdefs={
"bme280m_001",
"",
"",
"4",
"3",
"60",
"0",
"0",
"",
"192.168.0.10",
"1883",
"",
"",
"",
}
--no need for changes below here
cfgvars={
"wifi_hostname",
"wifi_SSID",
"wifi_password",
"pin_scl",
"pin_sda",
"meas_period",
"altitude",
"qnh_offs",
"nodeid",
"mqtt_broker_ip",
"mqtt_broker_port",
"mqtt_username",
"mqtt_password",
"mqtt_client_id"
}

function mqreq(opt)
  if opt==1 then
    topic="thp/"..nodeid.."/payload"
    payload=temperature .. "," .. humidity .. "," .. qnh.. ",\"" .. dev .. "\",\"" .. ver .. "\""
  elseif opt==2 then
    topic="thp/"..nodeid.."/status"
    payload="fail"
  end
  print("req:"..topic..":"..payload)
  return topic,payload
end


print("\n\nHold Pin00 low for 1s to stop boot.")
print("\n\nHold Pin00 low for 5s for config mode.")
tmr.delay(1000000)
if gpio.read(3) == 0 then
  print("Release to stop boot...")
  tmr.delay(4000000)
  if gpio.read(3) == 0 then
    print("Release now (wifi cfg)...")
    print("Starting wifi config mode...")
    dofile("wifi_setup.lua")
    return
  else
    print("...boot stopped")
    return
    end
  end

print("Starting...")
if pcall(function ()
    print("Open config")
--    dofile("config.lc")
    dofile("config.lua")
    end) then
  dofile("app.lua")
else
  print("Starting wifi config mode...")
  dofile("wifi_setup.lua")
end
