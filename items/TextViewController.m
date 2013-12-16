#import "TextViewController.h"
#import <BlocksKit.h>
#import <Dropbox/Dropbox.h>
#import "DBAccount+defaultStore.h"

@interface TextViewController ()

@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) DBRecord *record;

@end

@implementation TextViewController

//- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
//{
//    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//    if (self) {
//        // Custom initialization
//    }
//    return self;
//}

- (id)initWithDBRecord:(DBRecord *)record
{
    self = [super init];
    if (self) {
        self.record = record;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // text view
    UITextView *textView = [[UITextView alloc] initWithFrame:self.view.frame];
    self.textView = textView;
    [self.view addSubview:textView];
    if (self.record) {
        textView.text = self.record[@"title"];
    } else {
        // cancel button
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel handler:^(id sender) {
            [self dismissViewControllerAnimated:YES completion:^{
                NSLog(@"textViewController canceled");
            }];
        }];
    }
    // save button
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave handler:^(id sender) {
        DBAccount *account = [DBAccountManager sharedManager].linkedAccount;
        DBDatastore *store = account.defaultStore;
        if (self.record) {
            self.record[@"title"] = self.textView.text;
            [self.navigationController popToRootViewControllerAnimated:YES];
        } else {
            DBTable *table = [store getTable:@"items"];
            NSNumber *pos = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
            /*DBRecord *record =*/ [table insert:@{@"title": self.textView.text, @"pos": pos}];
            [self dismissViewControllerAnimated:YES completion:^{
                NSLog(@"textViewController saved");
            }];
        }
        DBError *error = nil;
        [store sync:&error];
        if (error) {
            NSLog(@"DBError: %@", error);
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.textView becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
