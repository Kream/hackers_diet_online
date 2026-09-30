# Changelog 
## Unreleased
### Added
	- firstnames.txt and lastnames.txt files to generate pseudonyms that users can share with others who then want to be able to view their progress. In the absence of these files, selecting "add a pseudonym" fails. The files have to be copied to hackdiet-data/Pubname/ and chowned to www-data:www-data 
### Changed
    - 2026-09-30 17:47 docker/entrypoint.sh copies firstnames.txt and lastnames.txt from the image into the Pubname data directory every start so a fresh bind mount gets the lists without a manual copy
