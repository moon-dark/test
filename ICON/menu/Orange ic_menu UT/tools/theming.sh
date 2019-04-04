#!/sbin/sh
#
# Flasheador universal de temas (JRsoft & Intronauta) v. 1.0 

PATHFRAM="/sdcard/UTHEME/system/framework"
PATHAPP="/sdcard/UTHEME/system/app"
APPLY="/sdcard/UTHEME/apply/TMP"
SYSTEM="/system/framework"
RESTORE="/sdcard/UTHEME2/restore"
XTRAS="/sdcard/UTHEME2/XTRAS"
LOGDATE=`date +%d%b%Y-%H%M`
LOGFILE="/sdcard/Universal-Themes/Theme_$LOGDATE.log"
MOD=`cat /cache/tools/MOD`
OUTFD=$(ps | grep -v "grep" | grep -o -E "update_binary(.*)" | cut -d " " -f 3);
CHECK=0
x=1


UI_PRINT()
{
	if [ ${OUTFD} ]; then
		echo "ui_print ${1} " 1>&$OUTFD;
		echo "ui_print " 1>&$OUTFD;
	else
		if [ "${#}" -lt 1 ]; then
			echo " ";
		else
			echo "${1}";
		fi;
	fi;
} 



if [ ! -d /sdcard/Universal-Themes ];then
   mkdir /sdcard/Universal-Themes
fi


date > $LOGFILE

mkdir -p $RESTORE
unzip /cache/tools/restore.zip -d $RESTORE

UI_PRINT " "
UI_PRINT " "
UI_PRINT " "
UI_PRINT "    << Universal Theme Engine >>"
UI_PRINT "       by JRsoft & Intronauta"
UI_PRINT " "
UI_PRINT " "
LOG="[ Themeing $MOD]"
echo $LOG >> $LOGFILE
UI_PRINT "$LOG"


#MOD

until [ $x = 0 ]; do

   if [ -d $PATHFRAM ];then
       WORK=$PATHFRAM 
   elif [ ! -d $PATHFRAM ] && [ -d $PATHAPP ]; then
       WORK=$PATHAPP
       SYSTEM="/system/app"
   elif  [ ! -d $PATHFRAM ] && [ ! -d $PATHAPP ]; then
       x=0
   fi


   if [ $x = 1 ]; then       

       mkdir -p $APPLY

       for f in $(ls $WORK); do
          if [ -e $SYSTEM/$f ];then
             LOG="[!] Applying"
             echo "$LOG $SYSTEM/$f" >> $LOGFILE 
             UI_PRINT "$LOG $f"  
             cp $SYSTEM/$f $RESTORE$SYSTEM/

             mkdir -p /$APPLY
             mv $SYSTEM/$f /$APPLY/
             

                #FIX FOR v4 FOLDERS

                FILES=`/cache/tools/busybox unzip -l $APPLY/$f | awk '{print $4}'`
                cd $WORK/$f/res  

                   for i in $(ls -d *); do
                      if [ $(echo $FILES | grep $i-v4 | wc -l) -ne 0 ]; then
                         mv $WORK/$f/res/$i $WORK/$f/res/$i-v4 
                      fi   
                   done 



                 #CLEAN NON MATCHING FILES

                 cd $WORK/$f     
                 FIX=`find * -type f`

                   for i in $FIX; do
                      FIX2=`echo $FILES | grep $i | wc -l`
                      if [ $FIX2 = 0 ]; then
                         rm $WORK/$f/$i 
                      fi
                   done
                 


                 #ZIP & ZIPALIGN

                 cd $WORK/$f
                 /cache/tools/zip -rv9 $APPLY/$f *
                 /cache/tools/zipalign -f 4 $APPLY/$f $SYSTEM/$f

                 rm -R $APPLY $WORK/$f
                 chown 0.0 $SYSTEM/$f && chmod 644 $SYSTEM/$f
                 
                 
                  
                 if [ -e $SYSTEM/$f ]; then
                    LOG="[v] Successful"
                    echo $LOG >> $LOGFILE
                    UI_PRINT "$LOG"
                 else 
                    mv $RESTORE$SYSTEM/ $SYSTEM/$f
                    LOG= "[X] Something went wrong with $f . Restored original apk"
                    echo $LOG >> $LOGFILE
                    UI_PRINT "$LOG"
                 fi

                 let CHECK=$CHECK+1
 
          else
             LOG="[!] $SYSTEM/$f does not exist, ignoring"
             echo $LOG >> $LOGFILE
             UI_PRINT "$LOG"
          fi

       done

       rm -R $WORK
 
   fi

done


if [ $CHECK = 0 ];then
     LOG="[!] There is nothing to theme"
     echo $LOG >> $LOGFILE
     UI_PRINT "$LOG"
fi



#XTRAS
UI_PRINT " "
LOG="[ XTRAS ]"
echo $LOG >> $LOGFILE
UI_PRINT "$LOG"

if [ -d $XTRAS ];then

 cd $XTRAS
 XT=`find * -type f`

 if [ $(find * -type f | wc -l) -ne 0 ]; then

  for i in $XT; do
           
      PATHXTRA=`dirname $i`
      APPXTRA=`basename $i`     
      
             
      if [ -e /$i ];then
         mkdir -p $RESTORE/$PATHXTRA
         cp $i $RESTORE/$PATHXTRA
         LOG="[v] Backup"
         echo "$LOG /$i original" >> $LOGFILE
         UI_PRINT "$LOG $APPXTRA original"
      else
         echo 'delete("/'$i'");'>>$RESTORE/META-INF/com/google/android/updater-script
      fi

      mv $XTRAS/$i /$i

      LOG="[v] Including new"
      echo "$LOG /$i" >> $LOGFILE
      UI_PRINT "$LOG $APPXTRA"
       

      if [ $PATHXTRA = "system/app/" ] || [ $PATHXTRA = "system/framework/" ];then
         chown 0.0 /$i && chmod 644 /$i 
      elif [ $PATHXTRA = "data/app/" ];then
         chown system.system /$i && chmod 644 /$i 
      elif [ $PATHXTRA = "system/etc/init.d/" ] || [ $PATHXTRA = "system/bin/" ] || [ $PATHXTRA = "system/etc/" ];then
         chown 0.0 /$i && chmod 755 /$i
      elif [ $PATHXTRA = "system/media/" ];then
         chown 0.0 /$i && chmod 644 /$i
      fi

      
      let CHECK=$CHECK+1   
 
  done
 fi

else
      LOG="[!] Nothing to do in Xtras"
      echo $LOG >> $LOGFILE
      UI_PRINT "$LOG" 
fi


 
#BACKUP, BUILD.PROP

if [ $CHECK -ge 1 ]; then

   #MOD
   LOG="[!] Establishing name of build.prop..."
   echo $LOG >> $LOGFILE
   UI_PRINT "$LOG"

   if  [ $(echo $MOD | wc -l) -ne 0 ]; then
        
        if [ $(cat /system/build.prop | grep ro.modversion | wc -l) -eq 1 ];then
           MODFIX="ro.modversion"
        else
           MODFIX="ro.build.display.id"           
        fi
  
        BUILD=`cat /system/build.prop | grep $MODFIX | cut -d "=" -f 2`                          
        OLDBUILD=`echo "$BUILD" | cut -d "~" -f 1`
        MOD="$OLDBUILD~$MOD"
   
        echo 'run_program("/sbin/sed", "-i", "s/'$MODFIX=''$MOD''/''$MODFIX''=''$BUILD''/g'" , "/system/build.prop");'>>$RESTORE/META-INF/com/google/android/updater-script
        sed -i "s/$MODFIX=$BUILD/$MODFIX=$MOD/g" /system/build.prop 

        LOG="[v] < $MOD >"
        echo "$LOG en build.prop -> $MODFIX" >> $LOGFILE
        UI_PRINT "$LOG"

   else
        LOG="[!] There is no theme name defined."
        echo $LOG >> $LOGFILE
        UI_PRINT "$LOG"
   fi
   
   #BACKUP
   UI_PRINT " "
   LOG="[ EMERGENCY BACKUP ]"
   echo $LOG >> $LOGFILE
   UI_PRINT "$LOG"
   cd $RESTORE
   /cache/tools/zip -rv9 /sdcard/Universal-Themes/ThemeBackup_$LOGDATE.zip *
   LOG="[v] Craeted Emergency backup"
   echo  "$LOG en /sdcard/Universal-Themes/ThemeBackup_$LOGDATE.zip" >> $LOGFILE
   UI_PRINT "$LOG"

   
   rm -R /data/dalvik-cache

else
   LOG="[!] Nothing has changed"
   echo $LOG >> $LOGFILE
   UI_PRINT "$LOG"
fi


#CLEAN
rm -R /cache/tools /sdcard/UTHEME*
UI_PRINT " "
LOG="[ TEMPORARY FILE REMOVED ]"
echo $LOG >> $LOGFILE
UI_PRINT "$LOG"
