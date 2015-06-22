#!/bin/sh
while :
do
  echo "turning pin on"
  meshblu-util message -u b9944342-b8c7-4ca6-9d3e-074eb470626 -f ./message-on.json ./example-meshblu.json
  sleep 1
  echo "turning pin off"
  meshblu-util message -u b9944342-b8c7-4ca6-9d3e-074eb470626 -f ./message-off.json ./example-meshblu.json
  sleep 1
done
