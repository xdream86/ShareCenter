//
//  BSNSCOAuthValidationViewController.m
//  BSNShareCenter
//
//  Created by Jun Xia on 15/5/24.
//
//

#import "BSNSCXAuthValidationViewController.h"
#import "UIView+BSNSCAutoLayout.h"
#import "BSNSCDeclarations.h"

#ifdef ShareCenter
#import "SVProgressHUD.h"
#else
#import <BSNApp/SVProgressHUD.h>
#endif


@interface BSNSCTextBoxCell : UITableViewCell
@property (nonatomic, strong) UITextField *textField;
- (void)configureTextField:(NSString *)text placeholder:(NSString *)placeholder;
@end

@interface BSNSCXAuthValidationViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@end

@implementation BSNSCXAuthValidationViewController

#pragma mark- View Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Login", nil);
    
    [self configureUsernameAndPasswordInputBox];
    [self configureNavagtaionBar];
}

#pragma mark- SubView Configuration
- (void)configureUsernameAndPasswordInputBox {
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.backgroundColor = [UIColor colorWithRed:239.0/255.0 green:239.0/255.0 blue:244.0/255.0 alpha:1.0];
    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [_tableView registerClass:[BSNSCTextBoxCell class] forCellReuseIdentifier:@"Cell"];
    _tableView.tableFooterView = [[UIView alloc] init];
    [self.view addSubview:_tableView];

    [_tableView pinToSuperviewEdges:JRTViewPinAllEdges inset:0.0f];
    
    if ([_tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [_tableView setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([_tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [_tableView setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (void)configureNavagtaionBar {
    UIBarButtonItem * leftButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil)
                                                                        style:UIBarButtonItemStyleBordered
                                                                       target:self
                                                                       action:@selector(cancelAuthorization:)];
    self.navigationItem.leftBarButtonItem = leftButtonItem;
    
    
    UIBarButtonItem * rightButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil)
                                                                         style:UIBarButtonItemStyleBordered
                                                                        target:self
                                                                        action:@selector(confirm:)];
    self.navigationItem.rightBarButtonItem = rightButtonItem;
}

#pragma mark- Action
- (void)cancelAuthorization:(id)sender {
    [self.view endEditing:YES];
    [SVProgressHUD dismiss];
    [self dismissViewControllerAnimated:YES completion:^{
        BLOCK_SAFE_RUN(_cancelAuthorizationBlock);
    }];
}

- (void)confirm:(id)sender {
    [self.view endEditing:YES];
    BSNSCTextBoxCell *row1 = (BSNSCTextBoxCell*)[_tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    BSNSCTextBoxCell *row2 = (BSNSCTextBoxCell*)[_tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    NSString *userName = row1.textField.text;
    NSString *password = row2.textField.text;
    if (userName.length && password.length) {
        [self.view endEditing:YES];
        [SVProgressHUD showWithStatus:NSLocalizedString(@"Logging In...",nil)];
        BLOCK_SAFE_RUN(_submitAuthorizationBlock, userName, password, ^(BOOL success, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!success || error) {
                    [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Login Error", nil)];
                } else {
                    [SVProgressHUD dismiss];
                }
            });
        });
    }
}

#pragma mark- Delegate，DataSource, Callback Method
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    BSNSCTextBoxCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    // Prevent the cell from inheriting the Table View's margin settings
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [cell setPreservesSuperviewLayoutMargins:NO];
    }
    
    // Explictly set your cell's layout margins
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }

    if (indexPath.row == 0) {
        [cell configureTextField:@"" placeholder:NSLocalizedString(@"Account",nil) ];
    } else if (indexPath.row == 1) {
        cell.textField.secureTextEntry = YES;
        [cell configureTextField:@"" placeholder:NSLocalizedString(@"Password", nil)];
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 35;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

#pragma mark - Getter Method
- (AuthorizationResponseBlock)authorizationResponseBlock {
    return ^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!success || error) {
                [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Login Error", nil)];
            } else {
                [SVProgressHUD dismiss];
            }
        });
    };
}

@end

@implementation BSNSCTextBoxCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (!self) {
        return nil;
    }
    
    _textField = [[UITextField alloc] initWithFrame:CGRectZero];
    _textField.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_textField];
    [_textField pinToSuperviewEdges:JRTViewPinLeftEdge inset:16.0f];
    [_textField pinToSuperviewEdges:JRTViewPinTopEdge | JRTViewPinBottomEdge | JRTViewPinRightEdge inset:0.0f];
    _textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    
    return self;
}

- (void)configureTextField:(NSString *)text placeholder:(NSString *)placeholder  {
    _textField.text = text;
    _textField.placeholder = placeholder;
}

@end