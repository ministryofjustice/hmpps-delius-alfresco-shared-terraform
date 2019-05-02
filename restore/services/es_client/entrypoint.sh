#!/bin/sh

echo "Waiting for elasticsearch..."

while ! nc -z elasticsearch 9200; do
  sleep 0.1
done

echo "elasticsearch started"

pytest -v 