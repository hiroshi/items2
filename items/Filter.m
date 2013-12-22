#import "Filter.h"

typedef enum {
    FilterTypeLabel,
    FilterTypeAllItems,
    FilterTypeArchive
} FilterType;


@interface Filter ()

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *labelName;
@property (nonatomic, assign) FilterType filterType;

@end

@implementation Filter

+ (Filter *)allItems
{
    Filter *filter = [Filter new];
    filter.title = @"All items";
    filter.filterType = FilterTypeAllItems;
    return filter;
}

+ (Filter *)archive
{
    Filter *filter = [Filter new];
    filter.title = @"Archive";
    filter.filterType = FilterTypeArchive;
    return filter;
}

+ (Filter *)filterWithLabelName:(NSString *)labelName
{
    Filter *filter = [Filter new];
    filter.title = labelName;
    filter.labelName = labelName;
    filter.filterType = FilterTypeLabel;
    return filter;
}

- (BOOL)isEqual:(id)object
{
    if (self.filterType == FilterTypeLabel) {
        return [self.labelName isEqual:[object labelName]];
    }
    return (self.filterType == [object filterType]);
}

- (NSArray *)labelNames
{
    if (self.labelName) {
        return @[self.labelName];
    }
    return @[];
}

- (BOOL)isArchive
{
    return (self.filterType == FilterTypeArchive);
}

@end
