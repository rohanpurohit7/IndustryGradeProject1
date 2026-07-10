FROM tomcat:10.1-jre21-temurin

RUN rm -rf /usr/local/tomcat/webapps/* \
    && groupadd --system appgroup \
    && useradd --system --gid appgroup --home-dir /usr/local/tomcat appuser \
    && chown -R appuser:appgroup /usr/local/tomcat

COPY ABC\ Technologies/target/*.war /usr/local/tomcat/webapps/ROOT.war

USER appuser
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD curl -fsS http://127.0.0.1:8080/ || exit 1

CMD ["catalina.sh", "run"]
