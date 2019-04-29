#!/bin/sh

echo "Waiting for postgres..."

while ! nc -z alf_db 5432; do
  sleep 0.1
done

echo "PostgreSQL started"