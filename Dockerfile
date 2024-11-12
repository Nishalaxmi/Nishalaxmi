
# Stage 1: Build Maven App
FROM maven:3.8.4-openjdk-17-slim AS build
WORKDIR /usr/src/app

# Copy the POM file and download dependencies
COPY pom.xml .
RUN mvn dependency:go-offline

# Copy the application source code
COPY src src

# Build the application
RUN mvn clean install

# Stage 2: Deploy WAR file to Tomcat
FROM tomcat:9-jdk17-openjdk-slim
WORKDIR /usr/local/tomcat/webapps

# Copy the WAR file from the build image to Tomcat
COPY --from=build /usr/src/app/target/thetym-service.war ./

# Copy default applications from webapps.dist to webapps
RUN cp -R /usr/local/tomcat/webapps.dist/* /usr/local/tomcat/webapps/

# Modify context.xml
RUN echo '<?xml version="1.0" encoding="UTF-8"?> \
<Context antiResourceLocking="false" privileged="true" > \
  <CookieProcessor className="org.apache.tomcat.util.http.Rfc6265CookieProcessor" \
                   sameSiteCookies="strict" /> \
  <!--<Valve className="org.apache.catalina.valves.RemoteAddrValve" \
  allow="127\.\d+\.\d+\.\d+|::1|0:0:0:0:0:0:0:1" />--> \
  <Manager sessionAttributeValueClassNameFilter="java\.lang\.(?:Boolean|Integer|Long|Number|String)|org\.apache\.catalina\.filters\.CsrfPreventionFilter\$LruCache(?:\$1)?|java\.util\.(?:Linked)?HashMap"/> \
</Context>' > /usr/local/tomcat/webapps/manager/META-INF/context.xml

# Modify tomcat-users.xml
RUN echo '<?xml version="1.0" encoding="utf-8"?> \
<tomcat-users> \
  <role rolename="admin-gui"/> \
  <role rolename="admin-script"/> \
  <role rolename="manager-gui"/> \
  <role rolename="manager-status"/> \
  <role rolename="manager-script"/> \
  <role rolename="manager-jmx"/> \
  <user name="admin" password="admin" roles="admin-gui,admin-script,manager-gui,manager-status,manager-script,manager-jmx"/> \
</tomcat-users>' > /usr/local/tomcat/conf/tomcat-users.xml

# Expose port 8080 (Tomcat's default port)
EXPOSE 8080

# Start Tomcat
CMD ["catalina.sh", "run"]
