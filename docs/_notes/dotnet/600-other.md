---
layout: post
title: Other
tags: ['dev', 'web']
icon: bookmark
set: dotnet
---

### Reference types
- class, interface, record, delegate, object, dynamic, string
- These are references to data rather than stores of the actual values
- You can have multiple variables linked to the same reference type
  - i.e. passing them inbetween methods

### Value types
- bool, char, enum, numbers, struct, tuple
- These store the actual values of the object directly
- Value types are copied when set to other variables
  - i.e. passing them into a method
  - To get around this we can use `in`, `ref`, `out` keywords 
- `ref` pass value type by reference allowing operations to be performed on the variable, modifying the value in the executing method & the caller
  - `ref`s are limited in application, they cant be used in async methods, cant be a element in a array, can't be declared as a field, cant implement interfaces and so on. This is due to them being allocated on the stack and can't escape the managed heap.
- `in` passes a readonly reference to a value type (contravariance)
- `out` expects the reference to be set or modified in the method, they don't have to be initialized then passed (covariance)

### Record
- Reference type with shallow immutability & value type equality checks
- Records follow this struct definition while also being a reference type, they are equal when they are the same type & contain the same values
- Provides built in functionality for encapsulation. 
  - Automatically generates a constructor out of the public properties
  - `required` keyword
- Can be a `record class` reference type (default) or `record struct` value type 
- Properties are immutable in a `record` / `record class`
- `readonly` can also be added to a `record struct` to make it immutable
- You can define a `record` like this `record Person(string FirstName, string LastName);`
  - This will auto implement the properties for each parameter in the declaration
  - `record` and `readonly record struct` types the implement these as `init;`  properties
  - `record struct` will be implemented with `set;` properties. These will also be generated with a parameter-less constructor that will set the values to their default values.
  - [todo] A `Deconstruct` method with an out parameter for each positional parameter will also be added
  - You can add a target to an attribute when defining the record `[property: JsonPropertyName("apple")]`
  - Can also just declare any additional properties within the body
- `with` keyword can be used to copy a record with changes i.e. `Person person2 = person1 with { FirstName = "John" };`
- Improved printing capabilities, will auto generate a `PrintMembers` method and also override `ToString()`

### Class
- Reference type
- Classes are only equal if both are the same object reference in memory
- Classes can only be public or internal (default) unless nested inside another class where all the access modifiers are valid

### Struct
- Value type
- Structs are equal if both are the same type and both store the same values
- Copied on assignment (including: passing as an argument, returning from a method)
- `ref struct` and `readonly ref struct` exist too
- Used for small data-centric types that provide little to no behaviour.
- In `readonly` stucts any fields or properties must also be `readonly` (properties can also be `init` only)
- `with` keyword can be used to create copies of structs with different data `var p2 = p1 with { X = 3 };`

### Interface
- An layer of abstraction between the implementation and the consumer
- Useful for testing as we can use libraries like `moq` to create mock objects that implement the interface
- Can have multiple implementations under the same interface allowing them to be swapped for one another depending on the functionality you want to receive
- [todo] Can apparently have `static`, `virtual` & `abstract` members now, and default implementations ?? 

### Delegate
- Reference type
- The delegate type defines a method signature and is similar to a method pointer in function.
- Can be named or anonymous (Func, Action etc)

### Immutability
- Useful when you need a type to be thread-safe or you are depending on the hash code remaining in the same table. Or you want to ensure something hasn't/isn't going to be changed.

`init` properties have shallow immutability. After initialization you cant change the value of value type properties or the reference of reference type properties. But you can the the data the reference type refers to

### Collections  

- Linear collections
  - Array
  - List
  - Stack*
  - Queue*

- Associative collections
  - Dictionary
  - Hashset*
  - Cache*

- Graph collections
  - Trees etc

Encapsulated > Linear > Associative > Graphs

The collections performance profile & what you are doing. Things like Adding an element, finding an element or removing and element are notable characteristics.

`Span<T>` is a ref struct type and enforces rules to ensure it cant be accessed after the sequence is no longer in scope. `Memory<T>` is similar but doesnt use a ref struct type (async code?)

### Abstract collection types

The best collection type is the one you do not depend on!
i.e. Sorting does not require us to know the underlying implementation only that its an `IEnumerable` and can be sorted. They just need to be comparable.

`IList<T>` is THE linear collection in .NET, all linear collections will implement this interface.

`IDictionary<T>` is THE associative collection in .NET, all associative collections will implement this interface.

### Iteration
Some collection types do not support multiple iterations. Choosing which collection is best for the task is important. 

### Lists
Lists dynamic whereas Arrays are not.

Working with lists can cause issues as they can mutate while being iterated causing issues.

`ToList()` is faster & more memory efficient because it collects all the data in one go whereas `ToArray()` requires the one more copy iteration & uses an intermediate storage variable.

But `List<T>` uses `Array<T>` as its underlying type with over half the array not in use (wastes memory), Array uses memory optimally.

We can use `ReadOnlyCollections` to make sure the collection is made readonly and isn't manipulated by external sources. `IReadOnlyList<T>` is another way to do this

### Arrays
`Array`, `Span` & `Memory` don't support adding & removing items dynamically.

Arrays can be multi dimensional, single dimensional or jagged (array of arrays).

### Ordered & Partially Ordered Lists

Given a paginated list we need to order our array so that it maintains its sorting order.  

Sorting takes time & requires access to all items in a collection at the same time.

Quick sort has a pivot point and makes it so the we don't need to sort the full list at once. Works by partitioning and pivot points.

`Sort()` takes an `IComparer` interface whereas `OrderBy()` takes a lambda function that returns an `IComparer`. Both are similar to each other in performance as the `OrderBy()` method just uses sort underneath it.

`OrderBy` returns an `IEnumerable`, Calling `First()` after will be optimised to use min or max. `First()` with params will not use the optimized versions because it would result in a breaking change due to it not calling the lambda method on each iteration anymore. 

### `IEnumerable<T>`

`IEnumerable<T>` execution may (or may not) be deferred until the enumerator is iterated upon (`ToList`/`ToArray`/`Foreach`). 

You can defer the execution to a point in time where you are happy to execute it.

`IEmumerable<T>` does not guarantee multiple iterations are supported.

You can implement `IEnumerable<T>` to create your own collection types. 

### `Span<T>`

Type & memory safe representation of a contiguous region of memory (Similar to an array). It can point to managed memory, native memory or memory managed on the stack

### `Stack<T>` and `Queue<T>`

Stacks and queue are the same but work in opposite directions:
  - Stacks are last in first out
  - Queues are first in first out

These are similar to message queues.
You can push, peek, clear and pop items from the collection.

### `LinkedList<T>`

Good for arranging data in specific orders, adding elements in specific positions as they provide separate nodes of type `LinkedListNode<T>`. Each node points to the next node in the collection.

### `HashSet<T>`

High performance set operations, they contain no duplicate elements and have no particular ordering. Provides high performance similar to matching data on keys of a `Dictionary` or `HashTable`. Acts as a dictionary without values, just keys.

Provides mathematical operations such as Unions, set subtractions and set equality.

### Concurrent types 
- `ConcurrentDictionary<Tkey, TValue>`
- `ConcurrentStack<T>`
- `ConcurrentQueue<T>`
- `ConcurrentBag<T>`

- Mutexes and monitors may be used to create our own concurrent types.

### Generics

Type parameters so the compiler can verify the types.

### Access Modifiers
https://learn.microsoft.com/en-us/dotnet/csharp/programming-guide/classes-and-structs/access-modifiers

- `public`
  - Everywhere
- `protected internal`
  - The same class, A derived class in & outside the assembly, A non derived class within the same assembly (odd)
  - Acts as public/internal within the same assembly, acts as protected outside of the assembly 
- `protected`
  - The same class & derived classes
- `private`
  - The same class
- `internal`
  - Anywhere in the same assembly
- `private protected`
  - The same class or a derived class within the same assembly

At a namespace level classes can only be `public` or `internal`. 

### Garbage Collection
- The `CLR` manages the GarbageCollector (`GC`) to handle automatic memory management
- Frees developers from having to worry _too_ much about freeing and managing memory, Allocates objects onto the managed heap, Reclaims objects that are no longer in use (i.e. go out of scope) 
- Provides memory safety 
- The garbage collectors engine picks the best time to perform a collection based on the allocations being made
- Releases memory for objects that are no longer being used by the application by examining the programs 'roots' (static fields, local vars, cpu registers, GC handlers and the finalize queue)
- Garbage collector considers unreachable objects to be garbage
- Large objects are managed in a separate heap, this memory is not compacted
- Conditions for GC
  - System memory is low
  - Memory on the managed heap is beyond the acceptable thershold
  - `GC.Collect` is called
- Server and workstation heaps and GC are handled differently as workloads are generally different
- `GC.Finalize`

### Memory
- Developers work with the virtual address space and not the physical memory directly
- Virtual memory can be in 3 states: free, reserved or committed
- Virtual memory can get fragmented which means there are holds in the address spaces, It can only allocate single blocks upon request i.e. if you request 100MB and there isn't a 100MB slot available it will be unsuccessful 

### Allocation
- When you initialize a process the runtime reserves a contiguous region of space for the process called the managed heap
- The managed heap will keep a pointer to the location the next object will be allocated (base address by default)
- Managed heaps are faster than unmanaged heaps

### Other

- `Lazy` type allows you to use a lambda method in place of actually instantiating a property, only creating that property when it is accessed
- Benchmark.NET is a good project for benchmarking different processes
  - Use `[Benchmark]` attribute on methods
  - `BenchmarkRunner.Run<TClass>`
- Finializers `~Car()` called by the garbage collector and should be used to do any final cleaning of the object before being collected
  - Can be useful when your code attaches itself to unmanaged resources like windows, files and network connections to make sure you release those resources
  - Generally we should also implement `IDisposable` so we can explicitly release the resource manually (via using keyword or managed scope). Finalizer is a safeguard
- `sealed` prevents other classes from inheriting or overriding something
- `string` are immutable, re-setting them will create a new reference, not set the reference to the new value

### Solution Design
Top level directories:
- src
- test
Splitting these keeps the tests separated from the main code. 

- Application
  - Describes what the application is doing (interfaces, abstractions)
  - Can consume the domain layer
- Service / Presentation
  - API, Web UI, Console
  - Can look import application layer
- Infrastructure
  - Implementations of application description
  - Can consume the application and domain layers
- Domain / Core
  - Enterprise wide concerns, types, clients, values
  - Should be at the center of the project, should not import any thing else

## Azure

### Current Configuration
- Monolithic app running on Azure VM Server
- SQL & MongoDb Running on VM Servers
- App Services for smaller services
  - Auto-Reconciliation
  - Sign in/out action service (Visitors, staff, students)
  - Reporting Service
- Functions apps
  - Scheduled emails & Notifications
  - Virus scanning files
    - Picks up file refs from Azure Storage MQ & communicates with the monolithic API to retrieve & update scan results
  - Wonde data sync service scheduled & manual
- More recently the plan to move data into Cosmos to create a better reporting engine with the help of Data Factories
- Sendgrid API for emails

### Pipelines

### App service
- Deployment
    - Single container deployment via docker container + tags (prod, staging, testing-<value>)
    - Push to container registry from build pipelines in Azure DevOps (Docker Build & Push)
	- They are also implementing deployment via docker compose

### Functions
- Schedule
- Http
- Events (MessageQueue, Upload to azure storage container)