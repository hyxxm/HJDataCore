//
//  HJDataCenter.m
//  Hejiajinrong+
//
//  Created by HeJia on 16/5/3.
//  Copyright © 2016年 HeJia. All rights reserved.
//

#import "HJDataCenter.h"
#import "HJNetWorking.h"
#import "HJPersistence.h"
#import <objc/runtime.h>
#import <CommonCrypto/CommonDigest.h>


#define NET_DRIVER         @"HJAFNetWorking"
#define PERSISTENCE_DRIVER @"HJSQLPersistence"
#define PARAM_SIGN         @"sign"
#define PARAM_RSID         @"rsid"
#define PARAM_CMD          @"cmd"
#define PARAM_TIMESTAMP    @"timestamp"
#define HJSecretKey @"%le&nvhZnEg@bp%oAo9gHA8x^fW8&Qd#kgjxeXbX@d13vmFv!mSkysd!8BW72R6M"

static inline NSString* md5(NSString *from){
    const char *cStr = [from UTF8String];
    unsigned char result[16];
    CC_MD5( cStr, (CC_LONG)strlen(cStr), result );
    return [NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

static inline id dynamicCreate(NSString* className){
    Class class = objc_getClass([className UTF8String]);
    if(class == nil) return nil;
    id instance = [class new];
    
    return instance;
}



static unsigned short _s_rid = 1;

static inline bool isValidKey(NSString *key){
    if([key isEqualToString:PARAM_RSID] || [key isEqualToString:PARAM_SIGN] || [key isEqualToString:PARAM_TIMESTAMP] ||[key isEqualToString:@"context"]){
        return NO;
    }else{
        return YES;
    }
}


static inline NSString* MakeSQLKey(RequestParam* param){
    NSMutableString* SQLKey = [NSMutableString new];
    if(param.type == CACHE_SINGLE){
        
    }else if(param.type == CACHE_MULTI){
        [SQLKey appendFormat:@"%@|",param.cmd];
    }else{
    }
    [SQLKey appendString:[NSString stringWithFormat:@"%@|",param.url]];
    [param.param enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * stop) {
        NSString *strVal = obj, *strKey = key;
        if(isValidKey(strKey)) [SQLKey appendFormat:@"%@=%@|",strKey,strVal];
        *stop = NO;
    }];
    
    return SQLKey;
}




#define NET_STATUS [_networking getNetReachabilityStatus]


@interface GlobalDataCenter()
{
    id<HJNetWorking>        _networking;
    id<HJPersistence>       _persistence;
    NSMutableDictionary     *_requestMap;
    NSMutableDictionary     *_commonMap;
}

@property (nonatomic,strong) NSMutableDictionary *commonMap;
@property (nonatomic,strong) NSMutableSet *blacklist;

@end








@implementation GlobalDataCenter

+(GlobalDataCenter *)sharedGlobalDataCenter{
    static GlobalDataCenter *sharedGlobalDataCenter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedGlobalDataCenter = [[self alloc] init];
    });
    return sharedGlobalDataCenter;
}

-(instancetype)init{
    if(self = [super init]){
        [self _initModule];
        _requestMap = [NSMutableDictionary new];
    }
    return self;
}

+(void)initModule:(NSDictionary *)pCommparam signBlackList:(NSSet *)pBlacklist{
    GlobalDataCenter* center = [self sharedGlobalDataCenter];
    center.commonMap =[NSMutableDictionary new];
    for(NSString *key in pCommparam.allKeys){
        center.commonMap[key] = pCommparam[key];
    }
    center.blacklist = [[NSMutableSet alloc] initWithSet:pBlacklist copyItems:YES];
    [center.blacklist setSet:pBlacklist];
    [center.blacklist addObject:PARAM_RSID];
    [center.blacklist addObject:@"context"];
    [center.blacklist addObject:PARAM_CMD];
}

+(void) updateCommParam:(NSString *)key value:(NSString *)val{
    GlobalDataCenter* center = [self sharedGlobalDataCenter];
    center.commonMap[key] = val;
}


-(void) _initModule{
    _networking = dynamicCreate(NET_DRIVER);
    _persistence = dynamicCreate(PERSISTENCE_DRIVER);
}



-(NSUInteger)sendAsynPostRequest:(RequestParam *)param
                       ParseData:(ParseData)parser
                       LocalResp:(LocalResp)localFunc
                         NetResp:(NetResp)netFunc
                           Error:(ErrorResp)error{
    @synchronized (self) {
        short curRID = _s_rid;
        //! 增加通用字段
        [param.param setValue:[NSString stringWithFormat:@"%d",curRID] forKey:PARAM_RSID];
        [param.param setValue:param.cmd forKey:PARAM_CMD];
        if(_commonMap){
            [_commonMap enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                if(param.param[key] == nil){
                    param.param[key] = obj;
                }
            }];
//            [param.param addEntriesFromDictionary:_commonMap];
        }
        //! 加上sign
        [self addSign:param];
        
        [self handleLocalData:param localFunc:localFunc ParseFunc:parser];
        
        [self handleNetData:param Parser:parser NetResp:netFunc Error:error];
        
        _s_rid++;
        return curRID;
    }
}

-(void) addSign:(RequestParam *)param{
    if(param.needSign){
        //! 加入时间戳
        double timestamp = [[NSDate date] timeIntervalSince1970]*1000-60000;//减1分钟,保证容错
        NSString *strTimestamp = [NSString stringWithFormat:@"%llu",(unsigned long long)timestamp];
        [param.param setObject:strTimestamp forKey:PARAM_TIMESTAMP];
        
        //! 过滤黑名单
        NSMutableArray* arySign = [NSMutableArray new];
        [param.param enumerateKeysAndObjectsUsingBlock:^(NSString *key,  id obj, BOOL *stop) {
            if((_blacklist != nil && [_blacklist containsObject:key]) ){
                return;
            }
            [arySign addObject:[NSString stringWithFormat:@"%@=%@&",key,obj]];
        }];
        //! 排序
        NSSortDescriptor* sortDesc = [NSSortDescriptor sortDescriptorWithKey:nil ascending:YES];
        NSArray *sortAry = [arySign sortedArrayUsingDescriptors:@[sortDesc]];
        NSString *sign = [NSString new];
        for(NSString *param in sortAry){
            sign = [sign stringByAppendingString:param];
        }
        
        //! 去掉最后一个“&”
        sign = [sign substringToIndex:sign.length - 1];
        
        //! md5 请求标志
        sign = [sign stringByAppendingString:HJSecretKey];
        NSString *md5Sign = md5(sign);
        
        //! 加入请求串;
        [param.param setObject:md5Sign forKey:PARAM_SIGN];
    }
}

/**
 *  处理网络数据
 *
 *  @param param   请求数据
 *  @param parser  数据解析回调
 *  @param netFunc 网络请求回调
 *  @param error   错误回调
 */
-(void) handleNetData:(RequestParam *)param Parser:(ParseData)parser NetResp:(NetResp) netFunc Error:(ErrorResp) error{
    if(NET_STATUS == NetworkReachabilityStatusNotReachable){
        error([RequestResult create:param.cmd rsid:0 errorMsg:@"您还没连接上网络" errCode:-999]);
        return;
    }
    
//! debug下输出原始请求的get形式
#ifdef DEBUG
    __block NSString* getRequest = [param.url stringByAppendingString:@"?"];
    [param.param enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL * _Nonnull stop) {
        getRequest = [getRequest stringByAppendingString:[NSString stringWithFormat:@"%@=%@&",key,obj]];
    }];
    getRequest = [getRequest substringToIndex:getRequest.length - 1];
    NSLog(@"Request get style: %@",getRequest);
#endif
    
    
    //!记录最新请求编号
    NSString* sqlKey = MakeSQLKey(param);
    [_requestMap setObject:param.param[@"rsid"] forKey:sqlKey];
    
    __weak typeof(self) weakSelf = self;
    [_networking sendAsynPostRequest:param NetResp:^(id jsonData, RequestResult *result) {
        if(result.errcode != 0){
            if(error) error(result);
            return;
        }
        __strong typeof(weakSelf) self = weakSelf;
        
        //! 确定当前返回的数据是不是该请求的最新数据，不是则不做处理
        NSString* requestSqlKey = MakeSQLKey(param);
        NSString* latestRsid = _requestMap[requestSqlKey];
        if([latestRsid intValue]!= result.rsid)
            return;
        
        //! 解析并通知上层数据返回
        if(parser){
            dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT) , ^{
                id parseData = parser(jsonData[param.cmd]);
                if(netFunc){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        netFunc(parseData,result);
                    });
                }
                [self updateDB:param Data:jsonData];
            });
            
        }else{
            if(netFunc){
                netFunc(jsonData,result);
                //!GCD 不需要weak self
                dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
                    [self updateDB:param Data:jsonData];
                });
            }
            
        }
    } Error:^(RequestResult *result) {
        error(result);
    }];
}



/**
 *  读取本地数据
 *
 *  @param param     请求串
 *  @param localFunc 本地数据回调函数
 *  @param parser    解析回调函数
 */
-(void) handleLocalData:(RequestParam*) param localFunc:(LocalResp) localFunc ParseFunc:(ParseData) parser{
    //! WIFI环境下不返回数据
    if([_networking getNetReachabilityStatus] == NetworkReachabilityStatusReachableViaWIFI && !(param.type & CACHE_MUST_READ)){
        return;
    }
    
    if(param.type == CACHE_NONE){
        return;
    }
    
    @synchronized (_persistence) {
        
        NSString* sqlKey = MakeSQLKey(param);
        id jsonData = [_persistence readCache:sqlKey];
        
        if(jsonData == nil) return;
        
        if(parser){
            dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT) , ^{
                id parseData = parser(jsonData[param.cmd]);
                if(localFunc){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        localFunc(parseData);
                    });
                }
            });
        }else{
            if(localFunc) localFunc(jsonData);
        }
    }
}

/**
 *  更新本地数据库。如果数据类型是cache_single，直接覆盖老数据，如果类型是cache_multi，则删除所有关联数据后，再插入新数据
 *
 *  @param param    请求串
 *  @param jsonData 需要存储的数据
 */
-(void) updateDB:(RequestParam*) param Data:(id) jsonData{
    @synchronized (_persistence) {
        if(param.type == CACHE_NONE){
            return;
        }
        
        NSString* sqlKey = MakeSQLKey(param);
        id localData = [_persistence readCache:sqlKey];
        if(localData == nil){
            [_persistence writeCache:sqlKey data:jsonData];
        }else{
            if(param.type == CACHE_SINGLE) [_persistence removeCache:sqlKey];
            else if(param.type == CACHE_MULTI) [_persistence removeCacheByPrefix:param.cmd];
            
            [_persistence writeCache:sqlKey data:jsonData];
        }
    }
}

-(NetworkReachabilityStatus)getNetReachabilityStatus{
    return [_networking getNetReachabilityStatus];
}


-(void) downloadFile:(RequestParam *)param savePath:(NSURL *)savePath progress:(Progress)progressFunc finished:(DownloadFinished)finishFunc Error:(ErrorResp)error{
    [_networking downloadFile:param savePath:savePath progress:progressFunc finished:finishFunc Error:error];
}





-(void) uploadImage:(RequestParam *)param img:(UIImage *)img progress:(Progress)progressFunc finished:(UploadFinished)finishFunc Error:(ErrorResp)error{
    if(_commonMap){
        [param.param addEntriesFromDictionary:_commonMap];
    }
    [_networking uploadImage:param img:img progress:progressFunc finished:finishFunc Error:error];
}


-(void)uploadFile:(RequestParam *)param filePath:(NSString *)filePath progress:(Progress)Progress finished:(UploadFinished)finished Error:(ErrorResp)error{
    [_networking uploadFile:param filePath:filePath progress:Progress finished:finished Error:error];
}




/**
 *  这些方法用于单元测试
 */
-(id) localCacheData:(RequestParam *)param{
    NSString* sqlKey = MakeSQLKey(param);
    id jsonData = [_persistence readCache:sqlKey];
    return jsonData;
}

-(NSInteger)localCacheCount{
    return [_persistence cacheCount];
}

-(NSDictionary*) requestIDMap{
    return _requestMap;
}

-(void)clearLocalCache{
    [_persistence clearLocalCache];
}

@end














