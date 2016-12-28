//
//  HJDataCenter_tests.m
//  Hejiajinrong+
//
//  Created by HeJia on 16/5/6.
//  Copyright © 2016年 HeJia. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "HJDataInterface.h"

@interface HJDataInterface_tests : XCTestCase

@end

@implementation HJDataInterface_tests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

-(void) testDownLoadFile{
    XCTestExpectation * expectation = [self expectationWithDescription:@"test downloadFile,should pass"];
    RequestParam* param = [RequestParam new];
    param.url = @"http://www.baidu.com/img/bdlogo.png";
    param.type = CACHE_NONE;
    param.cmd = @"downLoadFile";
    NSURL* tmpFileurl = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"8a28b6eb54615d3d01547fad3c940067.png"]];
    
    DownloadFile(param, [tmpFileurl absoluteString], ^(NSProgress *progress) {
        NSLog(@"progress:%lld/%lld",progress.completedUnitCount,progress.totalUnitCount);
    }, ^(NSURL *filePath) {
        UIImage *img = [UIImage imageWithContentsOfFile:filePath.path];
        NSLog(@"%@",img);
        [expectation fulfill];
    }, ^(RequestResult *result) {
        NSLog(@"%@",result.errmsg);
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        //Do something when time out
    }];
}


-(void) testUploadImage{
    XCTestExpectation * expectation = [self expectationWithDescription:@"test downloadFile,should pass"];
    RequestParam* param = [RequestParam new];
    param.url = @"http://toulema.net/upload_test/upload.php";
    param.type = CACHE_NONE;
    param.cmd = @"downLoadFile";
    UIImage* img = [UIImage imageNamed:@"ball1"];
    
    UploadImage(param, img, ^(NSProgress *progress){
        NSLog(@"progress:%lld/%lld",progress.completedUnitCount,progress.totalUnitCount);
    }, ^{
        NSLog(@"Success");
        [expectation fulfill];
    }, ^(RequestResult *result) {
        NSLog(@"%@",result.errmsg);
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        //Do something when time out
    }];
}

-(void) testSingleDataRequest{
    XCTestExpectation * expectation = [self expectationWithDescription:@"test downloadFile,should pass"];
    RequestParam* param = [RequestParam new];
    param.url = @"http://fenxiao.toulema.net:9905/mwz?cmd=get_initinfos";
    param.type = CACHE_SINGLE;
    param.cmd = @"get_initinfos";
    [param.param setValue:[NSNumber numberWithInt:0] forKey:@"ostype"];
    
    GetData(param, nil, ^(id jsonData) {
        NSLog(@"local: %@",jsonData);
    }, ^(id jsonData, RequestResult *result) {
        NSLog(@"JsonData:%@   result:%d",jsonData,result.errcode);
    }, ^(RequestResult *result) {
        NSLog(@"%@",result.errmsg);
    });
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        sleep(5);
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        //Do something when time out
    }];
}


- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
