# Changelog 
## Unreleased
### Added
    - firstnames.txt and lastnames.txt files to generate pseudonyms that users can share with others who then want to be able to view their progress. In the absence of these files, selecting "add a 
      pseudonym" fails.
    - 2026-10-02 14:37 TODO.md
    - 2026-10-02 14:37 
        docker/msmtprc - msmtp config file
        docker/sendmail-msmtp - msmtp (sendmail)  wrapper
### Changed
    - 2026-10-02 15:00 fixed a flaw where the password reset system reset the password even if the password reset email was not properly sent. Now, the password is only reset if the mail is properly
      sent.
    - 2026-10-02 14:35 for password reset mails, HDO_MAIL_FROM and HDO_MAIL_DOMAIN are now to be defined in secrets.env. There's a sendmail wrapper that now supplies the EHLO name. Feedback is still 
      TODO.
    - 2026-10-02 12:54 UTC remember-me cookie gains Secure when HDO_SITE_SCHEME is https. Apache PassEnv now forwards that scheme, or mod_cgid would hide it and the flag would never be set. Build 5260.
    - 2026-10-01 19:45 on import of a backup, carry the previous month's last trend into the imported log instead of letting the next month recompute from zero. This is the first real improvement to 
      the code since the passing of John Walker (1949-2024). What a titan you were and thank you forever for open-sourcing your code. Rest in Peace. Also increments the build id by 1 so we're in build 
      5259, after a hiatus in development of about 4 years.
    - 2026-09-30 17:47 docker/entrypoint.sh copies firstnames.txt and lastnames.txt from the image into the Pubname data directory every start so a fresh bind mount gets the lists without a manual copy
