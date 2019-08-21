//
//  HSpeechRecognizer.h
//
//  Created by  cynic on 2019/8/21.
//  Copyright © 2019年 cynic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Speech/Speech.h>
#import <AVFoundation/AVFoundation.h>
#import "SVProgressHUD/SVProgressHUD.h"


#define kSpeechManager [HSpeechRecognizer share]

@interface HSpeechRecognizer : NSObject <SFSpeechRecognizerDelegate>
@property (nonatomic,assign) BOOL isSpeechAuthorized;
@property (nonatomic,copy) NSString *speakText;

@property (nonatomic,strong) SFSpeechRecognizer *speechRecognizer;
@property (nonatomic,strong) SFSpeechRecognitionTask *speechTask;
@property (nonatomic,strong) SFSpeechAudioBufferRecognitionRequest *speechRequest;
@property (nonatomic,strong) AVAudioEngine *audioEngine;
  /* 必须网络支持 因为走得是苹果的服务器 */
+ (HSpeechRecognizer *)share;

- (void)requestSpeechAuthorization:(void(^)(BOOL isAuthorized))authorize;

- (void)startRecordSpeech:(void(^)(NSString *speakingText))speechResult;

- (void)endRecordSpeech;
@end

