#!/bin/bash

applicationDir="${PWD##*/}"
applicationRunName="${applicationDir//-/_}"

cd ../devenvironment/

bin/console purge

cd $application
