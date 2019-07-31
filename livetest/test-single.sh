#! /usr/bin/env bash

UUID=`uuidgen | awk '{print tolower($0)}'`
echo $UUID

TESTING_TOPIC="topic-${UUID}"
echo "Test Topic: ${TESTING_TOPIC}"

# Option 2 - Deploy via kafka script - needs to connect through kcluster-kafka-0
kubectl exec -n kafka -ti kcluster-kafka-0 -- bin/kafka-topics.sh --zookeeper localhost:2181 --create --topic $TESTING_TOPIC --partitions 3 --replication-factor 2



# Create messages via perf test producer
# kubectl exec -n kafka -it kafkaclient-0 -- bin/kafka-producer-perf-test.sh --topic $TESTING_TOPIC --num-records 10 --record-size 100 --throughput 1 --producer-props acks=1 bootstrap.servers=kcluster-kafka-brokers:9092 buffer.memory=1000000 batch.size=8196

# TODO: Create input file from generated UUIDs and use those as messages. Capture in a list. Will compare conents at end.

MESSAGE_INPUT_FILE="./temp/${TESTING_TOPIC}-input-messages.txt"

echo "Creating Input Message file."
for i in {0..9}
do
  MESSAGE=`uuidgen`
  # echo "Message: ${MESSAGE}"
  echo "${MESSAGE}" >> $MESSAGE_INPUT_FILE
done

cat $MESSAGE_INPUT_FILE

# Create messages via console producer
kubectl exec -n kafka -ti kafkaclient-0 -- bin/kafka-console-producer.sh --broker-list kcluster-kafka-brokers:9092 --topic $TESTING_TOPIC < $MESSAGE_INPUT_FILE

# Consume messages from topic
MESSAGE_OUTPUT_FILE="./temp/${TESTING_TOPIC}-output-messages.txt"
# TODO: Figure out how to swallow message "Unable to use a TTY - input is not a terminal or the right kind of file"
# kubectl exec -n kafka -ti kafkaclient-0 -- bin/kafka-console-consumer.sh --bootstrap-server kcluster-kafka-bootstrap:9092 --topic $TESTING_TOPIC --from-beginning 2>&1 | tee $MESSAGE_INPUT_FILE.txt
kubectl exec -n kafka -ti kafkaclient-0 -- bin/kafka-console-consumer.sh --bootstrap-server kcluster-kafka-bootstrap:9092 --topic $TESTING_TOPIC --from-beginning > $MESSAGE_OUTPUT_FILE &

CONSUMER_PID=$!
sleep 10
kill $CONSUMER_PID

# Delete test topic
kubectl exec -n kafka -ti kcluster-kafka-0 -- bin/kafka-topics.sh --zookeeper localhost:2181 --delete --topic $TESTING_TOPIC

# Compare contents of input and output
SORTED_INPUT="./temp/sorted-input.txt"
SORTED_OUTPUT="./temp/sorted-output.txt"
sort $MESSAGE_INPUT_FILE > $SORTED_INPUT
sort $MESSAGE_OUTPUT_FILE > $SORTED_OUTPUT

DIFF=`diff ${SORTED_INPUT} ${SORTED_OUTPUT}`
if [ "$DIFF" != "" ] 
then
    echo "Test Failed!!! - There's a difference between input and output!!!"
    exit 1
fi

echo "Test Passed!!! - All input messages are in the output!"
exit 0
