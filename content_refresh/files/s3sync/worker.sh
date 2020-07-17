#!/usr/bin/env bash

rq worker --results-ttl ${RESULTS_TTL:-60} -u ${REDISTOGO_URL} high default low
