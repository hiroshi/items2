//
//  LabelsViewController.m
//  items
//

#import "LabelsViewController.h"
#import "DBAccount+defaultStore.h"
#import <BlocksKit.h>
#import "Filter.h"

@interface LabelsViewController ()

@property (nonatomic, strong) NSArray *labels;
@property (nonatomic, strong) Filter *lastFilter;
@property (nonatomic, weak) id<LabelsViewControllerDelegate> delegate;

@end

@implementation LabelsViewController

- (id)initWithSelectedFilter:(Filter *)filter delegate:(id<LabelsViewControllerDelegate>)delegate
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
        self.lastFilter = filter;
        self.delegate = delegate;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = @"Labels";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel handler:^(id sender) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -

- (NSArray *)labels
{
    if (!_labels) {
        NSMutableArray *labels = [NSMutableArray arrayWithObject:[Filter allItems]];
        DBAccount *account = [DBAccountManager sharedManager].linkedAccount;
        if (account) {
            DBDatastore *store = account.defaultStore;
            DBError *error = nil;
            DBTable *table = [store getTable:@"labels"];
            [labels addObjectsFromArray:[[table query:nil error:&error] map:^id(id obj) {
                return [Filter filterWithLabelName:obj[@"name"]];
            }]];
        }
        [labels addObject:[Filter archive]];
        _labels = labels;
    }
    return _labels;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.labels.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    Filter *filter = self.labels[indexPath.row];
    BOOL check = [filter isEqual:self.lastFilter];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", check ? @"\u2713" :  @"\u2001", filter.title];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self dismissViewControllerAnimated:YES completion:nil];
    Filter *filter = self.labels[indexPath.row];
    [self.delegate labelsViewController:self didSelectFilter:filter];
}
@end
