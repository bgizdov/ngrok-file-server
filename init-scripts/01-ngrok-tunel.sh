#!/bin/sh

if [ -z "$NGROK_AUTH_TOKEN" ]; then
  echo "#############################################"
  echo "#                                           #"
  echo "#                 ERROR                     #"
  echo "#        NGROK_AUTH_TOKEN not set           #" 
  echo "#                                           #"
  echo "#############################################"
  exit 1
fi

echo "#############################################"
echo "#                                           #"
echo "#                 INFO                      #"
echo "#        starting ngrok tunnel              #"
echo "#                                           #"
echo "#############################################"

ngrok config add-authtoken $NGROK_AUTH_TOKEN
ngrok http 80 --log stdout &
