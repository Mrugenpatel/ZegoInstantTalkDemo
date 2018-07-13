//
//  ZegoAVKitManager.m
//  LiveDemo
//
//  Copyright © 2015年 Zego. All rights reserved.
//

#include "ZegoAVKitManager.h"

ZegoLiveApi *g_zegoAV = NULL;
NSData *g_signKey = nil;
uint32 g_appID = 0;

BOOL g_useTestEnv = NO;
BOOL g_useAlphaEnv = NO;

#if TARGET_OS_SIMULATOR
BOOL g_requireHardwareAccelerated = NO;
#else
BOOL g_requireHardwareAccelerated = YES;
#endif

BizLiveRoom *g_bizRoom = nil;

void setCustomAppIDAndSign(uint32 appid, NSData* data)
{
    g_appID = appid;
    g_signKey = data;
}


NSData * zegoAppSignFromServer()
{
    //!! Demo 把signKey先写到代码中
    //!! 规范用法：这个signKey需要从server下发到App，避免在App中存储，防止盗用
    
    Byte signkey[] = {0x91, 0x93, 0xcc, 0x66, 0x2a, 0x1c, 0x0e, 0xc1, 0x35, 0xec, 0x71, 0xfb, 0x07, 0x19, 0x4b, 0x38, 0x41, 0xd4, 0xad, 0x83, 0x78, 0xf2, 0x59, 0x90, 0xe0, 0xa4, 0x0c, 0x7f, 0xf4, 0x28, 0x41, 0xf7};
    
    return [NSData dataWithBytes:signkey length:32];
}


#import <ZegoAVKit2/ZegoVideoCapture.h>
#import "./advanced/video_capture_external_demo.h"
#import "./advanced/ZegoVideoCaptureFromImage.h"

static __strong id<ZegoVideoCaptureFactory> g_factory = nullptr;

void ZegoSetVideoCaptureDevice()
{
#if TARGET_OS_SIMULATOR
    if (g_factory == nullptr) {
        g_factory = [[ZegoVideoCaptureFactory alloc] init];
        [ZegoLiveApi setVideoCaptureFactory:g_factory];
    }
#else
    /*
     // try VideoCaptureFactoryDemo for camera
     if (g_factory == nullptr)
     {
     g_factory = [[VideoCaptureFactoryDemo alloc] init];
     [ZegoLiveApi setVideoCaptureFactory:g_factory];
     }
     */
#endif
}


ZegoLiveApi * getZegoAV_ShareInstance()
{
    if (g_zegoAV == nil) {
        [ZegoLiveApi setLogLevel:4];
        [ZegoLiveApi setUseTestEnv:g_useTestEnv];
        [ZegoLiveApi setBusinessType:2];
        
        ZegoSetVideoCaptureDevice();
        
        if (g_appID != 0 && g_signKey != nil) {
            g_zegoAV = [[ZegoLiveApi alloc] initWithAppID:g_appID appSignature:g_signKey];
        } else {
            NSData * appSign =  zegoAppSignFromServer();
            g_zegoAV = [[ZegoLiveApi alloc] initWithAppID:1 appSignature:appSign];
        }
        
        [g_zegoAV requireHardwareAccelerated:g_requireHardwareAccelerated];
    }
    return g_zegoAV;
}


void releaseZegoAV_ShareInstance()
{
    g_zegoAV = nil;
}

BizLiveRoom *getBizRoomInstance()
{
    if (g_bizRoom == nil)
    {
        [BizLiveRoom setLogLevel:4];
        
        uint32 appID = 766949305;
        Byte signKey[] = { 0x18,  0x9d,  0x83,  0x5a,  0x62,  0xe8,  0xec,
             0xbf,  0xc6,  0x58,  0x53,  0xeb,  0xaf,  0x26, 0x5a,
             0xab,  0x34,  0x48,  0x58,  0x6f,  0x7a,  0x9d,  0xd0,
             0x10,  0xee,  0xb3,  0x81,  0x78,  0x6d,  0x86,  0x18,  0x5d};
        NSData *signKeyData = [NSData dataWithBytes:signKey length:32];
        
        g_bizRoom = [[BizLiveRoom alloc] initWithBizID:appID bizSignature:signKeyData];
        if (g_bizRoom == nil)
        {
            NSString *alertMessage = NSLocalizedString(@"Zego Only", nil);
            NSLog(@"%@", alertMessage);
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:alertMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alertView show];
            
            assert(g_bizRoom != nil);
        }
    }
    
    return g_bizRoom;
}

void releaseBizRoomInstance()
{
    g_bizRoom = nil;
}

Byte toByte(NSString* c)
{
    NSString *str = @"0123456789abcdef";
    Byte b = [str rangeOfString:c].location;
    return b;
}

NSData* ConvertStringToSign(NSString* strSign)
{
    if(strSign == nil || strSign.length == 0)
        return nil;
    strSign = [strSign lowercaseString];
    strSign = [strSign stringByReplacingOccurrencesOfString:@" " withString:@""];
    strSign = [strSign stringByReplacingOccurrencesOfString:@"0x" withString:@""];
    NSArray* szStr = [strSign componentsSeparatedByString:@","];
    int nLen = (int)[szStr count];
    Byte szSign[32];
    for(int i = 0; i < nLen; i++)
    {
        NSString *strTmp = [szStr objectAtIndex:i];
        if(strTmp.length == 1)
            szSign[i] = toByte(strTmp);
        else
        {
            szSign[i] = toByte([strTmp substringWithRange:NSMakeRange(0, 1)]) << 4 | toByte([strTmp substringWithRange:NSMakeRange(1, 1)]);
        }
        NSLog(@"%x,", szSign[i]);
    }
    
    //    NSData *sign = [[NSData alloc]initWithBytes:szSign length:32];
    NSData *sign = [NSData dataWithBytes:szSign length:32];
    return sign;
}

void ZegoDemoSetCustomAppIDAndSign(uint32 appid, NSString* strSign)
{
    NSData *d = ConvertStringToSign(strSign);
    
    if (d.length == 32 && appid != 0) {
        g_appID = appid;
        g_signKey = [[NSData alloc] initWithData:d];
    }
    
    g_zegoAV = nil;
}

void setUseTestEnv(BOOL testEnv)
{
    g_useTestEnv = testEnv;
    [ZegoLiveApi setUseTestEnv:testEnv];
}


BOOL isUseingTestEnv()
{
    return g_useTestEnv;
}

uint32 ZegoGetAppID()
{
    return g_appID;
}

void ZegoRequireHardwareAccelerated(bool hardwareAccelerated)
{
    g_requireHardwareAccelerated = hardwareAccelerated;
    [g_zegoAV requireHardwareAccelerated:hardwareAccelerated];
}

BOOL ZegoIsRequireHardwareAccelerated()
{
    return g_requireHardwareAccelerated;
}

NSString *ZegoGetSDKVersion()
{
    return [getZegoAV_ShareInstance() version];
}

@interface NSObject()
// * suppress warning
+ (void)setUseAlphaEnv:(id)useAlphaEnv;
@end

void setUseAlphaEnv(BOOL alphaEnv)
{
    if ([ZegoLiveApi respondsToSelector:@selector(setUseAlphaEnv:)])
    {
        if (g_useAlphaEnv != alphaEnv)
            releaseZegoAV_ShareInstance();
        
        g_useAlphaEnv = alphaEnv;
        
        [ZegoLiveApi performSelector:@selector(setUseAlphaEnv:) withObject:@(alphaEnv)];
    }
}

BOOL isUsingAlphaEnv()
{
    return g_useAlphaEnv;
}
