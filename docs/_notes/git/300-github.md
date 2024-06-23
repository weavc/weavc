---
layout: post
title: Github
tags: ['dev', 'devops', 'git']
icon: github
---

### Actions

#### Dotnet build and push container
```yaml
name: Docker CI - Identity

on:
  workflow_dispatch:
  push:
    paths: 
     - services/identity
    branches: 
      - master

jobs:

  build:

    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v2
      with:
        submodules: recursive
        token: ${{ secrets.PAT }}

    - name: Build the Docker image
      run: docker build . --file .docker/Dockerfile.Identity --tag registry.digitalocean.com/checkout-dev/identity:latest
      
    - name: DigitalOcean Login
      run: docker login -u ${{ secrets.DO_API_TOKEN }} -p ${{ secrets.DO_API_TOKEN }} registry.digitalocean.com
      
    - name: Push docker image
      run: docker push registry.digitalocean.com/checkout-dev/identity
```

#### Go build and test
```yaml
name: Go build and test

on:
  push:
    branches: [ master ]
  pull_request:

jobs:

  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2

    - name: Set up Go
      uses: actions/setup-go@v2
      with:
        go-version: 1.17

    - name: Build
      run: go build -v ./...

    - name: Test
      run: go test -v ./...

```

#### Python poetry build and test
```yaml
name: Python package

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]

jobs:
  build:

    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        python-version: ["3.11"]

    steps:
    - uses: actions/checkout@v3
    - name: Set up Python ${{ matrix.python-version }}
      uses: actions/setup-python@v3
      with:
        python-version: ${{ matrix.python-version }}
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        python -m pip install poetry
        python -m poetry config virtualenvs.create false
        poetry install --no-interaction --no-ansi --with dev
    - name: Lint with flake8
      run: |
        # stop the build if there are Python syntax errors or undefined names
        flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics
        # exit-zero treats all errors as warnings. The GitHub editor is 127 chars wide
        flake8 . --count --exit-zero --max-complexity=10 --max-line-length=127 --statistics
    - name: Test with pytest
      run: |
        pytest test
```

#### Python poetry publish
```yaml
name: Upload Python Package

on:
  release:
    types: [published]

permissions:
  contents: read

jobs:
  deploy:

    runs-on: ubuntu-latest
    environment: release
    permissions:      
      id-token: write

    steps:
    - uses: actions/checkout@v3
    - name: Set up Python
      uses: actions/setup-python@v3
      with:
        python-version: '3.11'
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        python -m pip install poetry
        python -m poetry config virtualenvs.create false
        python -m poetry install --no-interaction --no-ansi --with dev
    - name: Build package
      run: python -m poetry build
    - name: Publish package
      uses: pypa/gh-action-pypi-publish@2f6f737ca5f74c637829c0f5c3acd0e29ea5e8bf
```
