//
//  LabelsViewController.h
//  items
//

#import <UIKit/UIKit.h>
@protocol LabelsViewControllerDelegate;
@class Filter;

@interface LabelsViewController : UITableViewController

- (id)initWithSelectedFilter:(Filter *)filter delegate:(id<LabelsViewControllerDelegate>)delegate;

@end


@protocol LabelsViewControllerDelegate

- (void)labelsViewController:(LabelsViewController *)labelsViewController didSelectFilter:(Filter *)filter;

@end