#! /usr/bin/env bash

UUID=`uuidgen | awk '{print tolower($0)}'`
echo $UUID

TESTING_TOPIC="livetest-topic-${UUID}"
echo "Test Topic: ${TESTING_TOPIC}"

MESSAGE_INPUT_FILE="${TESTING_TOPIC}-input-messages.txt"

for i in {0..9}
do
  MESSAGE=`uuidgen`
  echo "Message: ${MESSAGE}"
  echo "${MESSAGE}" >> $MESSAGE_INPUT_FILE
done

cat $MESSAGE_INPUT_FILE