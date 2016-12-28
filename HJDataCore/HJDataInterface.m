//
//  HJDataInterface.m
//  HJDataCore
//
//  Created by HeJia on 16/6/8.
//  Copyright © 2016年 HeJia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HJDataCenter.h"

static inline GlobalDataCenter* DataCenter(){
    return [GlobalDataCenter sharedGlobalDataCenter];
}

NSUInteger GetData(RequestParam *param,ParseData parse, LocalResp local,NetResp net,ErrorResp error){
    return [DataCenter() sendAsynPostRequest:param ParseData:parse LocalResp:local NetResp:net Error:error];
}

void UploadImage(RequestParam *param, UIImage *img, Progress Progress,UploadFinished finished,ErrorResp error){
    [DataCenter() uploadImage:param img:img progress:Progress finished:finished Error:error];
}

void UploadFile(RequestParam *param,NSString *filePath,Progress Progress,UploadFinished finished,ErrorResp error){
    [DataCenter() uploadFile:param filePath:filePath progress:Progress finished:finished Error:error];
}


void DownloadFile(RequestParam *param,NSURL* savePath,Progress progress,DownloadFinished finished,ErrorResp error){
    [DataCenter() downloadFile:param savePath:savePath progress:progress finished:finished Error:error];
}

void initDM(NSDictionary *commparam , NSSet *signBlacklist){
    [GlobalDataCenter initModule:commparam signBlackList:signBlacklist];
}

void updateCommparam(NSString *key , NSString *val){
    [GlobalDataCenter updateCommParam:key value:val];
}

NetworkReachabilityStatus getNetReachabilityStatus(){
    return [DataCenter() getNetReachabilityStatus];
}

void setCommonParam(NSDictionary *dic){
    
}
