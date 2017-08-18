//
//  ViewController.m
//  RunLoop
//
//  Created by elong on 2017/8/17.
//  Copyright © 2017年 QCxy. All rights reserved.
//

#import "ViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "AutoreleaObject.h"

@interface ViewController ()

@property (strong, nonatomic) NSPort *emptyPort;
@property (strong, nonatomic) NSThread *thread;
@property (strong, nonatomic) NSTimer *timer;
@property (assign, nonatomic) CFRunLoopTimerRef cfTimer;
@property (assign, nonatomic) CFRunLoopSourceRef source;
@property (assign, nonatomic) NSInteger count;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //来自引用自，但是找不到链接了
    //每个线程 结束的时候 都会发送一个NSThreadWillExitNotification的通知
    //也可以点击调试窗口的暂停按钮，查看所有线程情况
    //首先 注册一个观察者对象 监听线程 是否结束(线程只要把 相关的函数执行完就结束)
    //通知中心 内部会起一个子线程 专门监听
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(threadWillEnd:) name:NSThreadWillExitNotification object:nil];
    [self test];
//    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(mainTimerTask) userInfo:nil repeats:YES];
    
    UIButton *wakeupButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    wakeupButton.frame = CGRectMake(20, 40, 300, 40);
    wakeupButton.layer.borderColor = [UIColor redColor].CGColor;
    wakeupButton.layer.borderWidth = 1;
    
    [wakeupButton setTitle:@"wake up" forState:UIControlStateNormal];
    [wakeupButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [wakeupButton addTarget:self action:@selector(tapWakeUP:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:wakeupButton];
    
    UIButton *stopTimerButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    stopTimerButton.frame = CGRectMake(20, wakeupButton.frame.origin.y+wakeupButton.frame.size.height+20, 300, 40);
    stopTimerButton.layer.borderColor = [UIColor redColor].CGColor;
    stopTimerButton.layer.borderWidth = 1;
    
    [stopTimerButton setTitle:@"stop timer" forState:UIControlStateNormal];
    [stopTimerButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [stopTimerButton addTarget:self action:@selector(stopTimer:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:stopTimerButton];
    
    UIButton *stopRunloopButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    stopRunloopButton.frame = CGRectMake(20, stopTimerButton.frame.origin.y+stopTimerButton.frame.size.height+20, 300, 40);
    stopRunloopButton.layer.borderColor = [UIColor redColor].CGColor;
    stopRunloopButton.layer.borderWidth = 1;
    
    [stopRunloopButton setTitle:@"stop runloop" forState:UIControlStateNormal];
    [stopRunloopButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [stopRunloopButton addTarget:self action:@selector(stopstopRunloopButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:stopRunloopButton];
}

- (void)mainTimerTask
{
    for (int index=0; index<5; index++) {
        //The Application Kit creates an autorelease pool on the main thread at the beginning of every cycle of the event loop, and drains it at the end
        //            @autoreleasepool {
        __autoreleasing AutoreleaObject *oibject = [[AutoreleaObject alloc] init];
        NSLog(@"------run:%@",oibject);
        //            }
    }
}


- (void)tapWakeUP:(id)sender {
    if (_thread.isFinished == NO) {
        //去RunLoop 的线程取得 RunLoop
        [self performSelector:@selector(wakeUP) onThread:_thread withObject:nil waitUntilDone:NO];
    }else{
        NSLog(@"thread = %@ isFinished", _thread);
    }
}

- (void)stopTimer:(UIButton *)button
{
    if (_thread.isFinished == NO) {
        //这里不用判断，因为停掉timer并不会造成，runloop停止
        [self performSelector:@selector(invalidateTimer) onThread:self.thread withObject:nil waitUntilDone:YES];
    }else{
        NSLog(@"thread = %@ isFinished", _thread);
    }
}

- (void)invalidateTimer
{
    //    在 invalidate 方法的文档里还有这这样一段话：
    //
    //    You must send this message from the thread on which the timer was installed. If you send this message from another thread, the input source associated with the timer may not be removed from its run loop, which could prevent the thread from exiting properly.
    //
    //    NSTimer 在哪个线程创建就要在哪个线程停止，否则会导致资源不能被正确的释放。
    //定时任务结束，runloop是否退出和启动runloop的方式有关系
    //如果通过[runloop runMode:NSDefaultRunLoopMode beforeDate:delayDate];方式启动，会造成没有要执行的任务runloop退出
    if (_timer) {
        [_timer invalidate];
        self.timer = nil;
    }
}

- (void)stopstopRunloopButtonClicked:(id)sender {
    if (_thread.isFinished == NO) {
        [self performSelector:@selector(stopRunloop) onThread:self.thread withObject:nil waitUntilDone:YES];
    }else{
        NSLog(@"thread = %@ isFinished", _thread);
    }
}

- (void)stopRunloop {
    
    //    [_thread cancel];//只是标记，并不会退出立即线程
    
//    [NSThread exit];//内存泄漏,直接退出线程，不会有退出runloop操作
    
    
//    NSRunLoop *runloop = [NSRunLoop currentRunLoop];
//    [runloop removePort:self.emptyPort forMode:NSDefaultRunLoopMode];//还可以停止timer
//    
//    CFRunLoopRef cfRunLoop= runloop.getCFRunLoop;
//    CFRunLoopStop(cfRunLoop);
//    或
//    CFRunLoopStop(CFRunLoopGetCurrent());
}

-(void)wakeUP{
    if (_source == nil) {
        NSLog(@"_source == nil");
    }else{
        //        NSLog(@"wakeUP Runloop:%@",CFRunLoopGetCurrent());
        CFRunLoopSourceSignal(_source);
        CFRunLoopWakeUp(CFRunLoopGetCurrent());
    }
}

- (void)threadWillEnd:(NSNotification *)nf {
    
    NSLog(@"线程结束:%@",nf.object);//谁发的通知
}

- (void)test
{
    for (int i = 0; i < 3; ++i) {
        if (i==0) {
            self.thread = [[NSThread alloc] initWithTarget:self selector:@selector(run0) object:nil];
            [self.thread start];
            NSLog(@"创建需长期存活子线程:%@",self.thread);
        }else{
            //这样声明 运行完任务 线程就退出了
            NSThread *tread = [[NSThread alloc] initWithTarget:self selector:@selector(run) object:nil];
            [tread start];
            NSLog(@"创建子线程:%@",tread);
        }
    }
}

- (void)run {
    NSLog(@"current thread = %@", [NSThread currentThread]);
//    for (int index=0; index<100000; index++) {
//        @autoreleasepool {
//            AutoreleaObject *oibject = [[AutoreleaObject alloc] init];
//            NSLog(@"------run:%@",oibject);
//        }
//    }
}

//创建SourceRunLoop
-(void)creatSourceRunLoop{
    NSLog(@"create RunLoop");
    @autoreleasepool {
        //source上下文
        CFRunLoopSourceContext context = {0};
        //指定事件回调
        context.perform = DoNothingRunLoopCallback;
        //为source添加事件
        self.source = CFRunLoopSourceCreate(NULL, 0, &context);
        // source添加到RunLoop
        CFRunLoopAddSource(CFRunLoopGetCurrent(), _source, kCFRunLoopCommonModes);
        
        [self observeReturn];
//        //监听事件直到RunLoop停止
//        CFRunLoopRun();
        
        //停止RunLoop的时候 移除source
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), _source, kCFRunLoopCommonModes);
        CFRelease(_source);
        NSLog(@"thread has stopped");
    }
}

static void DoNothingRunLoopCallback(void *info)
{
    NSLog(@"dosomething");
}


//需要长期存活的线程
- (void)run0 {
    if (!_emptyPort) {
        self.emptyPort = [NSMachPort port];
    }
    @autoreleasepool {
        NSLog(@"current thread = %@", [NSThread currentThread]);
        NSRunLoop *runloop = [NSRunLoop currentRunLoop];
        //    NSLog(@"----------currentRunLoop:%@",runloop);
        
        [self creatObserve];
        
        //添加端口并且不主动退出runloop可以使线程长期存活
        [runloop addPort:self.emptyPort forMode:NSDefaultRunLoopMode];//添加端口
        
        //单纯添加定时任务或者源并不能使线程长期存活，必须将runloop的超时时间设置成永远或者超级大的数1.0e10。并且不主动退出runloop，才能使线程长期存活
        //CFRunLoopRunSpecific(CFRunLoopGetCurrent(), kCFRunLoopDefaultMode, 1.0e10, false);
        //下边两个定时任务二选一
        //1  repeats:NO 定时任务执行一次，执行完runloop退出 线程结束
        
    //    self.timer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(doTimerTask1:) userInfo:nil repeats:YES];
    //    [runloop addTimer:_timer forMode:NSDefaultRunLoopMode];//NSRunLoopCommonModes可以使timer在UITrackingRunLoopMode也响应
        //如果是通过scheduledTimerWithTimeInterval创建的NSTimer, 默认就会添加到RunLoop得DefaultMode中
        //    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(doTimerTask1:) userInfo:nil repeats:YES];
        
    //    NSTimeInterval fireDate = CFAbsoluteTimeGetCurrent();
    //    self.cfTimer = CFRunLoopTimerCreateWithHandler(kCFAllocatorDefault, fireDate, 0.5f, 0, 0, ^(CFRunLoopTimerRef timer) {
    //        NSLog(@"cftimer task");
    //        _count++;
    //        if (_count == 2) {
    //            if (_cfTimer) {
    //                CFRunLoopRemoveTimer(CFRunLoopGetCurrent(), _cfTimer, kCFRunLoopCommonModes);
    //                CFRelease(_cfTimer);
    //                self.cfTimer = nil;//这里要将指针设置为nil，否则第二次调用handleRemoveCFTimer会出现EXC_BAD_ACCESS
    //            }
    //        }
    //    });
    //    CFRunLoopAddTimer(CFRunLoopGetCurrent(), _cfTimer, kCFRunLoopCommonModes);

        
        //2
        //    [self performSelector:@selector(printSomething) withObject:nil afterDelay:1];
        
//        for (int index=0; index<100; index++) {
//            //@autoreleasepool 开启 如下生成的autorelease对象马上就释放，如果注释掉@autoreleasepool，那么就是等到runloop退出，线程退出才释放autorelease对象
//            //            @autoreleasepool {
//            __autoreleasing AutoreleaObject *oibject = [[AutoreleaObject alloc] init];
//            NSLog(@"------run:%@",oibject);
//            //            }
//        }
        
        //输入源启动runloop
        [self creatSourceRunLoop];
        
        //3种启动方式
        //    - (void)run;
        //    - (void)runUntilDate:(NSDate *)limitDate;
        //    - (void)runMode:(NSString *)mode beforeDate:(NSDate *)limitDate;
        
        //    这三种方式无论通过哪一种方式启动runloop，如果没有一个输入源或者timer附加于runloop上，runloop就会立刻退出。
        //    　　(1) 使用第一种启动方式，runloop会一直运行下去，在此期间会处理来自输入源的数据，并且会在NSDefaultRunLoopMode模式下重复调用runMode:beforeDate:方法；
        //    　　(2) 使用第二种启动方式，可以设置超时时间，在超时时间到达之前，runloop会一直运行，在此期间runloop会处理来自输入源的数据，并且也会在NSDefaultRunLoopMode模式下重复调用runMode:beforeDate:方法；
        //    　　(3) 使用第三种启动方式，runloop会运行一次，超时时间到达或者第一个input source被处理且returnAfterSourceHandled==YES，则runloop就会退出。
        
        
        
//        [self observeReturn];
        
        
    //    NSDate *nowDate = [NSDate date];
    //    NSDate *futureDate = [NSDate distantFuture];
    //    NSInteger delaySecond = 4000;
    //    NSDate *delayDate = [NSDate dateWithTimeIntervalSinceNow:delaySecond];
    //    NSTimeInterval future = [futureDate timeIntervalSinceDate:nowDate];
    //    [runloop runMode:NSDefaultRunLoopMode beforeDate:delayDate];
    }
}

- (void)creatObserve {
    //创建监听者
    /*
     第一个参数 CFAllocatorRef allocator：分配存储空间 CFAllocatorGetDefault()默认分配
     第二个参数 CFOptionFlags activities：要监听的状态 kCFRunLoopAllActivities 监听所有状态
     第三个参数 Boolean repeats：YES:持续监听 NO:不持续
     第四个参数 CFIndex order：优先级，一般填0即可
     第五个参数 ：回调 两个参数observer:监听者 activity:监听的事件
     */
    /*
     所有事件
     typedef CF_OPTIONS(CFOptionFlags, CFRunLoopActivity) {
     kCFRunLoopEntry = (1UL << 0),   //   即将进入RunLoop
     kCFRunLoopBeforeTimers = (1UL << 1), // 即将处理Timer
     kCFRunLoopBeforeSources = (1UL << 2), // 即将处理Source
     kCFRunLoopBeforeWaiting = (1UL << 5), //即将进入休眠
     kCFRunLoopAfterWaiting = (1UL << 6),// 刚从休眠中唤醒
     kCFRunLoopExit = (1UL << 7),// 即将退出RunLoop
     kCFRunLoopAllActivities = 0x0FFFFFFFU
     };
     */
    CFRunLoopObserverRef observer = CFRunLoopObserverCreateWithHandler(CFAllocatorGetDefault(), kCFRunLoopAllActivities, YES, 0, ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
        switch (activity) {
            case kCFRunLoopEntry:
                NSLog(@"RunLoop进入");
                break;
            case kCFRunLoopBeforeTimers:
                NSLog(@"RunLoop要处理Timers了");
                break;
            case kCFRunLoopBeforeSources:
                NSLog(@"RunLoop要处理Sources了");
                break;
            case kCFRunLoopBeforeWaiting:
                NSLog(@"RunLoop要休息了");
                break;
            case kCFRunLoopAfterWaiting:
                NSLog(@"RunLoop醒来了");
                break;
            case kCFRunLoopExit:
                NSLog(@"RunLoop退出了");
                break;
                
            default:
                break;
        }
    });
    
    // 给RunLoop添加监听者
    /*
     第一个参数 CFRunLoopRef rl：要监听哪个RunLoop,这里监听的是主线程的RunLoop
     第二个参数 CFRunLoopObserverRef observer 监听者
     第三个参数 CFStringRef mode 要监听RunLoop在哪种运行模式下的状态
     */
    CFRunLoopAddObserver(CFRunLoopGetCurrent(), observer, kCFRunLoopDefaultMode);
    /*
     CF的内存管理（Core Foundation）
     凡是带有Create、Copy、Retain等字眼的函数，创建出来的对象，都需要在最后做一次release
     GCD本来在iOS6.0之前也是需要我们释放的，6.0之后GCD已经纳入到了ARC中，所以我们不需要管了
     */
    CFRelease(observer);
}

- (void)observeReturn {
    NSDate *nowDate = [NSDate date];
    NSDate *futureDate = [NSDate distantFuture];
    NSInteger delaySecond = 4000;
    NSDate *delayDate = [NSDate dateWithTimeIntervalSinceNow:delaySecond];
    NSTimeInterval future = [futureDate timeIntervalSinceDate:nowDate];
    
    //returnAfterSourceHandled参数表示runloop处理完source事件是否退出
    //NSRunloop是基于CFRunloop来封装的，NSRunloop是线程不安全的，而CFRunloop则是线程安全的。
    //使用 CFRunLoopRun() 启动 runloop，可以通过 CFRunLoopStop() 方法结束
    SInt32 result = CFRunLoopRunInMode(kCFRunLoopDefaultMode, delaySecond, YES);
    /*
     kCFRunLoopRunFinished = 1, //Run Loop结束，没有Timer或者其他Input Source
     kCFRunLoopRunStopped = 2, //Run Loop被停止，使用CFRunLoopStop停止Run Loop
     kCFRunLoopRunTimedOut = 3, //Run Loop超时
     kCFRunLoopRunHandledSource = 4 ////Run Loop处理完source事件returnAfterSourceHandled==YES那么runloop退出，否则不退出 runloop源码中if (stopAfterHandle && sourceHandled) {
     break;
     }
     */
    switch (result) {
        case kCFRunLoopRunFinished:
            NSLog(@"kCFRunLoopRunFinished");
            
            break;
        case kCFRunLoopRunStopped:
            NSLog(@"kCFRunLoopRunStopped");
            
        case kCFRunLoopRunTimedOut:
            NSLog(@"kCFRunLoopRunTimedOut");
            
        case kCFRunLoopRunHandledSource:
            NSLog(@"kCFRunLoopRunHandledSource");
        default:
            break;
    }
}

- (void)doTimerTask1:(NSTimer *)timer
{
    NSLog(@"current thread = %@", [NSThread currentThread]);
    //如果不停止timer，超时以后runloop就退出
    _count++;
//    if (_count == 2) {
//        [_timer invalidate];
//        self.timer = nil;
//    }
    NSLog(@"do timer task count:%ld",(long)_count);
}

- (void)printSomething {
    NSLog(@"printSomething current thread = %@", [NSThread currentThread]);
    [self performSelector:@selector(printSomething) withObject:nil afterDelay:1];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
