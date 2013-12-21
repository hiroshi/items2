//
//  LabelsViewController.m
//  items
//

#import "LabelsViewController.h"
#import "DBAccount+defaultStore.h"
#import <BlocksKit.h>


@interface LabelsViewController ()

@property (nonatomic, strong) NSArray *labels;
@property (nonatomic, strong) NSString *oldLabelName;
@property (nonatomic, weak) id<LabelsViewControllerDelegate> delegate;

@end

@implementation LabelsViewController

- (id)initWithCurrentLabelName:(NSString *)labelName delegate:(id<LabelsViewControllerDelegate>)delegate
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
        self.oldLabelName = labelName;
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
        DBAccount *account = [DBAccountManager sharedManager].linkedAccount;
        if (account) {
            DBDatastore *store = account.defaultStore;
            DBError *error = nil;
            DBTable *table = [store getTable:@"labels"];
            _labels = [table query:Nil error:&error];
        }
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
    return self.labels.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    BOOL check = NO;
    NSString *name = @"All Items";
    if (indexPath.row == 0) {
        check = !self.oldLabelName;
    } else {
        DBRecord *record = self.labels[indexPath.row - 1];
        name = record[@"name"];
        check = [name isEqual:self.oldLabelName];
    }
    cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", check ? @"\u2713" :  @"\u2001", name];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self dismissViewControllerAnimated:YES completion:nil];
    NSString *labelName = nil;
    if (indexPath.row > 0) {
        DBRecord *record = self.labels[indexPath.row - 1];
        labelName = record[@"name"];
    }
    [self.delegate labelsViewController:self didSelectLabelName:labelName];
}
@end
