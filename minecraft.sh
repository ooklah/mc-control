#!/bin/bash
# /etc/init.d/minecraft
# version 0.2.2 2013-10-16
#	- moved prep checks to mc_checkService
#	- created render function
# version 0.2.1 2013-10-14
# version 0.2.0 2013-09-23

#Settings
MAP=$2

SERVICE=$MAP"_server.jar"
SCREEN=$MAP"_screen"
USER="minecraft"
ME=`whoami`
SERVERPATH="/home/minecraft"
BACKUPSPATH="/home/$USER/backups"
DONOTARCHIVE="*.jar"
DATE=$(date +"%m%d%Y-%H%M")
INVOKE="java -Xmx1512M -Xms512M -jar $SERVICE nogui"
LOGFILE="/home/$USER/log/minecraft_$MAP.log"
USELOGGING=1

if [ -z $MAP ]
then
  echo "Please specify a map after your command"
  echo "Example: minecraft backup <Map>"
  echo "Example: minecraft say|command <Map> \"Text\""
  exit 2
fi


#Execute as $USER
as_user(){
  if [ $ME == $USER ]; then
   bash -c "$1"
  else
   su - $USER -c "$1"
  fi
}

#Because I got tired of writing out the pgrep line for every new method
mc_checkService(){
  if pgrep -u $USER -f $SERVICE > /dev/null
  then
    return 0
  else
    return 1
  fi
}

#Run comments through here, will also log if enabled.
log(){
  echo $1
  if [ $USELOGGING > /dev/null ]
  then
   echo $(date +"%m-%d-%Y %H:%M:%S") " $1" >> $LOGFILE
  fi
}

mc_say(){
  if mc_checkService
  then
    pre_log_len=`wc -l "$SERVERPATH/$MAP/logs/latest.log" | awk '{print $1}'`
    as_user "screen -p 0 -S $SCREEN -X eval 'stuff \"say $1\"\015'"
    sleep .2
    log "Say: ""$1"
    tail -n$[`wc -l "$SERVERPATH/$MAP/logs/latest.log" | awk '{print $1}'`-$pre_log_len] "$SERVERPATH/$MAP/logs/latest.log"
  else
    log "Say: $SERVICE is not running"
  fi
}

mc_command(){
  if mc_checkService
  then
    pre_log_len=`wc -l "$SERVERPATH/$MAP/logs/latest.log" | awk '{print $1}'`
    as_user "screen -p 0 -S $SCREEN -X eval 'stuff \"$1\"\015'"
    sleep .2
    log "Command: ""$1"
    tail -n$[`wc -l "$SERVERPATH/$MAP/logs/latest.log" | awk '{print $1}'`-$pre_log_len] "$SERVERPATH/$MAP/logs/latest.log"
  else
   log  "Command: $SERVICE is not running"
  fi
}

mc_start(){
  if mc_checkService
  then
    log "START: Error! $SERVICE is already running!"
  else
    log "START: $SERVICE Startup initiated."
    cd $SERVERPATH
    as_user "cd $SERVERPATH/$MAP && screen -dmS $SCREEN $INVOKE"
    sleep 5
    if mc_checkService
    then
      log "START: $SERVICE is now running."
    else
      log "START: Error! Could not start $SERVICE."
    fi
  fi
}

mc_stop(){
  if mc_checkService
  then
    log "STOP: $SERVICE Shutdown initiated."
    mc_say "Clocktower Announcement: Server is Shutting down in 60 seconds!"
    sleep 50
    mc_say "Clocktower Announcement: SERVER SHUTTING DOWN IN 10 SECONDS."
    sleep 10
    mc_say "Clocktower Announcement: SHUTTING DOWN!"
    mc_command "save-all"
    sleep 5
    mc_command "stop"
    sleep 5
  else
    log "STOP: $SERVICE was not running"
  fi
  if mc_checkService
  then
    log "STOP: Error! $SERVICE could not be stopped."
  else
    log "STOP: $SERVICE closed gracefully."
  fi
}

mc_estop(){
  if mc_checkService
  then
    log  "E-STOP $SERVICE"
    mc_say "SHUTTING DOWN IN 10 SECONDS"
    sleep 10
    mc_command "save-all"
    sleep 5
    mc_command "stop"
    sleep 5
  fi
}


mc_render(){
  if mc_checkService
  then
    log "Render: Starting Render Process"
    mc_say "World Shutdown for Map Render in 30 Seconds..."
    sleep 30
    mc_command "stop"
    sleep 10
  else
    log "Render: $SERVICE is not Running"
  fi

    log "Render: Map Rendering Starting"
    cd /home/minecraft/overviewer
    overviewer.py --config=$MAP".py"

    log "Render: Generating Metadata"
    overviewer.py --genpoi --config=$MAP".py"

#  if mc_checkService
#  then
#    sleep 10
#    mc_start
#    log "Render: Restarting Map"
#   fi
}


mc_backup(){
   if [ -z $MAP ]
   then
     log "Backup: Please specify a map to backup"
     exit 1
   else
     echo "Backup: World $MAP Beginning"

     if mc_checkService
     then
       mc_say "Clocktower Announcement: World Backup Started..."
       mc_command "save-off"
       mc_command "save-all"
       sleep 5
     fi

     cd $SERVERPATH/$MAP
     SAVE=`ls -d */`
     cd $SERVERPATH
     log "Backup: Beginning Zip Backup"
     log "Backup: Path is ""$BACKUPSPATH/$MAP/$MAP""_""$DATE"
     zip -9 -r $BACKUPSPATH/$MAP/$MAP"_"$DATE $MAP -x $DONOTARCHIVE

     if mc_checkService
     then
       mc_command "save-on"
       mc_say "Clocktower Announcement: World Backup Complete."
     fi

     log "Backup: Zip Finished"
   fi
}


mc_backupSize(){
  SIZE=`du -ch $BACKUPSPATH/$MAP/$MAP"_"$DATE".zip" | grep total`
  log "Info: Backup Zip is $SIZE"
}


mc_serverSize(){
  SIZE=`du -ch $SERVERPATH/$MAP | grep total`
  log "Info: Server folder is $SIZE"
}


mc_tail(){
  tail $SERVERPATH/$MAP/logs/latest.log
}

#Top Message, which server map we are working on.
echo  "Minecraft Server MAP->"$MAP

#Start-Stop here
case "$1" in
  backup);&
  -b)
    mc_backup
    mc_backupSize
    mc_serverSize
    ;;
  render)
   mc_render
   ;;
  tail);&
  -t)
    mc_tail
    ;;
  start)
    mc_start
    ;;
  stop)
    mc_stop
    ;;
  estop)
    mc_estop
    ;;
  reboot)
   log "Reboot: Initiated"
   mc_say "Clocktower Announcement: The server is going to reboot."
   mc_say "=== Server should be back online 30 seconds after stop. ==="
   mc_estop
   sleep 10
   mc_start
   log "Reboot: Finished"
   ;;
  command);&
  -co)
    mc_command "$3"
    ;;
  say)
   mc_say "$3"
   ;;
 *)
  echo "Usage: minecraft {backup|start|stop|reboot|render [Server] say|command [Server] 'command'}"
  exit 1
  ;;

esac

exit 0
