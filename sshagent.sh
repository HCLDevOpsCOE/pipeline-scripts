#!/bin/bash

#bash -i
eval `ssh-agent -s`
ssh-add ~/Provision_ec2_Docker_goagent/DevOpsPOC.pem
bash -i
