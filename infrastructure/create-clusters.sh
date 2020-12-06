#!/bin/bash

gcloud compute instance-groups managed list-instances sdp-mesh --zone=europe-west2-c | grep sdp-mesh- | awk '{print $1}' | while read line ; do gcloud container clusters create $line --zone europe-west2-c --network sdp-mesh --subnetwork sdp-mesh --enable-autoscaling --machine-type n1-standard-2 --min-nodes 3 --max-nodes 5 --async --quiet --release-channel regular ; done