### Do before Launch
2026-10-02 18:06 allow pseudonym view to see comments
2026-10-03 03:52 centre align the checkbox in the Fat burning field
2026-10-02 15:38 implement logging system so weightlog updates, account creation and password reset attempts are logged
2026-10-02 15:42 implement Telegram notifications on weight log including Δ. 

###Post-Launch
2026-10-02 15:39 restrict account creation to admin user
2026-10-02 15:41 allow Google OAuth authentication for registered users
2026-10-02 18:41 check "Two leftovers are not in this commit. webdoc/hdiet.js still defines loadDietCalcFields(), and nothing calls it." - this is from removing the diet calculator 
2026-10-02 19:00 check "HackDietBadge.pl is still copied into the image, so a direct /cgi-bin/HackDietBadge URL can still answer." - after removing the web badge functionality
2026-10-03 03:26 check "Still unused, and not served as a control: the forgotten-password line that would have appended HDiet_handheld=y, and hdiet_handheld.css in the image."
