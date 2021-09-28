---
layout: md
title: Oak.TaskScheduler
repo: weavc/Oak.TaskScheduler
description: Dotnet library for creating & hosting a task scheduler
tags: ['dotnet', 'tasks', 'cron', 'scheduler']
sort_key: 1
pinned: true
---

{% include project-headers.html %}

[![Dotnet Build And Test](https://github.com/weavc/Oak.TaskScheduler/actions/workflows/dotnet-build-and-test.yml/badge.svg)](https://github.com/weavc/Oak.TaskScheduler/actions/workflows/dotnet-build-and-test.yml)
[![Dotnet Publish Package](https://github.com/weavc/Oak.TaskScheduler/actions/workflows/dotnet-publish-package.yml/badge.svg?event=release)](https://github.com/weavc/Oak.TaskScheduler/actions/workflows/dotnet-publish-package.yml)

Dotnet library for creating a simple task scheduler. Built with concurrency &amp; dependency injection in mind.

### Usage

Install the package:
```bash
dotnet add package Oak.TaskScheduler
```

Write your scheduled tasks, implementing the `IScheduledTask` interface:
```c#
public class Task1 : IScheduledTask
{
    private readonly ILogger<Task1> logger;

    public Task1(ILogger<Task1> logger)
    {
        this.logger = logger;
    }

    // Configure the occurrence of the task, there are a number of different options, 
    // see the Occurrence section more details.
    public IOccurrence Occurrence => new CronOccurrence("*/1 * * * *");

    // Should the task run on start up or wait for the next occurrence
    public bool RunOnStartUp => false;

    public async Task Run(CancellationToken token = default)
    {
        this.logger.LogInformation($"{this.Name} triggered [{this.guid.ToString()}]");

        // ... do stuff

        return;
    }
}
```

Add & configure your tasks and the scheduler in your startup file: 
```c#
.ConfigureServices((hostContext, services) =>
{
    // register scheduled tasks, these will be consumed by the scheduler
    services.AddTransient<IScheduledTask, Task1>();
    services.AddTransient<IScheduledTask, Task2>();
    services.AddTransient<IScheduledTask, Task3>();

    // Attach the scheduler
    // This will register a number of services with the serviceCollection & add the
    // scheduler class as a Hosted Service
    services.AttachHostedScheduler();
});
```

This was written with `Microsoft.NET.Sdk.Worker` & background service in mind, but can also work in the background of web applications or on the fly aswell.

### Occurrence

We provide a number of different options for configuring the occurrence of your task:
- Cron (`CronOccurrence`)
- Timespans & offsets (`TimespanOccurrence`)
- Every X minutes (`EveryXMinutesOccurrence`)
- Every X hours (`EveryXHoursOccurrence`)
- Every X days (`EveryXDaysOccurrence`)

Cron and Timespan are by far the most configurable, but the others are handy for their simplicity. You can write & implement your own `IOccurrence`, it will just pass you a `DateTime` and expect the `DateTime` of the next scheduled occurrence back. 
