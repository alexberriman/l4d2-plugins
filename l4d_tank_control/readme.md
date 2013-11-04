Changes:

- Will reset the tank queue on new game (useful in pugs when games are often played one after the other)
- Fix issue with players becoming tank multiple times (got rid of team a/b tracking, uses one array for tank pool)
- Admin command to scramble the tank (!tankshuffle)
- Admin command to force give the tank to someone (!givetank arti)
- Works on finales with multiple tanks (new player is queued on tank death)