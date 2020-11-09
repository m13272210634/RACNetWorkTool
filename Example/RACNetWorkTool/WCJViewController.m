//
//  WCJViewController.m
//  RACNetWorkTool
//
//  Created by m13272210634 on 05/25/2020.
//  Copyright (c) 2020 m13272210634. All rights reserved.
//

#import "WCJViewController.h"
#import <RACNetWorkTool/RACHttpService.h>
#import "Body.h"
@interface WCJViewController ()

@property(nonatomic, strong)UITextField*feild;


@end

@implementation WCJViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    
    [self.feild.rac_textSignal subscribeNext:^(id x) {
        
    }];

}




@end
