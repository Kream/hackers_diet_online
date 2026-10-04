# Do before Launch
2026-10-03 20:02 implement logging of weightlog updates including Δ
2026-10-02 15:38 implement logging system so weightlog updates, account creation are logged
2026-10-02 15:42 implement Telegram notifications on weight log including Δ. 

# Post-Launch
2026-10-04 11:17 in weightlog addition log include message about NLW / NLW-since Earlier Lowest Weight Date (ELWD) where ELWD is more than 15 days ago.
2026-10-04 11:18 consider logging failed login attempts
2026-10-03 20:08 log and notify streaks in fat burning 
2026-10-03 20:09 log and notify streaks in consecutive days of weight loss
2026-10-02 15:39 restrict account creation to admin user
2026-10-02 15:41 allow Google OAuth authentication for registered users
2026-10-02 18:41 check "Two leftovers are not in this commit. webdoc/hdiet.js still defines loadDietCalcFields(), and nothing calls it." - this is from removing the diet calculator 
2026-10-02 19:00 check "HackDietBadge.pl is still copied into the image, so a direct /cgi-bin/HackDietBadge URL can still answer." - after removing the web badge functionality
2026-10-03 03:26 check "Still unused, and not served as a control: the forgotten-password line that would have appended HDiet_handheld=y, and hdiet_handheld.css in the image." - after removing the handheld device functionality
