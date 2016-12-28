//
//  HJAFNetWorking.m
//  Hejiajinrong+
//
//  Created by HeJia on 16/5/4.
//  Copyright © 2016年 HeJia. All rights reserved.
//

#import "HJAFNetWorking.h"
#import "AFNetWorking.h"
#import "MJExtension.h"


@interface HJAFNetWorking(){
    NetworkReachabilityStatus status;
    AFHTTPSessionManager *_httpClient;
}

@end

@implementation HJAFNetWorking



static inline RequestResult* NSError2RequestResult(NSError* error){
    return [RequestResult create:@"" rsid:0 errorMsg:error.domain errCode:error.code];
}


-(instancetype)init{
    if(self = [super init]){
        [[AFNetworkReachabilityManager sharedManager] startMonitoring];
        
        _httpClient = [AFHTTPSessionManager manager];
        
        _httpClient.responseSerializer = [AFHTTPResponseSerializer serializer];
        _httpClient.requestSerializer.timeoutInterval = 30;
        _httpClient.requestSerializer.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        [_httpClient.requestSerializer setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        [_httpClient.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        
        _httpClient.requestSerializer.HTTPShouldHandleCookies = NO;
        
    }
    return self;
}

-(void)dealloc{
    [[AFNetworkReachabilityManager sharedManager] stopMonitoring];
}

-(void)sendAsynPostRequest:(RequestParam *)param
                   NetResp:(NetResp) netFunc
                     Error:(ErrorResp) errRep
{

    [_httpClient POST:param.url
          parameters:param.param
            progress:nil
             success:^(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject) {
                 NSError* parseErr = nil;
                 NSDictionary* json = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers|NSJSONReadingAllowFragments error:&parseErr];
                 if(parseErr != nil){
                     if(errRep) errRep(NSError2RequestResult(parseErr));
                     return;
                 }
                 RequestResult* res = [RequestResult mj_objectWithKeyValues:json[@"baseApiResult"]];
                 netFunc(json , res);
             }
             failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                 NSError *err = [NSError errorWithDomain:@"网络连接出错，请检测您的网络" code:error.code userInfo:error.userInfo];
                 if(errRep) errRep(NSError2RequestResult(err));
             }
     ];
    
}

-(void) uploadFile:(RequestParam *) param
          filePath:(NSString *) filePath
          progress:(Progress) Progress
          finished:(UploadFinished) finished
             Error:(ErrorResp) errorFunc
{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager POST:param.url parameters:param.param constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        NSData *data = [NSData dataWithContentsOfFile:filePath];
        [formData appendPartWithFileData:data name:@"file" fileName:[filePath lastPathComponent] mimeType:@"application/octet-stream"];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        if(Progress){
            dispatch_async(dispatch_get_main_queue(), ^{
                Progress(uploadProgress);
            });
        }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSError* parseErr = nil;
        NSDictionary* json = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers|NSJSONReadingAllowFragments error:&parseErr];
        if(parseErr != nil){
            if(errorFunc) errorFunc(NSError2RequestResult(parseErr));
            return;
        }
        RequestResult* res = [RequestResult mj_objectWithKeyValues:json[@"baseApiResult"]];
        
        if(finished) finished(json,res);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if(errorFunc) errorFunc(NSError2RequestResult(error));
    }];

    
}

-(void)uploadImage:(RequestParam *)param
               img:(UIImage *)img
          progress:(Progress)progressFunc
          finished:(UploadFinished)finishFunc
             Error:(ErrorResp)errResp
{
    
    NSInteger time = [NSDate timeIntervalSinceReferenceDate];
    NSString* imgName = [NSString stringWithFormat:@"%ld",time];
    NSString* imgFile = [NSString stringWithFormat:@"%ld.png",(long)time];
    if([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0){
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        [manager POST:param.url parameters:param.param constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
            NSData *data = UIImagePNGRepresentation(img);
            [formData appendPartWithFileData:data name:@"imagesFile" fileName:imgFile mimeType:@"image/png"];
        } progress:^(NSProgress * _Nonnull uploadProgress) {
            if(progressFunc){
                dispatch_async(dispatch_get_main_queue(), ^{
                    progressFunc(uploadProgress);
                });
            }
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            NSError* parseErr = nil;
            NSDictionary* json = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers|NSJSONReadingAllowFragments error:&parseErr];
            if(parseErr != nil){
                if(errResp) errResp(NSError2RequestResult(parseErr));
                return;
            }
            RequestResult* res = [RequestResult mj_objectWithKeyValues:json[@"baseApiResult"]];
            if(res.errcode == 0){
                if(finishFunc) finishFunc(json,res);
            }else{
                if(errResp) errResp(res);
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            if(errResp) errResp(NSError2RequestResult(error));
        }];
    }else{
        NSString* tmpFilename = imgFile;
        NSURL* tmpFileurl = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:tmpFilename]];
        NSMutableURLRequest *multipartRequest = [[AFHTTPRequestSerializer serializer] multipartFormRequestWithMethod:@"POST" URLString:param.url parameters:param.param constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
            NSData* data = UIImagePNGRepresentation(img);
            [formData appendPartWithFileData:data name:imgName fileName:imgFile mimeType:@"image/png"];
        } error:nil];
        
        [[AFHTTPRequestSerializer serializer] requestWithMultipartFormRequest:multipartRequest writingStreamContentsToFile:tmpFileurl completionHandler:^(NSError * _Nullable error) {
            AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
            manager.responseSerializer = [AFHTTPResponseSerializer serializer];
            NSURLSessionUploadTask *uploadTask = [manager uploadTaskWithRequest:multipartRequest fromFile:tmpFileurl progress:^(NSProgress * _Nonnull uploadProgress) {
                if(progressFunc){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        progressFunc(uploadProgress);
                    });
                }
            } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
                [[NSFileManager defaultManager] removeItemAtURL:tmpFileurl error:nil];
                if(error){
                    if(errResp)  errResp(NSError2RequestResult(error));
                }else{
                    NSError* parseErr = nil;
                    NSDictionary* json = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers|NSJSONReadingAllowFragments error:&parseErr];
                    if(parseErr != nil){
                        if(errResp) errResp(NSError2RequestResult(parseErr));
                        return;
                    }
                    RequestResult* res = [RequestResult mj_objectWithKeyValues:json[@"baseApiResult"]];
                    if(res.errcode == 0){
                        if(finishFunc) finishFunc(json,res);
                    }else{
                        if(errResp) errResp(NSError2RequestResult(parseErr));
                    }
                }
            }];
            [uploadTask resume];
        }];
    }
}


-(void)downloadFile:(RequestParam *)param
           savePath:(NSURL*)savePath
           progress:(Progress)progressFunc
           finished:(DownloadFinished) finishFunc
              Error:(ErrorResp)errResp
{
    NSURLSessionConfiguration* sessionConf = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *downLoadManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:sessionConf];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:param.url]];
    NSURLSessionDownloadTask* downloadTask = [downLoadManager downloadTaskWithRequest:request
                                    progress: ^(NSProgress * _Nonnull downloadProgress) {
                                        if(progressFunc){
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                progressFunc(downloadProgress);
                                            });
                                        }
                                    }
                                 destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
                                     return savePath;
                                 }
                           completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                               if(error == nil){
                                   if(finishFunc) finishFunc(filePath);
                               }else{
                                   if(errResp) errResp(NSError2RequestResult(error));
                               }
                           }
     ];
    
    [downloadTask resume];
}

-(NetworkReachabilityStatus)getNetReachabilityStatus{
    AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
    return manager.networkReachabilityStatus;
}


-(AFSecurityPolicy*) configSecurityPolicy{
    // SSL Pinning
    NSString *certificatePath = [[NSBundle mainBundle] pathForResource:@"certificate" ofType:@"der"];
    NSData *certificateData = [NSData dataWithContentsOfFile:certificatePath];
    
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    [securityPolicy setAllowInvalidCertificates:YES];
    [securityPolicy setPinnedCertificates:[NSSet setWithObject:certificateData]];
    
    return securityPolicy;
}


-(AFHTTPSessionManager*) createAndConfigSessionManager{
    AFHTTPSessionManager *httpClient = [AFHTTPSessionManager new];
    httpClient.responseSerializer = [AFHTTPResponseSerializer serializer];
    httpClient.requestSerializer.timeoutInterval = 30;
    httpClient.requestSerializer.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    [httpClient.requestSerializer setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [httpClient.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    return httpClient;
}

@end
