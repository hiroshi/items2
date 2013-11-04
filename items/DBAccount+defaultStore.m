#import "DBAccount+defaultStore.h"
#import <objc/runtime.h>

@implementation DBAccount (defaultStore)

- (DBDatastore *)defaultStore
{
    static char key;
    DBDatastore *store = (DBDatastore *)objc_getAssociatedObject(self, &key);
    if (!store) {
        DBError *error = nil;
        store = [DBDatastore openDefaultStoreForAccount:self error:&error];
        objc_setAssociatedObject(self, &key, store, OBJC_ASSOCIATION_RETAIN);
        if (error) {
            NSLog(@"Error: %@", error);
        }
    }
    return store;
}

@end