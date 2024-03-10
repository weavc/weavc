---
layout: post
title: Dotnet
tags: ['dev']
icon: code-slash
---

## Useful Notes
Add all projects to sln:
```shell
dotnet sln add ./**/*.csproj
```

## Enitity Framework:
 
### Setup
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

### Useful Makefile:
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

## Configutation for reusable packages
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

## Custom lifetime validation
Workaround for: [AzureAD/azure-activedirectory-identitymodel-extensions-for-dotnet/issues/92](https://github.com/AzureAD/azure-activedirectory-identitymodel-extensions-for-dotnet/issues/92)

There is currently an issue with the default lifetime validation for a token, where if the token expires after `19/01/2038 12:00:00 AM` it overflows the `int` value causing the `DateTime` recieved by the default `LifetimeValidatier` to be `null`.

The following is a custom `LifetimeValidator` method that can be used in `TokenValidationParameters`. It resolves the issue by wrapping the default `LifetimeValidator` provided in `Microsoft.IdentityModel.Tokens` and using the `ValidTo` property on the Security Token passed to the method if the criteria is met.

```c#
    public bool CustomLifetimeValidator(
        DateTime? notBefore, 
        DateTime? expires, 
        SecurityToken securityToken, 
        TokenValidationParameters validationParameters)
    {
        if (!expires.HasValue && validationParameters.RequireExpirationTime)
        {
            var overflowDate = DateTimeOffset.FromUnixTimeSeconds(int.MaxValue).DateTime;
            if (securityToken is not null && securityToken.ValidTo >= overflowDate)
                expires = securityToken.ValidTo;
        }
        
        // Prevents validation loop
        var newParameters = validationParameters.Clone();
        newParameters.LifetimeValidator = null;
        
        // Use the default validation logic with the new expiry time
        Validators.ValidateLifetime(notBefore, expires, securityToken, newParameters);

        return true;
    }
```

## Helpers

### Add paging to queryable:
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

### Json Http Helpers

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

## Minimal Apis
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


## Github actions publish nuget
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

## Configure a service at runtime in code:
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

## Custom Csv Parser

### Interface:
```c#
public interface ICsvParser
{
    IEnumerable<T> Parse<T>(string csv, CsvMapper<T> mapper, CsvParserConfig config);
}
```

### Attribute:
```c#
[AttributeUsage(AttributeTargets.Property)]
public class CsvParserAttribute(string name) : Attribute
{
    public string Name { get; } = name;
}
```

### Configuration:
```c#
public record CsvParserConfig(
    string[]? Headers = null, 
    string[]? RequiredHeaders = null, 
    char SeperatorCharacter = ',', 
    bool IncludesHeaders = true);
```

### Type mapping:
```c#
public delegate T CsvMapper<out T>(IEnumerable<KeyValuePair<string, string?>> model);

public static class DefaultCsvParserAttributeMapping
{
    public static T DefaultCsvMapper<T>(
        IEnumerable<KeyValuePair<string, string>> model) 
        where T : new()
    {
        var l = model.ToList();

        var result = new T();
        var t = typeof(T);
        var props = t.GetProperties();
        foreach (var prop in props)
        {
            foreach (var attr in prop.GetCustomAttributes(true))
            {
                if (attr is CsvParserAttribute)
                {
                    var key = ((CsvParserAttribute) attr).Name;
                    var value = l.FirstOrDefault(s => s.Key == key).Value;

                    if (prop.PropertyType == typeof(string))
                    {
                        prop.SetValue(result, value?.Trim());
                    }
                    else if (prop.PropertyType == typeof(decimal))
                    {
                        _ = decimal.TryParse(value?.Trim(), out decimal decValue);
                        prop.SetValue(result, decValue);
                    }
                    else if (prop.PropertyType == typeof(double))
                    {
                        _ = double.TryParse(value?.Trim(), out double doubValue);
                        prop.SetValue(result, doubValue);
                    }
                    else if (prop.PropertyType == typeof(int))
                    {
                        _ = int.TryParse(value?.Trim(), out int intValue);
                        prop.SetValue(result, intValue);
                    }
                    else if (prop.PropertyType == typeof(int?))
                    {
                        _ = int.TryParse(value?.Trim(), out int intValue);
                        prop.SetValue(result, intValue);
                    }                    
                }
            }
        }
        return result;
    }
}
```

### Parser:
```c#
public class DefaultCsvParser : ICsvParser
{
    public IEnumerable<T> Parse<T>(string csv, CsvMapper<T> mapper, CsvParserConfig config)
    {
        var lines = csv.Split("\n");
        var headers = config.Headers;
            
        if (config.IncludesHeaders && headers.IsNullOrEmpty())
            yield break;

        for(var i = 0; i < lines.Length; i++)
        {
            var line = lines[i];
            if (string.IsNullOrWhiteSpace(line))
                continue;
                
            var rowData = line.Split(config.SeperatorCharacter).ToArray();
                
            if (config.IncludesHeaders && i == 0 && headers.IsNullOrEmpty())
            {  
                headers = ParseHeaders(rowData, config.RequiredHeaders);
                continue;
            }

            if (headers.IsNullOrEmpty())
                yield break;

            yield return ParseRow(rowData, mapper, headers!);
        }
    }
        
    private T ParseRow<T>(IReadOnlyList<string> csvRow, CsvMapper<T> mapper, string[] headers)
    {
        var rowData = new List<KeyValuePair<string, string?>>();
        foreach(var header in headers)
        {
            int index = Array.IndexOf(headers, header);
            if (index >= csvRow.Count)
            {
                rowData.Add(new KeyValuePair<string, string?>(header, null));
                continue;
            }

            rowData.Add(new KeyValuePair<string, string?>(header, csvRow[index]));
        }

        return mapper(rowData);
    }

    private string[] ParseHeaders(string[]? csvRow, string[]? required)
    {
        if (csvRow == null)
            return [];

        required ??= [];

        var headers = new List<string>();

        foreach (var header in csvRow)
            headers.Add(header.ToLower());

        var missing = new List<string>();
        foreach (var req in required)
        {
            if (!headers.Contains(req.ToLower()))
                missing.Add(req);
        }

        if (missing.Count > 0)
            throw new Exception($"Missing required headers: {string.Join(", ", [.. missing])}");

        return [.. headers];
    }
}
```

## Example Pbkdf2 for password hashing & verification:

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