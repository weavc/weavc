---
layout: post
title: Nice ways to build and configure .NET dependency injection containers
description: 'Handy DI notes for .NET'
terms: ['dotnet', 'dev']
icon: code-slash
sort_key: 1
---

```c#
public static IServiceCollection AddStorage(this IServiceCollection sc, Action<StorageOptions> configure)
{
    // Initialse & populate StorageOptions so that we are able to use
    // them to setup our storage services.
    var options = new StorageOptions();
    configure.Invoke(options);

    // Add IOptions<StorageOptions> to the DI container.  
    sc.Configure(configure);

    // Add our storage providers based on whats enabled in settings
    if (options.Local.Enabled)
        sc.AddScoped<IStorageProvider, LocalStorageProvider>();
    if (options.Azure.Enabled)
        sc.AddScoped<IStorageProvider, AzureStorageProvider>();
    if (options.DigitalOcean.Enabled)
        sc.AddScoped<IStorageProvider, DigitalOceanStorageProvider>();

    // Use LocalStorageProvider as default fallback
    // TryAdd will only add the service if there is no other implementation already added
    sc.TryAddScoped<IStorageProvider>(sp => new LocalStorageProvider(StorageOptions.LoacalStorageDefaults()));

    sc.TryAddScoped<IStorageService>(sp => 
    {
        // We can build our implemention of IStorageService here

        // We can get other services from the scoped DI container
        var services = sp.GetServices<IStorageProvider>();
        var logger = sp.GetRequiredService<ILogger<IStorageService>>();

        // Use the options to configure services
        var @default = services.FirstOrDefault(s => s.GetType().Name == options.Default);
        if (@default is null)
            throw new NotImplementedException($"StorageProvider {options.Default} is not configured.");

        // Or to return a different implementation
        if (options.UseV2Service)
            return new StorageServiceV2(@default, services, options, logger);

        return new StorageService(@default, services, options, logger);
    });

    return sc;
}
```

### Usage in `Program.cs`

Binding to configuration i.e. `appsettings.json`:
```c#
builder.Services.AddStorage(configure => builder.Configuration.GetSection("storage").Bind(configure));
```

Configuring in code:
```c#
builder.Services.AddStorage(configure =>
{
    configure.Default = nameof(AzureStorageProvider);
    configure.UseV2Service = false;
    configure.Azure = new AzureStorageOptions
    {
        Enabled = true,
        Container = "Assets",
        ConectionString = "<private stuff>"
    };
});
```


