#!/bin/bash
# Catch TERM and INT. KILL cannot be caught.
trap 'echo "got TERM, cleaning up"; exit 143' TERM
trap 'echo "got INT"; exit 130' INT
echo "trap.sh pid=$$; try: kill -TERM $$ or kill -KILL $$"
while true; do sleep 1; done
