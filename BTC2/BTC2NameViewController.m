//
//  BTC2NameViewController.m
//  BTC2
//
//  Created by Nicholas Asch on 2013-05-18.
//  Copyright (c) 2013 Joakim Fernstad. All rights reserved.
//

#import "BTC2NameViewController.h"

@interface BTC2NameViewController ()
@property (nonatomic, strong) IBOutlet UITextField *nameField;
@property (nonatomic, strong) IBOutlet UIImageView *roboImage;
@end

@implementation BTC2NameViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
