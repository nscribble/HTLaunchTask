//
//  HTViewController.m
//  HTLaunchTask
//
//  Created by Jason on 2022/09/24.
//

#import "HTViewController.h"

@interface HTViewController ()

@end

@implementation HTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    UIButton *button = [[UIButton alloc] init];
    [button setTitle:@"按钮" forState:UIControlStateNormal];
    [button setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    [button setTitleColor:UIColor.grayColor forState:UIControlStateHighlighted];
    button.frame = CGRectMake(100, 100, 240, 120);
    [self.view addSubview:button];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
