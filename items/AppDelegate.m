#import "AppDelegate.h"
#import "ItemsViewController.h"
#import <Dropbox/Dropbox.h>
#import "DBAccount+defaultStore.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Dropbox
    NSString *appKey = [[NSUserDefaults standardUserDefaults] stringForKey:@"DropboxAppKey"];
    [[NSUserDefaults standardUserDefaults] setObject:appKey forKey:@"DropboxAppKey"];
    NSString *appSecret = [[NSUserDefaults standardUserDefaults] stringForKey:@"DropboxAppSecret"];
    [[NSUserDefaults standardUserDefaults] setObject:appSecret forKey:@"DropboxAppSecret"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    DBAccountManager* accountMgr = [[DBAccountManager alloc] initWithAppKey:appKey secret:appSecret];
    [DBAccountManager setSharedManager:accountMgr];
    DBAccount *account = [DBAccountManager sharedManager].linkedAccount;
    if (account) {
        DBError *error = nil;
        [account.defaultStore sync:&error];
        if (error) {
            NSLog(@"DBError: %@", error);
        }
    }
    // Window and rootViewController
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    ItemsViewController *viewController = [[ItemsViewController alloc] initWithStyle:UITableViewStylePlain];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
    self.window.rootViewController = navController;
    // Dropbox account
    if (!account) {
        [[DBAccountManager sharedManager] linkFromController:self.window.rootViewController];
    }
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url sourceApplication:(NSString *)source annotation:(id)annotation
{
    DBAccount *account = [[DBAccountManager sharedManager] handleOpenURL:url];
    if (account) {
        NSLog(@"App linked successfully!");
        return YES;
    }
    return NO;
}
@end
