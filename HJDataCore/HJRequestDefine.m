//
//  HJRequestStruct.m
//  Hejiajinrong+
//
//  Created by HeJia on 16/5/4.
//  Copyright © 2016年 HeJia. All rights reserved.
//

#import "HJRequestDefine.h"
//#import "NSDictionary+DeepCopy.h"

@implementation RequestParam

@synthesize url;
@synthesize param;
@synthesize type;
@synthesize cmd;
@synthesize needSign;

-(instancetype)init{
    if(self = [super init]){
        param = [NSMutableDictionary new];
        type = CACHE_SINGLE;
        needSign = NO;
    }
    return self;
}

-(id)copyWithZone:(NSZone *)zone{
    RequestParam* copyParam = [RequestParam new];
    copyParam.url = [self.url copy];
    copyParam.type = self.type;
    copyParam.cmd = [self.cmd copy];
    copyParam.param = [self.param copy];
    
    return copyParam;
}

-(id)mutableCopyWithZone:(NSZone *)zone{
    RequestParam* mutableParam = [RequestParam new];
    mutableParam.url = [self.url mutableCopy];
    mutableParam.type = self.type;
    mutableParam.cmd = [self.cmd mutableCopy];
    mutableParam.param = [self.param mutableCopy];
    return mutableParam;
}

+(RequestParam *)create:(NSString *)url param:(NSDictionary *)param cmd:(NSString *)cmd type:(short)cacheType needSign:(bool)b{
    RequestParam *retReq = [RequestParam new];
    retReq.url = url;
    [retReq.param setDictionary:param];
    retReq.cmd = cmd;
    retReq.type = cacheType;
    retReq.needSign = b;
    
    return retReq;
}

+(instancetype) emptyResult{
    RequestParam *param = [RequestParam new];
    param.cmd = @"";
    param.url = @"";
    return param;
}

+(RequestParam *) create:(NSString *) url
                   param:(NSDictionary *)param
                     cmd:(NSString *)cmd
                    type:(REQUEST_CACHE_TYPE) cacheType{
    return [self create:url param:param cmd:cmd type:cacheType needSign:NO];
}

-(NSString *)description{
    return [NSString stringWithFormat:@"RequestParam: url = %@,type = %d,cmd = %@,param = %@",self.url,self.type,self.cmd,self.param];
}

@end

@implementation RequestResult

@synthesize rsid;
@synthesize errmsg;
@synthesize errcode;
@synthesize cmd;

+(instancetype)create:(NSString *)cmd rsid:(unsigned short)rsid errorMsg:(NSString *)errMsg errCode:(NSUInteger)errCode{
    RequestResult* rqRes = [RequestResult new];
    rqRes.cmd = cmd;
    rqRes.rsid = rsid;
    rqRes.errmsg = errMsg;
    rqRes.errcode = errCode;
    
    return rqRes;
}

-(NSError *)transResult2Error{
    return [NSError errorWithDomain:self.errmsg code:self.errcode userInfo:@{@"rsid":[NSNumber numberWithInteger:self.rsid],@"cmd":self.cmd == nil?@"":self.cmd}];
}

+ (NSDictionary *)mj_replacedKeyFromPropertyName{
    return @{@"errcode":@"status"};
}

@end
