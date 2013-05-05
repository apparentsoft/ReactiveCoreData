# ReactiveCoreData

ReactiveCoreData (RCD) is an attempt to bring Core Data into the [ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa) (RAC) world.

Currently built as an empty Mac application with specs, not a framework.
To use, copy the source files from ReactiveCoreData to your project.

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

See the test Specs (in RACManagedObjectFetchSpecs.m) for some usage examples.

Also checkout the test application in the project which shows a simple table-view with Core Data backed storage using ReactiveCoreData and ReactiveCocoa for connecting things.


### Done:

- Initial signals that represent and modify NSFetchRequests (findAll, findOne)
- `-[RACSignal where:args:]` method that sets a predicate with given format that can have signals as its arguments. This brings execution of NSFetchRequests into the Reactive domain. As any signal to predicate changes, the query is modified and sent next — to be fetched, for example.
- `[RACSignal limit:]` that accepts either a value or a signal.
- `fetch` and `count` methods on RACSignal to execute the NSFetchRequest that's passed to them in the current NSManagedObjectContext and send the resulting array (or count) as "next".
- `fetchWithTrigger:` which will rerun the fetch if the trigger fires any value.
- Running in background contexts
- Saving of non-main contexts merges them into the main context.
- Support not only for shoebox applications (with one main managed object context) but also document-based applications where you have a separate context for each document.

### TODO:

- More signal operations to modify fetch requests (sorting, result type). In general, they can also be modified with a `-map:`.
- Signals that are fired when a context is saved (wrap the NSNotification).
