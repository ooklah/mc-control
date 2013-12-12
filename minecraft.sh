#!/bin/bash
# /etc/init.d/minecraft
# version 0.2.1 2013-12-11
# version 0.2.2 2013-10-16
# version 0.2.1 2013-10-14
# version 0.2.0 2013-09-23
#
#Requirements
# screen;
#
#Optional
# minecraft-overviewer

#Settings
MAP=$2

#Edit Variables
USER="minecraft"
USELOGGING=1
RENDER_RESTART=0

#Path Variables
SERVERPATH="/home/$USER"
BACKUPSPATH="$SERVERPATH/backups"
LOGFILE="$SERVERPATH/log/minecraft_$MAP.log"

#Variables
SERVICE=$MAP"_server.jar"
SCREEN=$MAP"_screen"
ME=`whoami`
DONOTARCHIVE="*.jar"
DATE=$(date +"%m%d%Y-%H%M")
INVOKE="java -Xmx1512M -Xms512M -jar $SERVICE nogui"


# Execute as $USER
as_user(){
  if [ $ME == $USER ]; then
   bash -c "$1"
  else
   su - $USER -c "$1"
  fi
}

mc_checkMap(){
  if [ -z $MAP ]
  then
    echo "A server wasn't specified, Please tell me which server to act on"
    echo "ex: minecraft start Homeworld"
    exit 2
  fi
}

# Because I got tired of writing out the pgrep line for every new method
mc_checkService(){
  if pgrep -u $USER -f $SERVICE > /dev/null
  then
    return 0
  else
    return 1
  fi
}


# Run comments through here, will also log if enabled.
log(){
  echo $1
  if [ $USELOGGING > /dev/null ]
  then
   echo $(date +"%m-%d-%Y %H:%M:%S") " $1" >> $LOGFILE
  fi
}


# Send a message to a specific running server.
mc_say(){
  mc_checkMap
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


# Send a minecraft command to a specific running server.
mc_command(){
  mc_checkMap
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


# Starts a server isntance. Checks to make sure it is not running already
mc_start(){
  mc_checkMap
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


# Announces a server stop is coming and warns at 60,10, and 0 second marks.
mc_stop(){
  mc_checkMap
  log "STOP: $SERVICE shutdown initiated."
  if mc_checkService
  then
    mc_say "Server is shutting down in 60 seconds. Please exit in a safe place!"
    sleep 50
    mc_say "Server is shutting down in 10 seconds."
    sleep 10
    mc_say "Server is now shutting down!"
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


# E-stop, stops the server immediately
mc_estop(){
  mc_checkMap
  if mc_checkService
  then
    log  "E-STOP $SERVICE"
    mc_say "Server is Shutting Down Immediately!"
    sleep 5
    mc_command "save-all"
    sleep 5
    mc_command "stop"
    sleep 5
  fi
}


# Render the map using minecraft-overviewer.
# Requires cleanup.
mc_render(){
  mc_checkMap
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

  if [ RENDER_RESTART > /dev/null ]
  then
    sleep 10
    mc_start
    log "Render: Restarting Map"
  fi
}


# Backup a specific world
mc_backup(){
  mc_checkMap
  log "Backup: World $MAP Beginning"

  if mc_checkService
  then
    mc_say "World Backup Started..."
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
    mc_say "World Backup Complete."
  fi

  log "Backup: Zip Finished"
}


# Reboot a specifc server
mc_reboot(){
  mc_checkMap
  log "Reboot Requested"
  mc_say "Server will be rebooting 60 seconds."
  sleep 60
  mc_say "Server is now rebooting."
  mc_estop
  sleep 10
  mc_start
  log "Reboot finished."
}


# Used by mc_backup to get a size of the zip backup it just created.
mc_backupSize(){
  SIZE=`du -ch $BACKUPSPATH/$MAP/$MAP"_"$DATE".zip" | grep total`
  log "Info: Backup Zip is $SIZE"
}


# Get the size of the server folder
mc_serverSize(){
  mc_checkMap
  SIZE=`du -ch $SERVERPATH/$MAP | grep total`
  log "Info: Server folder is $SIZE"
}


# Shows the last few lines of the server log. 
# Works with 1.7 or newer
mc_tail(){
  mc_checkMap
  tail $SERVERPATH/$MAP/logs/latest.log
}

#Top Message, which server map we are working on.
echo  "Minecraft Server MAP -> "$MAP

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
    mc_reboot
    ;;
  command);&
  -co)
    mc_command "$3"
    ;;
  say)
   mc_say "$3"
   ;;
 *)
  echo "Usage: minecraft {backup|start|stop|estop|tail|reboot|render [Server]} {say|command [Server] 'command or dialog'}"
  exit 1
  ;;

esac

exit 0
