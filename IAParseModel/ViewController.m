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
#import <YYModel.h>

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
    
    
}

- (NSDictionary *)getDic {
    return @{@"n1":@"19",
             @"testArr":@[@"1",@"2"],
             @"ii":@10,
             @"point":@"13",
             @"name":@"Alter",
             @"age":@28,
             @"array":@[@{@"name":@"Jack1",@"subtype":@11},@{@"name":@"Jack2",@"subtype":@12}],// subModel
             @"model":@{@"name":@"Jack",@"subtype":@1},
             @"dic":@{@"key":@"value"},
             @"num":@100000,
             @"ID":@"10086",
             @"sub":@{@"name":@"9.Ca",@"subtype":@100}
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

- (IBAction)actionForDo:(id)sender {
    
//    TestModel *test = [[TestModel alloc] init];
//    [test ia_parseForm:[self getDic]];
    TestModel *test = [TestModel ia_parseFrom:[self getDic]];
//    test.rect = CGRectMake(20, 30, 80, 80);
    test.array = @[@1,@2];
    NSLog(@"%@",test.debugIvarsDescription);
    
    return;
    
//    int p = 20;
//    test.point = &p;
//    test.date =[NSDate date];
    
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    //完整的文件路径
    NSString *path = [docPath stringByAppendingPathComponent:@"archiver.archiver"];
//    NSError *error = nil;
//    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:test requiringSecureCoding:NO error:&error];
    BOOL success = [NSKeyedArchiver archiveRootObject:test toFile:path];
    NSLog(@"%d",success);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        TestModel *model = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
        NSLog(@"%@",model.debugIvarsDescription);
        
//        NSError *err = nil;
//        TestModel *model1 = [NSKeyedUnarchiver unarchivedObjectOfClass:TestModel.class fromData:data error:&err];
//        NSLog(@"%@",model1);
    });
    
//    id str = [test ia_parseToJSONModel];
//    NSLog(@"%@",str);
    
//    CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
//    for (int i = 0; i < 10000; i++) {
//       id str = [test ia_parseToJSONModel];
//    }
//    CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
//    NSLog(@"=========1:%f", end - start);
//
//    CFAbsoluteTime start1 = CFAbsoluteTimeGetCurrent();
//    for (int i = 0; i < 10000; i++) {
//        id str1 =[test yy_modelToJSONObject];
//    }
//    CFAbsoluteTime end1 = CFAbsoluteTimeGetCurrent();
//    NSLog(@"=========2:%f", end1 - start1);
    
}
@end
