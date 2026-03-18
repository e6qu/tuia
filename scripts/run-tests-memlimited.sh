#!/bin/bash
# Run a command with a memory limit enforced by monitoring.
# Usage: ./scripts/run-tests-memlimited.sh [max_mb] [command...]
# Default: 1024 MB (1 GiB), command = zig build test

MAX_MB=${1:-1024}
shift 2>/dev/null
CMD="${@:-zig build test}"

echo "Running: $CMD"
echo "Memory limit: ${MAX_MB}MB"
echo "---"

# Start the command in background
$CMD &
CMD_PID=$!

PEAK_MB=0

# Monitor memory usage of the process and all descendants
while kill -0 $CMD_PID 2>/dev/null; do
    # On macOS, get RSS of all child processes (in bytes via ps -o rss=)
    # ps -o rss= gives KB on macOS
    TOTAL_KB=0
    while IFS= read -r line; do
        kb=$(echo "$line" | awk '{print $1}')
        TOTAL_KB=$((TOTAL_KB + kb))
    done < <(pgrep -P $CMD_PID 2>/dev/null | xargs -I{} ps -o rss= -p {} 2>/dev/null; ps -o rss= -p $CMD_PID 2>/dev/null)

    # Also get grandchildren
    for child in $(pgrep -P $CMD_PID 2>/dev/null); do
        for gchild in $(pgrep -P $child 2>/dev/null); do
            kb=$(ps -o rss= -p $gchild 2>/dev/null | awk '{print $1}')
            TOTAL_KB=$((TOTAL_KB + ${kb:-0}))
        done
    done

    TOTAL_MB=$((TOTAL_KB / 1024))
    if [ "$TOTAL_MB" -gt "$PEAK_MB" ] 2>/dev/null; then
        PEAK_MB=$TOTAL_MB
    fi

    if [ "$TOTAL_MB" -gt "$MAX_MB" ] 2>/dev/null; then
        echo ""
        echo "!!! MEMORY LIMIT EXCEEDED: ${TOTAL_MB}MB > ${MAX_MB}MB"
        echo "!!! Killing process tree..."
        # Kill all descendants first
        pkill -P $CMD_PID 2>/dev/null
        for child in $(pgrep -P $CMD_PID 2>/dev/null); do
            pkill -P $child 2>/dev/null
            kill $child 2>/dev/null
        done
        kill $CMD_PID 2>/dev/null
        sleep 1
        kill -9 $CMD_PID 2>/dev/null
        echo "Peak memory: ${PEAK_MB}MB"
        exit 137
    fi

    sleep 0.5
done

# Collect exit status
wait $CMD_PID
EXIT=$?

echo "---"
if [ $EXIT -eq 0 ]; then
    echo "SUCCESS (peak ${PEAK_MB}MB)"
else
    echo "FAILED with exit code $EXIT (peak ${PEAK_MB}MB)"
fi
exit $EXIT
