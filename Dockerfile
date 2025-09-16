# ---------- Stage 1: Build ----------
FROM eclipse-temurin:21-jdk AS builder
WORKDIR /build

# Copy source
COPY src /build/src
COPY web /build/webapp

# Tải Jakarta Servlet API 5.x + JSTL 3.0.1 (phù hợp Tomcat 10)
ARG SERVLET_API_VER=5.0.0
ARG JSTL_API_VER=3.0.0
ARG JSTL_IMPL_VER=3.0.1

RUN mkdir -p /build/lib /build/webapp/WEB-INF/lib && \
    curl -fSL "https://repo1.maven.org/maven2/jakarta/servlet/jakarta.servlet-api/${SERVLET_API_VER}/jakarta.servlet-api-${SERVLET_API_VER}.jar" \
      -o /build/lib/jakarta.servlet-api.jar && \
    curl -fSL "https://repo1.maven.org/maven2/jakarta/servlet/jsp/jstl/jakarta.servlet.jsp.jstl-api/${JSTL_API_VER}/jakarta.servlet.jsp.jstl-api-${JSTL_API_VER}.jar" \
      -o /build/webapp/WEB-INF/lib/jakarta.servlet.jsp.jstl-api.jar && \
    curl -fSL "https://repo1.maven.org/maven2/org/glassfish/web/jakarta.servlet.jsp.jstl/${JSTL_IMPL_VER}/jakarta.servlet.jsp.jstl-${JSTL_IMPL_VER}.jar" \
      -o /build/webapp/WEB-INF/lib/jakarta.servlet.jsp.jstl.jar

# Compile Java -> WEB-INF/classes
RUN mkdir -p /build/webapp/WEB-INF/classes && \
    find /build/src -name "*.java" > /tmp/sources.list && \
    if [ -s /tmp/sources.list ]; then \
      javac -encoding UTF-8 -cp /build/lib/jakarta.servlet-api.jar \
            -d /build/webapp/WEB-INF/classes @/tmp/sources.list ; \
    else \
      echo "[WARN] Không tìm thấy file .java để compile. Bỏ qua."; \
    fi

# ---------- Stage 2: Runtime ----------
FROM tomcat:10.1.46-jdk21-temurin

RUN rm -rf /usr/local/tomcat/webapps/ROOT
COPY --from=builder /build/webapp /usr/local/tomcat/webapps/ROOT

EXPOSE 8080
CMD ["catalina.sh", "run"]
