ARG SPARK_VERSION

FROM ghcr.io/hienduyph/spark:${SPARK_VERSION}

USER root

RUN export AWS_VERSION=1.12.429 ICEBERG_VERSION=1.1.0 \
  && curl -fsSO "https://repo.maven.apache.org/maven2/org/apache/iceberg/iceberg-spark-runtime-${SPARK_SHORT}_${SCALA}/${ICEBERG_VERSION}/iceberg-spark-runtime-${SPARK_SHORT}_${SCALA}-${ICEBERG_VERSION}.jar"

USER spark
