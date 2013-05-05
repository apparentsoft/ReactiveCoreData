//
//  ASWAppDelegate.m
//  ReactiveCoreData
//
//  Created by Jacob Gorban on 25/04/2013.
//  Copyright (c) 2013 Apparent Software. All rights reserved.
//

#import <ReactiveCocoa/ReactiveCocoa.h>
#import "ASWAppDelegate.h"
#import "ReactiveCoreData.h"
#import "Parent.h"

@interface ASWAppDelegate ()
@property (weak) IBOutlet NSButton *addButton;
@property (weak) IBOutlet NSButton *removeButton;
@property (weak) IBOutlet NSSearchField *searchField;
@property (weak) IBOutlet NSTableView *tableView;

@property (strong) NSArray *filteredParents;

@end

@implementation ASWAppDelegate

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Need to do this for automatic detection of context
    [NSManagedObjectContext setMainContext:[self managedObjectContext]];

    // Using RACCommand instead of target/action
    self.addButton.rac_command = [RACCommand command];

    // The signal holds the newly inserted parent, though we don't use it later.
    RACSignal *addedParent = [self.addButton.rac_command addSignalBlock:^(id _) {
        self.searchField.stringValue = @""; // reset search field on add

        // insert a new parent and set its default values
        // Of course, it might be better to do this in the model class itself
        // but it gives an example of using ReactiveCoreData
        return [RACSignal return:
            [Parent insert:^(Parent *parent) {
                parent.name = @"No name";
                parent.age = 40;
            }]];
    }];

    // Basically, implement a delegate method in a signal
    RACSignal *aParentIsSelected = [[self rac_signalForSelector:@selector(tableViewSelectionDidChange:)]
                                    map:^(id x) {
                                        return @(self.tableView.numberOfSelectedRows);
                                    }];

    // Add it after the selector above is used, so that it gets called
    // Otherwise, need to subscribe to NSTableViewSelectionDidChangeNotification manually
    self.tableView.delegate = self;

    self.removeButton.rac_command = [RACCommand commandWithCanExecuteSignal:aParentIsSelected];

    // Pretty straight-forward removal
    // I'd even say unnecessary long with the return of signal in addSignalBlock:
    // The good about having it a signal is that we can chain it later to react to deletion
    // See how this affects objectsChanged.
    RACSignal *removedParent = [self.removeButton.rac_command addSignalBlock:^(id _) {
        NSArray *objectsToRemove = [self.filteredParents objectsAtIndexes:self.tableView.selectedRowIndexes];
        NSManagedObjectContext *context = [NSManagedObjectContext currentContext];
        for (NSManagedObject *obj in objectsToRemove) {
            [context deleteObject:obj];
        }
        return [RACSignal return:@YES];
    }];

    // reload the data after filteredParents is updated
    [RACAble(self.filteredParents) subscribeNext:^(id x) {
        [self.tableView reloadData];
    }];

    // we use this later to trigger refetch of the table
    // startWith is needed for the initial trigger on launch
    RACSignal *objectsChanged = [[RACSignal merge:@[addedParent, removedParent]] startWith:@YES];

    // filterText will send next when the text in searchField changes either by user edit or direct update by us.
    RACSignal *filterText = [[RACSignal
        merge:@[self.searchField.rac_textSignal, RACAbleWithStart(self.searchField.stringValue)]]
        map:^id(id value) {
            return [value copy]; // just in case
        }];

    // This part refetches data for the table and puts it into filteredParents
    // It either fetches all Parents or filters by name, if there's something in the search field
    // It will also refetch, if objectsChanged send a next
    RAC(self.filteredParents) = [[filterText
        flattenMap:^(NSString *filter) {
            if ([filter length] > 0)
                return [[Parent findAll] where:@"name contains[cd] %@" args:@[filter]];
            else
                return [Parent findAll];
        }]
        fetchWithTrigger:objectsChanged];

    // select the first row in the table
    [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
}


#pragma mark - NSTableView related
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView;
{
    return [self.filteredParents count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;
{
    if (row < 0) return nil;
    NSUInteger r = (NSUInteger) row;

    if ([[tableColumn identifier] isEqualToString:@"Name"]) {
        return [self.filteredParents[r] name];
    }
    return @([self.filteredParents[r] age]);
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;
{
    if (row < 0) return;
    Parent *parent = self.filteredParents[(NSUInteger) row];
    if ([tableColumn.identifier isEqualToString:@"Name"]) {
        parent.name = object;
    }
    else {
        parent.age = [object integerValue];
    }
}




#pragma mark - Boilerplate

// Returns the directory the application uses to store the Core Data store file. This code uses a directory named "com.apparentsoft.ReactiveCoreData" in the user's Application Support directory.
- (NSURL *)applicationFilesDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *appSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    return [appSupportURL URLByAppendingPathComponent:@"com.apparentsoft.ReactiveCoreData"];
}

// Creates if necessary and returns the managed object model for the application.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
	
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"ReactiveCoreData" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }
    
    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
    NSError *error = nil;
    
    NSDictionary *properties = [applicationFilesDirectory resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
    
    if (!properties) {
        BOOL ok = NO;
        if ([error code] == NSFileReadNoSuchFileError) {
            ok = [fileManager createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if (!ok) {
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    } else {
        if (![properties[NSURLIsDirectoryKey] boolValue]) {
            // Customize and localize this error.
            NSString *failureDescription = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationFilesDirectory path]];
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:failureDescription forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:101 userInfo:dict];
            
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    
    NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"ReactiveCoreData.storedata"];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    if (![coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]) {
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _persistentStoreCoordinator = coordinator;
    
    return _persistentStoreCoordinator;
}

// Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) 
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];

    return _managedObjectContext;
}

// Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    return [[self managedObjectContext] undoManager];
}

// Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
- (IBAction)saveAction:(id)sender
{
    NSError *error = nil;
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }
    
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    // Save changes in the application's managed object context before the application terminates.
    
    if (!_managedObjectContext) {
        return NSTerminateNow;
    }
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
    
    if (![[self managedObjectContext] hasChanges]) {
        return NSTerminateNow;
    }
    
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {

        // Customize this code block to include application-specific recovery steps.              
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }

        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];

        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertAlternateReturn) {
            return NSTerminateCancel;
        }
    }

    return NSTerminateNow;
}

@end
