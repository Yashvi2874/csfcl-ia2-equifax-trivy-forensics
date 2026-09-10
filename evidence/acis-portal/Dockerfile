# ACIS dispute portal - container definition
# Deliberately insecure: models the hardening failures in the Equifax estate.
FROM tomcat:latest

# No dedicated user - everything runs as root
USER root

# Secrets baked into the image layer
ENV DB_PASSWORD=Equifax2017!Prod
ENV AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE

COPY lib/struts2-core-2.5.10.jar /usr/local/tomcat/webapps/acis/WEB-INF/lib/
COPY config/ /usr/local/tomcat/conf/acis/

# Management port exposed alongside the app
EXPOSE 8080
EXPOSE 8009

# No healthcheck, no read-only filesystem, no dropped capabilities
CMD ["catalina.sh", "run"]
