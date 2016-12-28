//
//  HJRequestStruct.h
//  Hejiajinrong+
//
//  Created by HeJia on 16/5/4.
//  Copyright © 2016年 HeJia. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  请求结果集
 */
@interface RequestResult : NSObject
/**
 *  请求id，用于校验是否是最新请求
 */
@property (nonatomic,assign) unsigned short     rsid;
/**
 *  错误信息，错误包含本地网路连接问题，以及业务逻辑出现的错误
 */
@property (nonatomic,copy) NSString             *errmsg;
/**
 *  错误码
 */
@property (nonatomic,assign) NSUInteger         errcode;
/**
 *  请求命令
 */
@property (nonatomic,copy) NSString             *cmd;

+(instancetype) create:(NSString*)cmd rsid:(unsigned short)rsid errorMsg:(NSString*)errMsg errCode:(NSUInteger) errCode;

+(instancetype) emptyResult;

-(NSError*) transResult2Error;

@end

/**
 *  请求串
 */
#define REQUEST_CACHE_TYPE      short
#define CACHE_SINGLE            0x01
#define CACHE_MULTI             0x02
#define CACHE_NONE              0x00

//! 就算本地缓存没有，或者本地是wifi环境，依然会从本地去读数据，并且调用localDataResponse
#define CACHE_MUST_READ         0x10

@interface RequestParam : NSObject<NSCopying,NSMutableCopying>
/**
 *  请求地址
 */
@property (nonatomic,copy) NSString             *url;
/**
 *  请求参数
 */
@property (nonatomic,copy) NSMutableDictionary  *param;
/**
 *  请求类型，此参数与cmd参数关系到缓存及缓存更新的策略
 *  @param type 请求的类型， SINGLE代表单一型数据，比如获取菜单栏，详情页。MULTI代表列表型翻页数据。NONE代表不需要数据存储。
 */
@property (nonatomic,assign) REQUEST_CACHE_TYPE type;
/**
 *  请求命令
 */
@property (nonatomic,copy) NSString             *cmd;
/**
 *  是否需要请求串校验
 */
@property (nonatomic,assign) bool               needSign;

/**
 *  创建请求
 *
 *  @param url       请求地址
 *  @param param     请求参数
 *  @param cmd       请求命令
 *  @param cacheType 缓存类型
 *  @param b         是否需要请求串校验
 *  @return 请求
 */
+(RequestParam *) create:(NSString *) url
                   param:(NSDictionary *)param
                     cmd:(NSString *)cmd
                    type:(REQUEST_CACHE_TYPE) cacheType
                needSign:(bool) b;

+(RequestParam *) create:(NSString *) url
                   param:(NSDictionary *)param
                     cmd:(NSString *)cmd
                    type:(REQUEST_CACHE_TYPE) cacheType;

@end






//! call back
/**
 *  本地数据返回
 *
 *  @param jsonData 本地json数据
 */
typedef void(^LocalResp)(id jsonData);

/**
 *  解析数据，返回数据模型
 *
 *  @param jsonData dictionary 类型数据
 *
 *  @return 返回数据模型
 */
typedef id(^ParseData)(id jsonData);
/**
 *  网络数据返回
 *
 *  @param jsonData 数据json
 *  @param result   请求结果集
 */
typedef void(^NetResp)(id jsonData,RequestResult* result);
/**
 *  请求失败返回
 *
 *  @param result 请求结果集
 */
typedef void(^ErrorResp)(RequestResult* result);

/**
 *  下载或上传的进度，回调时已经在主线程，无需转线程
 *
 *  @param progress 进度
 */
typedef void(^Progress)(NSProgress* progress);

/**
 *  文件下载完成callback
 *
 *  @param filePath 文件所在的本地路径
 */
typedef void(^DownloadFinished)(NSURL* filePath);

/**
 *   文件上传完成
 */
typedef void(^UploadFinished)(id jsonData,RequestResult* result);




//! 数据项定义
#define _RESULT_    @"result"



#define NetworkReachabilityStatus short                     //网络状态
#define NetworkReachabilityStatusUnknow             -1      //未识别的网络
#define NetworkReachabilityStatusNotReachable       0       //不可达的网络
#define NetworkReachabilityStatusReachableViaWWAN   1       //2G,3G,4G
#define NetworkReachabilityStatusReachableViaWIFI   2       //wifi
