//
//  MNLoginViewController.m
//  ManaLoan
//
//  Created by xiongfei on 2017/3/10.
//  Copyright © 2017年 xiongfei. All rights reserved.
//

#import "MNLoginViewController.h"
#import "MNTextField.h"
#import "RegisterViewController.h"
#import "ForgetPasswordViewController.h"
#import "ManaUserManger.h"
#import "MNDataEnvironment.h"
#import "MNDevice.h"
#import "MNDataEnvironment.h"
#import "ManaCacheHelper.h"
#import "ManaUserManger.h"
#import "ManaTimerManger.h"
#import "SentinelSDKHelper.h"

//static NSString *kTestPhone = @"18516522869";// 15901734195
//static NSString *kTestPassword = @"123123";

@interface MNLoginViewController ()<UITextFieldDelegate>
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIView *phoneView;
@property (nonatomic, strong) UIImageView *phoneImageView;
@property (nonatomic, strong) TextFieldForInset *phoneTextField;
@property (nonatomic, strong) UIView *passwordView;
@property (nonatomic, strong) UIImageView *passwordImageView;
@property (nonatomic, strong) TextFieldForInset *passwordTextField;
@property (nonatomic, strong) UIButton *loginButton;
@property (nonatomic, strong) UIButton *resButton;
@property (nonatomic, strong) UIButton *forgotButton;
@property (nonatomic, strong) UIButton *canBtn;

@end

@implementation MNLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"登录";
    [self makeConstraints];
    [self devBackBarButton];
    [self monitorKeyboard];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)];
    tapGesture.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapGesture];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.phoneTextField.text = [ManaUserManger shareInatance].username;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


//共有方法
#pragma mark - public methods
- (void)backItemClickEvent:(id)sender {
    [[MNDataEnvironment sharedInstance].tabbarController setSelectedIndex:0];
    self.tabBarController.selectedIndex = 0;
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)devBackBarButton {
    UIImage *rightImage = [UIImage imageNamed:@"navbar_back"];
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc]initWithImage:rightImage style:UIBarButtonItemStylePlain target:self action:@selector(backItemClickEvent:)];
    self.navigationItem.leftBarButtonItem = rightItem;
}
//私有方法
#pragma mark - private methods
- (void)monitorKeyboard {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)note {
    CGFloat keyboardH = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    BOOL is320 = [MNDevice isWidth320];
    BOOL is375 = [MNDevice isWidth375];
    BOOL is621 = [MNDevice isWidth414];
    CGFloat height = 0.0;
    if (is320 == YES) {
        height = -keyboardH/2 + 20;
    }
    if (is375 == YES) {
        height = -keyboardH/2 + 120;
    }
    if (is621 == YES) {
        height = -keyboardH/2 + 160;
    }
    self.view.frame = CGRectMake(0, height, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame));
}

- (void)keyboardWillHide:(NSNotification *)note {
    [UIView animateWithDuration:0.2 animations:^{
        self.view.frame = CGRectMake(0, 64, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame));
    }];
}

//按钮事件
#pragma mark event Response
-(void)viewTapped:(UITapGestureRecognizer*)tap {
    [self.view endEditing:YES];
}

- (void)checkPhoneNumber:(UITextField *)tf {

}

- (void)checkPassword:(UITextField *)tf {
    
}

- (void)login:(UIButton *)btn {
    if (self.phoneTextField.text.length == 0) {
        [self showError:@"请输入账号"];
        return ;
    }
    if (self.passwordTextField.text.length == 0) {
        [self showError:@"请输入密码"];
        return ;
    }
    [self showLoading];
    __weak typeof(self) weakSelf = self;
    
    [[ManaUserManger shareInatance] fetchUserWithMobile:self.phoneTextField.text completeBlock:^(id response, MNResult *result) {
        if (result.success) {
            BOOL user_existence = [[response objectForKey:@"user_existence"] boolValue];
            if (user_existence == NO) {
                [weakSelf hideLoading];
                [weakSelf showError:@"账号不存在,请更换账号登录或者去注册账号"];
            } else {
                [[ManaUserManger shareInatance] loginWithName:self.phoneTextField.text password:self.passwordTextField.text completeBlock:^(id response, MNResult *result) {
                    [weakSelf hideLoading];
                    if (result.success) {
                        [[ManaTimerManger shareInstance] endTimer];
                        [[ManaUserManger shareInatance] documentUserName:weakSelf.phoneTextField.text];
                        [[MNDataEnvironment sharedInstance].tabbarController showHomeViewController];
                        SentinelUserInfoModel *model = [[SentinelUserInfoModel alloc] initWithDictionary:response[@"applicant"] error:nil];
                        model.eventType = SentinelEventLoginType;
                        [[SentinelSDKHelper shareInstance] postInfoWithSentinelUserInfoModel:model];
                        [[ManaDataManger shareInstance] fetchAllMessageListWithCompleteBlock:nil];
                        if (_LoginSuccess) {
                            _LoginSuccess();
                        }
                    } else {
                        if ([result.resultError.message isEqualToString:@"Could not connect to the server."]) {
                            [self showError:@"登录失败,请检查设备联网情况."];
                        } else {
                            [weakSelf showError:result.resultError.message];
                        }
                    }
                }];
            }
        } else {
            [self hideLoading];
            [self showError:@"登录失败,请重试"];
        }
    }];
}

- (void)registerClick:(UIButton *)btn {
    RegisterViewController *vc = [[RegisterViewController alloc] init];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)forgotClick:(UIButton *)btn {
    ForgetPasswordViewController *vc = [[ForgetPasswordViewController alloc] init];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)removeText {
    self.phoneTextField.text = @"";
    self.canBtn.hidden = YES;
}
//UI配置
#pragma mark configure
- (void)makeConstraints {
    [self.headerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.height.mas_equalTo(170);
    }];
    
    [self.phoneView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(40);
        make.right.equalTo(self.view).offset(-40);
        make.top.equalTo(self.headerView.mas_bottom).offset(30);
        make.height.equalTo(@45);
    }];
    
    [self.passwordView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(40);
        make.right.equalTo(self.view).offset(-40);
        make.top.equalTo(self.phoneView.mas_bottom).offset(20);
        make.height.equalTo(@45);
    }];
    
    [self.phoneTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.phoneView).offset(12);
        make.left.equalTo(self.phoneView.mas_left).offset(55);
        make.right.equalTo(self.phoneView).offset(-30);
        make.bottom.equalTo(self.phoneView.mas_bottom).offset(-12);
    }];
    
    [self.canBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.phoneTextField.mas_right).offset(-10);
        make.centerY.equalTo(self.phoneTextField.mas_centerY);
        make.width.height.equalTo(@20);
    }];
    self.canBtn.hidden = YES;

    [self.passwordTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.passwordView).offset(12);
        make.left.equalTo(self.passwordView.mas_left).offset(55);
        make.right.equalTo(self.passwordView).offset(-30);
        make.bottom.equalTo(self.passwordView.mas_bottom).offset(-12);
    }];
    
    [self.loginButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(40);
        make.right.equalTo(self.view).offset(-40);
        make.top.equalTo(self.passwordView.mas_bottom).offset(20);
        make.height.equalTo(@45);
    }];

    [self.resButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.loginButton.mas_bottom).offset(20);
        make.left.equalTo(self.view).offset(40);
        make.height.equalTo(@30);
        make.width.equalTo(@100);
    }];
    
    [self.forgotButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.loginButton.mas_bottom).offset(20);
        make.right.equalTo(self.view).offset(-40);
        make.height.equalTo(@30);
        make.width.equalTo(@100);
    }];

}
//数据请求
#pragma mark data

#pragma mark - Custom Delegate

#pragma mark - System Delegate
-(void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField == self.phoneTextField) {
        self.phoneView.layer.borderColor = [UIColor colorWithHex:0x2491FF].CGColor;
        self.phoneImageView.image = [UIImage imageNamed:@"login_phone_icon_b"];

        self.passwordView.layer.borderColor = [UIColor colorWithHex:0xA8A8A8].CGColor;
        self.passwordImageView.image = [UIImage imageNamed:@"login_password_icon_g"];
        if (self.phoneTextField.text.length == 0) {
            self.canBtn.hidden = YES;
        } else {
            self.canBtn.hidden = NO;
        }
    } else {
    
        self.phoneView.layer.borderColor = [UIColor colorWithHex:0xA8A8A8].CGColor;
        self.phoneImageView.image = [UIImage imageNamed:@"login_phone_icon_g"];
        
        self.passwordView.layer.borderColor = [UIColor colorWithHex:0x2491FF].CGColor;
        self.passwordImageView.image = [UIImage imageNamed:@"login_password_icon_b"];
    }
}
#pragma mark - getter
-(UIView *)headerView {
    if (!_headerView) {
        _headerView = [[UIView alloc] init];
        _headerView.backgroundColor = [UIColor colorWithHex:0x2491FF];
        [self.view addSubview:_headerView];
        
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.image = [UIImage imageNamed:@"logo_heying"];
        [_headerView addSubview:imageView];
        [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(_headerView.mas_centerX);
            make.size.mas_equalTo(CGSizeMake(120, 105));
            make.centerY.equalTo(_headerView.mas_centerY).offset(-10);
        }];
        
       UILabel * detailLabel = [[UILabel alloc]init];
        detailLabel.font = kFont_14;
        [detailLabel setTextColor:[UIColor whiteColor]];
        [detailLabel setText:@""];
        detailLabel.textAlignment = NSTextAlignmentCenter;
        [_headerView addSubview:detailLabel];
        [detailLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(imageView.mas_bottom).offset(5);
            make.left.right.equalTo(_headerView);
            make.height.equalTo(@30);
        }];
    }
    return _headerView;
}

- (UIView *)phoneView {
    if (!_phoneView) {
        _phoneView = [[UIView alloc] init];
        _phoneView.layer.masksToBounds = YES;
        _phoneView.layer.cornerRadius = 5;
        _phoneView.layer.borderColor = [UIColor colorWithHex:0xA8A8A8].CGColor;
        _phoneView.layer.borderWidth = 0.5;
        [self.view addSubview:_phoneView];
        
        _phoneImageView = [[UIImageView alloc] init];
        _phoneImageView.image = [UIImage imageNamed:@"login_phone_icon_g"];
        [_phoneView addSubview:_phoneImageView];
        [_phoneImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_phoneView.mas_left).offset(20);
            make.size.mas_equalTo(CGSizeMake(20, 20));
            make.centerY.equalTo(_phoneView.mas_centerY);
        }];

    }
    return _phoneView;
}

- (UIView *)passwordView {
    if (!_passwordView) {
        _passwordView = [[UIView alloc] init];
        _passwordView.layer.masksToBounds = YES;
        _passwordView.layer.cornerRadius = 5;
        _passwordView.layer.borderColor = [UIColor colorWithHex:0xA8A8A8].CGColor;
        _passwordView.layer.borderWidth = 0.5;
        [self.view addSubview:_passwordView];
        
        _passwordImageView = [[UIImageView alloc] init];
        _passwordImageView.image = [UIImage imageNamed:@"login_password_icon_g"];
        [_passwordView addSubview:_passwordImageView];
        [_passwordImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_passwordView.mas_left).offset(20);
            make.size.mas_equalTo(CGSizeMake(20, 20));
            make.centerY.equalTo(_passwordView.mas_centerY);
        }];

    }
    return _passwordView;
}

- (TextFieldForInset *)phoneTextField {
    if (!_phoneTextField) {
        _phoneTextField = [[TextFieldForInset alloc] init];
        _phoneTextField.placeholder = @"请输入您的手机号码";
        _phoneTextField.font = kFont_14;
        _phoneTextField.delegate = self;
//        _phoneTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
        _phoneTextField.keyboardType = UIKeyboardTypeNumberPad;
        [_phoneTextField addTarget:self action:@selector(checkPhoneNumber:) forControlEvents:UIControlEventEditingChanged];
        [_phoneView addSubview:_phoneTextField];
    }
    return _phoneTextField;
}

-(UIButton *)canBtn {
    if (!_canBtn) {
        _canBtn = [[UIButton alloc] init];
        [_canBtn setBackgroundImage:[UIImage imageNamed:@"cancel _icon"] forState:UIControlStateNormal];
        [_canBtn addTarget:self action:@selector(removeText) forControlEvents:UIControlEventTouchUpInside];
        [_phoneView addSubview:_canBtn];
    }
    return _canBtn;
}

- (TextFieldForInset *)passwordTextField {
    if (!_passwordTextField) {
        _passwordTextField = [[TextFieldForInset alloc] init];
        _passwordTextField.placeholder = @"请输入您的密码";
        _passwordTextField.clearsOnBeginEditing = YES;
        _passwordTextField.font = kFont_14;
        _passwordTextField.delegate = self;
        _passwordTextField.secureTextEntry = YES;
        _passwordTextField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
        [_passwordTextField addTarget:self action:@selector(checkPassword:) forControlEvents:UIControlEventEditingChanged];
        [_passwordView addSubview:_passwordTextField];
    }
    return _passwordTextField;
}

- (UIButton *)loginButton {
    if (!_loginButton) {
        _loginButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _loginButton.backgroundColor = [UIColor colorWithHex:0x2491FF];
        _loginButton.layer.cornerRadius = 5;
        _loginButton.titleLabel.font = [UIFont systemFontOfSize:18];
        [_loginButton addTarget:self action:@selector(login:) forControlEvents:UIControlEventTouchUpInside];
        [_loginButton setTitle:@"登  录" forState:UIControlStateNormal];
        [self.view addSubview:_loginButton];
    }
    return _loginButton;
}

- (UIButton *)resButton {
    if (!_resButton) {
        _resButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _resButton.titleLabel.font = [UIFont systemFontOfSize:15];
        [_resButton addTarget:self action:@selector(registerClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_resButton];

        UILabel *label = [UILabel createLineLabelWithTitle:@"现在去注册" titleFont:kFont_16 titleColor:[UIColor colorWithHex:0x2491FF] textAlignment:NSTextAlignmentLeft];
        [self.view addSubview:label];
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.right.bottom.equalTo(_resButton);
        }];
    }
    return _resButton;
}

- (UIButton *)forgotButton {
    if (!_forgotButton) {
        _forgotButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _forgotButton.titleLabel.font = [UIFont systemFontOfSize:15];
        [_forgotButton addTarget:self action:@selector(forgotClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_forgotButton];
        
        UILabel *label = [UILabel createLineLabelWithTitle:@"忘记密码" titleFont:kFont_16 titleColor:[UIColor colorWithHex:0x2491FF] textAlignment:NSTextAlignmentRight];
        [self.view addSubview:label];
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.right.bottom.equalTo(_forgotButton);
        }];
    }
    return _forgotButton;
}


#pragma mark - setter
@end
