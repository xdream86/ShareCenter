//
//  ViewController.m
//  BSNShareCenterDemo
//
//  Created by Jun Xia on 15/5/7.
//
//

#import "ViewController.h"
#import "BSNSCShareCenter.h"

@interface ViewController () <UIWebViewDelegate>
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UITableView *tableview;
@property (nonatomic, strong) NSArray *options;
@property (nonatomic, strong) NSArray *sharers;
@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Share Center";
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleGray];
    UIBarButtonItem* spinner = [[UIBarButtonItem alloc] initWithCustomView: activityIndicator];
    self.navigationItem.rightBarButtonItem = spinner;
    [self.tableview registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    self.options = @[@"Share to Buffer", @"Logout Buffer", @"Share to Delicious", @"Logout Delicious",
                     @"Share to Readability", @"logout Readability", @"Share to Facebook", @"Logout Facebook",
                     @"Share to Twitter", @"Logout Twitter",@"Share to Pocket", @"Logout Pocket",
                     @"Share to Google+", @"Logout Google+", @"Share to Pinterest", @"Logout Pinterest",
                     @"Share to Instapaper", @"Logout Instapaper", @"Share to Dropbox", @"Logout Dropbox",
                     @"Share to Tumblr", @"Logout Tumblr", @"Share to WeiBo", @"Logout WeiBo", @"Share to LinkedIn", @"Logout LinkedIn",
                     @"Share to Pinboard", @"Logout Pinboard", @"Share to Evernote", @"Logout Evernote",
                     @"Share to WeChat", @"Logout WeChat", @"Share to WeChatFriends", @"Logout WeChatFriends"];
    self.sharers = @[@(BSNSCSharerTypeBuffer), @(BSNSCSharerTypeDelicious), @(BSNSCSharerTypeReadability),
                       @(BSNSCSharerTypeFacebook), @(BSNSCSharerTypeTwitter), @(BSNSCSharerTypePocket), @(BSNSCSharerTypeGooglePlus),
                       @(BSNSCSharerTypePinterest), @(BSNSCSharerTypeInstapaper), @(BSNSCSharerTypeDropbox), @(BSNSCSharerTypeTumblr),
                       @(BSNSCSharerTypeWeiBo), @(BSNSCSharerTypeLinkedIn), @(BSNSCSharerTypePinboard), @(BSNSCSharerTypeEvernote),
                       @(BSNSCSharerTypeWeChat), @(BSNSCSharerTypeWeChatFriends)];
    self.activityIndicator = activityIndicator;
    self.tableview.tableFooterView = [[UIView alloc] init];
}

#pragma mark- Action
#pragma mark- Delegate，DataSource, Callback Method
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    BSNSCShareModel *shareModel = [BSNSCShareModel new];
    BSNSCSharerType sharerType = [self.sharers[indexPath.row / 2] intValue];
    shareModel.sharerType = sharerType;
    shareModel.text = [[self randomStringWithLength:6] stringByAppendingString:@"我的分享:www.baidu.com"];
    shareModel.webPageLink = @"http://www.sohu.com";
    shareModel.tags = @"#Mercury Browser";

    BSNSCFileModel *file1 = [BSNSCFileModel new];
    file1.name = @"uploadImage.png";
    file1.rawData = UIImagePNGRepresentation([UIImage imageNamed:@"uploadImage.png"]);
    file1.link = @"http://placekitten.com/g/500/400";
    
    BSNSCFileModel *file2 = [BSNSCFileModel new];
    file2.name = @"uploadImage.png";
    file2.rawData = UIImagePNGRepresentation([UIImage imageNamed:@"uploadImage.png"]);
    file2.link = @"http://placekitten.com/g/500/400";
    
    [shareModel pushFileModel:file1];
    [shareModel pushFileModel:file2];
    if (indexPath.row % 2 == 0) {
        [self.activityIndicator startAnimating];
        [BSNSCShareCenter shareWithShareModel:shareModel completeBlock:^(BOOL success, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.activityIndicator stopAnimating];
                if (success) {
                    [self showMessage:@"success"];
                } else {
                    [self showMessage:[error localizedDescription]];
                }
            });
        }];
    } else {
        [BSNSCShareCenter logoutSharer:sharerType];
        [self showMessage:@"logout"];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell.textLabel.text = self.options[indexPath.row];
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.options count];
}

#pragma mark- Helper
- (void)showMessage:(NSString *)message {
    if (!message.length) return;
    
    if (NSClassFromString(@"UIAlertController")) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Tips"
                                                                                 message:message
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
        [alertController addAction:cancelAction];
        [self presentViewController:alertController animated:YES completion:nil];
    } else {
        UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"Title"
                                                           message:message
                                                          delegate:self
                                                 cancelButtonTitle:@"OK"
                                                 otherButtonTitles:nil];
        [theAlert show];
    }
}

NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

-(NSString *) randomStringWithLength: (int) len {
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform((int)[letters length])]];
    }
    
    return randomString;
}

@end
