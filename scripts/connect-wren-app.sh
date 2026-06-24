  #!/bin/bash

applicationDir="${PWD##*/}"
applicationRunName="${applicationDir//-/_}"

cd ../devenvironment/

bin/console attach service:"${applicationRunName}_httpd"
