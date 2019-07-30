#! /usr/bin/env bash

UUID=`uuidgen | awk '{print tolower($0)}'`
echo $UUID