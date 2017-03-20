//
//  ViewController.m
//  test_HotUpdate
//
//  Created by hejiahuan on 2017/1/5.
//  Copyright © 2017年 hejiahuan. All rights reserved.
//

#import "ViewController.h"
#import "HJDataInterface.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    GetDataWithID(nil, nil, nil, nil, nil, self);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
