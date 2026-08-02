//
//  QCloudStreamTTSController.h
//  QCloudStreamTTS
//
//  Created by tbolp on 2024/10/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

enum : NSInteger {
    STREAMTTSPARAMETERERROR = 2000, // 参数错误,SDK配置项设置有问题,一般为授权信息没有设置
    STREAMTTSWEBSOCKETERROR = 2001, // websocket错误,网络问题
    STREAMTTSCANCELERROR = 2002, // 取消错误,成功调用cancel返回此错误
    STREAMTTSSERVERERROR = 2003, // 服务端返回错误,可通过取userInfo中的Message获取详细信息
};

@protocol QCloudStreamTTSController <NSObject>

/*
 * 发送合成文本,需要在onReady后调用,否则发送的文本不会处理
 * @param text 需要合成的文本
 */
-(void)synthesis:(nonnull NSString*)text;
/*
 * 取消合成任务
 */
-(void)cancel;
/*
 * 停止合成任务
 */
-(void)stop;

@end

NS_ASSUME_NONNULL_END
