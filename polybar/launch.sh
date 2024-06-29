killall -q polybar

echo "---" tee -a /tmp/polybar1.log

for m in $(polybar --list-monitors | cut -d":" -f1); do
    MONITOR=$m polybar --reload bar1 &
done &

echo "Bar launched"