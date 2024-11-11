ARG SPARK_VERSION=3.5.3
ARG SCALA=2.12
FROM docker.io/apache/spark:${SPARK_VERSION}-scala${SCALA}-java17-r-ubuntu

USER root
RUN apt-get update && \
    apt-get install -y netcat-traditional procps curl && \
    apt-get autoremove -y && \
    apt-get clean

ARG SPARK_VERSION
ARG SCALA

RUN set -ex \
  && export HADOOP_VERSION="$(ls $SPARK_HOME/jars/hadoop-client-runtime*.jar | grep -Eo '[0-9]\.[0-9]\.[0-9]' )" SPARK_SHORT="$(echo ${SPARK_VERSION} | grep -Eo '^[0-9]\.[0-9]')" \
  && cd $SPARK_HOME/jars/ \
  && curl -LO https://repo1.maven.org/maven2/org/apache/spark/spark-avro_${SCALA}/${SPARK_VERSION}/spark-avro_${SCALA}-${SPARK_VERSION}.jar \
  && export AWS_VERSION=1.12.777 ICEBERG_VERSION=1.7.0 \
  && curl -LO https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/${AWS_VERSION}/aws-java-sdk-bundle-${AWS_VERSION}.jar \
  && curl -LO https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/${HADOOP_VERSION}/hadoop-aws-${HADOOP_VERSION}.jar  \
  && curl -LO "https://repo.maven.apache.org/maven2/org/apache/iceberg/iceberg-aws-bundle/${ICEBERG_VERSION}/iceberg-aws-bundle-${ICEBERG_VERSION}.jar" \
  && curl -fsSO "https://repo.maven.apache.org/maven2/org/apache/iceberg/iceberg-spark-runtime-${SPARK_SHORT}_${SCALA}/${ICEBERG_VERSION}/iceberg-spark-runtime-${SPARK_SHORT}_${SCALA}-${ICEBERG_VERSION}.jar"

USER spark
