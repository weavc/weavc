---
layout: post
title: Dotnet
sort_key: 1
tags: ['dev']
icon: code-slash
---

### Other notes

{% include notes.html set="dotnet" %}

<hr/>

### Useful Notes

Add all projects to sln:
```shell
dotnet sln add ./**/*.csproj
```

### Configutation for reusable packages

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

### Helpers

#### Add paging to queryable
```c#
public static class PagingExtensions
{
    public static IQueryable<T> Page<T>(this IQueryable<T> queryable, IPage model, PagingOptions options = null)
    {
        options ??= new PagingOptions();

        var values = model.GetValues(options);
        
        return queryable.Skip((values.page - 1) * values.count).Take(values.count);
    }

    public static (int page, int count) GetValues(this IPage model, PagingOptions options)
    {
        var count = model.Count;
        var page = model.Page;

        if (count > options.MaxCount || count <= 0)
            count = options.MaxCount;

        if (page <= 0)
            page = 1;

        return (page, count);
    }
}
```

#### Json Http Helpers

```c#
public class JsonHttpHandler
{
    public async Task<IError> HandleErrorResponse(HttpResponseMessage message)
    {
        string error = "Unknown";
        try
        {
            error = await message.Content.ReadAsStringAsync();
        }
        catch (Exception ex)
        {
            _logger?.LogError(ex.ToString());
        }

        return new CustomError(
            statusCode: (int) message.StatusCode, 
            errorMessage: error,
            errorType: message.StatusCode.ToString());
    }

    public async Task<Result<T>> HandleResponse<T>(HttpResponseMessage message)
    {
        try
        {
            var result = await message.Content.ReadAsStringAsync();
            if (result is null)
                throw new Exception("Error reading response");

            var dataResult = JsonConvert.DeserializeObject<T>(result);

            return Result<T>.Success(dataResult);
        }
        catch (Exception ex)
        {
            _logger?.LogError(ex.ToString());
            return Result<T>.Fail("An error occured reading the response from the remote server");
        }
    }
}
```


### Github actions publish nuget
```yml
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


### Configure a service at runtime in code
```c#
public static class ConfigureServices
{
    public static void CreateStorageService(this IServiceCollection sc)
    {
        // Pass unique variables through here.
        // These can be other services, i.e. an azure storage service rather than a local storage service:
        sc.TryAddTransient<TService>(s => {
            var opts = s.GetRequiredService<IOptions<StorageOptions>>();
            IStorageProvider storageProvider;
            if (opts.DefaultProvider == "azure")
                storageProvider = s.GetRequiredService<IAzureStorageProvider>();
            else
                storageProvider = s.GetRequiredService<IDefaultStorageProvider>();

            return new TService(storageProvider);
        });
    }

    public static void CreateCacheService(this IServiceCollection sc, IEnumerable<ICacheHandlers> cacheHandlers)
    {
        // Or you can consume parameters defined in the startup routine:
        sc.TryAddTransient(s => new TCacheService(cacheHandlers));
    }
}
```

### Example Pbkdf2 for password hashing & verification:

```c#
public class Pbkdf2HashingProvider : IHashingProvider
{
    public const string Algorithm = "Pbkdf2";
    private const int Iterations = 25000;
    private const int SaltBytes = 16;
    private const int PasswordBytes = 32;

    public string Hash(string password)
    {
        byte[] salt = RandomNumberGenerator.GetBytes(SaltBytes);
        var encoded = Encoding.UTF8.GetBytes(password);
        
        var pbkdf2 = new Rfc2898DeriveBytes(encoded, salt, Iterations);
        byte[] hash = pbkdf2.GetBytes(PasswordBytes);

        var hashBytes = new byte[PasswordBytes+SaltBytes];
        Array.Copy(salt, 0, hashBytes, 0, SaltBytes);
        Array.Copy(hash, 0, hashBytes, SaltBytes, PasswordBytes);

        return Convert.ToBase64String(hashBytes);
    }

    public bool Verify(string password, string hash)
    {
        byte[] hashBytes = Convert.FromBase64String(hash);
        byte[] salt = new byte[SaltBytes];
        Array.Copy(hashBytes, 0, salt, 0, PasswordBytes);

        var pbkdf2 = new Rfc2898DeriveBytes(password, salt, Iterations);
        byte[] buffer = pbkdf2.GetBytes(PasswordBytes);

        for (int i=0; i < PasswordBytes; i++)
        {
            if (hashBytes[i+HashBytes] != buffer[i])
            {
                return false;
            }
        }

        return true;
    }
}
```

### Examaple string with extra properties using implict operators and type conversion

```csharp
[TypeConverter(typeof(ServiceBusConnectionTypeConverter))]
public class ServiceBusConnection()
{
    string _connection = string.Empty;

    internal ServiceBusConnection(string connection) : this()
    {
        _connection = connection;
    }

    public static implicit operator ServiceBusConnection(string connection) =>  new ServiceBusConnection(connection);

    public static implicit operator string(ServiceBusConnection connection) => connection.ConnectionString;

    public string ConnectionString => IsNamespace ? FullyQualifiedNamespace : _connection;

    public string FullyQualifiedNamespace { get; init; } = string.Empty;

    public bool IsNamespace => !string.IsNullOrEmpty(FullyQualifiedNamespace);

    public override string ToString() => ConnectionString;
}

internal class ServiceBusConnectionTypeConverter : TypeConverter
{
    public override bool CanConvertFrom(ITypeDescriptorContext? context, Type sourceType)
    {
        if (sourceType == typeof(string))
            return true;

        return base.CanConvertFrom(context, sourceType);
    }

    public override object? ConvertFrom(ITypeDescriptorContext? context, CultureInfo? culture, object value)
    {
        if (value is string)
            return new ServiceBusConnection(value.ToString()!);

        return base.ConvertFrom(context, culture, value);
    }
}

```
