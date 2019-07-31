#! /usr/bin/env bash

UUID=`uuidgen | awk '{print tolower($0)}'`
echo $UUID

TESTING_TOPIC="livetest-topic-${UUID}"
echo test topic = $TESTING_TOPIC

# Option 2 - Deploy via kafka script - needs to connect through kcluster-kafka-0
kubectl exec -n kafka -ti kcluster-kafka-0 -- bin/kafka-topics.sh --zookeeper localhost:2181 --create --topic $TESTING_TOPIC --partitions 3 --replication-factor 2



# Create messages via perf test producer
# kubectl exec -n kafka -it kafkaclient-0 -- bin/kafka-producer-perf-test.sh --topic $TESTING_TOPIC --num-records 10 --record-size 100 --throughput 1 --producer-props acks=1 bootstrap.servers=kcluster-kafka-brokers:9092 buffer.memory=1000000 batch.size=8196

# Create messages via console producer - lol

kubectl exec -n kafka -ti kafkaclient-0 -- bin/kafka-console-producer.sh --broker-list kcluster-kafka-brokers:9092 --topic $TESTING_TOPIC < test-input.txt

PRODUCER_PID=$!

sleep 10

kill $PRODUCER_PID

# Consume messages from topic
OUTPUT_FILE="consumer-msg.txt"
# kubectl exec -n kafka -ti kafkaclient-0 -- bin/kafka-console-consumer.sh --bootstrap-server kcluster-kafka-bootstrap:9092 --topic $TESTING_TOPIC --from-beginning 2>&1 | tee $OUTPUT_FILE.txt
kubectl exec -n kafka -ti kafkaclient-0 -- bin/kafka-console-consumer.sh --bootstrap-server kcluster-kafka-bootstrap:9092 --topic $TESTING_TOPIC --from-beginning > $OUTPUT_FILE &

CONSUMER_PID=$!

sleep 10

kill $CONSUMER_PID

kubectl exec -n kafka -ti kcluster-kafka-0 -- bin/kafka-topics.sh --zookeeper localhost:2181 --delete --topic $TESTING_TOPIC

NUM_LINES=`wc -l < ${OUTPUT_FILE}`
echo $NUM_LINES

NUM_LINES_MATCH=`grep -w "SSXVNJHPDQDXVCRASTVYBCWVMGNYKRXVZXKGXTSPSJDGYLUEGQFLAQLOCFLJBEPOWFNSOMYARHAOPUFOJHHDXEHXJBHWGSMZJGNL" -c ${OUTPUT_FILE}`
echo $NUM_LINES_MATCH
