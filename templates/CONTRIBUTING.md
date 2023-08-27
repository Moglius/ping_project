# Contributing Guidelines

Please read through this document before submitting any pull requests to ensure we have all the necessary information to effectively review your changes.

## Requirements

The following tools need to be installed on your local machine:

### Mandatory

- [Visual Studio Code](https://code.visualstudio.com/)
- [pre-commit](https://pre-commit.com/)
- [pyenv](https://github.com/pyenv/pyenv)
- [pyenv-virtualenv](https://github.com/pyenv/pyenv-virtualenv)
- [tfenv](https://github.com/tfutils/tfenv)
- [tflint](https://github.com/terraform-linters/tflint)
- [terraform-docs](https://github.com/terraform-docs/terraform-docs)
- [checkov](https://github.com/bridgecrewio/checkov)
- [Go](https://go.dev/doc/install)

### Recommended

- [oh-my-zsh](https://ohmyz.sh/)
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
- [spaceship-prompt](https://github.com/spaceship-prompt/spaceship-prompt)

## Local Development Setup

Run these steps before making changes to the code. They will help automate the commands to lint the code or run tests. These steps help to ensure high code quality and reduce the likelihood that the changes inadvertently break something.

### Install Visual Studio Code recommended extensions

Install Visual Studio Code [recommended extensions](https://code.visualstudio.com/docs/editor/extension-marketplace#_recommended-extensions) defined in [.vscode/extensions.json](.vscode/extensions.json) to improve you productivity and increase code quality.

### Install latest terraform version

```shell
tfenv install latest
tfenv use latest
```

### Install Python 3.11

```shell
pyenv install 3.11
```

### Create and activate Python Virtual Environment

```shell
pyenv virtualenv 3.11 aws-lamdba-notifications-venv
pyenv activate aws-lamdba-notifications-venv

python -m pip install --upgrade pip

pip install -r requirements-dev.txt
```

> When necessary, execute `pyenv deactivate` to deactivate the virtual environment.

### Install pre-commit hooks

> This will ensure that the commands we want to execute before each commit are executed automatically.

```shell
pre-commit install
```

### Execute pre-commit hooks manually on all files

```shell
# All hooks
pre-commit run --all-files

# Checkov
pre-commit run checkov --all-files

# Terraform docs
pre-commit run terraform_docs --all-files
```

### Update pre-commit hooks

```shell
pre-commit autoupdate
```

### Execute tests with terratest manually

```shell
cd tests/infrastructure_tests

go mod init github.com/ExxonMobil/awsce-cloudalerts-notification

go mod tidy

go test -timeout 30m -v
```

### Execute tests with tox manually

```shell
# Format checks with isort and black
tox r -e format

# Style checks with flake8
tox r -e style

# Unit tests
tox r -e unittests
tox r -e coverage

# Security scan with Bandit
tox r -e bandit
```
