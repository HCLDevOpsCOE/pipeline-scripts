#!/bin/bash -x

resource_input=$1
app_port=$2
echo $resource_input

existingApp=`curl http://ec2-54-70-136-53.us-west-2.compute.amazonaws.com/eureka/apps -H "Content-Type:application/json" -H "Accept:application/json" | jq '.applications.application[] | select(.name == '\"$resource_input\"') | "http://ec2-54-70-136-53.us-west-2.compute.amazonaws.com/eureka/apps/"+.name+"/"+.instance[].instanceId+"/status?value=OUT_OF_SERVICE"'`
echo $existingApp


 existAppInstanceId=`curl http://ec2-54-70-136-53.us-west-2.compute.amazonaws.com/eureka/apps/$resource_input -H "Content-Type:application/json" -H "Accept:application/json" | jq '.application.instance[].instanceId'`

#end=$((SECONDS+40))

CONTAINER=$resource_input | tr '[:upper:]' '[:lower:]'

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

docker run --name $CONTAINER -d -P -e 'SPRING_PROFILES_ACTIVE=aws' -p $app_port:$app_port rohitgkk/$CONTAINER

end=$((SECONDS+40))

echo "Pinging green $resource_input app url to check status is UP or not."

while [ $SECONDS -lt $end ]; do

newAppStatus=`curl http://ec2-54-70-136-53.us-west-2.compute.amazonaws.com/eureka/apps/$resource_input -H "Content-Type:application/json" -H "Accept:application/json" | jq '.application.instance[] | select (.instanceId != $existAppInstanceId) | .status'`

if [ "$newAppStatus" = "UP" ]
then
    
    echo "Bringing down blue $resource_input app url"
    curl -X PUT  $existingApp
    sleep 5
    echo "Blue $resource_input app url is OUT_OF_SERVICE"
    exit 0
fi
done



#ls=`curl -k $agentUrl -H 'Accept: application/vnd.go.cd.v4+json' | jq '{ "hostname": .hostname, "agent_config_state" : "Disabled" , "resources": 
#["Disabled'$resource_input'"], "environments" : [ ] }'` 
#echo $agentDetails > agentdetails.json

#curl -k 'https://ec2-52-41-212-49.us-west-2.compute.amazonaws.com:8154/go/api/agents/e6a0ecfe-9536-498c-ba1f-7d9af7edaf3d' -H 'Accept: 
#application/vnd.go.cd.v4+json' -H 'Content-Type: application/json' -X PATCH --data @agentdetails.json

