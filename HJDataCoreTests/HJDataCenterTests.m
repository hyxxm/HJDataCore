//
//  HJDataCenter_Tests.m
//  Hejiajinrong+
//
//  Created by HeJia on 16/5/7.
//  Copyright © 2016年 HeJia. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "HJDataCenter.h"

@interface HJDataCenter_Tests : XCTestCase{
    GlobalDataCenter* _dataCenter;
    //    NSArray* _aryRequestlist;
    //    NSArray* _aryTableRequestList;
}

@end

@implementation HJDataCenter_Tests

static inline RequestParam* createTableRequest(short pageIdx){
    RequestParam* param = [RequestParam new];
    param.url = @"http://fenxiao.toulema.net:9905/mwz?cmd=get_wzlist";
    param.type = CACHE_MULTI;
    param.cmd = [NSString stringWithFormat:@"get_wzlist"];
    [param.param setValue:[NSNumber numberWithInteger:1] forKey:@"typeid"];
    [param.param setValue:[NSNumber numberWithShort:pageIdx] forKey:@"pageidx"];
    [param.param setValue:[NSNumber numberWithInt:2] forKey:@"count"];
    return param;
}

static inline RequestParam* initRequest(){
    RequestParam* initParam = [RequestParam new];
    initParam.url = @"http://fenxiao.toulema.net:9905/mwz?cmd=get_initinfos";
    initParam.type = CACHE_SINGLE;
    initParam.cmd = @"get_initinfos";
    [initParam.param setValue:[NSNumber numberWithInt:0] forKey:@"ostype"];
    return initParam;
}

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    //!启动测试前先删除本地数据
    _dataCenter = [GlobalDataCenter sharedGlobalDataCenter];
    [_dataCenter clearLocalCache];
}




- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

-(void) _execRequestArray:(NSArray*) aryRequest{
    for(RequestParam* param in aryRequest){
        XCTestExpectation * expectation = [self expectationWithDescription:@"test request,should pass"];
        [_dataCenter sendAsynPostRequest:param ParseData:nil LocalResp:^(id jsonData) {
        } NetResp:^(id jsonData, RequestResult *result) {
            [expectation fulfill];
        } Error:^(RequestResult *result) {
            [expectation fulfill];
        }];
    }
}


/**
 *  测试单个请求
 *  1.发送单挑数据
 *  2.检验数据返回是否相应
 */
-(void) testSingleDataRequest{
    XCTestExpectation * expectation = [self expectationWithDescription:@"test downloadFile,should pass"];
    RequestParam* param = initRequest();
    
    [_dataCenter sendAsynPostRequest:param ParseData:nil LocalResp:^(id jsonData) {
        NSLog(@"local: %@",jsonData);
    } NetResp:^(id jsonData, RequestResult *result) {
        NSLog(@"JsonData:%@   result:%d",jsonData,result.errcode);
    } Error:^(RequestResult *result) {
        NSLog(@"%@",result.errmsg);
    }];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        sleep(5);
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        //Do something when time out
        
    }];
}


/**
 *  测试列表类型数据请求返回
 *  1.请求列表数据，检验请求是否返回
 *  2.数据返回后，检验本地缓存数目及key是否对应
 *  3.发送一条列表数据请求，检验请求是否返回
 *  4.数据返回后，测试本地数据数目是否为一条
 */
-(void) testMultiDataRequest{
    //!先读取列表数据
    NSArray* ary = @[createTableRequest(1),createTableRequest(2),createTableRequest(3)];
    [self _execRequestArray:ary];
    
    //!检验列表数据是否已经全部缓存
    XCTestExpectation * checkCache = [self expectationWithDescription:@"check Cache,should pass"];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        sleep(2);
        bool isAllCacheWrited = NO;
        while (!isAllCacheWrited) {
            for(RequestParam* param in ary){
                if(param.type == CACHE_NONE){
                    continue;
                }
                
                id data = [_dataCenter localCacheData:param];
                if(data != nil) isAllCacheWrited = YES;
                else{
                    isAllCacheWrited = NO;
                    break;
                }
            }
            sleep(1);
        }
        [checkCache fulfill];
    });
    
    //!延时加载列表第一页数据
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 2*NSEC_PER_SEC);
    XCTestExpectation * expectation = [self expectationWithDescription:@"test request,should pass"];
    dispatch_after(time, dispatch_get_main_queue(), ^{
        [_dataCenter sendAsynPostRequest:createTableRequest(1) ParseData:nil LocalResp:^(id jsonData) {
        } NetResp:^(id jsonData, RequestResult *result) {
            [expectation fulfill];
        } Error:^(RequestResult *result) {
            [expectation fulfill];
        }];
    });
    
    //! 检验数据库缓存是否更新了除第一页数据，删除了之后的数据
    XCTestExpectation * checkCache2 = [self expectationWithDescription:@"check Cache,should pass"];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        sleep(3);
        while (_dataCenter.localCacheCount != 1) {
            sleep(1);
        }
        [checkCache2 fulfill];
        NSLog(@"DataCache is Updated: dataCache Count = %d , _aryCount = %d",[_dataCenter localCacheCount],ary.count);
    });
    [self waitForExpectationsWithTimeout:60 handler:^(NSError *error) {
        //Do something when time out
    }];
}

/**
 *  测试连续数据请求返回
 *  1.发送若干条数据
 *  2.检验数据是否全部返回
 */
-(void) testSeriesRequest{
    NSArray* ary = @[initRequest(),createTableRequest(1),createTableRequest(2),createTableRequest(3)];
    [self _execRequestArray:ary];
    
    XCTestExpectation * checkCache = [self expectationWithDescription:@"check Cache,should pass"];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        sleep(2);
        bool isAllCacheWrited = NO;
        while (!isAllCacheWrited) {
            for(RequestParam* param in ary){
                if(param.type == CACHE_NONE){
                    continue;
                }
                
                id data = [_dataCenter localCacheData:param];
                if(data != nil) isAllCacheWrited = YES;
                else{
                    isAllCacheWrited = NO;
                    break;
                }
            }
            NSLog(@"dataCache Count = %d , _aryCount = %d",[_dataCenter localCacheCount],ary.count);
            sleep(1);
        }
        NSLog(@"success :request is All write to local: Count = %d , _aryCount = %d",[_dataCenter localCacheCount],ary.count);
        [checkCache fulfill];
    });
    
    [self waitForExpectationsWithTimeout:60 handler:^(NSError *error) {
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
