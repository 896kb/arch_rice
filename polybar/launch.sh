killall -q polybar

echo "---" tee -a /tmp/polybar1.log

polybar bar1 >>/tmp/polybar1.log 2>&1 &

echo "Bar launched"