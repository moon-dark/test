#!/sbin/sh
# Universal Flasher tool by JRsoft & Intronauta
# More info http://www.htcmania.com/showthread.php?t=258333
# based in the "VillainTheme system" tool by VillainTeam. More info etc, head to www.villainrom.co.uk
#
# This file is part of Universal Flasher Template.
#
# Universal Flasher tool is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or any later version.
#
# Universal Flasher tool is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
# without even the implied warranty of # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
# See the GNU General Public License for more details: <http://www.gnu.org/licenses/>



SYSTEM=`cat /cache/tools/MOD.config | grep mount_system | cut -d ">" -f 2`
DATA=`cat /cache/tools/MOD.config | grep mount_data | cut -d ">" -f 2`
UTMP=`cat /cache/tools/MOD.config | grep mount_Utmp | cut -d ">" -f 2`
SD=`cat /cache/tools/MOD.config | grep default_internal_sdcard | cut -d "=" -f 2`
SD2=`cat /cache/tools/MOD.config | grep default_external_sdcard | cut -d "=" -f 2`



for i in /system /data /Utmp $SD $SD2; do
  if [ $i = "/system" ]; then
     /sbin/$SYSTEM
  elif [ $i = "/data" ]; then
     /sbin/$DATA
  elif [ $i = "/Utmp" ]; then
     mkdir -p $i
     /sbin/$UTMP
  fi
  
  if [ `mount | awk '{print $3}' | grep $i | wc -l` = 0 ]; then     
     touch /cache/tools/ERROR`basename $i`
  fi
done
