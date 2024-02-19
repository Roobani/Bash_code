#!/bin/bash
wget -q --post-data 'master_pwd=7o5@dC!4$FKXYmLVojVb&name=Demo' https://demo.sodexis.com/web/database/drop > /dev/null
sleep 10
curl -s -F 'master_pwd=7o5@dC!4$FKXYmLVojVb' -F 'backup_file=@/opt/support_files/dump/Demo_2018-01-30_15-46-31.zip' -F 'copy=true' -F 'name=Demo' https://demo.sodexis.com/web/database/restore > /dev/null
