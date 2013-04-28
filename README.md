# ReactiveCoreData

ReactiveCoreData (RCD) is an attempt to bring Core Data into the [ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa) (RAC) world.

Currently built as an empty Mac application with specs, not a framework.
To use, copy the source files from ReactiveCoreData to your project.

See the test Specs (in RACManagedObjectFetchSpecs.m) for some usage examples.

The idea is to write code such as:

```objc
[[[[[[MyManagedObject.findAll 
where:attribute equals:valueSignal] 
limit:50] 
sortBy:sortSignal] 
fetch]
subscribeNext: ^(NSArray *)objects {
	NSLog(@"Fetched %@", objects);
}];
```

### Done:

- Initial signals that represent and modify NSFetchRequests (findAll)
- `-[RACSignal where:args:]` method that sets a predicate with given format that can have signals as its arguments. This brings execution of NSFetchRequests into the Reactive domain. As any signal to predicate changes, the query is modified and sent next — to be fetched, for example.
- `fetch` and `count` methods on RACSignal to execute the NSFetchRequest that's passed to them in the current NSManagedObjectContext and send the resulting array (or count) as "next".
- Initial managing of NSManagedObjectContexts per thread
- Saving of non-main contexts merges them into the main context.


### TODO:

- More signal operations to modify fetch requests (limit, sorting, result type). In general, they can also be modified with a `-map:`.
- Think and implement better cross-thread operations, so that fetches could be done in the background and brought back into main thread, all within the confines of `RACScheduler` terminology.
- Signals that are fired when a context is saved (wrap the NSNotification).
