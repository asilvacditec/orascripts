#!/bin/bash
export x=0
while (( $x < 255 ))
do 
  ping -c 1 "192.168.56."$x 1>/dev/null 2>/dev/null
  if (( $? < 1 ));then 
    echo $x
  fi
  (( x = x + 1 ))
done
