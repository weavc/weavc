---
layout: post
title: Makefile wrapper for .NET migration commands 
description: 'Makefile wrapper around useful EF & git commands for migrations.'
terms: ['dotnet', 'dev', 'linux']
icon: code-slash
sort_key: 1
---

```Make
MIGRATION_NAME ?= $(shell bash -c 'read -p "Migration name > " migration_name; echo $$migration_name')
PROJECT = <project>/
STARTUP_PROJECT = <project>/
DBCONTEXT = <name>
RESTORE_TO = <branch target>

migration.add:
	dotnet ef migrations add $(MIGRATION_NAME) --project $(PROJECT) --startup-project $(STARTUP_PROJECT)
	
migration.script: 
	dotnet ef migrations script --project $(PROJECT) --startup-project $(STARTUP_PROJECT) --output  $(shell bash -c 'date +%s')_migration.sql --idempotent

migration.restore_snapshot:
	git restore --source $(RESTORE_TO) -- $(PROJECT)/Migrations/$(DBCONTEXT)ModelSnapshot.cs

migration.restore_migrations:
	git restore --source $(RESTORE_TO) -- $(PROJECT)Migrations/

migration.restore:
	make migration.restore_snapshot && migration.restore_migrations
```
