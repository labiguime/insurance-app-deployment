#!/bin/sh

echo `docker exec "$(docker ps -aq)" sh -c "service cron start"`
echo "Cron service restarted!"
