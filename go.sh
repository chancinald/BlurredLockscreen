#! /bin/sh
make package
mv *.deb p
scp p root@192.168.1.134:/
ssh root@192.168.1.134 "dpkg -i /p; rm /p; killall SpringBoard"
rm p
rm *.deb
make clean
clear
