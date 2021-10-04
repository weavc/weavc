---
layout: post
title: Async Events Services [.NET] 
description: 'Async event service'
terms: ['dotnet', 'dev']
icon: code-slash
sort_key: 1
---

#### AsyncEvent.cs
```c#
/// <summary>
/// Async implementation of an Event
/// </summary>
/// <typeparam name="TArgs">Type of Payload/args emitted by event</typeparam>

public delegate Task AsyncEvent<TArgs>(object sender, TArgs args);
```

#### IEventService.cs
```c#
/// <summary>
/// Used to emit events to handler services
/// </summary>
/// <typeparam name="TArgs">Type of Payload/args emitted by event</typeparam>
public interface IEventService<TArgs>
{
    Task Emit(object sender, TArgs args);
}
```

#### IEventHandler.cs
```c#
/// <summary>
/// Defines an event handler. These should be called by an event service when the event is trigged
/// </summary>
/// <typeparam name="TArgs">Type of Payload/args emitted by event</typeparam>
public interface IEventHandler<TArgs>
{
    Task HandleEvent(Object sender, TArgs args);
}
```

#### EventServiceBase.cs
```c#
/// <summary>
/// Base implementation of an event service
/// </summary>
/// <typeparam name="TArgs">Type of Payload/args emitted by event</typeparam>
public abstract class EventServiceBase<TArgs> : IEventService<TArgs>
{
    protected readonly IEnumerable<IEventHandler<TArgs>> events;

    public EventServiceBase(IEnumerable<IEventHandler<TArgs>> events)
    {
        // Add event handlers from service provider
        foreach (var ev in events)
        {
            this.@event += async (sender, args) => { await ev.Handle(sender, args); };
        }
    }

    protected virtual event AsyncEvent<TArgs> @event;

    /// <summary>
    /// Emit event now and wait for completion
    /// </summary>
    public virtual async Task Emit(Object sender, TArgs args)
    {
        if (this.@event != null)
        {
            await this.@event?.Invoke(sender, args);
        }

        return;
    }
}
```

### Example Implementation

#### LoginEvent.cs
```c#
public class LoginEvent : OnDisposalEventEmitterBase<LoginEventArgs>, IEventService<LoginEventArgs>
{
    public LoginEvent(IEnumerable<IEventHandler<LoginEventArgs>> events) : base(events) { }
}
```

#### LoginLogEventHandler.cs
```c#
public class LoginLogHandler : IEventHandler<LoginEventArgs>
{
    private readonly ILogger<LoginLogHandler> logger;

    public LoginLogHandler(ILogger<LoginLogHandler> logger)
    {
        this.logger = logger;
    }

    public Task HandleEvent(Object sender, LoginEventArgs args)
    {
        // This could log to a database, capture client information or whatever we want to do
        // for now it will just log if the request was successful or not.
        
        if (args.Result.Success)
            this.logger.LogInformation($"Successful login to user {args.Result.Payload.auth.Id}");
        else
            this.logger.LogWarning($"Unsuccessful login to user {args.Result.Payload.auth.Id}");

        return Task.CompletedTask;
    }
}
```
