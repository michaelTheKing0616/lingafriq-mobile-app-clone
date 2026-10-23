charter: v2

# Staged rollout

Flags move through 1 percent, 10 percent, 50 percent, and 100 percent. A percent between stages snaps down to the stage it has reached.

Assignment is a stable bucket of the user id and the flag key. The same user stays in or out of a stage.

`enabled: false` is the kill switch. Clients keep a cache for 60 seconds. After that, or when evaluation fails, the feature is off. That is the safe default. The failure is logged.
