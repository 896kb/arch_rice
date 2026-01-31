killall -q polybar

# Ensure fonts are loaded before starting polybar
fc-cache -f

echo "---" tee -a /tmp/polybar1.log

polybar bar1 >>/tmp/polybar1.log 2>&1 &

echo "Bar launched"