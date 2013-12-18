#import "Label.h"

static int32_t hashCode(NSString *str) {
    int32_t hash = 0;
    int len = str.length;
    if (len == 0) return hash;
    for (int i = 0; i < len; i++) {
        unichar c = [str characterAtIndex:i];
        hash = ((hash << 5) - hash) + c;
    }
    return hash;
}

static NSString *base36enc(long unsigned int value)
{
    char base36[36] = "0123456789abcdefghijklmnopqrstuvwxyz";
    /* log(2**64) / log(36) = 12.38 => max 13 char + '\0' */
    char buffer[14];
    unsigned int offset = sizeof(buffer);
    
    buffer[--offset] = '\0';
    do {
        buffer[--offset] = base36[value % 36];
    } while (value /= 36);
    return [NSString stringWithUTF8String:&buffer[offset]];
}


@implementation Label

+ (NSString *)labelKeyForName:(NSString *)labelName
{
    return [NSString stringWithFormat:@"label_%@", base36enc(hashCode(labelName))];
}

@end
