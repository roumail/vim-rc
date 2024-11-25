# Setup Vim

Requirements:
* vim-plug
* Docker
* Vim installation on mac OS x


## Host Machine Setup
Before running the Docker container, ensure that the following directories are 
present on your host machine:

`~/.vim/autoload`: This directory must contain the plug.vim file, which is the 
core script for vim-plug. Install it with:

```bash
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
```
`~/.vim/plugged`: This directory is where vim-plug installs plugins. It will 
be populated after running :PlugInstall in Vim.

## Launching Vim
Use the provided `launch_script.sh` to start the containerized Vim environment:

```bash
#!/usr/bin/env bash
# launch_vim.sh

docker run --rm -it \
  -v $(pwd)/.vim:/root/.vim \
  -v ~/.vim/autoload:/root/.vim/autoload \
  -v ~/.vim/plugged:/root/.vim/plugged \
  -v $(pwd)/.vimrc:/root/.vimrc \
  custom-vim
```
This script:

Mounts your `.vimrc` and modular configuration files in the `.vim` directory 
into the container. Ensures autoload and plugged directories are available in 
the container for plugin management.

## Notes for Windows Users
This setup has been tested on macOS only. If you are using Windows:

Replace paths in the `launch_script` with appropriate Windows paths.

Ensure Docker's volume mounting is correctly configured for Windows file paths.
Example modification for Windows (PowerShell):

```powershell
docker run --rm -it `
  -v "${PWD}\.vim:/root/.vim" `
  -v "$HOME\.vim\autoload:/root/.vim/autoload" `
  -v "$HOME\.vim\plugged:/root/.vim/plugged" `
  -v "${PWD}\.vimrc:/root/.vimrc" `
  custom-vim
```

## Testing Plugin Installation
To verify that plugins are installed and configured correctly:

Launch Vim in the container:
```bash
./launch_script.sh
```
Run :PlugStatus to check the status of installed plugins.
If plugins are missing, run :PlugInstall to install them.
