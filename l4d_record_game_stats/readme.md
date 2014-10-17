#L4D2 Record Game Stats
An improvement on the l4dlogger.

## Aim
The plugin should collect tonnes of data and store it in a central repository. The web frontend should tell the story of the match. It should be able to tell team stories (i.e. team A's story, or team B's story), individual player stories, entire match summary. 

### Key features:
- Time based
- Percentage based

### Notes:
- Flow percentage should represent their total progression through the map, and not current progression. Would get confusing it teams start running back.
- Should send data either every (x) seconds or on half round end.
- Try to send in compressed json format
- If can only send via SQL, store documents in temporary table and let server process and archive them.

## Todo:
- Send data to server
- Log data
- React to events (each event needs to store against it a time and flow percentage):
    - Tank killed
        - Damage done by each survivor
    - Tank spawned
    - Tank wiped
    - Witch killed
        - Damage done by each survivor
    - Witch crown failed (incapped by witch)
        - Damage done by each survivor
    - Player death
        - Killed by
    - SI death
        - Killed by
    - Player incapped
        - Incapped by
    - Hunter skeeted
        - Skeeted by
    - Charger levelled
        - Levelled by
            - Headshot level?
    - Boomer popped
        - Popped by
        - Popped in (x seconds)
    - Incapped by car
    - Tank rock lands
        - Landed on
    - Tank punches survivor
        - Survivor punched
    - Tank incap survivor
        - Survivor incapped
    - Tank kills survivor
        - Survivor incapped
    - Survivor hunted
        - Hunted by
    - Survivor charged
        - Charged by
    - Survivor jockeyed
        - Jockeyed by
    - Survivor boomed
        - Boomed by