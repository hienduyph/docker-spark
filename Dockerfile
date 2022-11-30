ARG OPENJDK_VERSION=11
FROM docker.io/openjdk:${OPENJDK_VERSION}-jre-slim

ARG SPARK_VERSION=3.3.1
ARG SPARK_SHORT=3.3
ARG HADOOP_VERSION=3
ARG SCALA=2.12
ARG ICEBERG_VERSION=1.0.0
ARG SPARK_MIRROR=https://dlcdn.apache.org/spark

LABEL org.label-schema.name="Apache Spark ${SPARK_VERSION}" \
      org.label-schema.version=$SPARK_VERSION      
      
ENV SPARK_HOME /opt/spark
ENV PATH="${SPARK_HOME}/bin:${SPARK_HOME}/sbin:${PATH}"
  
RUN apt-get update && \
    apt-get install -y netcat procps curl && \
    apt-get autoremove -y && \
    apt-get clean

USER root

WORKDIR $SPARK_HOME
RUN curl -fsSL "${SPARK_MIRROR}/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" | tar xz --no-same-owner --strip-components=1 -C $SPARK_HOME

RUN cd $SPARK_HOME/jars/\
  && curl -fsSO "https://repo.maven.apache.org/maven2/org/apache/iceberg/iceberg-spark-runtime-${SPARK_SHORT}_${SCALA}/${ICEBERG_VERSION}/iceberg-spark-runtime-${SPARK_SHORT}_${SCALA}-${ICEBERG_VERSION}.jar"

ARG TINI_VERSION=v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

ENTRYPOINT ["/tini", "--", "spark-submit"]
CMD ["--help"]
