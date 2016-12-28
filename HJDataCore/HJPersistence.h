//
//  HJPersistence.h
//  Hejiajinrong+
//
//  Created by HeJia on 16/5/4.
//  Copyright © 2016年 HeJia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HJRequestDefine.h"

/**
 *  持久化接口，分离持久化的具体实现
 */
@protocol HJPersistence <NSObject>
@required
/**
 *  读取本地缓存
 *
 *  @param param 原始请求包
 *
 *  @return 数据包
 */
-(id) readCache:(NSString*) param;
/**
 *  写缓存
 *
 *  @param key  原始请求包
 *  @param data 数据包
 */
-(void) writeCache:(NSString*) key data:(id)data;
/**
 *  删除缓存
 *
 *  @param key 原始数据包
 */
-(void) removeCache:(NSString*) key;

/**
 *  通过前缀删除缓存
 *
 *  @param prefix 前缀
 */
-(void) removeCacheByPrefix:(NSString*) prefix;

@optional

-(NSUInteger) cacheCount;

-(void) clearLocalCache;

@end
