FROM docker.io/eclipse-temurin:11-jre

ENV SPARK_HOME /opt/spark
ENV PATH="${SPARK_HOME}/bin:${SPARK_HOME}/sbin:${PATH}"

RUN userdel ubuntu || true && groupadd  hive --gid=1000 && \
    useradd -g hive --uid=1000 -d ${SPARK_HOME} hive -m && \
    chown hive:hive -R ${SPARK_HOME}

RUN apt-get update && \
    apt-get install -y netcat-traditional procps curl && \
    apt-get autoremove -y && \
    apt-get clean

ARG TINI_VERSION=v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

  
ARG SPARK_VERSION
# must match with hadoop in spark
ARG HADOOP_VERSION=3.4.0
ARG SCALA=2.12
ENV SPARK_VERSION=${SPARK_VERSION:-3.5.2}
ENV SCALA_VERSION=${SCALA}
ENV ICEBERG_VERSION=1.6.1

WORKDIR $SPARK_HOME
RUN set -ex \
  && export HADOOP_MAJOR="$(echo ${HADOOP_VERSION} | grep -Eo '^[0-9]' )" SPARK_SHORT="$(echo ${SPARK_VERSION} | grep -Eo '^[0-9]\.[0-9]')" \
  && curl -fsSL "https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-without-hadoop.tgz" | tar xz --no-same-owner --strip-components=1 -C $SPARK_HOME \
  && mkdir -p $SPARK_HOME/jars/ && cd $SPARK_HOME/jars/ \
  && curl -LO https://repo1.maven.org/maven2/org/apache/spark/spark-avro_${SCALA}/${SPARK_VERSION}/spark-avro_${SCALA}-${SPARK_VERSION}.jar \
  && export AWS_VERSION=2.28.1 \
  && curl -Lo awssdk-bundle-${AWS_VERSION}.jar https://repo1.maven.org/maven2/software/amazon/awssdk/bundle/${AWS_VERSION}/bundle-${AWS_VERSION}.jar \
  && curl -LO https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/${HADOOP_VERSION}/hadoop-aws-${HADOOP_VERSION}.jar  \
  && curl -LO "https://repo.maven.apache.org/maven2/org/apache/iceberg/iceberg-aws-bundle/${ICEBERG_VERSION}/iceberg-aws-bundle-${ICEBERG_VERSION}.jar" \
  && curl -fsSO "https://repo.maven.apache.org/maven2/org/apache/iceberg/iceberg-spark-runtime-${SPARK_SHORT}_${SCALA}/${ICEBERG_VERSION}/iceberg-spark-runtime-${SPARK_SHORT}_${SCALA}-${ICEBERG_VERSION}.jar"

ENV HIVE_HOME /opt/hive
ENV HIVE_VERSION=4.0.0
RUN export HIVE_MIRROR=https://dlcdn.apache.org && mkdir -p ${HIVE_HOME} \
  && curl -fsSL ${HIVE_MIRROR}/hive/hive-${HIVE_VERSION}/apache-hive-${HIVE_VERSION}-bin.tar.gz | tar xz --no-same-owner --strip-components=1 -C $HIVE_HOME

ENV HADOOP_HOME=/opt/hadoop
RUN mkdir -p ${HADOOP_HOME} && export HADOOP_MIRROR=https://dlcdn.apache.org/ \
  && curl -fsSL ${HADOOP_MIRROR}/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz | tar xz -C ${HADOOP_HOME} --strip-components=1


ENV SPARK_IMAGE_TAG=${SPARK_VERSION}

COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR $SPARK_HOME
USER spark

ENTRYPOINT ["/tini", "--", "/entrypoint.sh"]
CMD ["driver"]
