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
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd handler:^(id sender) {
//        
//    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    // Items
    DBAccount *account = [DBAccountManager sharedManager].linkedAccount;
    if (account) {
        DBDatastore *store = account.defaultStore;
        DBError *error = nil;
        DBTable *table = [store getTable:@"items"];
        self.items = [table query:nil error:&error];
        if (error) {
            NSLog(@"Error: %@", error);
        }
        [self.tableView reloadData];
    }
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

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
//    if ([cell.reuseIdentifier isEqual:@"LinkAccount"]) {
//        [[DBAccountManager sharedManager] linkFromController:self];
//    }
}

@end
