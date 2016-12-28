//
//  HJNetWorking.h
//  Hejiajinrong+
//
//  Created by HeJia on 16/5/4.
//  Copyright © 2016年 HeJia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HJRequestDefine.h"
#import <UIKit/UIKit.h>

/**
 *  网络请求接口层，分离网络请求的具体实现
 */
@protocol HJNetWorking <NSObject>
@required
/**
 *  post异步请求
 *
 *  @param param   请求内容
 *  @param netFunc 数据返回callback
 *  @param error   数据错误callback
 */
-(void)sendAsynPostRequest:(RequestParam *)param NetResp:(NetResp) netFunc Error:(ErrorResp) error;

/**
 *  下载文件
 *
 *  @param param        请求地址
 *  @param savePath     文件保存路径
 *  @param progressFunc 进度信息
 *  @param netFunc      数据返回callback
 *  @param error        数据错误callback
 */
-(void)downloadFile:(RequestParam*)param savePath:(NSURL*)savePath progress:(Progress) progressFunc finished:(DownloadFinished) finishFunc Error:(ErrorResp) error;

/**
 *  上传文件
 *
 *  @param param        请求内容
 *  @param progressFunc 进度信息
 *  @param netFunc      数据返回callback
 *  @param error        数据错误callback
 */
-(void)uploadImage:(RequestParam*)param img:(UIImage*)img progress:(Progress) progressFunc finished:(UploadFinished) finishFunc Error:(ErrorResp) error;


/**
 *  获取当前网络状态
 *
 *  @return 网络状态
 */
-(NetworkReachabilityStatus) getNetReachabilityStatus;

-(void) uploadFile:(RequestParam *) param filePath:(NSString *) filePath progress:(Progress) Progress finished:(UploadFinished) finished Error:(ErrorResp) error;

@end
