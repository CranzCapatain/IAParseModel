//
//  ViewController.m
//  IAParseModel
//
//  Created by 金峰 on 2018/8/18.
//  Copyright © 2018年 IA.Alter.com. All rights reserved.
//

#import "ViewController.h"
#import "TestModel.h"
#import "NSObject+IAParse.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // json -> model
//    TestModel *model = [[TestModel alloc] init];
//    [model setModelWithJson:[self getDic]];
//    NSLog(@"%@",[model propertysDescription]);
//
//    // model -> json
//    NSString *json = [model toJson];
//    NSLog(@"%@",json);
    
    
    [self testParse:TestModel.class];
    
}

- (NSDictionary *)getDic {
    return @{@"name":@"Alter",
             @"age":@18,
             @"subs":@[@{@"name":@"model1",
                        @"subtype":@100
                        },
                      @{@"name":@"model2",
                        @"subtype":@200}],
             @"id":@"10086"
             };
}

//- (TestModel *)getModel {
//    SubModel *sub1 = [[SubModel alloc] init];
//    sub1.name = @"sub1";
//    sub1.subtype = 1;
//    SubModel *sub2 = [[SubModel alloc] init];
//    sub2.name = @"sub2";
//    sub2.subtype = 2;
//    
//    
////    TestModel *model = [[TestModel alloc] init];
////    model.name = @"model";
////    model.age = 10;
////    model.array = @[sub1, sub2];
//    
//    return model;
//}

@end
