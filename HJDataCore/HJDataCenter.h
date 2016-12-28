//
//  HJDataCenter.h
//  Hejiajinrong+
//
//  Created by HeJia on 16/5/3.
//  Copyright © 2016年 HeJia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HJRequestDefine.h"
#import <UIKit/UIKit.h>

@interface GlobalDataCenter : NSObject

+(void) initModule:(NSDictionary *)commparam signBlackList:(NSSet *)blacklist;

+(void) updateCommParam:(NSString *) key value:(NSString *) val;

+ (GlobalDataCenter *)sharedGlobalDataCenter;

-(NSUInteger) sendAsynPostRequest:(RequestParam*) param ParseData:(ParseData)parser LocalResp:(LocalResp) localFunc NetResp:(NetResp) netFunc Error:(ErrorResp) error;

-(void)downloadFile:(RequestParam*)param savePath:(NSURL*)savePath progress:(Progress) progressFunc finished:(DownloadFinished) finishFunc Error:(ErrorResp) error;

-(void)uploadImage:(RequestParam*)param img:(UIImage*)img progress:(Progress) progressFunc finished:(UploadFinished) finishFunc Error:(ErrorResp) error;

-(void) uploadFile:(RequestParam *) param filePath:(NSString *) filePath progress:(Progress) Progress finished:(UploadFinished) finished Error:(ErrorResp) error;

-(NetworkReachabilityStatus) getNetReachabilityStatus;

@end



/**
 *  这些方法用于单元测试，外部切勿调用
 */
@interface GlobalDataCenter(DatatCenterTestFunc)

-(id) localCacheData:(RequestParam*) param;

-(NSInteger) localCacheCount;

-(NSDictionary*) requestIDMap;

-(void) clearLocalCache;

@end


