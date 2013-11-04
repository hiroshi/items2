#import <Dropbox/Dropbox.h>

@interface DBAccount (defaultStore)

@property (nonatomic, readonly) DBDatastore *defaultStore;

@end
