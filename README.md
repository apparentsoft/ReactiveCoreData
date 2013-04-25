# ReactiveCoreData

ReactiveCoreData (RCD) is an attempt to bring Core Data into the [ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa) (RAC) world.

Currently built as an empty Mac application with specs, not a framework.
To use, copy the source files from ReactiveCoreData to your project.

The idea is to write code such as:

```objc
[[[[[[MyManagedObject fetch] where:attribute equals:10] limit:50] sortBy:attribute] execute]
subscribeNext: ^(NSArray *)objects {
	NSLog(@"Fetched %@", objects);
}];
```


###TODO:
- Everything

