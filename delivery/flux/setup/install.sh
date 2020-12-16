#!/usr/bin/env bash

echo "---------------------------------------------------"
echo "Installing Flux CLI..."
echo "---------------------------------------------------"
curl -s https://toolkit.fluxcd.io/install.sh | sudo bash
flux --version

echo
echo "---------------------------------------------------"
echo "Checking cluster..."
echo "---------------------------------------------------"
flux check --pre

echo
echo "---------------------------------------------------"
echo "Install Flux..."
echo "---------------------------------------------------"
