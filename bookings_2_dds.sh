#!/bin/bash
PATH_ETL=/home/user/Netology
PATH_LOGS=/home/user/Netology/log
cd /home/user/Documents/distrib/Pentaho_DI_9.3.0.0-428/
./kitchen.sh -file:$PATH_ETL/bookings_2_dds.kjb -level:Error -logfile:$PATH_LOGS/bookings_2_dds.log
