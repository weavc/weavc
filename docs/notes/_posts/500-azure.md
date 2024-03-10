---
layout: post
title: Azure
tags: ['cloud', 'devops', 'dev']
icon: cloud
---

## Functions
### `local.settings.json`
```json
{
  "IsEncrypted": false,
  "Values": {
    "FUNCTIONS_WORKER_RUNTIME": "dotnet-isolated",
    "AzureWebJobs.FileScan.Disabled": false,
    "AzureWebJobs.FileAnalysis.Disabled": false,
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "Azure:FileAnalysisMq": "asset-analysis",
    "Azure:FileScanMq": "asset-scan",
    "VirusTotal:ApiKey": "f1447d364dfc3776b959377906515e80501530de9370da47d6958cbaaee75113",
    "SGW5D:ApiKey": "VkVyN0NHRWg1NEc0andndk5IODI4RkFiQUtqTjdGNTVBN2ZpYXhnVnlUUXdMQ01hdENyUHZ3TDNBclFWWjJQdA==",
    "SGW5D:BaseUrl": "http://localhost:57912/",
    "Cloudmersive:ApiKey": "bc19e243-3eea-4272-89a0-c7b36384397d"
  }
}
```
### `host.json`
```json
{
    "version": "2.0",
    "logging": {
        "applicationInsights": {
            "samplingSettings": {
                "isEnabled": true,
                "excludedTypes": "Request"
            }
        }
    }
}
```
### `Program.cs`
```c#
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Microsoft.Extensions.Hosting;

var host = new HostBuilder()
    .ConfigureAppConfiguration(c =>
    {
        c.AddJsonFile("./appsettings.local.json", true, false);
    })
    .ConfigureFunctionsWorkerDefaults()
    .ConfigureServices((context, sc) =>
    {
        sc.TryAddTransient<ITService, TService>();
    })
    .Build();

host.Run();
```
### csproj
```c#
<Project Sdk="Microsoft.NET.Sdk">
    <PropertyGroup>
        <TargetFramework>net6.0</TargetFramework>
        <AzureFunctionsVersion>V4</AzureFunctionsVersion>
        <OutputType>Exe</OutputType>
        <ImplicitUsings>enable</ImplicitUsings>
        <Nullable>disable</Nullable>
        <RootNamespace>Weavc</RootNamespace>
    </PropertyGroup>
    <ItemGroup>
        <PackageReference Include="Microsoft.Azure.Functions.Worker" Version="1.8.0" />
        <PackageReference Include="Microsoft.Azure.Functions.Worker.Extensions.Http" Version="3.0.13" />
        <PackageReference Include="Microsoft.Azure.Functions.Worker.Extensions.Storage" Version="5.0.1" />
        <PackageReference Include="Microsoft.Azure.Functions.Worker.Extensions.Timer" Version="4.1.0" />
        <PackageReference Include="Microsoft.Azure.Functions.Worker.Sdk" Version="1.7.0" />
    </ItemGroup>
    <ItemGroup>
        <None Update="host.json">
            <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
        </None>
        <None Update="local.settings.json">
            <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
            <CopyToPublishDirectory>Never</CopyToPublishDirectory>
        </None>
    </ItemGroup>
    <ItemGroup>
        <Using Include="System.Threading.ExecutionContext" Alias="ExecutionContext" />
    </ItemGroup>
    <ItemGroup>
      <Content Update="appsettings.Development.json">
        <ExcludeFromSingleFile>true</ExcludeFromSingleFile>
        <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
        <CopyToPublishDirectory>PreserveNewest</CopyToPublishDirectory>
      </Content>
    </ItemGroup>
</Project>
```

### Function Examples
```c#
public class HttpFunctions
{
    private readonly TService _service;

    public HttpFunctions(TService service)
    {
        _service = service;
    }
 
    [Function("<TriggerName>")]
    public async Task<HttpResponseData> RunAnalysis(
        [HttpTrigger(AuthorizationLevel.Function, "get", "post")] 
        HttpRequestData req,
        FunctionContext executionContext)
    {
        await Service.Run(new MyInfo(), executionContext);
        
        var response = req.CreateResponse(HttpStatusCode.OK);
        response.Headers.Add("Content-Type", "text/plain; charset=utf-8");
        await response.WriteStringAsync($"Successfully ran analysis");

        return response;
    }

    [Function("<TriggerName>")]
    public async Task Run([TimerTrigger("0 */1 * * * *")] MyInfo myTimer, FunctionContext context)
    {
        if (_fileScan is null)
            return;
        
        _logger?.LogInformation($"FileAnalysis function executed at: {DateTime.Now}");
        _logger?.LogInformation($"Next timer schedule at: {myTimer.ScheduleStatus?.Next}");

        var cancellationToken = new CancellationTokenSource();
        
        for (var i = 0; i < _processCount; i++)
        {
            var result = await _service.Run(context, cancellationToken.Token);
            if (result.IsFail())
            {
                if (result.Error.GetType() == typeof(NotFoundError))
                    return;
                
                _logger?.LogError(result.Message);
            }
        }
    }
}
```
