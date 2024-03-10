---
layout: post
title: Publishing to Nuget with Github Actions  
tags: ['dotnet', 'nuget', 'ci/cd']
terms: ['dotnet', 'dev']
icon: code-slash
---
{% raw %}
```yaml
name: Dotnet Publish Package

on:
  release:
    types:
      - created

jobs:
  build:

    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v2
    - name: Branch name
      id: branch_name
      run: |
        echo ::set-output name=SOURCE_NAME::${GITHUB_REF#refs/*/}
        echo ::set-output name=SOURCE_BRANCH::${GITHUB_REF#refs/heads/}
        echo ::set-output name=SOURCE_TAG::${GITHUB_REF#refs/tags/}
    - name: Setup .NET
      uses: actions/setup-dotnet@v1
      with:
        dotnet-version: 5.0.x
    - name: Restore dependencies
      run: dotnet restore ./src/Oak.TaskScheduler/Oak.TaskScheduler.csproj
    - name: Build
      run: dotnet build --no-restore --configuration=Release /property:Version=${{ steps.branch_name.outputs.SOURCE_TAG }} ./src/Oak.TaskScheduler/Oak.TaskScheduler.csproj
    - name: Test
      run: dotnet test test/ --verbosity normal
    - name: Pack
      run: dotnet pack ./src/Oak.TaskScheduler/Oak.TaskScheduler.csproj /property:Version=${{ steps.branch_name.outputs.SOURCE_TAG }} --configuration=Release
    - name: Publish
      run: |
	  	dotnet nuget push src/Oak.TaskScheduler/bin/Release/Oak.TaskScheduler.${{ steps.branch_name.outputs.SOURCE_TAG }}.nupkg \ 
		--api-key ${{ secrets.NUGET_API_KEY }} --source https://api.nuget.org/v3/index.json
```
{% endraw %}