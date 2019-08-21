//
//  HSpeechRecognizer.m
//
//  Created by  cynic on 2019/8/21.
//  Copyright © 2019年 cynic. All rights reserved.
//

#import "HSpeechRecognizer.h"



@implementation HSpeechRecognizer

+ (HSpeechRecognizer *)share {
    static HSpeechRecognizer *mgr = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mgr = [[self.class alloc] init];
    });
    return mgr;
}
  /* 录音功能发生变化 */
- (void)speechRecognizer:(SFSpeechRecognizer *)speechRecognizer availabilityDidChange:(BOOL)available {
    NSLog(@"%@--%d",speechRecognizer,available);
}

- (void)startRecordSpeech:(void (^)(NSString *))speechResult{
    [self notAuthorized];
    if (self.speechTask) {
        [self.speechTask cancel];
        self.speechTask = nil;
    }
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *error;
    [audioSession setCategory:AVAudioSessionCategoryRecord error:&error];
    NSParameterAssert(!error);
    [audioSession setMode:AVAudioSessionModeMeasurement error:&error];
    NSParameterAssert(!error);
    [audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
    NSParameterAssert(!error);

      /* 故障原因弹窗提醒 */
    self.speechRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    AVAudioInputNode *inputNode = self.audioEngine.inputNode;
    self.speechRequest.shouldReportPartialResults = YES;
    NSAssert(inputNode, @"录音故障1--可能没准备好");
    NSAssert(self.speechRequest, @"录音故障2--requesth初始化失败");
    
    self.speechTask = [self.speechRecognizer recognitionTaskWithRequest:self.speechRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        BOOL isFinished = NO;
        if (result) {
            NSLog(@"%@",result.bestTranscription.formattedString);
            isFinished = result.isFinal;
            NSString *bestString = result.bestTranscription.formattedString;
            NSRange range = [bestString rangeOfString:self.speakText];
            NSString *nowString = [bestString substringFromIndex:range.length];
            speechResult(nowString);
            self.speakText = bestString;
        }
        if (error || isFinished) {
            [self.audioEngine stop];
            [inputNode removeTapOnBus:0];
            self.speechRequest = nil;
            self.speechTask = nil;
            NSLog(@"录音结束");
        }
    }];
    
    AVAudioFormat *format = [inputNode outputFormatForBus:0];
    [inputNode removeTapOnBus:0];
    [inputNode installTapOnBus:0 bufferSize:1024 format:format block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        if (self.speechRequest) {
            [self.speechRequest appendAudioPCMBuffer:buffer];
        }
    }];
    
    [self.audioEngine prepare];
    [self.audioEngine startAndReturnError:&error];
    NSParameterAssert(!error);
}

- (void)endRecordSpeech {
    [self notAuthorized];
    [self.audioEngine stop];
    if (self.speechRequest) {
        [self.speechRequest endAudio];
    }
    if (self.speechTask) {
        self.speechTask = nil;
        [self.speechTask cancel];
    }
    NSLog(@"录音关闭");
}

- (void)requestSpeechAuthorization:(void (^)(BOOL))authorize {
    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        self.isSpeechAuthorized = status == SFSpeechRecognizerAuthorizationStatusAuthorized;
        authorize(self.isSpeechAuthorized);
        switch (status) {
            case SFSpeechRecognizerAuthorizationStatusNotDetermined:
            {
                [self showFailureAlertViewWithMessage:@"Speech Recognizer Authorization Status-Not Determined"];
            }
                break;
            case SFSpeechRecognizerAuthorizationStatusDenied:
            {
                [self showFailureAlertViewWithMessage:@"Speech Recognizer Authorization Status-Denied"];
                
            }
                break;
            case SFSpeechRecognizerAuthorizationStatusRestricted:
            {
                [self showFailureAlertViewWithMessage:@"Speech Recognizer Authorization Status-Restricted"];
                
            }
                break;
            case SFSpeechRecognizerAuthorizationStatusAuthorized:
            {
                 [self showSuccessAlertViewWithMessage:@"Authorized"];
            }
                break;
                
            default:
                break;
        }
    }];
}
- (void)notAuthorized {
    if (!self.isSpeechAuthorized) {
        [self showFailureAlertViewWithMessage:@"Speech Recognizer Not Authorized/Not Determined/Not Support"];
    }
    return;
}
- (void)showSuccessAlertViewWithMessage:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD showSuccessWithStatus:NSLocalizedString(message, nil)];
        [SVProgressHUD dismissWithDelay:2];
    });
}
- (void)showFailureAlertViewWithMessage:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(message, nil)];
        [SVProgressHUD dismissWithDelay:2];
    });
}
  /* 语种只能识别一种 手机系统语言是什么就只能识别什么 选择性设置*/
- (SFSpeechRecognizer *)speechRecognizer {
    if (!_speechRecognizer) {//[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"]
        _speechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:[NSLocale currentLocale]];
        _speechRecognizer.delegate = self;
    }
    return _speechRecognizer;
}

- (AVAudioEngine *)audioEngine{
    if (!_audioEngine) {
        _audioEngine = [[AVAudioEngine alloc] init];
    }
    return _audioEngine;
}
@end
