//
//  HJDataInterface.h
//  Hejiajinrong+
//
//  Created by HeJia on 16/5/7.
//  Copyright © 2016年 HeJia. All rights reserved.
//

#ifndef HJDataInterface_h
#define HJDataInterface_h

#import "HJRequestDefine.h"

/**
 *  初始化请求模块
 *
 *  @param commparam 通用请求参数，可缺省
 *  @param signBlacklist sign的黑名单，加入黑名单的参数不参与生成sign，可缺省
 *  @param commErrorHandler 统一处理错误的表格，key是错误码，value是处理函数
 */
extern void initDM(NSDictionary *commparam, NSSet *signBlacklist,NSDictionary<NSNumber * ,ErrorResp> *commErrorHandler);


/**
 *  获取数据
 *
 *  @param param 请求参数
 *  @param parse 解析回调。若实现该回调，解析过程将在子线程中进行，且LocalResp中返回的数据为解析后的数据模型。若没有实现此回调，则localResp中的返回数据是dictionary格式，上层需要再次自行实现优化解析过程。
 *  @param local 本地数据回调
 *  @param net   网络数据回调
 *  @param error 错误回调
 *  @param task 请求的具体handler
 */
extern NSUInteger GetDataWithID(RequestParam *param,ParseData parse, LocalResp local,NetResp net,ErrorResp error,id sender);


/**
 *  获取数据
 *
 *  @param param 请求参数
 *  @param parse 解析回调。若实现该回调，解析过程将在子线程中进行，且LocalResp中返回的数据为解析后的数据模型。若没有实现此回调，则localResp中的返回数据是dictionary格式，上层需要再次自行实现优化解析过程。
 *  @param local 本地数据回调
 *  @param net   网络数据回调
 *  @param error 错误回调
 */
extern NSUInteger GetData(RequestParam *param,ParseData parse, LocalResp local,NetResp net,ErrorResp error);

/**
 *  图片上传
 *
 *  @param param    请求参数
 *  @param img      上传的图片
 *  @param Progress 上传进度，已经在主线程，不需要线程调度
 *  @param finished 完成回调
 *  @param error    错误回调
 */
extern void UploadImageWithID(RequestParam *param, UIImage *img, Progress Progress,UploadFinished finished,ErrorResp error,id sender);

extern void UploadImage(RequestParam *param, UIImage *img, Progress Progress,UploadFinished finished,ErrorResp error);

/**
 *  下载文件
 *
 *  @param param    请求参数
 *  @param savePath 保存路径
 *  @param progress 下载进度，已经在主线程，不需要线程调度
 *  @param finished 下载完成回调
 *  @param error    错误通知
 */
extern void DownloadFileWithID(RequestParam *param,NSURL* savePath,Progress progress,DownloadFinished finished,ErrorResp error,id sender);

extern void DownloadFile(RequestParam *param,NSURL* savePath,Progress progress,DownloadFinished finished,ErrorResp error);


/**
 *  上传文件
 *
 *  @param param    请求地址
 *  @param filePath 文件本地地址
 *  @param Progress 上传进度
 *  @param finished 上传完成
 *  @param error    上传出错
 */
extern void UploadFileWithID(RequestParam *param,NSString *filePath,Progress Progress,UploadFinished finished,ErrorResp error,id sender);

extern void UploadFile(RequestParam *param,NSString *filePath,Progress Progress,UploadFinished finished,ErrorResp error);

/**
 *  更新请求常用字段
 *
 *  @param key 常用字段的key
 *  @param val 常用字段的val
 */
extern void updateCommparam(NSString *key , NSString *val);
/**
 *  获取当前网络状态
 *
 *  @return 网络状态
 */
extern NetworkReachabilityStatus getNetReachabilityStatus();

#endif /* HJDataInterface_h */
