#!/bin/bash -x

resource_input=$1
echo $resource_input

agentUrl=`curl -k 'https://35.162.119.3:8154/go/api/agents' -u 'admin:admin' -H 'Accept: application/vnd.go.cd.v4+json' | jq '._embedded.agents[] | select(.resources[] =='\"$resource_input\"') | (._links.self.href)'| tr -d '"'`
echo $agentUrl

agentDetails=`curl -k $agentUrl -H 'Accept: application/vnd.go.cd.v4+json' | jq '{ "hostname": .hostname, "agent_config_state" : "Disabled" , "resources": ["Disabled'$resource_input'"], "environments" : [ ] }'`
echo $agentDetails > agentdetails.json

curl -k $agentUrl -H 'Accept: application/vnd.go.cd.v4+json' -H 'Content-Type: application/json' -X PATCH --data @agentdetails.json
