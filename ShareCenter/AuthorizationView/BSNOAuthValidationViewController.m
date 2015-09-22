//
//  BSNAuthenticationViewController.m
//  BSNShareCenter
//
//  Created by Jun Xia on 15/5/8.
//
//

#import "BSNOAuthValidationViewController.h"
#import "BSNSCDeclarations.h"
#import "BSNSCError.h"

@interface BSNOAuthValidationViewController () <UIWebViewDelegate>
@property (strong, nonatomic, readwrite) UIWebView *webView;
@end

@implementation BSNOAuthValidationViewController

- (instancetype)initWithAuthorizationType:(BSNSCAuthorizationMethod)autoorizationType {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    return self;
}

#pragma mark- View Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureNavagtaionBar];
    [self configureWebView];
}

- (void)viewDidLayoutSubviews {
    self.webView.frame = self.view.bounds;
    self.webView.scalesPageToFit = YES;
}

#pragma mark- SubView Configuration
- (void)configureNavagtaionBar {
    self.title = NSLocalizedString(@"Login",nil);
    UIBarButtonItem * leftButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil)
                                                                        style:UIBarButtonItemStyleBordered
                                                                       target:self
                                                                       action:@selector(cancelAuthorization:)];
    self.navigationItem.leftBarButtonItem = leftButtonItem;
}

- (void)configureWebView {
    self.webView = [UIWebView new];
    [self.webView stringByEvaluatingJavaScriptFromString:@"document.body.style.zoom = 5.0;"];
    self.webView.backgroundColor = [UIColor whiteColor];
    self.webView.opaque = NO;
    [self.view addSubview:self.webView];
}

- (void)cancelAuthorization:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        BLOCK_SAFE_RUN(_cancelAuthorizationHandler);
    }];
}

@end
