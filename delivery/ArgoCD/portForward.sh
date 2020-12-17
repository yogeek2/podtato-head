#!/bin/sh

kubectl port-forward service/podtatohead-podtatohead -n podtatoargocd 9090:9000