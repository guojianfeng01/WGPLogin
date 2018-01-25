//
//  MNLoginViewController.h
//  ManaLoan
//
//  Created by xiongfei on 2017/3/10.
//  Copyright © 2017年 xiongfei. All rights reserved.
//

#import "ViewController.h"
#import "MNTabbarController.h"
@interface MNLoginViewController : ViewController
@property (nonatomic, strong) void(^LoginSuccess)(void);
@end
