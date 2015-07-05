#!/bin/sh
while :
do
  echo "turning pin on"
  meshblu-util message -u ff12c403-04c7-4e63-9073-2e3b1f8e4450 -f ./message-on.json ./example-meshblu.json
  sleep 1
  echo "turning pin off"
  meshblu-util message -u ff12c403-04c7-4e63-9073-2e3b1f8e4450 -f ./message-off.json ./example-meshblu.json
  sleep 1
done
