#import "ItemsViewController.h"
#import <Dropbox/Dropbox.h>
#import "DBAccount+defaultStore.h"
#import <BlocksKit.h>
#import "TextViewController.h"
#import "LabelsViewController.h"

static int32_t hashCode(NSString *str) {
    int32_t hash = 0;
    int len = str.length;
    if (len == 0) return hash;
    for (int i = 0; i < len; i++) {
        unichar c = [str characterAtIndex:i];
        hash = ((hash << 5) - hash) + c;
    }
    return hash;
}

NSString *base36enc(long unsigned int value)
{
    char base36[36] = "0123456789abcdefghijklmnopqrstuvwxyz";
    /* log(2**64) / log(36) = 12.38 => max 13 char + '\0' */
    char buffer[14];
    unsigned int offset = sizeof(buffer);
    
    buffer[--offset] = '\0';
    do {
        buffer[--offset] = base36[value % 36];
    } while (value /= 36);
    return [NSString stringWithUTF8String:&buffer[offset]];
}


NSString *labelKey(NSString *labelName) {
    //u_int32_t hash = hashCode([labelName UTF8String]);
    u_int32_t hash = hashCode(labelName);
    return [NSString stringWithFormat:@"label_%@", base36enc(hash)];
}


@interface ItemsViewController () <LabelsViewControllerDelegate>

@property (nonatomic, strong) NSArray *items;
@property (nonatomic, strong) NSString *currentLabelName;

@end

@implementation ItemsViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        //[self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"LinkAccount"];
        [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Item"];
        //[self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"AddItem"];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Edit button
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    // Label select
    UIButton *labelSelectButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [labelSelectButton setTitle:@"All Items" forState:UIControlStateNormal];
    [labelSelectButton addEventHandler:^(id sender) {
        LabelsViewController *labelsViewController = [[LabelsViewController alloc] initWithCurrentLabelName:self.currentLabelName delegate:self];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:labelsViewController];
        [self presentViewController:nav animated:YES completion:^{
            NSLog(@"completion");
        }];
    } forControlEvents:UIControlEventTouchDown];
    self.navigationItem.titleView = labelSelectButton;
    // Dropbox things
    DBAccount *account = [DBAccountManager sharedManager].linkedAccount;
    [account.defaultStore addObserver:self block:^{
        DBError *error = nil;
        [account.defaultStore sync:&error];
        if (error) {
            NSLog(@"Error: %@", error);
        }
        [self reloadItems];
        [self.tableView reloadData];
    }];
    [account.defaultStore sync:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self reloadItems];
    [self.tableView reloadData];
    // Set toolbar - [AddItem]
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd handler:^(id sender) {
        TextViewController *viewController = [TextViewController new];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
        [self presentViewController:navController animated:YES completion:^{
            NSLog(@"present textViewController for new item done.");
        }];
    }];
    [self setToolbarItems:@[addButton] animated:animated];
    [self.navigationController setToolbarHidden:NO animated:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -

- (void)reloadItems
{
    DBAccount *account = [DBAccountManager sharedManager].linkedAccount;
    if (account) {
        DBDatastore *store = account.defaultStore;
        DBError *error = nil;
        DBTable *table = [store getTable:@"items"];
        NSDictionary *query = nil;
        if (self.currentLabelName) {
            query = @{labelKey(self.currentLabelName): self.currentLabelName};
        }
        self.items = [[table query:query error:&error] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [((DBRecord *)obj2)[@"pos"] doubleValue] - [((DBRecord *)obj1)[@"pos"] doubleValue];
        }];
        if (error) {
            NSLog(@"Error: %@", error);
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Item" forIndexPath:indexPath];
    DBRecord *record = self.items[indexPath.row];
    cell.textLabel.text = record[@"title"];
    return cell;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    NSLog(@"move: %ld -> %ld", (long)sourceIndexPath.row, (long)destinationIndexPath.row);
    DBRecord *sourceRecord = self.items[sourceIndexPath.row];
    NSInteger destIndex = destinationIndexPath.row;
    double pos = 0;
    if (destIndex == 0) {
        pos = [NSDate timeIntervalSinceReferenceDate];
    } else if (destIndex == self.items.count - 1) {
        pos = 0;
    } else {
        DBRecord *before = self.items[destIndex - 1];
        DBRecord *after = self.items[destIndex];
        pos = ([before[@"pos"] doubleValue] + [after[@"pos"] doubleValue]) / 2.0;
    }
    NSLog(@"  pos: %f", pos);
    sourceRecord[@"pos"] = [NSNumber numberWithDouble:pos];
    DBDatastore *store = sourceRecord.table.datastore;
    DBError *error = nil;
    [store sync:&error];
    if (error) {
        NSLog(@"DBError: %@", error);
    }
    [self reloadItems];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    DBRecord *record = self.items[indexPath.row];
    DBError *error = nil;
    switch (editingStyle) {
        case UITableViewCellEditingStyleDelete:
            [record deleteRecord];
            [[DBAccountManager sharedManager].linkedAccount.defaultStore sync:&error];
            if (error) {
                NSLog(@"Error: %@", error);
            }
            [self reloadItems];
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        default:
            break;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DBRecord *record = self.items[indexPath.row];
    TextViewController *viewController = [[TextViewController alloc] initWithDBRecord:record];
    [self.navigationController pushViewController:viewController animated:YES];
//    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
//    if ([cell.reuseIdentifier isEqual:@"LinkAccount"]) {
//        [[DBAccountManager sharedManager] linkFromController:self];
//    }
}

#pragma mark - LabelsViewControllerDelegate

- (void)labelsViewController:(LabelsViewController *)labelsViewController didSelectLabelName:(NSString *)labelName
{
    // filter items
    self.currentLabelName = labelName;
    
    
    // change button title
    UIButton *button = (UIButton *)self.navigationItem.titleView;
    if (!labelName) {
        labelName = @"All Items";
    }
    [button setTitle:labelName forState:UIControlStateNormal];
    [button sizeToFit];
    [self reloadItems];
    [self.tableView reloadData];
}

@end
