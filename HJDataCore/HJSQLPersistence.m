//
//  HJSQLPersistence.m
//  Hejiajinrong+
//
//  Created by HeJia on 16/5/5.
//  Copyright © 2016年 HeJia. All rights reserved.
//

#import "HJSQLPersistence.h"
#import "YTKKeyValueStore.h"

#define CACHE_TABLE_NAME @"cache"

@interface HJSQLPersistence()

@property (nonatomic,strong,readonly) YTKKeyValueStore *DB;
@end


@implementation HJSQLPersistence
@synthesize DB = _DB;

-(instancetype)init{
    if(self = [super init]){
        _DB = [[YTKKeyValueStore alloc] initDBWithName:@"HJ.db"];
        [_DB createTableWithName:CACHE_TABLE_NAME];
    }
    return self;
}

-(void)dealloc{
    [_DB close];
}

-(id)readCache:(NSString *) key{
    return [self.DB getObjectById:key fromTable:CACHE_TABLE_NAME];
}

-(void)removeCache:(NSString *)key{
    [self.DB deleteObjectById:key fromTable:CACHE_TABLE_NAME];
}

-(void) writeCache:(NSString *)key data:(id)data{
    [self.DB putObject:data withId:key intoTable:CACHE_TABLE_NAME];
}

-(void) removeCacheByPrefix:(NSString *)prefix{
    [self.DB deleteObjectsByIdPrefix:prefix fromTable:CACHE_TABLE_NAME];
}

-(NSUInteger) cacheCount{
    return [self.DB getAllItemsFromTable:CACHE_TABLE_NAME].count;
}

-(void)clearLocalCache{
    [self.DB clearTable:CACHE_TABLE_NAME];
}

@end
