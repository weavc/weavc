---
layout: post
title: MongoDb
tags: ['dev', 'web']
icon: server
---

## MongoDB
- No-sql document store
- Stores BSON (Binary json)

### Crud
#### Create
- `db.collection.insertOne()`
- `db.collection.insertMany()`
#### Update
- `db.collection.updateOne(<match on>, <set values>)`
- `db.collection.updateMany(<match on>, <set values>)`
- `db.collection.replaceOne(<match on>, <document>)`
#### Read
- `db.collection.find()<.limit(5)>`
#### Delete
- `db.collection.deleteOne()`
- `db.collection.deleteMany()`

There is also a `db.collection.bulkWrite()` which takes an array of changes i.e. `[{insertOne: { ... }}, {updateOne: { ... }}]`

### Indexing
Indexes are data structures that store a small portion of the collections data in an easy to traverse form.

`_id` is used as the default index.

- Single field indexes
- Compound indexes
  - Can specify 2 or more indexes
  - Data is grouped by 1st index -> nth index
  - i.e. `CustomerId`, `SystemTypeId`, `CompanyTypeId`
  - Can also define a sort order on these
- Multikey indexes
  - Keys against an array
- Text indexes
  - Good for text search & support text search queries
  - A collection can only have one text index
- Wildcard indexes
  - Indexing fields that we don't know or are likely to change

#### Index notes
- You can hide an index instead of deleting it straight away
  - This will stop queries using the index but keep it around so that we can see the impact deleting it will have before actually deleting it
  - `db.restaurants.hideIndex({borough: 1, ratings: 1})` or `db.restaurants.hideIndex("borough_1_ratings_1")`
  - Unhide works in the same way but is `unhideIndex` rather than `hideIndex`
- Indexes should be able to fit in memory
  - Measure index use `db.orders.aggregate([{$indexStats: { }}])`
  - See other indexing stats using `db.collection.stats(<option>)`
  - Includes index sizes etc
  - Another way to see index sizes are: `db.collection.totalIndexSize()`

### WiredTiger
> https://www.mongodb.com/docs/manual/core/wiredtiger/

- MongoDb storage engine since 3.2
- WiredTiger uses document-level concurrency control for write operations. As a result, multiple clients can modify different documents of a collection at the same time.
- MultiVersion Concurrency Control (MVCC). At the start of an operation, WiredTiger provides a point-in-time snapshot of the data to the operation. A snapshot presents a consistent view of the in-memory data.
- Uses a write-ahead log (i.e. [journal](https://www.mongodb.com/docs/manual/core/journaling/)) in combination with checkpoints to ensure data durability.
  - Persists all data modifications between checkpoints
- Responsible for caching data
  - By default, can use a maximum of 0.5*memory-1GB of memory on the in-memory cache. The rest writes to disk 

#### Read Concern/Write Concern/Read Preference

### Replication
- Provide redundancy & high availability
- Should be used in production
- Write to primary database & the primary will replicate this onto the secondary sets
- Provides automatic failover
  - When there is no heartbeat to the primary server there will be a new primary elected
- Can read from a secondary server if specified

### Sharding
> [https://www.mongodb.com/resources/products/capabilities/database-sharding-explained](https://www.mongodb.com/resources/products/capabilities/database-sharding-explained)
> [https://www.mongodb.com/docs/manual/sharding/](https://www.mongodb.com/docs/manual/sharding/)

- Sharding is a method for distributing data across multiple machines.
- Used for horizontal scaling across servers
- Shard keys
  - Single indexed field or compound indexed fields
  - `sh.shardCollection()`

### Aggregation
> [https://www.mongodb.com/docs/manual/reference/aggregation/](https://www.mongodb.com/docs/manual/reference/aggregation/)
- Aggregation pipeline builds up a set of stages that process documents.
- Each stage preforms an operation on the input documents (filter, group, calculate)
- Once the stage has been processed the results are passed to the next stage
- Can return results for groups of documents (i.e. counts, calculations etc)

example:
```
db.orders.aggregate( [

   // Stage 1: Filter pizza order documents by pizza size
   {
      $match: { size: "medium" }
   },

   // Stage 2: Group remaining documents by pizza name and calculate total quantity
   {
      $group: { _id: "$name", totalQuantity: { $sum: "$quantity" } }
   }

] )
```