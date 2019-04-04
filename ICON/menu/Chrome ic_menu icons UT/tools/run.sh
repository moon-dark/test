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
#
# << [Changelog] >>
# v.1.0   >hello world
# v.1.1   >"dirty fix" detecting path for internal sdcard in CWM4 || check free space before start the process to prevent errors
# v.1.2   >minor backup fixes
# v.1.3   >permissions fixes in backup  
# v.1.4   >redone "CWM4 compatibility" and sdcard path
# v.2.0   >new backup system in .tar format for keep permissions
# v.2.1   >minor bug fixes with dalvik-cache, mod version & logs
# v.2.2   >minor bug fixes with sdcard path and check for free space available before theming
# v.2.3   >minor changes and added credits
# v.2.4   >now XTRAS is applied in first place || fixed working sdcard path in restore
# v.2.5   >minor bug fixes
# v.3.0   >Now the whole process takes place in RAM instead of sdcard || Added mount.sh and MOD.config files || working with 7z instead zip binary
# v.3.1   >New error management system || Adding exceptions to forced exit when we have problems mounting partitions, sdcards a/or space required ||
#         >Added mount command for /Utmp in MOD.config || Utmp full resized ||  Redone backup, now works in Utmp instead sdcard too||
#         >minor bugfixes in extreme conditions
# v.3.2   >Fixed the "update binary" in the restore to solve problems restoring in CyanogenMods roms (Thanks to shayne77)
# v.3.3   >Now it's possible to add in the same folder files for stock and cyanogenmod roms by adding the "CMOD#" prefix to the cyano files/resources 
#         >This feature works in the morph and xtras process and must be enabled in the MOD.config file (check it for more details and examples)
# v.3.4   >Minor fixes, optimizations and mergers in code



UI_PRINT()
{
	if [ ${OUTFD} ];then
		echo "ui_print ${1} " 1>&$OUTFD
		echo "ui_print " 1>&$OUTFD
	else
		if [ "${#}" -lt 1 ];then
			echo " "
		else
			echo "${1}"
		fi
	fi
} 

  
EXITING()
{
        rm -Rf /cache/tools /system/xbin/7z /system/lib/p7zip
        if [ $1 = 0 ];then
           exit 0
	else           
          for i in  /data/dalvik-cache /dalvik/dalvik-cache /cache/dalvik-cache /sd-ext/dalvik-cache;do
            if [ -d $i ];then 
               rm -Rf $i 
            fi
          done
        fi 
} 


LOGS()
{
        echo $1 >>$LOGFILE
} 




OUTFD=`ps | grep -v "grep" | grep -o -E "update_binary(.*)" | cut -d " " -f 3`
SD=`cat /cache/tools/MOD.config | grep default_internal_sdcard | cut -d "=" -f 2`
SD2=`cat /cache/tools/MOD.config | grep default_external_sdcard | cut -d "=" -f 2`
BACKUP=`cat /cache/tools/MOD.config | grep DO_BACKUP | cut -d "=" -f 2`
CLEANMORPHING=`cat /cache/tools/MOD.config | grep CLEAN_MORPHING | cut -d "=" -f 2`
MULTIPLATTFORM=`cat /cache/tools/MOD.config | grep MULTIPLATTFORM | cut -d "=" -f 2`
V4MORPHING=`cat /cache/tools/MOD.config | grep V4_MORPHING | cut -d "=" -f 2`
LOGENABLED=`cat /cache/tools/MOD.config | grep LOG_ENABLED | cut -d "=" -f 2`
SCREENLOG=`cat /cache/tools/MOD.config | grep SCREEN_LOG | cut -d "=" -f 2`
MOD=`cat /cache/tools/MOD.config | grep MOD_VERSION | cut -d "=" -f 2`



#########################################   E N V I R O N M E N T    ##############################################
LOG="SETTING UP THE ENVIRONMENT >>"; UI_PRINT "$LOG"


#CHECKING IF MOUNTING PROCESS WAS FINE & EXIT IF GOT CRITICAL ERRORS
ERROR=0
for i in system data Utmp; do 
   if [ -e /cache/tools/ERROR$i ]; then
      if [ `find ./Utmp/XTRAS/$i/* -type f | wc -l` = 0 ] && [ `find ./Utmp/MORPH/$i/* -type f | wc -l` = 0 ] && [ $i != "Utmp" ];then
         ERROR=0
         UI_PRINT " "; UI_PRINT "[v] /$i can't be mounted but don't need it"
      else
         UI_PRINT " ";UI_PRINT "[!] Impossible to mount /$i!"
         ERROR=1
      fi
   fi
done

if [ $ERROR = 1 ] || [ -e /cache/tools/ERRORUtmp ];then
   UI_PRINT " "; UI_PRINT "[ERROR] We can't ignore some problems!"; UI_PRINT "[EXIT]  Check and configure MOD.config"
   EXITING "0"
fi


#SET THE WORKING SDCARD & EXIT IF GOT CRITICAL ERRORS
if [ -e /cache/tools/ERROR`basename $SD` ] && [ -e /cache/tools/ERROR`basename $SD2` ] && [ $BACKUP = "yes" ];then
   UI_PRINT " "; UI_PRINT "[ERROR] We need one sdcard mounted!"; UI_PRINT "[EXIT]  Check and configure MOD.config"
   EXITING "0"
elif [ -e /cache/tools/ERROR`basename $SD` ];then
   SD=$SD2
fi 

if [ -d /Utmp/XTRAS/sdcard ];then
  mv /Utmp/XTRAS/sdcard  /Utmp/XTRAS$SD
fi



#CHECK FOR FREE SPACE REQUIRED & EXIT IF GOT CRITICAL ERRORS
SP1=`df -P $SD | grep % | awk '{print $4}'`
SP2=`du -s /Utmp | awk '{print $1}'`
SP3=`df -P /Utmp | grep % | awk '{print $4}'`
if [ $SP3 -lt $SP2 ];then
   UI_PRINT "[>] Free RAM available: $SP3 kB"
   UI_PRINT "[>] Free RAM required: $SP2 kB"; UI_PRINT " "
   UI_PRINT "[ERROR] There's not enough RAM to work!"; UI_PRINT "[EXIT]  This zip is too big!"
   EXITING "0"
elif [ $BACKUP = "yes" ];then
   UI_PRINT " "; UI_PRINT "[>] sdcard: $SD"
   UI_PRINT "[>] Free space available: $SP1 kB"
   UI_PRINT "[>] Free space required: $SP2 kB"; UI_PRINT " "

   if [ $SP1 -lt $SP2 ];then
      UI_PRINT "[ERROR] There's not enough space in $SD!"
      EXITING "0"
   fi
else
   UI_PRINT "[v] Everything is OK"; UI_PRINT " "
fi


#CYANO or STOCK?
if [ `cat /system/build.prop | grep ro.build.host=cyanogenmod | wc -l` = 1 ];then   
   CYANO="yes"
   BASEROM="Cyanogenmod"    
else                                                                                 
   CYANO="no"
   BASEROM="Stock"
fi


#########################################   H E R E    W E   G O!    ############################################
PATHFRAM="/Utmp/system/framework"
PATHAPP="/Utmp/system/app"
PATHDATA="/Utmp/data/app"
APPLY="/Utmp/apply/TMP"
RESTORE="/Utmp/restore"
XTRAS="/Utmp/XTRAS"
LOGDATE=`date +%d%b%Y-%H%M`

/cache/tools/tar -pxPf  /cache/tools/p7zip.tar


#PREPARING BACKUP ENVIRONMENT
if [ ! -d $SD/UniversalFlasher ];then
   mkdir -p $SD/UniversalFlasher
fi

mkdir -p $RESTORE
/system/xbin/7z x /cache/tools/restore.zip -o$RESTORE

if [ $BACKUP = "yes" ];then
   cp /cache/tools/tar $RESTORE/tools/
   for i in mount_system mount_data mount_Utmp;do
      echo `cat /cache/tools/MOD.config | grep $i | cut -d ">" -f 2` >> $RESTORE/tools/mount.sh
   done
fi



#LOG FILE INIT
if [ $LOGENABLED = "yes" ];then
   LOGFILE="$SD/UniversalFlasher/Backup_$LOGDATE.log"
   date > $LOGFILE
   LOGS "$LOG"
   LOGS "> Set working sdcard path as $SD"
   LOGS "> Clean morphing enabled? $CLEANMORPHING"
   LOGS "> We're working in a $BASEROM based rom"
   LOGS "> Multiplattform support enabled? $MULTIPLATTFORM"
   LOGS "> FIX -v4 folders enabled? $V4MORPHING"
else
   LOGFILE="/dev/null"
fi


LOG="<< FLASHING $MOD MOD >>"; LOGS "$LOG"; UI_PRINT "$LOG"


if [ $SCREENLOG != "yes" ];then
   OUTFD=0
fi


###############   ADDING XTRAS   ##################
LOG="ADDING XTRA FILES >>"; LOGS "$LOG"; UI_PRINT " "; UI_PRINT "$LOG"

if [ -d $XTRAS ];then

 cd $XTRAS

 if [ `find * -type f | wc -l` != 0 ]; then
   CHECK=1 

   find * -type f | while read i;do 
     PATHXTRA=`dirname $i`
     APPXTRA=`basename $i`
     x=0

     #CYANOGENMOD vs STOCK BASED ROM
     if [ $MULTIPLATTFORM = "yes" ] && [ $CYANO = "yes" ];then  
        if [ `echo $APPXTRA | cut -d "#" -f 1` = "CMOD" ];then 
           mv ./$i ./$PATHXTRA/`echo $APPXTRA | cut -d "#" -f 2` 
           i="$PATHXTRA/`echo $APPXTRA | cut -d "#" -f 2`" 
           APPXTRA=`basename $i`  
        elif [ `echo $APPXTRA | cut -d "#" -f 1` != "CMOD" ] && [ -e $XTRAS/$PATHXTRA/CMOD#$APPXTRA ];then
           rm $XTRAS/$i
           x=1
        fi
     elif [ $MULTIPLATTFORM = "yes" ] && [ $CYANO = "no" ] && [ `echo $APPXTRA | cut -d "#" -f 1` = "CMOD" ];then   
        rm $XTRAS/$i
        x=1        
     fi
     
     #APPLYING A/OR BACKUP
     if [ $x = 0 ] && [ -e $XTRAS/$i ];then       
        if [ -e /$i ];then         
           if [ $BACKUP = "yes" ];then
              /cache/tools/tar -prPf  $RESTORE/backup.tar /$i 
              LOG="[v] Backup old"; LOGS "$LOG /$i"; UI_PRINT "$LOG $APPXTRA"                    
           else 
               if [ -d /Utmp/$i ];then
               #WE NEED TO BACKUP FILES THAT WILL BE MORPHING EVEN WITH THE BACKUP DISABLED TO BE ABLE TO FIX ERRORS LATER.
                  /cache/tools/tar -prPf  $RESTORE/backup.tar /$i
               fi 
           fi
        elif [ ! -e /$i ] && [ $BACKUP = "yes" ];then
           echo 'delete("/'$i'");'>>$RESTORE/META-INF/com/google/android/updater-script
        fi 
       
        if [ ! -d /$PATHXTRA ];then
           mkdir -p /$PATHXTRA
        fi 

        mv $XTRAS/$i /$i

        LOG="[v] Added new"; LOGS "$LOG /$i"; UI_PRINT "$LOG $APPXTRA"

       
        #FIXING SOME CRITICAL PERMISSIONS FOR THE NEW FILES ADDED
        if [ $PATHXTRA = "system/app" ] || [ $PATHXTRA = "system/framework" ] || [ $PATHXTRA = "system/lib" ];then
           chown 0.0 /$i && chmod 644 /$i 
        elif [ $PATHXTRA = "system/etc/init.d" ] || [ $PATHXTRA = "system/etc" ];then
           chown 0.0 /$i && chmod 755 /$i
        elif [ $PATHXTRA = "system/bin" ];then
           chown 0.2000 /$i && chmod 755 /$i
        fi
     fi  
   done
 fi

else
      LOG="[!] Nothing to do in XTRAS"; LOGS "$LOG"; UI_PRINT "$LOG" 
      CHECK=0
fi


###################    MORPHING    ##################
UI_PRINT " "; LOG="MORPHING >>"; LOGS "$LOG"; UI_PRINT "$LOG"
CHECK2=0
x=1

until [ $x = 0 ]; do
   if [ -d $PATHDATA ];then
       WORK=$PATHDATA 
       SYSTEM="/data/app"
   elif [ ! -d $PATHDATA ] && [ -d $PATHFRAM ];then
       WORK=$PATHFRAM 
       SYSTEM="/system/framework"
   elif [ ! -d $PATHDATA ] && [ ! -d $PATHFRAM ] && [ -d $PATHAPP ]; then
       WORK=$PATHAPP
       SYSTEM="/system/app"
   elif  [ ! -d $PATHDATA ] && [ ! -d $PATHFRAM ] && [ ! -d $PATHAPP ]; then
       x=0
   fi

   if [ $x = 1 ]; then
       for f in $(ls $WORK); do
          if [ -e $SYSTEM/$f ];then            
             if [ `/cache/tools/tar -tPf $RESTORE/backup.tar $SYSTEM/$f | wc -l`  = 0 ]; then
                /cache/tools/tar -prPf  $RESTORE/backup.tar $SYSTEM/$f
             fi
             
             mkdir -p /$APPLY
             f2="`echo $f | cut -d "." -f 1`.zip"
             mv $SYSTEM/$f /$APPLY/$f2


             #FIX -V4 SUFFIXES IN FOLDERS
             if [ $V4MORPHING = "yes" ] && [ -d $WORK/$f/res ];then
                FILES=`/system/xbin/7z l $APPLY/$f2 | awk '{print $6}'`
                cd $WORK/$f/res
                find * -type d | while read i;do 
                   if [ `echo $FILES | grep $i-v4 | wc -l` != 0 ]; then
                      mv $WORK/$f/res/$i $WORK/$f/res/$i-v4 
                   fi   	
                done 
             fi 

             #CYANOGENMOD vs STOCK BASED ROM
             if [ $MULTIPLATTFORM = "yes" ];then  
                cd $WORK/$f
                find * -type f | while read i;do     
                   if [ $CYANO = "yes" ] && [ `basename $i | cut -d "#" -f 1` = "CMOD" ];then
                      mv $WORK/$f/$i $WORK/$f/`dirname $i`/`basename $i | cut -d "#" -f 2` 
                   elif [ $CYANO = "no" ] && [ `basename $i | cut -d "#" -f 1` = "CMOD" ];then      
                      rm $i
                   fi 
                done
             fi


             #MORPH, ZIP & ZIPALIGN            
             if [ $CLEANMORPHING = "yes" ];then
                MORPH=`/system/xbin/7z a -ur0x2y2z2w2 $APPLY/$f2 $WORK/$f/* | grep -o -E "Everything is Ok" | wc -l`
             else
                MORPH=`/system/xbin/7z a $APPLY/$f2 $WORK/$f/* | grep -o -E "Everything is Ok" | wc -l` 
             fi     

             /cache/tools/zipalign -f 4 $APPLY/$f2 $SYSTEM/$f 

             rm -Rf $APPLY $WORK/$f
             chown 0.0 $SYSTEM/$f && chmod 644 $SYSTEM/$f 
                 
                  
             if [ ! -e $SYSTEM/$f ] || [ $MORPH = 0 ]; then
                 /cache/tools/tar -pxPf  $RESTORE/backup.tar $SYSTEM/$f
                 LOG="[X] Error with $f!"; LOGS "$LOG"; UI_PRINT "$LOG"
                 LOG="[<] Restored original $f"; LOGS "$LOG"; UI_PRINT "$LOG"
                 let CHECK2=$CHECK2-1
             else
                 LOGS "[v] $SYSTEM/$f morphed"; UI_PRINT "[v] $f morphed"
                 let CHECK2=$CHECK2+2
             fi
 
          else
             LOG="[!] $f not found, ignoring"; LOGS "$LOG"; UI_PRINT "$LOG"
          fi
       done
       rm -R $WORK 
   fi
done

if [ $CHECK2 -le 0 ];then
     LOG="[!] Nothing to morph"; LOGS "$LOG"; UI_PRINT "$LOG"
fi


 
################ MOD & BACKUP ###################
if [ $CHECK = 1 ] || [ $CHECK2 -ge 1 ]; then   
   #MOD VERSION
   if  [ `cat /cache/tools/MOD.config | grep MOD_VERSION | cut -d "=" -f 2 | wc -w` != 0 ]; then
        LOG="MOD VERSION >>"; LOGS "$LOG"; UI_PRINT " "; UI_PRINT "$LOG"        
        LOG="[>] Setting MOD version..."; LOGS "$LOG"; UI_PRINT "$LOG"
        
        if [ `cat /system/build.prop | grep ro.modversion | wc -l` = 1 ];then
           MODFIX="ro.modversion"
        else
           MODFIX="ro.build.display.id"           
        fi
  
        BUILD=`cat /system/build.prop | grep $MODFIX | cut -d "=" -f 2`                          
        OLDBUILD=`echo "$BUILD" | cut -d "~" -f 1`
        MOD="$OLDBUILD~$MOD"
        
        if [ $BACKUP = "yes" ];then   
           echo 'run_program("/sbin/sed", "-i", "s/'$MODFIX=''$MOD''/''$MODFIX''=''$BUILD''/g'" , "/system/build.prop");'>>$RESTORE/META-INF/com/google/android/updater-script
        fi

        sed -i "s/$MODFIX=$BUILD/$MODFIX=$MOD/g" /system/build.prop 
        LOG="[v] < $MOD >"; LOGS "$LOG in build.prop -> $MODFIX"; UI_PRINT "$LOG"
   else
        LOG="{ MOD VERSION not defined }"; LOGS "$LOG"; UI_PRINT " "; UI_PRINT "$LOG"
   fi
   
   #BUILDING BACKUP
   if [ $BACKUP = "yes" ];then
      if [ $SCREENLOG = "no" ];then
         OUTFD=`ps | grep -v "grep" | grep -o -E "update_binary(.*)" | cut -d " " -f 3`
      fi
      UI_PRINT " "; LOG="BUILDING FLASHABLE BACKUP >>"; LOGS "$LOG"; UI_PRINT "$LOG"

      echo 'delete_recursive("/data/dalvik-cache/");'>>$RESTORE/META-INF/com/google/android/updater-script
      echo 'run_program("/sbin/umount", "/Utmp");'>>$RESTORE/META-INF/com/google/android/updater-script
      echo 'run_program("/sbin/umount", "/system");'>>$RESTORE/META-INF/com/google/android/updater-script
      echo 'run_program("/sbin/umount", "/data");'>>$RESTORE/META-INF/com/google/android/updater-script
      echo 'run_program("/sbin/rm", "-Rf", "/cache/tools");'>>$RESTORE/META-INF/com/google/android/updater-script

      /system/xbin/7z a $SD/UniversalFlasher/Backup_$LOGDATE.zip $RESTORE/*
  
      LOG="[v] Backup done"; LOGS "$LOG in $SD/UniversalFlasher/Backup_$LOGDATE.zip"
      UI_PRINT "$LOG"; UI_PRINT "$SD/UniversalFlasher/Backup_$LOGDATE.zip"
      if [ $LOGENABLED = "yes" ];then
         UI_PRINT " "; UI_PRINT "** Check the log for details"; UI_PRINT "$LOGFILE"
      fi 
   else
      UI_PRINT " "; UI_PRINT "{ BACKUP DISABLED }"
   fi
else
   if [ $SCREENLOG = "no" ];then
      OUTFD=`ps | grep -v "grep" | grep -o -E "update_binary(.*)" | cut -d " " -f 3`
   fi
   LOG="{ Nothing has changed }"; UI_PRINT " "; UI_PRINT "$LOG"
   rm $LOGFILE   
fi



###########################################  CLEANING SYSTEM  ###########################################
LOG="CLEANING CACHE, TEMPORAL FILES & EXIT >>"; UI_PRINT " "; UI_PRINT "$LOG" 
EXITING "1"
