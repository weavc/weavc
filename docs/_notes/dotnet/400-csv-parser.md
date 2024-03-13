---
layout: post
title: Custom CSV Parser
tags: ['dev']
icon: file-earmark-spreadsheet
set: dotnet
---

### Custom Csv Parser

#### Interface:
```c#
public interface ICsvParser
{
    IEnumerable<T> Parse<T>(string csv, CsvMapper<T> mapper, CsvParserConfig config);
}
```

#### Attribute:
```c#
[AttributeUsage(AttributeTargets.Property)]
public class CsvParserAttribute(string name) : Attribute
{
    public string Name { get; } = name;
}
```

#### Configuration:
```c#
public record CsvParserConfig(
    string[]? Headers = null, 
    string[]? RequiredHeaders = null, 
    char SeperatorCharacter = ',', 
    bool IncludesHeaders = true);
```


#### Type mapping:
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


#### Parser:
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
