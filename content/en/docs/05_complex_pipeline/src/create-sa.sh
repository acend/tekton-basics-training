#!/bin/bash

for i in {20..40..1}
do
    sed "s/\$USER/user$i/g" sa.yaml | oc apply -f - -n user$i
done