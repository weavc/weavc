---
layout: post
title: MongoDb
tags: ['dev', 'web']
icon: server
set: dotnet
---

### Date type mongo

```c#
using MongoDB.Bson.Serialization;
using MongoDB.Bson.Serialization.Attributes;
using MongoDB.Bson.Serialization.Serializers;

class UtcDateSerializer : DateTimeSerializer, IBsonSerializer<DateTime>
{
    public override DateTime Deserialize(BsonDeserializationContext context, BsonDeserializationArgs args)
    {
        var obj = base.Deserialize(context, args);
        return new DateTime(obj.Ticks, DateTimeKind.Utc);
    }

    public override void Serialize(BsonSerializationContext context, BsonSerializationArgs args, DateTime value)
    {
        var utcValue = new DateTime(value.Date.Ticks, DateTimeKind.Utc);
        base.Serialize(context, args, utcValue);
    }
}

record MongoTestDocument(
    [property: BsonId] int Id,
    [property: BsonSerializer(typeof(UtcDateSerializer))] DateTime Date,
    DateTime OtherDate);
```
Usage examples:
```c#
using MongoDB.Driver;

var client = new MongoClient("mongodb://localhost:27017");
var database = client.GetDatabase("testdb");
var collection = database.GetCollection<MongoTestDocument>("mongotestdocuments");
var utcFilter = Builders<MongoTestDocument>.Filter.Eq(s => s.Date, new DateTime(2024, 6, 1, 0, 0, 0, DateTimeKind.Utc));
var localFilter = Builders<MongoTestDocument>.Filter.Eq(s => s.Date, new DateTime(2024, 6, 1, 0, 0, 0, DateTimeKind.Local));

database.DropCollection("mongotestdocuments");
await collection.InsertOneAsync(new MongoTestDocument(1, new DateTime(2024, 6, 1, 11, 0, 0, DateTimeKind.Utc), new DateTime(2024, 6, 1, 11, 0, 0, DateTimeKind.Utc)));
await collection.InsertOneAsync(new MongoTestDocument(2, new DateTime(2024, 6, 1, 11, 0, 0, DateTimeKind.Local), new DateTime(2024, 6, 1, 11, 0, 0, DateTimeKind.Local)));
await collection.InsertOneAsync(new MongoTestDocument(3, new DateTime(2024, 6, 1, 11, 0, 0, DateTimeKind.Unspecified), new DateTime(2024, 6, 1, 11, 0, 0, DateTimeKind.Unspecified)));

// var localDocs = (await collection.FindAsync(localFilter)).ToList();
var localDocs = collection.AsQueryable().Where(d => d.Date == new DateTime(2024, 6, 1, 0, 0, 0, DateTimeKind.Local)).ToList();
var utcDocs = collection.AsQueryable().Where(d => d.Date == new DateTime(2024, 6, 1, 0, 0, 0, DateTimeKind.Utc)).ToList();
// var utcDocs = (await collection.FindAsync(utcFilter)).ToList();

Console.WriteLine("Local:");
foreach (var d in localDocs)
    Console.WriteLine($"Id: {d.Id}, DateKind: {d.Date.Kind}, Date: {d.Date}, OtherKind: {d.OtherDate.Kind}, Other: {d.OtherDate}");

Console.WriteLine("UTC:");
foreach (var d in utcDocs)
    Console.WriteLine($"Id: {d.Id}, DateKind: {d.Date.Kind}, Date: {d.Date}, OtherKind: {d.OtherDate.Kind}, Other: {d.OtherDate}");
```

Output:
```shell
Local:
Id: 1, DateKind: Utc, Date: 01/06/2024 00:00:00, OtherKind: Utc, Other: 01/06/2024 11:00:00
Id: 2, DateKind: Utc, Date: 01/06/2024 00:00:00, OtherKind: Utc, Other: 01/06/2024 10:00:00
Id: 3, DateKind: Utc, Date: 01/06/2024 00:00:00, OtherKind: Utc, Other: 01/06/2024 10:00:00
UTC:
Id: 1, DateKind: Utc, Date: 01/06/2024 00:00:00, OtherKind: Utc, Other: 01/06/2024 11:00:00
Id: 2, DateKind: Utc, Date: 01/06/2024 00:00:00, OtherKind: Utc, Other: 01/06/2024 10:00:00
Id: 3, DateKind: Utc, Date: 01/06/2024 00:00:00, OtherKind: Utc, Other: 01/06/2024 10:00:00
```

Data:
```json
[
  {
    _id: 1,
    Date: ISODate("2024-06-01T00:00:00.000Z"),
    OtherDate: ISODate("2024-06-01T11:00:00.000Z")
  },
  {
    _id: 2,
    Date: ISODate("2024-06-01T00:00:00.000Z"),
    OtherDate: ISODate("2024-06-01T10:00:00.000Z")
  },
  {
    _id: 3,
    Date: ISODate("2024-06-01T00:00:00.000Z"),
    OtherDate: ISODate("2024-06-01T10:00:00.000Z")
  }
]
testdb> db.mongotestdocuments.find()
[
  {
    _id: 1,
    Date: ISODate("2024-06-01T00:00:00.000Z"),
    OtherDate: ISODate("2024-06-01T11:00:00.000Z")
  },
  {
    _id: 2,
    Date: ISODate("2024-06-01T00:00:00.000Z"),
    OtherDate: ISODate("2024-06-01T10:00:00.000Z")
  },
  {
    _id: 3,
    Date: ISODate("2024-06-01T00:00:00.000Z"),
    OtherDate: ISODate("2024-06-01T10:00:00.000Z")
  }
]
```

We can see that the `Date` property is always populated with the day of the datetime and the time set to `00:00:00.000Z` no matter what datekind we pass to mongo. 
