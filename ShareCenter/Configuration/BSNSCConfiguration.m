//
//  BSNSCConfiguration.h
//  BSNShareCenter
//
//  Created by Jun Xia on 15/5/17.
//
//

#import "BSNSCConfiguration.h"
#import "BSNSCDefaultConfigurator.h"
#import "BSNSCDeclarations.h"

@interface BSNSCConfiguration ()

@property (readonly, strong) BSNSCDefaultConfigurator *configurator;

- (id)initWithConfigurator:(BSNSCDefaultConfigurator*)config;

@end

static BSNSCConfiguration *sharedInstance = nil;

@implementation BSNSCConfiguration

#pragma mark -
#pragma mark Instance methods

- (id)configurationValue:(NSString*)selector withObject:(id)object {
	//SHKLog(@"Looking for a configuration value for %@.", selector);

	SEL sel = NSSelectorFromString(selector);
	if ([self.configurator respondsToSelector:sel]) {
		id value;        
        if (object) {
            SuppressPerformSelectorLeakWarning(value = [self.configurator performSelector:sel withObject:object]);
        } else {
            SuppressPerformSelectorLeakWarning(value = [self.configurator performSelector:sel]);
        }

		if (value) {
			//SHKLog(@"Found configuration value for %@: %@", selector, [value description]);
			return value;
		}
	}

	//SHKLog(@"Configuration value is nil or not found for %@.", selector);
	return nil;
}

#pragma mark -
#pragma mark Singleton methods

// Singleton template based on http://stackoverflow.com/questions/145154

+ (BSNSCConfiguration*)sharedInstance
{
    @synchronized(self)
    {
        if (sharedInstance == nil) {
            [NSException raise:@"IllegalStateException" format:@"BSNShareCenter must be configured before use. Use your subclass of BSNSCDefaultConfigurator"];
        }
    }
    return sharedInstance;
}

+ (BSNSCConfiguration*)sharedInstanceWithConfigurator:(BSNSCDefaultConfigurator*)config
{
    if (sharedInstance != nil) {
		[NSException raise:@"IllegalStateException" format:@"SHKConfiguration has already been configured with a delegate."];
    }
    
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedInstance = [[self alloc] initWithConfigurator:config];
    });
    
    return sharedInstance;
}

- (id)initWithConfigurator:(BSNSCDefaultConfigurator*)config
{
    if ((self = [super init])) {
		_configurator = config;
    }
    return self;
}

@end
