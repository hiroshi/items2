#import <UIKit/UIKit.h>
@class DBRecord;

@interface TextViewController : UIViewController

- (id)initWithDBRecord:(DBRecord *)record;
- (id)initWithLabelNames:(NSArray *)labels text:(NSString *)text;

@end
