#!/bin/bash -x

uuid=$1
resource_input=$2
agentDetails=`curl -k 'https://35.162.119.3:8154/go/api/agents/'$uuid -u 'admin:admin' -H 'Accept: application/vnd.go.cd.v4+json'| jq '{ "hostname": .hostname, "agent_config_state" : "Enabled" , "resources": ['\"$resource_input\"'], "environments" : ["Deploy"] }'`
echo $agentDetails > agentdetailstoUpdate.json

curl -k 'https://35.162.119.3:8154/go/api/agents/'$uuid -u 'admin:admin' -H 'Accept: application/vnd.go.cd.v4+json' -H 'Content-Type: application/json' -X PATCH --data @agentdetailstoUpdate.json
