## ILSSCShareCenter

### 需求
Mercury移动浏览器有一个分享内容到第三方平台的功能，第三方平台的数量有十几个。现有的方案是将每个平台自家或第三方发布的SDK集成到项目中来实现。带来的问题是App体积包增大，代码的可控性降低。因为只需要实现文本和链接的分享，并不需要用到SDK所有的功能。为此开发了ILSSCShareCenter，ILSSCShareCenter只按照业务需要实现了Mercury中必要的分享功能。
ILSSCShareCenter由两部分组成：认证和分享。认证实现了OAuth1.0,OAuth2.0,OAuth2.0变体, XAuth认证协议；分享实现了对文本、网址链接、图片链接、文件的后台分享，需要注意，因平台不同，并不是所有平台都对这些分享内容作支持。

### ILSSCShareCenter目前支持的平台
  - Buffer
  - Delicious
  - Readability
  - Facebook
  - Pocket
  - Twitter
  - Pinterest
  - Instapaper
  - Dropbox
  - Tumblr
  - SinaWeibo
  - LinkedIn
  - Pinboard
  - Evernote
  - WeChat

### 配置ILSSCShareCenter
第一步：为了不更改原有的代码，对ILSSCShareCenter的配置需要你在你的项目中创建一个ILSSCDefaultConfigurator的子类，然后根据需要覆盖对应的配置方法。你需要在AppDelegate类中，尽早的初始化ILSSCConfiguration。示例代码如下：

```objective-c
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    MyConfigurator *configurator = [[MyConfigurator alloc] init];
    [ILSSCConfiguration sharedInstanceWithConfigurator:configurator];
    
    return YES;
}
```

第二步：因为有一些分享平台的认证是由浏览器将认证的信息通过OpenURL回传给App，所以还需要在AppDelegate类中处理登录回调信息:
```objective-c
- (BOOL)application: (UIApplication *)application openURL: (NSURL *)url sourceApplication: (NSString *)sourceApplication annotation: (id)annotation {
    if ([ILSSCShareCenter handLoginCallback:url]) {
        return YES;
    }
    
    return NO;
}
```

配置完成之后，就可以使用ILSSCShareCenter中如下方法完成分享：

```objective-c
- (void)shareWithShareModel:(ILSSCShareModel *)shareModel completeBlock:(void(^)(BOOL success, NSError *error))completeBlock;
```

注意,如果分享的平台不支持分享的内容类型，不支持的内容将被忽略。

### 参考资源
##### Buffer
https://buffer.com/developers/api/oauth
 
##### Delicious
 https://github.com/SciDevs/delicious-api 
 
##### Twitter
 https://dev.twitter.com/oauth/3-legged
 https://dev.twitter.com/rest/reference/post/statuses/update

##### Readability
 https://www.readability.com/developers/api/reader
 http://blog.csdn.net/yangjian8915/article/details/11816669
 https://github.com/Christian-Hansen/simple-oauth1
 
##### Facebook
 https://developers.facebook.com/docs/facebook-login/manually-build-a-login-flow/v2.3
 https://developers.facebook.com/docs/sharing/overview
 https://developers.facebook.com/docs/graph-api/reference/user/photos/#publish
 https://developers.facebook.com/docs/graph-api/common-scenarios#sharinglinks
 
##### Pocket
 http://getpocket.com/developer/docs/authentication

##### Pinterest
https://developers.pinterest.com/ios/

##### Instapaper
https://www.instapaper.com/api
https://dev.twitter.com/oauth/xauth

##### Dropbox
https://www.dropbox.com/developers/core/docs

##### Tumblr
https://www.tumblr.com/docs/en/api/v2#posting

##### SinaWeiBo
http://open.weibo.com/wiki/%E6%8E%88%E6%9D%83%E6%9C%BA%E5%88%B6#.E6.8E.88.E6.9D.83.E6.9C.89.E6.95.88.E6.9C.9F
http://open.weibo.com/wiki/V1_To_V2

##### LinkedIn
https://developer.linkedin.com/docs/oauth2
https://developer.linkedin.com/docs/share-on-linkedin

##### Pinboard
https://pinboard.in/api#user_api_token

##### Evernote 
https://dev.evernote.com/doc/

##### WeiXin
https://open.weixin.qq.com/cgi-bin/showdocument?action=dir_list&t=resource/res_list&verify=1&lang=zh_CN
