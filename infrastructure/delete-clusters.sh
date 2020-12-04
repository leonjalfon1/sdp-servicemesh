#!/bin/bash

gcloud container clusters list | grep sdp-mesh- | awk '{print $1}' | while read line ; do gcloud container clusters delete $line --zone europe-west2-c --quiet --async ; done