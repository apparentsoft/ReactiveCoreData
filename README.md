# ReactiveCoreData

ReactiveCoreData (RCD) is an attempt to bring Core Data into the [ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa) (RAC) world.

Currently has several files with the source code, [Specta](https://github.com/petejkim/specta) specs and a [demo application][Demo] for the Mac.

To use, copy the source files from [ReactiveCoreData](ReactiveCoreData) folder to your project. You should also have ReactiveCocoa in your project, of course.

Code from the Mac example:

```objc
// This part refetches data for the table and puts it into filteredParents
// It either fetches all Parents or filters by name, if there's something in the search field
// It will also refetch, if objectsChanged send a next
RAC(self.filteredParents) = [[[[Parent findAll]
    where:@"name" contains:filterText options:@"cd"]
    sortBy:@"name"]
    fetchWithTrigger:objectsChanged];
```

Another example of background processing:
```objc
[[[[triggerSignal 
    performInBackgroundContext:^(NSManagedObjectContext *context) {
        [Parent insert];
    }]
    saveContext]
    deliverOn:RACScheduler.mainThreadScheduler]
    subscribeNext:^(id _) {
        // Update UI
    }];
    
// We can also react to main context's merge notifications to update the UI
[mainContext.rcd_merged 
    subscribeNext:^(NSNotification *note){
        // Update UI
    }];
```

See the test [Specs][Specs] for some crude usage examples.

Also checkout the demo application in the project. It shows a simple table-view with Core Data backed storage using ReactiveCoreData and ReactiveCocoa for connecting things.

The headers also provide documentation for the various methods.

It's not feature-complete and more could be done but will be added based on actual usage and your contributions.

That being said, it should work both with shoebox and document-based applications, where there are many object contexts.


### Done:

- Start signals that represent and modify NSFetchRequests (findAll, findOne) from NSManagedObject.
- `-[RACSignal where:args:]` method that sets a predicate with given format that can have signals as its arguments. This brings execution of NSFetchRequests into the Reactive domain. As any signal to predicate changes, the query is modified and sent next — to be fetched, for example.
- A couple of signal-aware convenience methods for common predicate cases, like for CONTAINS predicate and for equal 
- `[RACSignal limit:]` that accepts either a value or a signal.
- `[RACSignal sortBy:]` that accepts either a "key" string, or a "-key" (for descending sort), or a sort descriptor, or an array of sort descriptors, or a signal with any of these
- `fetch` and `count` methods on RACSignal to execute the NSFetchRequest that's passed to them in the current NSManagedObjectContext and send the resulting array (or count) as "next".
- `fetchWithTrigger:` which will rerun the fetch if the trigger fires any value.
- fetching objectID and converting objectIDs to objects in current context
- Running in background contexts
- Saving of non-main contexts merges them into the main context.
- Signal that's fired when a context is saved (wraps NSManagedObjectContextDidSaveNotification).
- Signal that's fired after a merge.
- Support not only for shoebox applications (with one main managed object context) but also document-based applications where you have a separate context for each document.

[Demo]: ReactiveCoreDataApp/ASWAppDelegate.m
[Specs]: ReactiveCoreDataTests/RACManagedObjectFetchSpecs.m
