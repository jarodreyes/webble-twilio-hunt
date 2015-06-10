webble-twilio
==============

Scavenger Hunt App that works like so:
- User texts phone number receives instructions.
- User registers a nickname. User is given 0 points.
- User finds webble beacon
- User views beacon photos, sees a hint in photo. 
- User takes picture with the object the hint suggests.
- User texts photo to Twilio number.
- User is awarded points! 
OR
- User is told to try again.

Admin:
- '/players' View list of players. See points and correct/incorrect guesses.
- '/verify' View list of un-verified pictures. Admin can click 'Verify' to award points. Should remove picture from list.
- '/leaderboard' View list of highscores. With name and phone number.


