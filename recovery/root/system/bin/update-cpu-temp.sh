#!/system/bin/sh
while true; do
    cat /sys/class/thermal/thermal_zone20/temp > /tmp/cpu_temp 2>/dev/null
    sleep 2
done
