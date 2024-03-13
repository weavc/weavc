---
layout: post
title: Entity Framework
tags: ['dev', 'database']
icon: server
set: dotnet
---

### Enitity Framework
 
#### Setup
```shell
dotnet add package Microsoft.EntityFrameworkCore --version=8.0.2
dotnet add package Microsoft.EntityFrameworkCore.SqlServer --version=8.0.2
```

```c#
public class AppDbContext(DbContextOptions<UserDbContext> options) : DbContext(options)
{
    public DbSet<User> Users { get; set; }
}

// usage:
builder.Services.AddDbContext<AppDbContext>(options => {
    options.UseSqlServer("Server=localhost,1483;Database=users;User=sa;Password=<password>;TrustServerCertificate=True;");
});
```

#### Migrations Makefile

```shell
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