#!/bin/bash
#repo init -u git@zidoo.3322.org:promethean/rk/platform/manifest -b master --repo-url git@zidoo.3322.org:promethean/rk/tools/repo
cd /opt/zidoo-x6-pro
result=1
while [ $result -ge 1 ]; do 
  .repo/repo/repo sync
  result=$?
done

echo "Repo sync appears to have been completed successfully."	
