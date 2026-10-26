#!/bin/sh

# The system cron daemon requires root to manage its spool/pid files, which
# conflicts with running the container rootless, so this is a small
# replacement scheduler that runs ampache_cron.sh on the hour at :30
# (matching the schedule this previously ran via `crontab -u www-data`).
# logrotate is also run on every tick; it only actually rotates once a day
# has passed, tracked in its own state file.
while true; do
    MIN=$(date +%-M)
    SEC=$(date +%-S)
    if [ "$MIN" -lt 30 ]; then
        SLEEP=$(( (30 - MIN) * 60 - SEC ))
    else
        SLEEP=$(( (90 - MIN) * 60 - SEC ))
    fi
    [ "$SLEEP" -lt 1 ] && SLEEP=1
    sleep "$SLEEP"
    /usr/local/bin/ampache_cron.sh
    logrotate --state /var/log/ampache/.logrotate.status /etc/logrotate.d/ampache
done
