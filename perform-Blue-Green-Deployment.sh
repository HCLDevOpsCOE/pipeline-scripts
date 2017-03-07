#!/bin/bash

resource_input=$1
app_port=$2

app_name=`echo $resource_input | tr '[:lower:]' '[:upper:]'`

existingApp=`curl http://ec2-54-70-136-53.us-west-2.compute.amazonaws.com/eureka/apps -H "Content-Type:application/json" -H "Accept:application/json" | jq '.applications.application[] | select(.name == '\"$app_name\"') | "http://ec2-54-70-136-53.us-west-2.compute.amazonaws.com/eureka/apps/"+.name+"/"+.instance[].instanceId+"/status?value=OUT_OF_SERVICE"' | tr -d '\"'`



 existAppInstanceId=`curl http://ec2-54-70-136-53.us-west-2.compute.amazonaws.com/eureka/apps/$app_name -H "Content-Type:application/json" -H "Accept:application/json" | jq '.application.instance[].instanceId' | tr -d '\"'`




CONTAINER=$resource_input

RUNNING=$(docker inspect --format="{{ .State.Running }}" $CONTAINER 2> /dev/null)


if [ $? -eq 1 ]; then
  echo "UNKNOWN - $CONTAINER does not exist."
  docker pull rohitgkk/$CONTAINER
fi

if [ "$RUNNING" == "true" ]; then
  echo "$CONTAINER is running"
  docker stop $CONTAINER
  docker rm $CONTAINER
fi

if [ "$RUNNING" == "false" ]; then
  echo "CRITICAL - $CONTAINER is not running."
  docker rm $CONTAINER
fi

echo "CONTAINER ID of $app_name is below:"
echo `docker run --name $CONTAINER -d -P -e 'SPRING_PROFILES_ACTIVE=aws' -p $app_port:$app_port rohitgkk/$CONTAINER`

sleep 30

end=$((SECONDS+140))

echo "Please Wait!..... Pinging green $app_name app url to check status is UP or not."

while [ $SECONDS -lt $end ]; do

newAppStatus=`curl -s http://ec2-54-70-136-53.us-west-2.compute.amazonaws.com/eureka/apps/$app_name -H "Content-Type:application/json" -H "Accept:application/json" | jq '.application.instance[] | select(.instanceId != '\"$existAppInstanceId\"') | .status' | tr -d '\"'`



if [ "$newAppStatus" == "UP" ]; then
    
    echo "Bringing down blue $app_name app url"
    curl -X PUT $existingApp
    if [ $? -eq 0 ]; then
     sleep 30
     echo "Blue $app_name app url is OUT_OF_SERVICE"
     exit 0
    else
     echo "Error: Unable to make Blue $app_name app url OUT_OF_SERVICE"
     exit 1
    fi
fi
done










