//
//  LoadingView.m
//  WYBasisKit
//
//  Created by  jacke-xu on 2018/8/14.
//  Copyright © 2018年 jacke-xu. All rights reserved.
//

#import "LoadingView.h"

@interface LoadingView ()

///显示文本
@property (nonatomic, weak) UILabel *label;

///系统小菊花
@property (nonatomic, weak) UIActivityIndicatorView *activity;

///自定义动图
@property (nonatomic, weak) UIImageView *heartImageView;

///用户交互状态
@property (nonatomic, assign) BOOL userInteraction;

@end

@implementation LoadingView

#pragma mark 构造单例
static LoadingView *_loadingView = nil;
+ (LoadingView *)shared {
    
    [StateView dismiss];
    
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        
        _loadingView = [[LoadingView alloc]init];
        _loadingView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
        _loadingView.layer.cornerRadius = 10;
        _loadingView.layer.masksToBounds = YES;
    });
    return _loadingView;
}

#pragma mark 构造方法
+ (void)showMessage:(NSString *)message {
    
    [self showMessageStr:[NSString emptyStr:message] showType:@"Message" superView:nil];
}

+ (void)showMessage:(NSString *)message superView:(UIView *)superView {
    
    [self showMessageStr:[NSString emptyStr:message] showType:@"Message" superView:superView];
}

+ (void)showInfo:(NSString *)info {
    
    [self showMessageStr:[NSString emptyStr:info] showType:@"Info" superView:nil];
}

+ (void)showInfo:(NSString *)info superView:(UIView *)superView {
    
    [self showMessageStr:[NSString emptyStr:info] showType:@"Info" superView:superView];
}

+ (void)userInteractionEnabled:(BOOL)userInteractionEnabled {
    
    [self shared].userInteraction = !userInteractionEnabled;
}

+ (void)showMessageStr:(NSString *)messageStr showType:(NSString *)showType superView:(UIView *)superView {
    
    //获取单例
    _loadingView = [self shared];
    
    //找到父控制器
    superView = [_loadingView sharedSuperView:superView];
    
    //初始化设置
    [self initializationSettings:showType messageStr:messageStr superView:superView];
    
    //添加到父控制器上
    [superView addSubview:_loadingView];
    
    //设置用户交互
    [UIApplication sharedApplication].keyWindow.userInteractionEnabled = !_loadingView.userInteraction;
}

+ (void)dismiss {
    
    //关闭动画
    [_loadingView.heartImageView stopAnimating];
    [_loadingView.activity stopAnimating];
    
    //移除自己
    [_loadingView removeFromSuperview];
    
    //打开用户交互
    [UIApplication sharedApplication].keyWindow.userInteractionEnabled = YES;
}

#pragma mark 查找当前显示的控制器的view，找不到就用keyWindow
- (UIView *)sharedSuperView:(UIView *)superView {
    
    if(superView == nil) {
        
        superView = ([self currentViewController].view == nil) ? [UIApplication sharedApplication].keyWindow : [self currentViewController].view;
    }
    
    //防止弹窗时键盘挡住自己
    [superView endEditing:YES];
    
    return superView;
}

#pragma mark 初始化设置
+ (void)initializationSettings:(NSString *)showType messageStr:(NSString *)messageStr superView:(UIView *)superView {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSLog(@"LoadingView提示文本：%@",messageStr);
        
        _loadingView.label.text = messageStr;
        _loadingView.label.hidden = !(messageStr.length > 0);
        
        if([showType isEqualToString:@"Message"]) {
            
            _loadingView.activity.hidden = YES;
            [_loadingView.activity stopAnimating];
            
            [_loadingView.heartImageView startAnimating];
            _loadingView.heartImageView.hidden = NO;
            
            //给定临时宽度
            CGFloat tempWidth = (_loadingView.label.hidden == YES) ? _loadingView.heartImageView.width+(_loadingView.heartImageView.top*2) : _loadingView.heartImageView.width+(_loadingView.label.left*2);
            
            if(_loadingView.label.hidden == NO) {
                
                //根据文本及计算弹窗width
                tempWidth = [self sharedWindowWidth:tempWidth];
            }
            
            _loadingView.heartImageView.left = (tempWidth - _loadingView.heartImageView.width)/2;
            
            _loadingView.label.top = _loadingView.heartImageView.bottom-10;//由于图片内容底部留白过大，这里减10，如更换图片可自行适当调整
            
            _loadingView.size = CGSizeMake(tempWidth, (_loadingView.label.hidden == YES) ? (tempWidth*0.95) : (_loadingView.label.bottom+10));//个人觉得不要完全正方形的好看一点
        }
        else {
            
            _loadingView.heartImageView.hidden = YES;
            [_loadingView.heartImageView stopAnimating];
            
            [_loadingView.activity startAnimating];
            _loadingView.activity.hidden = NO;
            
            //给定临时宽度
            CGFloat tempWidth = (_loadingView.label.hidden == YES) ? _loadingView.activity.width+(_loadingView.activity.top*2) : _loadingView.activity.width+(_loadingView.label.left*2)+40;
            
            if(_loadingView.label.hidden == NO) {
                
                //根据文本及计算弹窗width
                tempWidth = [self sharedWindowWidth:tempWidth];
            }
            
            _loadingView.activity.left = (tempWidth - _loadingView.activity.width)/2;
            
            _loadingView.label.top = _loadingView.activity.bottom+10;//由于图片内容底部留白过小，这里加10
            
            _loadingView.size = CGSizeMake(tempWidth, (_loadingView.label.hidden == YES) ? tempWidth : (_loadingView.label.bottom+10));//个人觉得不要完全正方形的好看一点
        }
        
        _loadingView.left = (screenWidth-_loadingView.width)/2;
        
        _loadingView.top = ((superView.height-_loadingView.height)/2)-(([UIScreen mainScreen].bounds.size.height-superView.height)/2);
    });
}

//布局关键
+ (CGFloat)sharedWindowWidth:(CGFloat)tempWidth {
    
    //临时宽度
    CGFloat windowWidth = tempWidth;
    //图像动画width
    CGFloat graphicalWidth = windowWidth-(_loadingView.label.left*2);
    //文本总宽度
    CGFloat textWidth = [_loadingView.label.text boundingRectWithSize:CGSizeMake(MAXFLOAT, _loadingView.label.font.lineHeight) withFont:_loadingView.label.font lineSpacing:0].width;
    
    //2行及以上(目前只适配2行)
    if(textWidth > graphicalWidth) {
        
        if(textWidth < (graphicalWidth+_loadingView.label.font.lineHeight)) {
            
            windowWidth = textWidth+(_loadingView.label.left*2);
        }
        else {
            
            windowWidth = graphicalWidth+_loadingView.label.font.lineHeight+(_loadingView.label.left*2);
        }
    }
    
    _loadingView.label.width = windowWidth-(_loadingView.label.left*2);
    //这里执行下sizeToFit，防止弹窗底部留白过大
    [_loadingView.label sizeToFit];
    //重置lable.size，防止原点改变
    _loadingView.label.size = CGSizeMake(windowWidth-((5+_loadingView.layer.cornerRadius)*2), _loadingView.label.height);
    
    return windowWidth;
}

#pragma mark 懒加载
- (UIActivityIndicatorView *)activity {
    
    if(_activity == nil) {
        
        UIActivityIndicatorView *acti = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        acti.size = CGSizeMake(40, 40);
        acti.top = 20;
        [_loadingView addSubview:acti];
        
        _activity = acti;
    }
    return _activity;
}

- (UILabel *)label {
    
    if(_label == nil) {
        
        UILabel *lab = [[UILabel alloc]init];
        lab.font = [UIFont boldSystemFontOfSize:16];
        lab.textColor = [UIColor whiteColor];
        lab.textAlignment = NSTextAlignmentCenter;
        lab.clipsToBounds = YES;
        lab.numberOfLines = 2;
        lab.left = 5+_loadingView.layer.cornerRadius;
        
        [_loadingView addSubview:lab];
        
        _label = lab;
    }
    return _label;
}

- (UIImageView *)heartImageView {
    
    if(_heartImageView == nil) {
        
        UIImageView *imgView = [[UIImageView alloc]initWithFrame:CGRectZero];
        NSMutableArray *images = [[NSMutableArray alloc]init];
        for (int i=1; i<=5; i++)
        {
            [images addObject:[UIImage imageWithContentsOfFile:[[[NSBundle mainBundle] pathForResource:@"Loading" ofType:@"bundle"] stringByAppendingPathComponent:[NSString stringWithFormat:@"loading%d.png",i]]]];
        }
        imgView.animationImages = images;
        imgView.animationDuration = 0.4 ;
        imgView.animationRepeatCount = MAXFLOAT;
        imgView.size = CGSizeMake(85, 85);
        imgView.top = 5;
        imgView.contentMode = UIViewContentModeScaleAspectFit;
        [_loadingView addSubview:imgView];
        
        _heartImageView = imgView;
    }
    return _heartImageView;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
