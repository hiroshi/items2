#import "TextViewController.h"
#import <BlocksKit.h>
#import <Dropbox/Dropbox.h>
#import "DBAccount+defaultStore.h"

@interface TextViewController ()

@property (nonatomic, strong) UITextView *textView;

@end

@implementation TextViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // text view
    UITextView *textView = [[UITextView alloc] initWithFrame:self.view.frame];
    self.textView = textView;
    textView.text = @"hello";
    //textView.backgroundColor = [UIColor redColor];
    [self.view addSubview:textView];
    // cancel button
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel handler:^(id sender) {
        [self dismissViewControllerAnimated:YES completion:^{
            NSLog(@"textViewController canceled");
        }];
    }];
    // save button
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave handler:^(id sender) {
        DBAccount *account = [DBAccountManager sharedManager].linkedAccount;
        DBDatastore *store = account.defaultStore;
        DBError *error = nil;
        DBTable *table = [store getTable:@"items"];
        NSNumber *pos = [NSNumber numberWithDouble:[NSDate timeIntervalSinceReferenceDate]];
        /*DBRecord *record =*/ [table insert:@{@"title": self.textView.text, @"pos": pos}];
        [store sync:&error];
        [self dismissViewControllerAnimated:YES completion:^{
            NSLog(@"textViewController saved");
        }];
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
