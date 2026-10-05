# Changelog 
## Unreleased
### Added
    - 2026-10-04 12:09 new weight logs or modifications to the current day's weight logs are logged in the site log
    - 2026-10-03 19:57 On new account creation, write a logfile with IST timing to /server/pub/hackdiet/log/hdo.log
    - firstnames.txt and lastnames.txt files to generate pseudonyms that users can share with others who then want to be able to view their progress. In the absence of these files, selecting "add a 
      pseudonym" fails.
    - 2026-10-02 14:37 TODO.md
    - 2026-10-02 14:37 
        docker/msmtprc - msmtp config file
        docker/sendmail-msmtp - msmtp (sendmail)  wrapper
### Changed
    - 2026-10-05 11:55 site log for a current-day weight change appends today's comment in quotes, then (Prev) and yesterday's comment in quotes. Yesterday means the previous calendar day, including the last day of the previous month. A blank comment is omitted. Build 15280.
    - 2026-10-05 10:19 site log weight delta includes the calendar gap, such as (2d), when the previous weight is older than yesterday. Build 15279.
    - 2026-10-04 22:29 document title is The Word of Mouth Diet, with an iPhone touch icon and an Android manifest. Build 15278.
    - 2026-10-04 20:34 Dockerfile makes the copied webdoc tree readable, so a restrictive host umask cannot leave CSS and images at mode 600. Build number unchanged.
    - 2026-10-04 19:25 Dockerfile makes the CGI tree readable after copy, so a restrictive host umask cannot leave www-data unable to read HackDiet.pl. Build number unchanged.
    - 2026-10-04 16:59 Fixed the links for the icons on the top of the page, changed the site name. Ready to go live with this. Build 5277.
    - 2026-10-04 14:42 site log weight delta is from the previous logged day, not today's old value. Kilograms show grams. Pounds stay pounds. Build 5276.
    - 2026-10-04 12:10 In Utilities, the build text now is a hyperlink to the github repo
    - 2026-10-04 11:08 Changed the date format for the site log
    - 2026-10-03 16:15 the Fat burn checkbox is now centre-aligned, not left-aligned. Also updated CHANGELOG.md   
    - 2026-10-03 14:45 public account view shows the weight-log comments as text. The owner's log still has the input box. Build 5271.
    - 2026-10-03 03:30 the weight-log column header Flag is now Fat 🔥. The control is still the checkbox and still stores 1. Build 5269.
    - 2026-10-02 17:07 feedback mail uses HDO_MAIL_FROM and HDO_FEEDBACK_RECIPIENT from secrets.env. Build 5262.:
    - 2026-10-02 15:00 fixed a flaw where the password reset system reset the password even if the password reset email was not properly sent. Now, the password is only reset if the mail is properly
      sent.
    - 2026-10-02 14:35 for password reset mails, HDO_MAIL_FROM and HDO_MAIL_DOMAIN are now to be defined in secrets.env. There's a sendmail wrapper that now supplies the EHLO name. Feedback is still 
      TODO.
    - 2026-10-02 12:54 remember-me cookie gains Secure when HDO_SITE_SCHEME is https. Apache PassEnv now forwards that scheme, or mod_cgid would hide it and the flag would never be set. Build 5260.
    - 2026-10-01 19:45 on import of a backup, carry the previous month's last trend into the imported log instead of letting the next month recompute from zero. This is the first real improvement to 
      the code since the passing of John Walker (1949-2024). What a titan you were and thank you forever for open-sourcing your code. Rest in Peace. Also increments the build id by 1 so we're in build 
      5259, after a hiatus in development of about 4 years.
    - 2026-09-30 17:47 docker/entrypoint.sh copies firstnames.txt and lastnames.txt from the image into the Pubname data directory every start so a fresh bind mount gets the lists without a manual copy
### Removed
    - 2026-10-03 03:57 Rung is hidden on the weight-log entry page. The public account view and the month file still have it. Build 5270.
    - 2026-10-02 19:40 the handheld-device checkbox, the small header, and the session flag are gone. A handheld=y URL no longer changes the layout. Build 5268.
    - 2026-10-02 19:22 the Utilities download of a native database zip is gone. The account-close tar into hackdiet-data/Backups remains. Build 5267.
    - 2026-10-02 19:10 the paper-log menu item is gone, and src/hdiet.w, src/hdiet.tex, and src/hdiet.pdf are deleted. Build 5266.
    - 2026-10-02 18:54 the web-badge configure page, Apply handler, and BadgeImage redraws are gone. HackDietBadge.pl is still in the tree. Build 5265.
    - 2026-10-02 18:38 the diet calculator menu item and its handlers are gone. Build 5264.
    - 2026-10-02 18:14 the manual hdo.html, webapp.html, screenshots, and export examples are gone. The centre title is text, and the tagline is gone. Log CSS, JS, and figures stayed. Build 5263.
