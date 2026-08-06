#!/bin/bash

applicationDir="${PWD##*/}"
applicationRunName="${applicationDir//-/_}"

cd ../devenvironment/

aws sso login --profile DevEnvironment

cd $application
