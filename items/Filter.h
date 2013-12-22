#import <Foundation/Foundation.h>

@interface Filter : NSObject

+ (Filter *)allItems;
+ (Filter *)archive;
+ (Filter *)filterWithLabelName:(NSString *)labelName;

@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSArray *labelNames;
@property (nonatomic, assign, readonly) BOOL isArchive;

@end
