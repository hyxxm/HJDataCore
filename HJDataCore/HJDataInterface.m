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

NSUInteger GetDataWithID(RequestParam *param,ParseData parse, LocalResp local,NetResp net,ErrorResp error,id sender){
    return [DataCenter() sendAsynPostRequest:param ParseData:parse LocalResp:local NetResp:net Error:error sender:sender];
}

NSUInteger GetData(RequestParam *param,ParseData parse, LocalResp local,NetResp net,ErrorResp error){
    return GetDataWithID(param, parse, local, net, error, nil);
}

void UploadImageWithID(RequestParam *param, UIImage *img, Progress Progress,UploadFinished finished,ErrorResp error , id sender){
    [DataCenter() uploadImage:param img:img progress:Progress finished:finished Error:error sender:sender];
}

void UploadImage(RequestParam *param, UIImage *img, Progress Progress,UploadFinished finished,ErrorResp error){
    UploadImageWithID(param, img, Progress, finished, error, nil);
}

void UploadFileWithID(RequestParam *param,NSString *filePath,Progress Progress,UploadFinished finished,ErrorResp error ,id sender){
    [DataCenter() uploadFile:param filePath:filePath progress:Progress finished:finished Error:error sender:sender];
}

void UploadFile(RequestParam *param,NSString *filePath,Progress Progress,UploadFinished finished,ErrorResp error){
    UploadFileWithID(param, filePath, Progress, finished, error, nil);
}

void DownloadFileWithID(RequestParam *param,NSURL* savePath,Progress progress,DownloadFinished finished,ErrorResp error, id sender){
    return [DataCenter() downloadFile:param savePath:savePath progress:progress finished:finished Error:error sender:sender];
}

void DownloadFile(RequestParam *param,NSURL* savePath,Progress progress,DownloadFinished finished,ErrorResp error){
    DownloadFileWithID(param,savePath,progress,finished,error,nil);
}

void initDM(NSDictionary *commparam , NSSet *signBlacklist ,NSDictionary<NSNumber * ,ErrorResp> *commErrorHandler){
    [GlobalDataCenter initModule:commparam signBlackList:signBlacklist commErrHandler:commErrorHandler];
}

void updateCommparam(NSString *key , NSString *val){
    [GlobalDataCenter updateCommParam:key value:val];
}

NetworkReachabilityStatus getNetReachabilityStatus(){
    return [DataCenter() getNetReachabilityStatus];
}

void setCommonParam(NSDictionary *dic){
    
}
