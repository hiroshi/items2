#import "ItemsViewController.h"
#import <Dropbox/Dropbox.h>
#import "DBAccount+defaultStore.h"
#import <BlocksKit.h>
#import "TextViewController.h"
#import "LabelsViewController.h"
#import "Label.h"
#import "Filter.h"

@interface ItemsViewController () <LabelsViewControllerDelegate>

@property (nonatomic, strong) NSArray *items;
//@property (nonatomic, strong) NSString *currentLabelName;
//@property (nonatomic, assign) BOOL isArchive;
@property (nonatomic, strong) Filter *filter;

@end

@implementation ItemsViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.filter = [Filter allItems];
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
    [labelSelectButton setTitle:self.filter.title forState:UIControlStateNormal];
    [labelSelectButton addEventHandler:^(id sender) {
        //LabelsViewController *labelsViewController = [[LabelsViewController alloc] initWithCurrentLabelName:self.currentLabelName isArchive:self.isArchive delegate:self];
        LabelsViewController *labelsViewController = [[LabelsViewController alloc] initWithSelectedFilter:self.filter delegate:self];
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
        //NSArray *labelNames = self.currentLabelName ? @[self.currentLabelName] : nil;
        //NSArray *labelNames = self.filter.labelName ? @[self.filtercurrentLabelName] : nil;
        TextViewController *viewController = [[TextViewController alloc] initWithLabelNames:self.filter.labelNames text:nil];        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
        [self presentViewController:navController animated:YES completion:^{
            NSLog(@"present textViewController for new item done.");
        }];
    }];
    [self setToolbarItems:@[addButton] animated:animated];
    [self.navigationController setToolbarHidden:NO animated:animated];
    // NOTE: view for UIBarbuttonItem may not created before setToolbarHidden:NO
    UIGestureRecognizer *gesture = [[UILongPressGestureRecognizer alloc] initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
        if (state == UIGestureRecognizerStateBegan) {
            UIActionSheet *sheet = [UIActionSheet actionSheetWithTitle:@"New item"];
            [sheet addButtonWithTitle:@"Create from clipboard" handler:^{
                NSString *text = [UIPasteboard generalPasteboard].string;
                DBAccount *account = [DBAccountManager sharedManager].linkedAccount;
                DBDatastore *store = account.defaultStore;
                DBTable *table = [store getTable:@"items"];
                NSNumber *pos = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
                NSMutableDictionary *fields = [NSMutableDictionary dictionaryWithDictionary:@{@"text": text, @"pos": pos}];
                for (NSString *labelName in self.filter.labelNames) {
                    fields[[Label labelKeyForName:labelName]] = labelName;
                }
                /*DBRecord *record =*/ [table insert:fields];
                DBError *error = nil;
                [store sync:&error];
                if (error) {
                    NSLog(@"DBError: %@", error);
                }

                
//                TextViewController *viewController = [[TextViewController alloc] initWithLabelNames:self.filter.labelNames text:text];
//                UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
//                [self presentViewController:navController animated:YES completion:^{
//                    NSLog(@"present textViewController from clipboard done.");
//                }];
            }];
            [sheet setCancelButtonWithTitle:nil handler:nil];
            [sheet showInView:sender.view];
        }
    }];
    UIView *addButtonView = [addButton valueForKey:@"view"];
    [addButtonView addGestureRecognizer:gesture];
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
        if (self.filter.isArchive) {
            DBTable *table = [store getTable:@"archives"];
            self.items = [table query:nil error:&error];
        } else {
            DBTable *table = [store getTable:@"items"];
            NSMutableDictionary *query = [NSMutableDictionary dictionary];
            for (NSString *labelName in self.filter.labelNames) {
                [query setObject:labelName forKey:[Label labelKeyForName:labelName]];
            }
            self.items = [[table query:query error:&error] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                return [((DBRecord *)obj2)[@"pos"] doubleValue] - [((DBRecord *)obj1)[@"pos"] doubleValue];
            }];
        }
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
    cell.textLabel.text = record[@"text"];
    [cell addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
        if (state == UIGestureRecognizerStateBegan) {
            UIActionSheet *sheet = [UIActionSheet actionSheetWithTitle:nil];
            [sheet addButtonWithTitle:@"Copy text" handler:^{
                [UIPasteboard generalPasteboard].string = record[@"text"];
            }];
//            [sheet addButtonWithTitle:@"Open URL" handler:^{
//                //[UIPasteboard generalPasteboard].string = record[@"title"];
//            }];
            [sheet setCancelButtonWithTitle:nil handler:nil];
            [sheet showInView:sender.view];
        }
    }]];
    return cell;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    NSLog(@"move: %ld -> %ld", (long)sourceIndexPath.row, (long)destinationIndexPath.row);
    DBRecord *sourceRecord = self.items[sourceIndexPath.row];
    NSInteger destIndex = destinationIndexPath.row;
    double pos = 0;
    if (destIndex == 0) {
        pos = [[NSDate date] timeIntervalSince1970];
    } else if (destIndex == self.items.count - 1) {
        DBRecord *last = self.items[destIndex];
        pos = [last[@"pos"] doubleValue] / 2.0;
    } else {
        if (destIndex > sourceIndexPath.row) {
            destIndex += 1;
        }
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

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"Archive";
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    DBRecord *record = self.items[indexPath.row];
    DBError *error = nil;
    switch (editingStyle) {
        case UITableViewCellEditingStyleDelete:
            {
                DBDatastore *store = [DBAccountManager sharedManager].linkedAccount.defaultStore;
                [[store getTable:@"archives"] insert:record.fields];
                [record deleteRecord];
                [store sync:&error];
            }
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

- (void)labelsViewController:(LabelsViewController *)labelsViewController didSelectFilter:(Filter *)filter
{
    // change button title
    UIButton *button = (UIButton *)self.navigationItem.titleView;
    [button setTitle:filter.title forState:UIControlStateNormal];
    [button sizeToFit];
    // refresh items with filter
    self.filter = filter;
    [self reloadItems];
    [self.tableView reloadData];
}

@end
