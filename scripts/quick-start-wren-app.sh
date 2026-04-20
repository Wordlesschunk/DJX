#!/bin/bash

applicationDir="${PWD##*/}"
applicationRunName="${applicationDir//-/_}"

cd ../devenvironment/

bin/console run -f group:"$applicationRunName"

cd $application