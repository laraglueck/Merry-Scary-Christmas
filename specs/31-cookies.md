# Spec 31: Cookies for Jingles

Owner: Gloria (adds two objects to the living room (Lara) and changes the attic choice;
Lara is tagged in the pull request)

## Why
The good ending says "Leave the photo and cookies", but there were no cookies in the
game. The cookies give the merry ending a second thing to find and tell a little more
about Jingles: he waited every year and nobody came.

## What
- **The cookies:** a plate of cookies (`item_cookies.png`) on the living room table. A
  click (action `take_cookies`, only when the living room is lit and the team is in it,
  only once) puts "Cookies" into the inventory (`Settings.ITEMS`). The plate disappears
  and the note from J. that lay under it opens: "Every Christmas I leave cookies out for
  Santa. Every Christmas nobody comes for them. — J."
- **The good ending** needs the whole photo AND the cookies
  (`AtticRules.choose(attic, choice, has_photo, has_cookies)`). With the photo but no
  cookies the choice stays greyed out and says: "The photo alone feels too little.
  Remember the cookies on the table downstairs?" Locking him in needs no cookies.
- Santa's "Ho ho hint" in the attic also mentions the cookies.
- **Fix found while testing:** playing alone, only the own hero walks in the hall
  (before, two strangers stood next to them: `WalkRules.new_figures(1)`).

## Out of scope
A tin or anything by the fireplace.

## Done when
New tests (red first): taking the cookies (lit, dark, twice), the item order, the ending rule
with and without cookies, the attic screen with photo but no cookies, the cookies and the note
on the living room screen; one figure when playing alone, Santa's attic hint. All tests pass.
