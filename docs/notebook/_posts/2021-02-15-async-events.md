---
layout: md
title: Dotnet Async Events
description: 'Async event service'
categories: ['dotnet', 'dev']
sort_key: 1
---

{% include project-headers.html %}


### AsyncEvent.cs
```c#
/// <summary>
/// Async implementation of an Event
/// </summary>
/// <typeparam name="TArgs">Type of Payload/args emitted by event</typeparam>

public delegate Task AsyncEvent<TArgs>(object sender, TArgs args);
```

### IEventService.cs
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

### IEventHandler.cs
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

### EventServiceBase.cs
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

### OnDisposalEventServiceBase.cs
```c#
/// <summary>
/// An extended implementation of BaseEventService. Certain types of events wont be required to 
/// be emitted to their handlers right away. We can use this implemention to
/// queue the events and emit them on disposal instead of right away.
/// </summary>
/// <typeparam name="TArgs">Type of Payload/args emitted by event</typeparam>
public abstract class OnDisposalEventServiceBase<TArgs> : EventServiceBase<TArgs>, IAsyncDisposable, IEventService<TArgs>
{
    public OnDisposalEventServiceBase(IEnumerable<IEventHandler<TArgs>> events) : base(events)
    {
        this.queue = new List<(object sender, TArgs args)>();
    }

    /// <summary>
    /// Queue of events to be emitted on disposal of service.
    /// </summary>
    protected List<(Object sender, TArgs args)> queue { get; set; } 


    /// <summary>
    /// Add an emit call to the disposal queue
    /// </summary>
    public override Task Emit(Object sender, TArgs args)
    {
        this.queue.Add((sender, args));
        return Task.CompletedTask;
    }

    /// <summary>
    /// Implementation of async disposal method. Triggers each of the events in the queue.
    /// </summary>
    public async ValueTask DisposeAsync()
    {
        foreach(var evt in this.queue)
        {
            await base.Emit(evt.sender, evt.args);
        }

        return;
    }
}
```

## Example Implementation

### LoginEvent.cs
```c#
public class LoginEvent : OnDisposalEventEmitterBase<LoginEventArgs>, IEventService<LoginEventArgs>
{
    public LoginEvent(IEnumerable<IEventHandler<LoginEventArgs>> events) : base(events) { }
}
```

### LoginLogEventHandler.cs
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
