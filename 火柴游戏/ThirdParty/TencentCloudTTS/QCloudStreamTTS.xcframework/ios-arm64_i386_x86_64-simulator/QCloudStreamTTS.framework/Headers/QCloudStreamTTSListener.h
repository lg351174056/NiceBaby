//
//  QCloudStreamTTSListener.h
//  QCloudStreamTTS
//
//  Created by tbolp on 2024/10/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol QCloudStreamTTSListener <NSObject>

@required
/*
 * 合成任务结束
 */
-(void)onFinish;
/*
 * 合成任务出错
 * @param error 错误信息
 */
-(void)onError:(nonnull NSError*)error;

@optional
/*
 * 合成日志
 * @param value 日志信息
 * @param level 日志等级
 */
-(void)onLog:(nonnull NSString*)value level:(int)level;
/*
 * 服务端返回的音频数据,可参考文档https://cloud.tencent.com/document/product/1073/108595 说明
 * @param data 服务端返回的音频数据
 */
-(void)onData:(nonnull NSData*)data;
/*
 * 服务端返回的json数据,可参考文档https://cloud.tencent.com/document/product/1073/108595 说明
 * @param msg 服务端返回的json数据
 */
-(void)onMessage:(nonnull NSString*)msg;
/*
 * 服务端返回ready事件
 */
-(void)onReady;

@end

NS_ASSUME_NONNULL_END
