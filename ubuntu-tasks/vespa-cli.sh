wget https://github.com/vespa-engine/vespa/releases/download/v8.538.52/vespa-cli_8.538.52_linux_amd64.tar.gz
tar -xzf vespa-cli_8.538.52_linux_amd64.tar.gz
sudo mv vespa-cli_8.538.52_linux_amd64/bin/vespa /usr/local/bin/vespa
sudo mkdir -p /usr/local/share/man/man1
sudo cp vespa-cli_8.538.52_linux_amd64/share/man/man1/* /usr/local/share/man/man1/
