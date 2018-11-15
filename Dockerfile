#This is an "infected" container. This Dockerfile will be pulled and built by PAZUZU.
#After installing it, it will remain waiting. (It really doesn't infect anything, it's just a Debian image).
FROM 	debian:stretch-slim
CMD 	tail -f /dev/null