#!/usr/bin/env bash

echo "---------------------------------------------------"
echo "Installing Porter..."
echo "---------------------------------------------------"
curl https://cdn.porter.sh/latest/install-linux.sh | bash

sudo mv ~/.porter/porter /usr/local/bin/porter