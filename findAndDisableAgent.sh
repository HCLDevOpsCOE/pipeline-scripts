#!/bin/bash -x

resource_input=$1
echo $resource_input

agentUrl=`curl -k 'https://ec2-52-41-212-49.us-west-2.compute.amazonaws.com:8154/go/api/agents' -H 'Accept: application/vnd.go.cd.v4+json' | jq '._embedded.agents[] | select(.resources[] =='\"$resource_input\"') | (._links.self.href)'| tr -d '"'`
echo $agentUrl

agentDetails=`curl -k $agentUrl -H 'Accept: application/vnd.go.cd.v4+json' | jq '{ "hostname": .hostname, "agent_config_state" : "Disabled" , "resources": ["Disabled'$resource_input'"], "environments" : [ ] }'`
echo $agentDetails > agentdetails.json

curl -k 'https://ec2-52-41-212-49.us-west-2.compute.amazonaws.com:8154/go/api/agents/e6a0ecfe-9536-498c-ba1f-7d9af7edaf3d' -H 'Accept: application/vnd.go.cd.v4+json' -H 'Content-Type: application/json' -X PATCH --data @agentdetails.json
