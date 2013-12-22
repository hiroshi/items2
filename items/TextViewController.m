#import "TextViewController.h"
#import <BlocksKit.h>
#import <Dropbox/Dropbox.h>
#import "DBAccount+defaultStore.h"
#import "Label.h"

@interface TextViewController ()

@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) DBRecord *record;
@property (nonatomic, strong) NSArray *labelNames;

@end

@implementation TextViewController

- (id)initWithDBRecord:(DBRecord *)record
{
    self = [super init];
    if (self) {
        self.record = record;
    }
    return self;
}

- (id)initWithLabelNames:(NSArray *)labelNames
{
    self = [super init];
    if (self) {
        self.labelNames = labelNames;
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
        textView.text = self.record[@"text"];
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
            self.record[@"text"] = self.textView.text;
            [self.navigationController popToRootViewControllerAnimated:YES];
        } else {
            DBTable *table = [store getTable:@"items"];
            NSNumber *pos = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
            NSMutableDictionary *fields = [NSMutableDictionary dictionaryWithDictionary:@{@"text": self.textView.text, @"pos": pos}];
            for (NSString *labelName in self.labelNames) {
                fields[[Label labelKeyForName:labelName]] = labelName;
            }
            /*DBRecord *record =*/ [table insert:fields];
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
