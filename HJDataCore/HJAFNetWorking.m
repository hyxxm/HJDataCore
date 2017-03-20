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
#import "ReactiveCocoa/ReactiveCocoa.h"
#import <objc/objc.h>


@interface HJAFNetWorking(){
    NetworkReachabilityStatus status;
    AFHTTPSessionManager *_httpClient;
    NSMutableDictionary<id,NSMutableSet<NSURLSessionDataTask *> *> *_dicDataTask;
}

@end

@implementation HJAFNetWorking



static inline RequestResult* NSError2RequestResult(NSError* error){
    return [RequestResult create:@"" rsid:0 errorMsg:error.domain errCode:error.code];
}

static inline NSNumber *senderAddr(id sender){
    long long lSender = sender;
    return [NSNumber numberWithLongLong:sender];
}

-(void) addTask:(NSURLSessionDataTask *)task withSender:(id) sender{
    if(sender == nil){
        return;
    }
    
    NSNumber *senderAddrNum = senderAddr(sender);
    NSMutableSet<NSURLSessionDataTask *> *taskSet = _dicDataTask[senderAddrNum];
    if(taskSet == nil){
        taskSet = [NSMutableSet new];
        [_dicDataTask setObject:taskSet forKey:senderAddrNum];
        
        @weakify(self)
        if([sender isKindOfClass:[UIViewController class]]){
            [[sender rac_signalForSelector:@selector(viewWillDisappear:)] subscribeNext:^(id x){
                @strongify(self)
                [self cancelAllTask:senderAddrNum];
            }];
            
            [[sender rac_willDeallocSignal] subscribeCompleted:^{
                @strongify(self)
                [self removeTask:senderAddrNum];
            }];
            
        }else{
            [[sender rac_willDeallocSignal] subscribeCompleted:^{
                @strongify(self)
                [self disconnectTask:senderAddrNum];
            }];
        }
        
    }
    
    [taskSet addObject:task];
}

-(void) cancelAllTask:(NSNumber *)senderAddrNum{
    NSMutableSet<NSURLSessionDataTask *> *taskToRemove = _dicDataTask[senderAddrNum];
    [taskToRemove enumerateObjectsUsingBlock:^(NSURLSessionDataTask * _Nonnull obj, BOOL * _Nonnull stop) {
        *stop = NO;
        if([obj state] == NSURLSessionTaskStateRunning){
            [obj cancel];
        }
    }];
}

-(void) removeTask:(NSNumber *) senderAddrNum{
    NSMutableSet<NSURLSessionDataTask *> *taskToRemove = _dicDataTask[senderAddrNum];
    [taskToRemove removeAllObjects];
    [_dicDataTask removeObjectForKey:senderAddrNum];
}

-(void) disconnectTask:(NSNumber *)senderAddrNum{
    NSMutableSet<NSURLSessionDataTask *> *taskToRemove = _dicDataTask[senderAddrNum];
    [taskToRemove enumerateObjectsUsingBlock:^(NSURLSessionDataTask * _Nonnull obj, BOOL * _Nonnull stop) {
        *stop = NO;
        if([obj state] == NSURLSessionTaskStateRunning){
            [obj cancel];
        }
    }];
    [taskToRemove removeAllObjects];
    [_dicDataTask removeObjectForKey:senderAddrNum];
}

-(void) removeTask:(NSURLSessionDataTask *)task withSender:(id) sender{
    if(sender == nil){
        return;
    }
    
    NSLog(@"dealloc removeTask: data Response");
    
    NSMutableSet<NSURLSessionDataTask *> *taskSet = _dicDataTask[senderAddr(sender)];
    if(taskSet != nil){
        [taskSet removeObject:task];
    }
}

-(long) hasTask:(NSURLSessionDataTask *)task withSender:(id) sender{
    if(sender == nil){
        return -1;
    }
    NSMutableSet<NSURLSessionDataTask *> *taskSet = _dicDataTask[senderAddr(sender)];
    return taskSet ==nil?0:1;
}


-(instancetype)init{
    if(self = [super init]){
        
        _dicDataTask = [NSMutableDictionary new];
        
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

-(void )sendAsynPostRequest:(RequestParam *)param
                                     NetResp:(NetResp) netFunc
                                       Error:(ErrorResp) errRep
                                      sender:(id) sender
{
    @weakify(self)
    __weak id wSender = sender;
    NSURLSessionDataTask *task = [_httpClient POST:param.url
          parameters:param.param
            progress:nil
             success:^(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject) {
                 @strongify(self)
                 long lHasTask = [self hasTask:task withSender:wSender];
                 if(lHasTask == -1){
                     //! do nothing
                 }else{
                     if(lHasTask == 0){
                         //! 响应者被析构，不做处理直接返回
                         return;
                     }else{
                         //! 删除对应的记录
                         [self removeTask:task withSender:wSender];
                     }
                 }
                 
                 
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
                 @strongify(self)
                 long lHasTask = [self hasTask:task withSender:wSender];
                 if(lHasTask == -1){
                     //! do nothing
                 }else{
                     if(lHasTask == 0){
                         
                     }else{
                         //! 删除对应的记录
                         [self removeTask:task withSender:wSender];
                     }
                 }
                 
                 //! 请求取消，不做异常反馈
                 
#ifdef DEBUG
                 NSError *err = [NSError errorWithDomain:@"网络连接出错，请检测您的网络" code:error.code userInfo:error.userInfo];
                 if(errRep) errRep(NSError2RequestResult(err));
#else
                 if(error.code == -999){
                     
                 }else{
                     NSError *err = [NSError errorWithDomain:@"网络连接出错，请检测您的网络" code:error.code userInfo:error.userInfo];
                     if(errRep) errRep(NSError2RequestResult(err));
                 }
#endif
             }
     ];
    
    [self addTask:task withSender:sender];
}

-(void) uploadFile:(RequestParam *) param
          filePath:(NSString *) filePath
          progress:(Progress) Progress
          finished:(UploadFinished) finished
             Error:(ErrorResp) errorFunc
            sender:(id)sender
{
    @weakify(self)
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.requestSerializer.HTTPShouldHandleCookies = NO;
    manager.requestSerializer.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    
    __weak id wSender = sender;
    NSURLSessionDataTask *task = [manager POST:param.url parameters:param.param constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        NSData *data = [NSData dataWithContentsOfFile:filePath];
        [formData appendPartWithFileData:data name:@"file" fileName:[filePath lastPathComponent] mimeType:@"application/octet-stream"];
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        if(Progress){
            dispatch_async(dispatch_get_main_queue(), ^{
                Progress(uploadProgress);
            });
        }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        @strongify(self)
        long lHasTask = [self hasTask:task withSender:wSender];
        if(lHasTask == -1){
            //! do nothing
        }else{
            if(lHasTask == 0){
                //! 响应者被析构，不做处理直接返回
                return;
            }else{
                //! 删除对应的记录
                [self removeTask:task withSender:wSender];
            }
        }
        
        NSError* parseErr = nil;
        NSDictionary* json = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers|NSJSONReadingAllowFragments error:&parseErr];
        if(parseErr != nil){
            if(errorFunc) errorFunc(NSError2RequestResult(parseErr));
            return;
        }
        RequestResult* res = [RequestResult mj_objectWithKeyValues:json[@"baseApiResult"]];
        
        if(finished) finished(json,res);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        @strongify(self)
        long lHasTask = [self hasTask:task withSender:wSender];
        if(lHasTask == -1){
            //! do nothing
        }else{
            if(lHasTask == 0){
                //! 响应者被析构，不做处理直接返回
                return;
            }else{
                //! 删除对应的记录
                [self removeTask:task withSender:wSender];
            }
        }
        

        if(errorFunc) errorFunc(NSError2RequestResult(error));
    }];

    [self addTask:task withSender:sender];
}

-(void)uploadImage:(RequestParam *)param
               img:(UIImage *)img
          progress:(Progress)progressFunc
          finished:(UploadFinished)finishFunc
             Error:(ErrorResp)errResp
            sender:(id)sender
{
    @weakify(self)
    NSInteger time = [NSDate timeIntervalSinceReferenceDate];
    NSString* imgName = [NSString stringWithFormat:@"%ld",time];
    NSString* imgFile = [NSString stringWithFormat:@"%ld.png",(long)time];
    
    __weak id wSender = sender;
    if([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0){
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        NSURLSessionDataTask *task = [manager POST:param.url parameters:param.param constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
            NSData *data = UIImageJPEGRepresentation(img, 0.7);
            
            [formData appendPartWithFileData:data name:@"imagesFile" fileName:imgFile mimeType:@"image/png"];
            
        } progress:^(NSProgress * _Nonnull uploadProgress) {
            if(progressFunc){
                dispatch_async(dispatch_get_main_queue(), ^{
                    progressFunc(uploadProgress);
                });
            }
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            @strongify(self)
            long lHasTask = [self hasTask:task withSender:wSender];
            if(lHasTask == -1){
                //! do nothing
            }else{
                if(lHasTask == 0){
                    //! 响应者被析构，不做处理直接返回
                    return;
                }else{
                    //! 删除对应的记录
                    [self removeTask:task withSender:wSender];
                }
            }
            
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
            @strongify(self)
            long lHasTask = [self hasTask:task withSender:wSender];
            if(lHasTask == -1){
                //! do nothing
            }else{
                if(lHasTask == 0){
                    //! 响应者被析构，不做处理直接返回
                    return;
                }else{
                    //! 删除对应的记录
                    [self removeTask:task withSender:wSender];
                }
            }
            if(errResp) errResp(NSError2RequestResult(error));
        }];
        
        [self addTask:task withSender:sender];
    }else{
        NSString* tmpFilename = imgFile;
        NSURL* tmpFileurl = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:tmpFilename]];
        NSMutableURLRequest *multipartRequest = [[AFHTTPRequestSerializer serializer] multipartFormRequestWithMethod:@"POST" URLString:param.url parameters:param.param constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
            NSData* data = UIImagePNGRepresentation(img);
            [formData appendPartWithFileData:data name:imgName fileName:imgFile mimeType:@"image/png"];
        } error:nil];
        
        [[AFHTTPRequestSerializer serializer] requestWithMultipartFormRequest:multipartRequest writingStreamContentsToFile:tmpFileurl completionHandler:^(NSError * _Nullable error) {
            @strongify(self)
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
                long lHasTask = [self hasTask:uploadTask withSender:wSender];
                if(lHasTask == -1){
                    //! do nothing
                }else{
                    if(lHasTask == 0){
                        //! 响应者被析构，不做处理直接返回
                        return;
                    }else{
                        //! 删除对应的记录
                        [self removeTask:uploadTask withSender:wSender];
                    }
                }

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
            [self addTask:uploadTask withSender:sender];
        }];
    }
}


-(void)downloadFile:(RequestParam *)param
           savePath:(NSURL*)savePath
           progress:(Progress)progressFunc
           finished:(DownloadFinished) finishFunc
              Error:(ErrorResp)errResp
             sender:(id)sender
{
    @weakify(self)
    NSURLSessionConfiguration* sessionConf = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *downLoadManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:sessionConf];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:param.url]];
    __weak id wSender = sender;
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
                               @strongify(self)
                               long lHasTask = [self hasTask:downloadTask withSender:wSender];
                               if(lHasTask == -1){
                                   //! do nothing
                               }else{
                                   if(lHasTask == 0){
                                       //! 响应者被析构，不做处理直接返回
                                       return;
                                   }else{
                                       //! 删除对应的记录
                                       [self removeTask:downloadTask withSender:downloadTask];
                                   }
                               }

                               if(error == nil){
                                   if(finishFunc) finishFunc(filePath);
                               }else{
                                   if(errResp) errResp(NSError2RequestResult(error));
                               }
                           }
     ];
    
    [downloadTask resume];
    [self addTask:downloadTask withSender:sender];
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
