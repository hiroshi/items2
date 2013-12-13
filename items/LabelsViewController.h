//
//  LabelsViewController.h
//  items
//

#import <UIKit/UIKit.h>
@protocol LabelsViewControllerDelegate;

@interface LabelsViewController : UITableViewController

- (id)initWithCurrentLabelName:(NSString *)labelName delegate:(id<LabelsViewControllerDelegate>)delegate;

@end


@protocol LabelsViewControllerDelegate

- (void)labelsViewController:(LabelsViewController *)labelsViewController didSelectLabelName:(NSString *)labelName;

@end