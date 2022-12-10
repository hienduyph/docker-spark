ARG OPENJDK_VERSION=11
FROM docker.io/openjdk:${OPENJDK_VERSION}-jre-slim

RUN apt-get update && \
    apt-get install -y netcat procps curl && \
    apt-get autoremove -y && \
    apt-get clean

ARG TINI_VERSION=v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

ENV SPARK_HOME /opt/spark
ENV PATH="${SPARK_HOME}/bin:${SPARK_HOME}/sbin:${PATH}"
  
ARG SPARK_VERSION=3.3.1
ARG SPARK_SHORT=3.3
ARG HADOOP_MAJOR=3
ARG SCALA=2.12
ARG HADOOP_VERSION=3.3.4
ARG SPARK_MIRROR=https://dlcdn.apache.org

WORKDIR $SPARK_HOME
RUN curl -fsSL "${SPARK_MIRROR}/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_MAJOR}.tgz" | tar xz --no-same-owner --strip-components=1 -C $SPARK_HOME

RUN cd $SPARK_HOME/jars/\
  && curl -LO https://repo1.maven.org/maven2/org/apache/spark/spark-avro_${SCALA}/${SPARK_VERSION}/spark-avro_${SCALA}-${SPARK_VERSION}.jar 

ARG ICEBERG_VERSION=1.1.0
RUN cd $SPARK_HOME/jars/\
  && curl -fsSO "https://repo.maven.apache.org/maven2/org/apache/iceberg/iceberg-spark-runtime-${SPARK_SHORT}_${SCALA}/${ICEBERG_VERSION}/iceberg-spark-runtime-${SPARK_SHORT}_${SCALA}-${ICEBERG_VERSION}.jar" \
  && curl -LO https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.352/aws-java-sdk-bundle-1.12.352.jar  \
  && curl -LO https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/${HADOOP_VERSION}/hadoop-aws-${HADOOP_VERSION}.jar

ENV HIVE_HOME /opt/hive
ARG HIVE_VERSION=3.1.3
WORKDIR $HIVE_HOME
RUN  curl -fsSL ${SPARK_MIRROR}/hive/hive-${HIVE_VERSION}/apache-hive-${HIVE_VERSION}-bin.tar.gz | tar xz --no-same-owner --strip-components=1 -C $HIVE_HOME


ARG SPARK_IMAGE_TAG=latest
ENV SPARK_IMAGE_TAG=${SPARK_IMAGE_TAG}

COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN groupadd -r spark --gid=1000 && \
    useradd -r -g spark --uid=1000 -d ${SPARK_HOME} spark && \
    chown spark:spark -R ${SPARK_HOME}

WORKDIR $SPARK_HOME
USER spark

ENTRYPOINT ["/tini", "--", "/entrypoint.sh"]
CMD ["driver"]
