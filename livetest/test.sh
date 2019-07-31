#! /usr/bin/env bash

UUID=`uuidgen | awk '{print tolower($0)}'`
echo $UUID

TESTING_TOPIC="livetest-topic-${UUID}"
echo $TESTING_TOPIC
# Option 1 - Deploy via CRD
# kubectl apply -n kafka -f kafka-topics.yaml

# Option 2 - Deploy via kafka script - needs to connect through kcluster-kafka-0
kubectl exec -n kafka -ti kcluster-kafka-0 -- bin/kafka-topics.sh --zookeeper localhost:2181 --create --topic $TESTING_TOPIC --partitions 3 --replication-factor 2

# Create Consumer to topic
kubectl exec -n kafka -ti kafkaclient-0 -- bin/kafka-console-consumer.sh --bootstrap-server kcluster-kafka-bootstrap:9092 --topic $TESTING_TOPIC
# Consumer that consumes from beginning of topic
kubectl exec -n kafka -ti kafkaclient-0 -- bin/kafka-console-consumer.sh --bootstrap-server kcluster-kafka-bootstrap:9092 --topic $TESTING_TOPIC --from-beginning

# Create Publisher to topic
kubectl exec -n kafka -ti kafkaclient-0 -- bin/kafka-console-producer.sh --broker-list kcluster-kafka-brokers:9092 --topic $TESTING_TOPIC

# Delete Topic after Test runs
kubectl exec -n kafka -ti kcluster-kafka-0 -- bin/kafka-topics.sh --zookeeper localhost:2181 --delete --topic $TESTING_TOPIC
# or
# kubectl delete -n kafka -f kafka-topics.yaml