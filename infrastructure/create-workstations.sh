#!/bin/bash

gcloud compute instance-groups managed resize sdp-mesh --size=$1 --zone=europe-west2-c