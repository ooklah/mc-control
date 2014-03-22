#!/bin/bash
# /etc/init.d/minecraft
#
# Works with minecraft 1.7 or newer
# 1.6.x and lower use different logging methods.
#
#Requirements
# screen;
#
#Optional
# minecraft-overviewer: http://overviewer.org/

#Gets the map name immediately.
MAP=$2

#Edit Variables
USER="minecraft"
USELOGGING=1

#Path Variables
ROOT="/home/$USER"
SERVERPATH="$ROOT/worlds"
WEBROOT="$ROOT/www/minecraft"
BACKUPSPATH="$WEBROOT/$MAP/backups"
LOGROOT="$ROOT/logs"
LOGFILE="$ROOT/logs/minecraft_$MAP.log"
MAPSPATH="$ROOT/maps"

#Variables
SERVICE=$MAP"_server.jar"
SCREEN=$MAP"_screen"
ME=`whoami`
DONOTARCHIVE="*.jar"
DATE=$(date +"%Y%m%d-%H%M")
INVOKE="java -Xmx1512M -Xms512M -jar $SERVICE nogui"


# Execute as $USER
as_user(){
  if [ $ME == $USER ]; then
   bash -c "$1"
  else
   su - $USER -c "$1"
  fi
}

# Check if map variable exists, exit with message otherwise.
mc_checkMap(){
  if [ -z $MAP ]
  then
    echo "A server wasn't specified, Please tell me which server to act on"
    echo "ex: minecraft start Homeworld"
    exit 2
  fi
}

# Check to see if the current given server is already running.
mc_checkService(){
  if pgrep -u $USER -f $SERVICE > /dev/null
  then
    return 0
  else
    return 1
  fi
}


# All commands and dialog passes through here for logging.
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


# Send a command to a specific running server.
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


# Starts a server instance. Checks to make sure it is not running already
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


# Announces a server stop is coming and warns at 60, 10, and 0 second marks.
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
mc_render(){
  mc_checkMap
  if mc_checkService
  then
    mc_say "Rendering the world."
  fi

  log "Render: Map Rendering Starting"
  cd $MAPSPATH
  overviewer.py --config=$MAP".py"

  log "Render: Generating Metadata"
  overviewer.py --genpoi --config=$MAP".py"

  if mc_checkService
  then
    mc_say "Finished rendering the world."
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

  cd $SERVERPATH
  log "Backup: Beginning Zip Backup"
  # -x \*.jar works 
  # instead of -x \$DONOTARCHIVE or -x $DONOTARCHIVE="\*.jar"
  zip -9 -r $BACKUPSPATH/$MAP"_"$DATE $MAP -x \*.jar

  if mc_checkService
  then
    mc_command "save-on"
    mc_say "World Backup Complete."
  fi
  log "Backup: Path is ""$BACKUPSPATH/$MAP""_""$DATE"
  log "Backup: Zip finished."
}


# Restart a specifc server
mc_restart(){
  mc_checkMap
  log "Restart Requested"
  mc_say "Server will be restarting 60 seconds."
  sleep 60
  mc_say "Server is now restarting."
  mc_estop
  sleep 10
  mc_start
  log "Restart finished."
}


# Used by mc_backup to get a size of the zip backup it just created.
mc_backupSize(){
  SIZE=`du -ch $BACKUPSPATH/$MAP"_"$DATE".zip" | grep total`
  log "Info: Backup zip is $SIZE"
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

#Create a new server to run
mc_create(){
  # Check for already created map by the current name
  if [ -d $SERVERPATH/$MAP ]; then
    echo "There is already a $MAP world created."
    exit 3
  fi
  
  # Check if there is a log directory, create it otherwise
  if [ ! -d $LOGROOT ]; then
    mkdir -p $LOGROOT
  fi
  
  # Check for the map render directory
  if [ ! -d $MAPSPATH ]; then
    mkdir -p $MAPSPATH
  fi
  
  # Check if webroot exists, create it otherwise (if possible)
  if [ ! -d $WEBROOT ]; then
    mkdir -p $WEBROOT
  fi
  
  log "Creating New world: $MAP"
  mkdir -p {$SERVERPATH/$MAP,$BACKUPSPATH,$WEBROOT/$MAP/map} 
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
  restart);&
  -r)
    mc_restart
    ;;
  command);&
  -co)
    mc_command "$3"
    ;;
  say)
    mc_say "$3"
    ;;
  create)
    mc_create
    ;;
 *)
  echo "Usage:"
  echo "minecraft {backup|start|stop|estop|restart|tail|render [Server]}"
  echo "minecraft {say|command [Server] 'command'}"
  exit 1
  ;;

esac

exit 0
