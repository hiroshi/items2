#import "ItemsViewController.h"
#import <Dropbox/Dropbox.h>
#import "DBAccount+defaultStore.h"
#import <BlocksKit.h>
#import "TextViewController.h"

@interface ItemsViewController ()

@property (nonatomic, strong) NSArray *items;

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
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd handler:^(id sender) {
//        
//    }];
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
}

- (void)viewWillAppear:(BOOL)animated
{
    [self reloadItems];
    [self.tableView reloadData];
    // Add item button
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
        self.items = [[table query:nil error:&error] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
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

@end
