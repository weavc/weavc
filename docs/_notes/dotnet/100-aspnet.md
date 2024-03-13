---
layout: post
title: ASP.NET
tags: ['dev', 'web']
icon: globe
set: dotnet
---

### Minimal Apis
Really great for creating apis for minimal packages. 
```c#
public static void MapTasksEndpoints(this IEndpointRouteBuilder endpoints)
{
    var group = endpoints.MapGroup("/tasks");

    group.MapGet("", Task<Ok<string[]>> (HttpContext context, [FromServices] IServiceProvider sp) =>
    {   
        sp.GetRequiredService<ILogger<...>>().LogInformation("Getting all tasks");

        var result = TypedResults.Ok<string[]>(["task 1", "task 2"]);
        return Task.FromResult(result);
    });

    group.MapPost("{id:int}", async Task<Results<Ok, ValidationProblem>> (
        HttpContext context, 
        [FromRoute] int id, 
        [FromBody] Task task,
        [FromServices] IServiceProvider sp) =>
    {   
        if (!await task.IsValid())
            return Task.FromResult(TypedResults.ValidationProblem(...));

        Results<Ok, ValidationProblem> result = TypedResults.Ok();
        return result;
    }).RequireAuthorization()
    .WithTags("tasks");
}
```

### Microsoft.FeatureManagement

See: [use-feature-flags-dotnet-core](https://learn.microsoft.com/en-us/azure/azure-app-configuration/use-feature-flags-dotnet-core)

```shell
dotnet add package Microsoft.FeatureManagement
dotnet add package Microsoft.FeatureManagement.AspNetCore
```

#### Filter on specific claims
```c#
public class ClaimsTargettingContextAccessor : ITargetingContextAccessor, IFeatureFilterMetadata
{
    private readonly IHttpContextAccessor _httpContextAccessor;
    
    private const string TargetingContextLookup = "HttpContextAccessor.TargetingContext";
    
    private static readonly List<string> ValidGroups = new()
    { 
        "TenantId"
    };

    public ClaimsTargettingContextAccessor(IHttpContextAccessor httpContextAccessor = null)
    {
        _httpContextAccessor = httpContextAccessor;
    }

    public ValueTask<TargetingContext> GetContextAsync()
    {
        // This method checks for cached groups already attached to the HttpContext,
        // If they don't exist then we look for valid claims and adds them to the targetting context.

        if (_httpContextAccessor is null)
            return new ValueTask<TargetingContext>(new TargetingContext());
 
        var httpContext = _httpContextAccessor.HttpContext;
        if (httpContext.Items.TryGetValue(TargetingContextLookup, out object value))
            return new ValueTask<TargetingContext>((TargetingContext)value);

        var groups = httpContext.User.Claims
            .Where(c => ValidGroups.Contains(claim.Type))
            .Select(c => $"{c.Type}:{c.Value}")
            .ToArray();

        TargetingContext targetingContext = new()
        {
            UserId = user.Identity.Name,
            Groups = groups
        };

        httpContext.Items[TargetingContextLookup] = targetingContext;

        return new ValueTask<TargetingContext>(targetingContext);
    }
}
```

```c#
builder.Services.AddFeatureManagement()
                .WithTargeting<ClaimsTargettingContextAccessor>();
```