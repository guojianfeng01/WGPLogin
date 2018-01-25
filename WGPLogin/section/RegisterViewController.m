//
//  RegisterViewController.m
//  ManaLoan
//
//  Created by xiongfei on 2017/3/10.
//  Copyright © 2017年 xiongfei. All rights reserved.
//

#import "RegisterViewController.h"
#import "MNTextField.h"
#import "RegisterVerificationViewController.h"
#import "MNAuthcodeView.h"
#import "MNDevice.h"
#import "MNUtilities.h"
#import "ManaDataManger.h"
#import "MNWebViewController.h"

@interface RegisterViewController ()<UITextFieldDelegate,UIGestureRecognizerDelegate> {
    NSString *_codeString;
}
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIView *phoneView;
@property (nonatomic, strong) UIImageView *phoneImageView;
@property (nonatomic, strong) TextFieldForInset *phoneTextField;
@property (nonatomic, strong) UIView *passwordView;
@property (nonatomic, strong) UIImageView *passwordImageView;
@property (nonatomic, strong) TextFieldForInset *passwordTextField;
@property (nonatomic, strong) UIButton *hideButton;
@property (nonatomic, strong) UIButton *displayButton;
@property (nonatomic, strong) UIView *codeView;
@property (nonatomic, strong) UIImageView *codeImageView;
@property (nonatomic, strong) TextFieldForInset *codeTextField;
@property (nonatomic, strong) MNAuthcodeView *authCodeView;

@property (nonatomic, strong) UIButton *resButton;
@property (nonatomic, strong) UIButton *userAgreementButton;
@property (nonatomic, strong) UIButton *backLoginButton;

@end

@implementation RegisterViewController

- (void)dealloc {

}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"注册";
    [self makeConstraints];
    [self monitorKeyboard];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)];
    tapGesture.cancelsTouchesInView = NO;
    tapGesture.delegate = self;
    [self.view addGestureRecognizer:tapGesture];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//共有方法
#pragma mark - public methods

//私有方法
#pragma mark - private methods
- (void)monitorKeyboard {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)note {
    CGFloat keyboardH = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    CGFloat value =    [[note.userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue] .size.height;
    if (value>0 && self.codeTextField.secureTextEntry == YES) {
        //不让换键盘的textField的
        self.codeTextField.secureTextEntry = NO;
    }
    BOOL is320 = [MNDevice isWidth320];
    BOOL is375 = [MNDevice isWidth375];
    BOOL is621 = [MNDevice isWidth414];
    CGFloat height = 0.0;
    if (is320 == YES) {
        height = -keyboardH/2 + 200;
    }
    if (is375 == YES) {
        height = -keyboardH/2 + 170;
    }
    if (is621 == YES) {
        height = -keyboardH/2 + 180;
    }
    self.view.frame = CGRectMake(0, -height, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame));
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

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isKindOfClass:[UIButton class]] || [touch.view isKindOfClass:[TextFieldForInset class]]) {
        return NO;
    }
    return YES;
}

- (void)checkPhoneNumber:(UITextField *)tf {
    
}

- (void)checkPassword:(UITextField *)tf {
    
}

-(void)checkCode:(UITextField *)tf {

}

- (void)hidePassword:(UIButton *)btn {
    if (btn.selected == NO) {
        self.passwordTextField.secureTextEntry = NO;
        [self.hideButton setBackgroundImage:[UIImage imageNamed:@"password_show_icon"] forState:UIControlStateNormal];
        btn.selected = YES;
    } else {
        self.passwordTextField.secureTextEntry = YES;
        [self.hideButton setBackgroundImage:[UIImage imageNamed:@"password_conceal_icon"] forState:UIControlStateNormal];
        btn.selected = NO;
    }
}

-(void)displayPassword:(UIButton *)btn {

}

- (void)registerClick:(UIButton *)btn {
    if (self.phoneTextField.text.length == 0) {
        [self showError:@"请输入手机号"];
        return;
    }
    
    if ([MNUtilities isValidateMobile:self.phoneTextField.text] == NO) {
        [self showError:@"请输入正确的手机号"];
        return;
    }
    
    if (self.passwordTextField.text.length == 0) {
        [self showError:@"请输入密码"];
        return;
    }
    if (self.passwordTextField.text.length <= 7) {
        [self showError:@"请输入符合规则的密码"];
        return;
    }

    if (self.codeTextField.text.length == 0) {
        [self showError:@"请输入验证码"];
        return;
    }
    BOOL result = [self.codeTextField.text caseInsensitiveCompare:_codeString] == NSOrderedSame;
    if (result == NO) {
        [self showError:@"请输入正确的验证码"];
        return;
    }
    __weak typeof(self) weakSelf = self;
    [[ManaUserManger shareInatance] fetchUserWithMobile:self.phoneTextField.text completeBlock:^(id response, MNResult *result) {
        if (result.success) {
            BOOL user_existence = [[response objectForKey:@"user_existence"] boolValue];
            if (user_existence == YES) {
                [self showError:@"该手机号已经被注册"];
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[ManaDataManger shareInstance] sendValidationCode:self.phoneTextField.text type:@"register_user" completeBlock:^(id response, MNResult *result) {
                        if (result.success) {
                            NSRange range = NSMakeRange(self.phoneTextField.text.length - 4, 4);
                            NSString *str = [self.phoneTextField.text substringWithRange:range];
                            NSString *s = [NSString stringWithFormat:@"验证码已发送至尾号为%@的手机有效期5分钟",str];
                            UIAlertController *alertControl = [UIAlertController alertControllerWithTitle:@"手机验证码已经发送" message:s preferredStyle:UIAlertControllerStyleAlert];
                            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                                RegisterVerificationViewController *vc = [[RegisterVerificationViewController alloc] init];
                                vc.phoneString = weakSelf.phoneTextField.text;
                                vc.password = weakSelf.passwordTextField.text;
                                vc.code = response;
                                [weakSelf.navigationController pushViewController:vc animated:YES];
                            }];
                            [alertControl addAction:okAction];
                            [weakSelf presentViewController:alertControl animated:YES completion:nil];
                        } else {
                            [weakSelf showError:result.resultError.message];
                        }
                    }];
                });
            }
        }
    }];
}

- (void)backLoginButtonClick:(UIButton *)btn {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)userAgreementButtonClick:(UIButton *)btn {
    MNWebViewController *vc = [[MNWebViewController alloc] initWithURLString:kRegiserH5];
    vc.title = @"用户注册协议";
    [self.navigationController pushViewController:vc animated:YES];
}

//UI配置
#pragma mark configure
- (void)makeConstraints {
    
    BOOL is320 = [MNDevice isWidth320];
    if (is320) {
        [self.headerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.right.equalTo(self.view);
            make.height.mas_equalTo(130);
        }];
    } else {
        [self.headerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.right.equalTo(self.view);
            make.height.mas_equalTo(170);
        }];
    }
    
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
    
    [self.passwordTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.passwordView).offset(12);
        make.left.equalTo(self.passwordView.mas_left).offset(55);
        make.right.equalTo(self.passwordView).offset(-30);
        make.bottom.equalTo(self.passwordView.mas_bottom).offset(-12);
    }];
    
    [self.codeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(40);
        make.right.equalTo(self.view).offset(-40);
        make.top.equalTo(self.passwordView.mas_bottom).offset(20);
        make.height.equalTo(@45);
    }];
    
    [self.authCodeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.bottom.top.equalTo(_codeView);
        make.width.equalTo(@100);
    }];
    
    [self.codeTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.codeView).offset(12);
        make.left.equalTo(self.codeView.mas_left).offset(55);
        make.right.equalTo(self.authCodeView.mas_left).offset(-30);
        make.bottom.equalTo(self.codeView.mas_bottom).offset(-12);
    }];
    
    [self.resButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(40);
        make.right.equalTo(self.view).offset(-40);
        make.top.equalTo(self.codeView.mas_bottom).offset(20);
        make.height.equalTo(@45);
    }];
    
    [self.userAgreementButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.resButton.mas_bottom).offset(10);
        make.left.right.equalTo(self.view);
        make.height.equalTo(@20);
    }];
    
    [self.backLoginButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.userAgreementButton.mas_bottom).offset(10);
        make.left.equalTo(self.view).offset(60);
        make.right.equalTo(self.view).offset(-60);
        make.height.equalTo(@30);
    }];
}
//数据请求
#pragma mark data

#pragma mark - Custom Delegate

#pragma mark - System Delegate
//-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
//    //得到输入框的内容
//    NSString * textfieldContent = [textField.text stringByReplacingCharactersInRange:range withString:string];
//    if (textField == self.passwordTextField && textField.isSecureTextEntry ) {
//        textField.text = textfieldContent;
//        return NO;
//    }
//    return YES;
//}
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    //判断一下，哪个是不让换键盘的textField
    if (textField == self.codeTextField) {
        self.codeTextField.secureTextEntry = YES;
    }
    
    if (textField == self.phoneTextField) {
        self.phoneView.layer.borderColor = [UIColor colorWithHex:0x2491FF].CGColor;
        self.phoneImageView.image = [UIImage imageNamed:@"login_phone_icon_b"];
        
        self.passwordView.layer.borderColor = [UIColor colorWithHex:0xA8A8A8].CGColor;
        self.passwordImageView.image = [UIImage imageNamed:@"login_password_icon_g"];
        
        self.codeView.layer.borderColor = [UIColor colorWithHex:0xA8A8A8].CGColor;
        self.codeImageView.image = [UIImage imageNamed:@"login_captcha_icon_g"];
        
        
    } else if (textField == self.passwordTextField)  {
        
        self.phoneView.layer.borderColor = [UIColor colorWithHex:0xA8A8A8].CGColor;
        self.phoneImageView.image = [UIImage imageNamed:@"login_phone_icon_g"];
        
        self.passwordView.layer.borderColor = [UIColor colorWithHex:0x2491FF].CGColor;
        self.passwordImageView.image = [UIImage imageNamed:@"login_password_icon_b"];
        
        self.codeView.layer.borderColor = [UIColor colorWithHex:0xA8A8A8].CGColor;
        self.codeImageView.image = [UIImage imageNamed:@"login_captcha_icon_g"];
        
    } else {
        self.phoneView.layer.borderColor = [UIColor colorWithHex:0xA8A8A8].CGColor;
        self.phoneImageView.image = [UIImage imageNamed:@"login_phone_icon_g"];
        
        self.passwordView.layer.borderColor = [UIColor colorWithHex:0xA8A8A8].CGColor;
        self.passwordImageView.image = [UIImage imageNamed:@"login_password_icon_g"];
        
        self.codeView.layer.borderColor = [UIColor colorWithHex:0x2491FF].CGColor;
        self.codeImageView.image = [UIImage imageNamed:@"login_captcha_icon_b"];
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
        
        _hideButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_hideButton addTarget:self action:@selector(hidePassword:) forControlEvents:UIControlEventTouchUpInside];
        [_hideButton setBackgroundImage:[UIImage imageNamed:@"password_conceal_icon"] forState:UIControlStateNormal];
        [_passwordView addSubview:_hideButton];
        [_hideButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_passwordView).offset(15);
            make.right.equalTo(_passwordView.mas_right).offset(-10);
            make.size.mas_equalTo(CGSizeMake(20, 20));
        }];
    }
    return _passwordView;
}

- (TextFieldForInset *)phoneTextField {
    if (!_phoneTextField) {
        _phoneTextField = [[TextFieldForInset alloc] init];
        _phoneTextField.placeholder = @"请输入您的手机号码";
        _phoneTextField.font = kFont_14;
        _phoneTextField.keyboardType = UIKeyboardTypeNumberPad;
        _phoneTextField.delegate = self;
        [_phoneTextField addTarget:self action:@selector(checkPhoneNumber:) forControlEvents:UIControlEventEditingChanged];
        [_phoneView addSubview:_phoneTextField];
    }
    return _phoneTextField;
}

- (TextFieldForInset *)passwordTextField {
    if (!_passwordTextField) {
        _passwordTextField = [[TextFieldForInset alloc] init];
        _passwordTextField.placeholder = @"请输入您的密码(不小于8位)";
        _passwordTextField.font = kFont_14;
        _passwordTextField.delegate = self;
        _passwordTextField.secureTextEntry = YES;
        _passwordTextField.clearsOnBeginEditing = NO;
        _passwordTextField.keyboardType = UIKeyboardTypeASCIICapable;
        [_passwordTextField addTarget:self action:@selector(checkPassword:) forControlEvents:UIControlEventEditingChanged];
        [_passwordView addSubview:_passwordTextField];
    }
    return _passwordTextField;
}

- (UIView *)codeView {
    if (!_codeView) {
        _codeView = [[UIView alloc] init];
        _codeView.layer.masksToBounds = YES;
        _codeView.layer.cornerRadius = 5;
        _codeView.layer.borderColor = [UIColor colorWithHex:0xA8A8A8].CGColor;
        _codeView.layer.borderWidth = 0.5;
        [self.view addSubview:_codeView];
        
        _codeImageView = [[UIImageView alloc] init];
        _codeImageView.image = [UIImage imageNamed:@"login_captcha_icon_g"];
        [_codeView addSubview:_codeImageView];
        [_codeImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_codeView.mas_left).offset(20);
            make.size.mas_equalTo(CGSizeMake(20, 20));
            make.centerY.equalTo(_codeView.mas_centerY);
        }];
        
        _authCodeView = [[MNAuthcodeView alloc] initWithFrame:CGRectMake(30, 100, self.view.frame.size.width-60, 40) authcodeBlock:^(NSString *string) {
            _codeString = string;
        }];
        [_codeView addSubview:_authCodeView];
        
    }
    return _codeView;
}

- (TextFieldForInset *)codeTextField {
    if (!_codeTextField) {
        _codeTextField = [[TextFieldForInset alloc] init];
        _codeTextField.placeholder = @"请输入验证码";
        _codeTextField.font = kFont_14;
        _codeTextField.delegate = self;
        _codeTextField.secureTextEntry = NO;
        _codeTextField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
        [_codeTextField addTarget:self action:@selector(checkCode:) forControlEvents:UIControlEventEditingChanged];
        [_codeView addSubview:_codeTextField];
    }
    return _codeTextField;
}

- (UIButton *)resButton {
    if (!_resButton) {
        _resButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _resButton.backgroundColor = [UIColor colorWithHex:0x2491FF];
        _resButton.layer.cornerRadius = 5;
        _resButton.titleLabel.font = [UIFont systemFontOfSize:18];
        [_resButton addTarget:self action:@selector(registerClick:) forControlEvents:UIControlEventTouchUpInside];
        [_resButton setTitle:@"注  册" forState:UIControlStateNormal];
        [self.view addSubview:_resButton];
    }
    return _resButton;
}

- (UIButton *)userAgreementButton {
    if (!_userAgreementButton) {
        _userAgreementButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _userAgreementButton.titleLabel.font = [UIFont systemFontOfSize:15];
        [_userAgreementButton addTarget:self action:@selector(userAgreementButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_userAgreementButton];
        
        UILabel *label = [UILabel labelWithTitle:@"同意《用户注册及服务协议》" mainFont:kFont_10 mainColor:[UIColor colorWithHex:0x2491FF] Range:NSMakeRange(0, 2) font:kFont_10 color:[UIColor colorWithHex:0xA8A8A8]];
        label.textAlignment = NSTextAlignmentCenter;
        [self.view addSubview:label];
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.right.bottom.equalTo(_userAgreementButton);
        }];
        
        
    }
    return _userAgreementButton;
}


- (UIButton *)backLoginButton {
    if (!_backLoginButton) {
        _backLoginButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _backLoginButton.titleLabel.font = [UIFont systemFontOfSize:15];
        [_backLoginButton addTarget:self action:@selector(backLoginButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_backLoginButton];
        
        UILabel *label = [UILabel createLineLabelWithTitle:@"已有账号去登录" titleFont:kFont_16 titleColor:[UIColor colorWithHex:0x2491FF] textAlignment:NSTextAlignmentCenter];
        [self.view addSubview:label];
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.right.bottom.equalTo(_backLoginButton);
        }];
    }
    return _backLoginButton;
}

#pragma mark - setter

@end
