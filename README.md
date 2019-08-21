# iOS_Speech_Recoginzer
**最近因为需要做语音导航功能，公司又不想花钱，哪儿免费往哪儿钻，于是就有了这次记录(调试的时候尽量先用下微信或者QQ的语音功能，先排除硬件问题，鬼知道百来行代码的东西我查了多久)**
# 1.添加隐私权限
`Privacy - Speech Recognition Usage Description`

`Privacy - Microphone Usage Description`

**PS：对应的描述尽量保持 `xxAPP在xx时候请求打开xx权限用来做xx事情`的方式，降低被拒风险**
# 2.导入框架
`#import <Speech/Speech.h>`

`#import <AVFoundation/AVFoundation.h>`
# 3.声明四个基本属性
`@property (nonatomic,strong) SFSpeechRecognizer *speechRecognizer;`

`@property (nonatomic,strong) SFSpeechRecognitionTask *speechTask;`

`@property (nonatomic,strong) SFSpeechAudioBufferRecognitionRequest *speechRequest;`

`@property (nonatomic,strong) AVAudioEngine *audioEngine;`

# 4.核心代码部分


```
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
            speechResult(nowString);//这里保留单次识别内容，bestString为所有识别内容
            self.speakText = bestString;
        }
        if (error || isFinished) {//error如果报code209错误 可能是设备原因 比如话筒坏了
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

```
