ARG OPENJDK_VERSION=11
FROM openjdk:${OPENJDK_VERSION}-jre-slim

ARG SPARK_VERSION=3.3.1
ARG SPARK_SHORT=3.3
ARG HADOOP_VERSION=3.3
ARG SCALA=2.12
ARG ICEBERG_VERSION=1.0.0

LABEL org.label-schema.name="Apache Spark ${SPARK_VERSION}" \
      org.label-schema.version=$SPARK_VERSION      
      
ENV SPARK_HOME /usr/spark
ENV PATH="/usr/spark/bin:/usr/spark/sbin:${PATH}"
  
RUN apt-get update && \
    apt-get install -y wget netcat procps libpostgresql-jdbc-java && \
    wget -q "http://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" && \
    tar xzf "spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" && \
    rm "spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" && \
    mv "spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}" /usr/spark && \
    ln -s /usr/share/java/postgresql-jdbc4.jar /usr/spark/jars/postgresql-jdbc4.jar && \
    cd /usr/spark/jars/ && wget  "https://repo.maven.apache.org/maven2/org/apache/iceberg/iceberg-spark-runtime-${SPARK_SHORT}_${SCALA}/${ICEBERG_VERSION}/iceberg-spark-runtime-${SPARK_SHORT}_${SCALA}-${ICEBERG_VERSION}.jar" \
    apt-get remove -y wget && \
    apt-get autoremove -y && \
    apt-get clean

ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

ENTRYPOINT ["/tini", "--", "spark-submit"]
CMD ["--help"]
