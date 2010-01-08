//
//  Generated by preggers 0.2.0.
//

#import "PEGParser.h"

#import "Compiler.h"

@interface PEGParser ()

- (BOOL) _matchDot;
- (BOOL) _matchString:(char *)s;
- (BOOL) _matchClass:(unsigned char *)bits;
- (BOOL) matchAND;
- (BOOL) matchAction;
- (BOOL) matchBEGIN;
- (BOOL) matchCLOSE;
- (BOOL) matchChar;
- (BOOL) matchClass;
- (BOOL) matchComment;
- (BOOL) matchDOT;
- (BOOL) matchDefinition;
- (BOOL) matchEND;
- (BOOL) matchEffect;
- (BOOL) matchEndOfFile;
- (BOOL) matchEndOfLine;
- (BOOL) matchExpression;
- (BOOL) matchGrammar;
- (BOOL) matchIdentCont;
- (BOOL) matchIdentStart;
- (BOOL) matchIdentifier;
- (BOOL) matchLEFTARROW;
- (BOOL) matchLiteral;
- (BOOL) matchNOT;
- (BOOL) matchOPEN;
- (BOOL) matchOPTION;
- (BOOL) matchOption;
- (BOOL) matchPLUS;
- (BOOL) matchPrefix;
- (BOOL) matchPrimary;
- (BOOL) matchQUESTION;
- (BOOL) matchRange;
- (BOOL) matchSLASH;
- (BOOL) matchSTAR;
- (BOOL) matchSequence;
- (BOOL) matchSpace;
- (BOOL) matchSpacing;
- (BOOL) matchSuffix;

@end


@implementation PEGParser

@synthesize dataSource = _dataSource;
@synthesize compiler = _compiler;

//==================================================================================================
#pragma mark -
#pragma mark Rules
//==================================================================================================


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define YYRULECOUNT 32

#ifdef matchDEBUG
#define yyprintf(args)	{ fprintf args; fprintf(stderr," @ %s\n",[[_string substringFromIndex:_index] UTF8String]); }
#else
#define yyprintf(args)
#endif

- (BOOL) _refill
{
    if (!self.dataSource)
        return NO;

    NSString *nextString = [self.dataSource nextString];
    if (nextString)
    {
        nextString = [_string stringByAppendingString:nextString];
        [_string release];
        _string = [nextString retain];
    }
    _limit = [_string lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    yyprintf((stderr, "refill"));
    return YES;
}

- (BOOL) _matchDot
{
    if (_index >= _limit && ![self _refill]) return NO;
    ++_index;
    return YES;
}

- (BOOL) _matchString:(char *)s
{
#ifndef PEGPARSER_CASE_INSENSITIVE
    const char *cstring = [_string UTF8String];
#else
    const char *cstring = [[_string lowercaseString] UTF8String];
#endif
    int saved = _index;
    while (*s)
    {
        if (_index >= _limit && ![self _refill]) return NO;
        if (cstring[_index] != *s)
        {
            _index = saved;
    yyprintf((stderr, "  fail _matchString"));
            return NO;
        }
        ++s;
        ++_index;
    }
    yyprintf((stderr, "  ok   _matchString"));
    return YES;
}

- (BOOL) _matchClass:(unsigned char *)bits
{
    if (_index >= _limit && ![self _refill]) return NO;
    int c = [_string characterAtIndex:_index];
    if (bits[c >> 3] & (1 << (c & 7)))
    {
        ++_index;
        yyprintf((stderr, "  ok   _matchClass"));
        return YES;
    }
    yyprintf((stderr, "  fail _matchClass"));
    return NO;
}

- (void) yyDo:(SEL)action
{
    while (yythunkpos >= yythunkslen)
    {
        yythunkslen *= 2;
        yythunks= realloc(yythunks, sizeof(yythunk) * yythunkslen);
    }
    yythunks[yythunkpos].begin=  yybegin;
    yythunks[yythunkpos].end=    yyend;
    yythunks[yythunkpos].action= action;
    ++yythunkpos;
}

- (void) yyText:(int)begin to:(int)end
{
    int len = end - begin;
    if (len <= 0)
    {
        [_text release];
        _text = nil;
    }
    else
    {
        _text = [_string substringWithRange:NSMakeRange(begin, end-begin)];
        [_text retain];
    }
}

- (void) yyDone
{
    int pos;
    for (pos= 0;  pos < yythunkpos;  ++pos)
    {
        yythunk *thunk= &yythunks[pos];
        [self yyText:thunk->begin to:thunk->end];
        yyprintf((stderr, "DO [%d] %s %s\n", pos, [NSStringFromSelector(thunk->action) UTF8String], [_text UTF8String]));
        [self performSelector:thunk->action withObject:_text];
    }
    yythunkpos= 0;
}

- (void) yyCommit
{
    NSString *newString = [_string substringFromIndex:_index];
    [_string release];
    _string = [newString retain];
    _limit -= _index;
    _index = 0;

    yybegin -= _index;
    yyend -= _index;
    yythunkpos= 0;
}

- (void) yy_1_Option:(NSString *)text
{
 self.compiler.caseInsensitive = YES; ;
}

- (void) yy_1_Definition:(NSString *)text
{
 [self.compiler startRule:text]; ;
}

- (void) yy_2_Definition:(NSString *)text
{
 [self.compiler parsedRule]; ;
}

- (void) yy_1_Expression:(NSString *)text
{
 [self.compiler parsedAlternate]; ;
}

- (void) yy_1_Sequence:(NSString *)text
{
 [self.compiler append]; ;
}

- (void) yy_1_Prefix:(NSString *)text
{
 [self.compiler parsedLookAhead]; ;
}

- (void) yy_2_Prefix:(NSString *)text
{
 [self.compiler parsedNegativeLookAhead]; ;
}

- (void) yy_1_Suffix:(NSString *)text
{
 [self.compiler parsedQuestion]; ;
}

- (void) yy_2_Suffix:(NSString *)text
{
 [self.compiler parsedStar]; ;
}

- (void) yy_3_Suffix:(NSString *)text
{
 [self.compiler parsedPlus]; ;
}

- (void) yy_1_Primary:(NSString *)text
{
 [self.compiler parsedIdentifier:text]; ;
}

- (void) yy_2_Primary:(NSString *)text
{
 [self.compiler parsedLiteral:text]; ;
}

- (void) yy_3_Primary:(NSString *)text
{
 [self.compiler parsedClass:text]; ;
}

- (void) yy_4_Primary:(NSString *)text
{
 [self.compiler parsedDot]; ;
}

- (void) yy_1_Effect:(NSString *)text
{
 [self.compiler parsedAction:text]; ;
}

- (void) yy_2_Effect:(NSString *)text
{
 [self.compiler beginCapture]; ;
}

- (void) yy_3_Effect:(NSString *)text
{
 [self.compiler endCapture]; ;
}

- (BOOL) matchAND
{
    NSUInteger index0=_index, yythunkpos1=yythunkpos;
    yyprintf((stderr, "%s", "AND"));
    if (![self _matchString:"&"]) goto L2;
    if (![self matchSpacing]) goto L2;
    yyprintf((stderr, "  ok   %s", "AND"));
    return YES;
L2:
    _index=index0; yythunkpos=yythunkpos1;
    yyprintf((stderr, "  fail %s", "AND"));
    return NO;
}

- (BOOL) matchAction
{
    NSUInteger index5=_index, yythunkpos6=yythunkpos;
    yyprintf((stderr, "%s", "Action"));
    if (![self _matchString:"{"]) goto L7;
    yybegin = _index;
    ;
    NSUInteger index10, yythunkpos11;
L12:
    index10=_index; yythunkpos11=yythunkpos;
    if (![self _matchClass:(unsigned char *)"\377\377\377\377\377\377\377\377\377\377\377\377\377\377\377\337\377\377\377\377\377\377\377\377\377\377\377\377\377\377\377\377"]) goto L13;
    goto L12;
L13:
    _index=index10; yythunkpos=yythunkpos11;
    yyend = _index;
    if (![self _matchString:"}"]) goto L7;
    if (![self matchSpacing]) goto L7;
    yyprintf((stderr, "  ok   %s", "Action"));
    return YES;
L7:
    _index=index5; yythunkpos=yythunkpos6;
    yyprintf((stderr, "  fail %s", "Action"));
    return NO;
}

- (BOOL) matchBEGIN
{
    NSUInteger index14=_index, yythunkpos15=yythunkpos;
    yyprintf((stderr, "%s", "BEGIN"));
    if (![self _matchString:"<"]) goto L16;
    if (![self matchSpacing]) goto L16;
    yyprintf((stderr, "  ok   %s", "BEGIN"));
    return YES;
L16:
    _index=index14; yythunkpos=yythunkpos15;
    yyprintf((stderr, "  fail %s", "BEGIN"));
    return NO;
}

- (BOOL) matchCLOSE
{
    NSUInteger index19=_index, yythunkpos20=yythunkpos;
    yyprintf((stderr, "%s", "CLOSE"));
    if (![self _matchString:")"]) goto L21;
    if (![self matchSpacing]) goto L21;
    yyprintf((stderr, "  ok   %s", "CLOSE"));
    return YES;
L21:
    _index=index19; yythunkpos=yythunkpos20;
    yyprintf((stderr, "  fail %s", "CLOSE"));
    return NO;
}

- (BOOL) matchChar
{
    NSUInteger index24=_index, yythunkpos25=yythunkpos;
    yyprintf((stderr, "%s", "Char"));
    NSUInteger index27=_index, yythunkpos28=yythunkpos;
    if (![self _matchString:"\\"]) goto L30;
    if (![self _matchClass:(unsigned char *)"\000\000\000\000\204\000\000\000\000\000\000\070\000\100\024\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"]) goto L30;
    goto L29;
L30:
    _index=index27; yythunkpos=yythunkpos28;
    if (![self _matchString:"\\"]) goto L33;
    if (![self _matchClass:(unsigned char *)"\000\000\000\000\000\000\007\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"]) goto L33;
    if (![self _matchClass:(unsigned char *)"\000\000\000\000\000\000\377\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"]) goto L33;
    if (![self _matchClass:(unsigned char *)"\000\000\000\000\000\000\377\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"]) goto L33;
    goto L29;
L33:
    _index=index27; yythunkpos=yythunkpos28;
    if (![self _matchString:"\\"]) goto L36;
    if (![self _matchClass:(unsigned char *)"\000\000\000\000\000\000\377\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"]) goto L36;
    NSUInteger index39=_index, yythunkpos40=yythunkpos;
    if (![self _matchClass:(unsigned char *)"\000\000\000\000\000\000\377\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"]) goto L41;
    goto L42;
L41:
    _index=index39; yythunkpos=yythunkpos40;
L42:
    goto L29;
L36:
    _index=index27; yythunkpos=yythunkpos28;
    NSUInteger index45=_index, yythunkpos46=yythunkpos;
    if ([self _matchString:"\\"]) goto L26;
    _index=index45; yythunkpos=yythunkpos46;
    if (![self _matchDot]) goto L26;
    goto L29;
L29:
    yyprintf((stderr, "  ok   %s", "Char"));
    return YES;
L26:
    _index=index24; yythunkpos=yythunkpos25;
    yyprintf((stderr, "  fail %s", "Char"));
    return NO;
}

- (BOOL) matchClass
{
    NSUInteger index47=_index, yythunkpos48=yythunkpos;
    yyprintf((stderr, "%s", "Class"));
    if (![self _matchString:"["]) goto L49;
    yybegin = _index;
    ;
    NSUInteger index52, yythunkpos53;
L54:
    index52=_index; yythunkpos53=yythunkpos;
    NSUInteger index58=_index, yythunkpos59=yythunkpos;
    if ([self _matchString:"]"]) goto L55;
    _index=index58; yythunkpos=yythunkpos59;
    if (![self matchRange]) goto L55;
    goto L54;
L55:
    _index=index52; yythunkpos=yythunkpos53;
    yyend = _index;
    if (![self _matchString:"]"]) goto L49;
    if (![self matchSpacing]) goto L49;
    yyprintf((stderr, "  ok   %s", "Class"));
    return YES;
L49:
    _index=index47; yythunkpos=yythunkpos48;
    yyprintf((stderr, "  fail %s", "Class"));
    return NO;
}

- (BOOL) matchComment
{
    NSUInteger index60=_index, yythunkpos61=yythunkpos;
    yyprintf((stderr, "%s", "Comment"));
    if (![self _matchString:"#"]) goto L62;
    ;
    NSUInteger index65, yythunkpos66;
L67:
    index65=_index; yythunkpos66=yythunkpos;
    NSUInteger index71=_index, yythunkpos72=yythunkpos;
    if ([self matchEndOfLine]) goto L68;
    _index=index71; yythunkpos=yythunkpos72;
    if (![self _matchDot]) goto L68;
    goto L67;
L68:
    _index=index65; yythunkpos=yythunkpos66;
    if (![self matchEndOfLine]) goto L62;
    yyprintf((stderr, "  ok   %s", "Comment"));
    return YES;
L62:
    _index=index60; yythunkpos=yythunkpos61;
    yyprintf((stderr, "  fail %s", "Comment"));
    return NO;
}

- (BOOL) matchDOT
{
    NSUInteger index73=_index, yythunkpos74=yythunkpos;
    yyprintf((stderr, "%s", "DOT"));
    if (![self _matchString:"."]) goto L75;
    if (![self matchSpacing]) goto L75;
    yyprintf((stderr, "  ok   %s", "DOT"));
    return YES;
L75:
    _index=index73; yythunkpos=yythunkpos74;
    yyprintf((stderr, "  fail %s", "DOT"));
    return NO;
}

- (BOOL) matchDefinition
{
    NSUInteger index78=_index, yythunkpos79=yythunkpos;
    yyprintf((stderr, "%s", "Definition"));
    if (![self matchIdentifier]) goto L80;
    [self yyDo:@selector(yy_1_Definition:)];
    if (![self matchLEFTARROW]) goto L80;
    if (![self matchExpression]) goto L80;
    [self yyDo:@selector(yy_2_Definition:)];
    yyprintf((stderr, "  ok   %s", "Definition"));
    return YES;
L80:
    _index=index78; yythunkpos=yythunkpos79;
    yyprintf((stderr, "  fail %s", "Definition"));
    return NO;
}

- (BOOL) matchEND
{
    NSUInteger index83=_index, yythunkpos84=yythunkpos;
    yyprintf((stderr, "%s", "END"));
    if (![self _matchString:">"]) goto L85;
    if (![self matchSpacing]) goto L85;
    yyprintf((stderr, "  ok   %s", "END"));
    return YES;
L85:
    _index=index83; yythunkpos=yythunkpos84;
    yyprintf((stderr, "  fail %s", "END"));
    return NO;
}

- (BOOL) matchEffect
{
    NSUInteger index88=_index, yythunkpos89=yythunkpos;
    yyprintf((stderr, "%s", "Effect"));
    NSUInteger index91=_index, yythunkpos92=yythunkpos;
    if (![self matchAction]) goto L94;
    [self yyDo:@selector(yy_1_Effect:)];
    goto L93;
L94:
    _index=index91; yythunkpos=yythunkpos92;
    if (![self matchBEGIN]) goto L97;
    [self yyDo:@selector(yy_2_Effect:)];
    goto L93;
L97:
    _index=index91; yythunkpos=yythunkpos92;
    if (![self matchEND]) goto L90;
    [self yyDo:@selector(yy_3_Effect:)];
    goto L93;
L93:
    yyprintf((stderr, "  ok   %s", "Effect"));
    return YES;
L90:
    _index=index88; yythunkpos=yythunkpos89;
    yyprintf((stderr, "  fail %s", "Effect"));
    return NO;
}

- (BOOL) matchEndOfFile
{
    NSUInteger index102=_index, yythunkpos103=yythunkpos;
    yyprintf((stderr, "%s", "EndOfFile"));
    NSUInteger index105=_index, yythunkpos106=yythunkpos;
    if ([self _matchDot]) goto L104;
    _index=index105; yythunkpos=yythunkpos106;
    yyprintf((stderr, "  ok   %s", "EndOfFile"));
    return YES;
L104:
    _index=index102; yythunkpos=yythunkpos103;
    yyprintf((stderr, "  fail %s", "EndOfFile"));
    return NO;
}

- (BOOL) matchEndOfLine
{
    NSUInteger index107=_index, yythunkpos108=yythunkpos;
    yyprintf((stderr, "%s", "EndOfLine"));
    NSUInteger index110=_index, yythunkpos111=yythunkpos;
    if (![self _matchString:"\r\n"]) goto L113;
    goto L112;
L113:
    _index=index110; yythunkpos=yythunkpos111;
    if (![self _matchString:"\n"]) goto L114;
    goto L112;
L114:
    _index=index110; yythunkpos=yythunkpos111;
    if (![self _matchString:"\r"]) goto L109;
    goto L112;
L112:
    yyprintf((stderr, "  ok   %s", "EndOfLine"));
    return YES;
L109:
    _index=index107; yythunkpos=yythunkpos108;
    yyprintf((stderr, "  fail %s", "EndOfLine"));
    return NO;
}

- (BOOL) matchExpression
{
    NSUInteger index115=_index, yythunkpos116=yythunkpos;
    yyprintf((stderr, "%s", "Expression"));
    if (![self matchSequence]) goto L117;
    ;
    NSUInteger index120, yythunkpos121;
L122:
    index120=_index; yythunkpos121=yythunkpos;
    if (![self matchSLASH]) goto L123;
    if (![self matchSequence]) goto L123;
    [self yyDo:@selector(yy_1_Expression:)];
    goto L122;
L123:
    _index=index120; yythunkpos=yythunkpos121;
    yyprintf((stderr, "  ok   %s", "Expression"));
    return YES;
L117:
    _index=index115; yythunkpos=yythunkpos116;
    yyprintf((stderr, "  fail %s", "Expression"));
    return NO;
}

- (BOOL) matchGrammar
{
    NSUInteger index126=_index, yythunkpos127=yythunkpos;
    yyprintf((stderr, "%s", "Grammar"));
    if (![self matchSpacing]) goto L128;
    ;
    NSUInteger index131, yythunkpos132;
L133:
    index131=_index; yythunkpos132=yythunkpos;
    if (![self matchOption]) goto L134;
    goto L133;
L134:
    _index=index131; yythunkpos=yythunkpos132;
    if (![self matchSpacing]) goto L128;
    if (![self matchDefinition]) goto L128;
    ;
    NSUInteger index135, yythunkpos136;
L137:
    index135=_index; yythunkpos136=yythunkpos;
    if (![self matchDefinition]) goto L138;
    goto L137;
L138:
    _index=index135; yythunkpos=yythunkpos136;
    if (![self matchEndOfFile]) goto L128;
    yyprintf((stderr, "  ok   %s", "Grammar"));
    return YES;
L128:
    _index=index126; yythunkpos=yythunkpos127;
    yyprintf((stderr, "  fail %s", "Grammar"));
    return NO;
}

- (BOOL) matchIdentCont
{
    NSUInteger index139=_index, yythunkpos140=yythunkpos;
    yyprintf((stderr, "%s", "IdentCont"));
    NSUInteger index142=_index, yythunkpos143=yythunkpos;
    if (![self matchIdentStart]) goto L145;
    goto L144;
L145:
    _index=index142; yythunkpos=yythunkpos143;
    if (![self _matchClass:(unsigned char *)"\000\000\000\000\000\000\377\003\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"]) goto L141;
    goto L144;
L144:
    yyprintf((stderr, "  ok   %s", "IdentCont"));
    return YES;
L141:
    _index=index139; yythunkpos=yythunkpos140;
    yyprintf((stderr, "  fail %s", "IdentCont"));
    return NO;
}

- (BOOL) matchIdentStart
{
    NSUInteger index146=_index, yythunkpos147=yythunkpos;
    yyprintf((stderr, "%s", "IdentStart"));
    if (![self _matchClass:(unsigned char *)"\000\000\000\000\000\000\000\000\376\377\377\207\376\377\377\007\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"]) goto L148;
    yyprintf((stderr, "  ok   %s", "IdentStart"));
    return YES;
L148:
    _index=index146; yythunkpos=yythunkpos147;
    yyprintf((stderr, "  fail %s", "IdentStart"));
    return NO;
}

- (BOOL) matchIdentifier
{
    NSUInteger index149=_index, yythunkpos150=yythunkpos;
    yyprintf((stderr, "%s", "Identifier"));
    yybegin = _index;
    if (![self matchIdentStart]) goto L151;
    ;
    NSUInteger index154, yythunkpos155;
L156:
    index154=_index; yythunkpos155=yythunkpos;
    if (![self matchIdentCont]) goto L157;
    goto L156;
L157:
    _index=index154; yythunkpos=yythunkpos155;
    yyend = _index;
    if (![self matchSpacing]) goto L151;
    yyprintf((stderr, "  ok   %s", "Identifier"));
    return YES;
L151:
    _index=index149; yythunkpos=yythunkpos150;
    yyprintf((stderr, "  fail %s", "Identifier"));
    return NO;
}

- (BOOL) matchLEFTARROW
{
    NSUInteger index158=_index, yythunkpos159=yythunkpos;
    yyprintf((stderr, "%s", "LEFTARROW"));
    if (![self _matchString:"<-"]) goto L160;
    if (![self matchSpacing]) goto L160;
    yyprintf((stderr, "  ok   %s", "LEFTARROW"));
    return YES;
L160:
    _index=index158; yythunkpos=yythunkpos159;
    yyprintf((stderr, "  fail %s", "LEFTARROW"));
    return NO;
}

- (BOOL) matchLiteral
{
    NSUInteger index163=_index, yythunkpos164=yythunkpos;
    yyprintf((stderr, "%s", "Literal"));
    NSUInteger index166=_index, yythunkpos167=yythunkpos;
    if (![self _matchClass:(unsigned char *)"\000\000\000\000\200\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"]) goto L169;
    yybegin = _index;
    ;
    NSUInteger index172, yythunkpos173;
L174:
    index172=_index; yythunkpos173=yythunkpos;
    NSUInteger index178=_index, yythunkpos179=yythunkpos;
    if ([self _matchClass:(unsigned char *)"\000\000\000\000\200\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"]) goto L175;
    _index=index178; yythunkpos=yythunkpos179;
    if (![self matchChar]) goto L175;
    goto L174;
L175:
    _index=index172; yythunkpos=yythunkpos173;
    yyend = _index;
    if (![self _matchClass:(unsigned char *)"\000\000\000\000\200\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"]) goto L169;
    if (![self matchSpacing]) goto L169;
    goto L168;
L169:
    _index=index166; yythunkpos=yythunkpos167;
    if (![self _matchClass:(unsigned char *)"\000\000\000\000\004\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"]) goto L165;
    yybegin = _index;
    ;
    NSUInteger index182, yythunkpos183;
L184:
    index182=_index; yythunkpos183=yythunkpos;
    NSUInteger index188=_index, yythunkpos189=yythunkpos;
    if ([self _matchClass:(unsigned char *)"\000\000\000\000\004\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"]) goto L185;
    _index=index188; yythunkpos=yythunkpos189;
    if (![self matchChar]) goto L185;
    goto L184;
L185:
    _index=index182; yythunkpos=yythunkpos183;
    yyend = _index;
    if (![self _matchClass:(unsigned char *)"\000\000\000\000\004\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"]) goto L165;
    if (![self matchSpacing]) goto L165;
    goto L168;
L168:
    yyprintf((stderr, "  ok   %s", "Literal"));
    return YES;
L165:
    _index=index163; yythunkpos=yythunkpos164;
    yyprintf((stderr, "  fail %s", "Literal"));
    return NO;
}

- (BOOL) matchNOT
{
    NSUInteger index190=_index, yythunkpos191=yythunkpos;
    yyprintf((stderr, "%s", "NOT"));
    if (![self _matchString:"!"]) goto L192;
    if (![self matchSpacing]) goto L192;
    yyprintf((stderr, "  ok   %s", "NOT"));
    return YES;
L192:
    _index=index190; yythunkpos=yythunkpos191;
    yyprintf((stderr, "  fail %s", "NOT"));
    return NO;
}

- (BOOL) matchOPEN
{
    NSUInteger index195=_index, yythunkpos196=yythunkpos;
    yyprintf((stderr, "%s", "OPEN"));
    if (![self _matchString:"("]) goto L197;
    if (![self matchSpacing]) goto L197;
    yyprintf((stderr, "  ok   %s", "OPEN"));
    return YES;
L197:
    _index=index195; yythunkpos=yythunkpos196;
    yyprintf((stderr, "  fail %s", "OPEN"));
    return NO;
}

- (BOOL) matchOPTION
{
    NSUInteger index200=_index, yythunkpos201=yythunkpos;
    yyprintf((stderr, "%s", "OPTION"));
    if (![self _matchString:"@option"]) goto L202;
    NSUInteger index209=_index, yythunkpos210=yythunkpos;
    if ([self matchEndOfLine]) goto L202;
    _index=index209; yythunkpos=yythunkpos210;
    if (![self matchSpace]) goto L202;
    ;
    NSUInteger index205, yythunkpos206;
L211:
    index205=_index; yythunkpos206=yythunkpos;
    NSUInteger index215=_index, yythunkpos216=yythunkpos;
    if ([self matchEndOfLine]) goto L212;
    _index=index215; yythunkpos=yythunkpos216;
    if (![self matchSpace]) goto L212;
    goto L211;
L212:
    _index=index205; yythunkpos=yythunkpos206;
    yyprintf((stderr, "  ok   %s", "OPTION"));
    return YES;
L202:
    _index=index200; yythunkpos=yythunkpos201;
    yyprintf((stderr, "  fail %s", "OPTION"));
    return NO;
}

- (BOOL) matchOption
{
    NSUInteger index217=_index, yythunkpos218=yythunkpos;
    yyprintf((stderr, "%s", "Option"));
    if (![self matchOPTION]) goto L219;
    if (![self _matchString:"case-insensitive"]) goto L219;
    ;
    NSUInteger index222, yythunkpos223;
L224:
    index222=_index; yythunkpos223=yythunkpos;
    NSUInteger index228=_index, yythunkpos229=yythunkpos;
    if ([self matchEndOfLine]) goto L225;
    _index=index228; yythunkpos=yythunkpos229;
    if (![self matchSpace]) goto L225;
    goto L224;
L225:
    _index=index222; yythunkpos=yythunkpos223;
    if (![self matchEndOfLine]) goto L219;
    [self yyDo:@selector(yy_1_Option:)];
    yyprintf((stderr, "  ok   %s", "Option"));
    return YES;
L219:
    _index=index217; yythunkpos=yythunkpos218;
    yyprintf((stderr, "  fail %s", "Option"));
    return NO;
}

- (BOOL) matchPLUS
{
    NSUInteger index230=_index, yythunkpos231=yythunkpos;
    yyprintf((stderr, "%s", "PLUS"));
    if (![self _matchString:"+"]) goto L232;
    if (![self matchSpacing]) goto L232;
    yyprintf((stderr, "  ok   %s", "PLUS"));
    return YES;
L232:
    _index=index230; yythunkpos=yythunkpos231;
    yyprintf((stderr, "  fail %s", "PLUS"));
    return NO;
}

- (BOOL) matchPrefix
{
    NSUInteger index235=_index, yythunkpos236=yythunkpos;
    yyprintf((stderr, "%s", "Prefix"));
    NSUInteger index238=_index, yythunkpos239=yythunkpos;
    if (![self matchAND]) goto L241;
    if (![self matchSuffix]) goto L241;
    [self yyDo:@selector(yy_1_Prefix:)];
    goto L240;
L241:
    _index=index238; yythunkpos=yythunkpos239;
    if (![self matchNOT]) goto L244;
    if (![self matchSuffix]) goto L244;
    [self yyDo:@selector(yy_2_Prefix:)];
    goto L240;
L244:
    _index=index238; yythunkpos=yythunkpos239;
    if (![self matchSuffix]) goto L247;
    goto L240;
L247:
    _index=index238; yythunkpos=yythunkpos239;
    if (![self matchEffect]) goto L237;
    goto L240;
L240:
    yyprintf((stderr, "  ok   %s", "Prefix"));
    return YES;
L237:
    _index=index235; yythunkpos=yythunkpos236;
    yyprintf((stderr, "  fail %s", "Prefix"));
    return NO;
}

- (BOOL) matchPrimary
{
    NSUInteger index248=_index, yythunkpos249=yythunkpos;
    yyprintf((stderr, "%s", "Primary"));
    NSUInteger index251=_index, yythunkpos252=yythunkpos;
    if (![self matchIdentifier]) goto L254;
    NSUInteger index257=_index, yythunkpos258=yythunkpos;
    if ([self matchLEFTARROW]) goto L254;
    _index=index257; yythunkpos=yythunkpos258;
    [self yyDo:@selector(yy_1_Primary:)];
    goto L253;
L254:
    _index=index251; yythunkpos=yythunkpos252;
    if (![self matchOPEN]) goto L259;
    if (![self matchExpression]) goto L259;
    if (![self matchCLOSE]) goto L259;
    goto L253;
L259:
    _index=index251; yythunkpos=yythunkpos252;
    if (![self matchLiteral]) goto L262;
    [self yyDo:@selector(yy_2_Primary:)];
    goto L253;
L262:
    _index=index251; yythunkpos=yythunkpos252;
    if (![self matchClass]) goto L265;
    [self yyDo:@selector(yy_3_Primary:)];
    goto L253;
L265:
    _index=index251; yythunkpos=yythunkpos252;
    if (![self matchDOT]) goto L250;
    [self yyDo:@selector(yy_4_Primary:)];
    goto L253;
L253:
    yyprintf((stderr, "  ok   %s", "Primary"));
    return YES;
L250:
    _index=index248; yythunkpos=yythunkpos249;
    yyprintf((stderr, "  fail %s", "Primary"));
    return NO;
}

- (BOOL) matchQUESTION
{
    NSUInteger index270=_index, yythunkpos271=yythunkpos;
    yyprintf((stderr, "%s", "QUESTION"));
    if (![self _matchString:"?"]) goto L272;
    if (![self matchSpacing]) goto L272;
    yyprintf((stderr, "  ok   %s", "QUESTION"));
    return YES;
L272:
    _index=index270; yythunkpos=yythunkpos271;
    yyprintf((stderr, "  fail %s", "QUESTION"));
    return NO;
}

- (BOOL) matchRange
{
    NSUInteger index275=_index, yythunkpos276=yythunkpos;
    yyprintf((stderr, "%s", "Range"));
    NSUInteger index278=_index, yythunkpos279=yythunkpos;
    if (![self matchChar]) goto L281;
    if (![self _matchString:"-"]) goto L281;
    if (![self matchChar]) goto L281;
    goto L280;
L281:
    _index=index278; yythunkpos=yythunkpos279;
    if (![self matchChar]) goto L277;
    goto L280;
L280:
    yyprintf((stderr, "  ok   %s", "Range"));
    return YES;
L277:
    _index=index275; yythunkpos=yythunkpos276;
    yyprintf((stderr, "  fail %s", "Range"));
    return NO;
}

- (BOOL) matchSLASH
{
    NSUInteger index284=_index, yythunkpos285=yythunkpos;
    yyprintf((stderr, "%s", "SLASH"));
    if (![self _matchString:"/"]) goto L286;
    if (![self matchSpacing]) goto L286;
    yyprintf((stderr, "  ok   %s", "SLASH"));
    return YES;
L286:
    _index=index284; yythunkpos=yythunkpos285;
    yyprintf((stderr, "  fail %s", "SLASH"));
    return NO;
}

- (BOOL) matchSTAR
{
    NSUInteger index289=_index, yythunkpos290=yythunkpos;
    yyprintf((stderr, "%s", "STAR"));
    if (![self _matchString:"*"]) goto L291;
    if (![self matchSpacing]) goto L291;
    yyprintf((stderr, "  ok   %s", "STAR"));
    return YES;
L291:
    _index=index289; yythunkpos=yythunkpos290;
    yyprintf((stderr, "  fail %s", "STAR"));
    return NO;
}

- (BOOL) matchSequence
{
    NSUInteger index294=_index, yythunkpos295=yythunkpos;
    yyprintf((stderr, "%s", "Sequence"));
    NSUInteger index299=_index, yythunkpos300=yythunkpos;
    if (![self matchPrefix]) goto L301;
    goto L302;
L301:
    _index=index299; yythunkpos=yythunkpos300;
L302:
    ;
    NSUInteger index303, yythunkpos304;
L305:
    index303=_index; yythunkpos304=yythunkpos;
    if (![self matchPrefix]) goto L306;
    [self yyDo:@selector(yy_1_Sequence:)];
    goto L305;
L306:
    _index=index303; yythunkpos=yythunkpos304;
    yyprintf((stderr, "  ok   %s", "Sequence"));
    return YES;
L296:
    _index=index294; yythunkpos=yythunkpos295;
    yyprintf((stderr, "  fail %s", "Sequence"));
    return NO;
}

- (BOOL) matchSpace
{
    NSUInteger index309=_index, yythunkpos310=yythunkpos;
    yyprintf((stderr, "%s", "Space"));
    NSUInteger index312=_index, yythunkpos313=yythunkpos;
    if (![self _matchString:" "]) goto L315;
    goto L314;
L315:
    _index=index312; yythunkpos=yythunkpos313;
    if (![self _matchString:"\t"]) goto L316;
    goto L314;
L316:
    _index=index312; yythunkpos=yythunkpos313;
    if (![self matchEndOfLine]) goto L311;
    goto L314;
L314:
    yyprintf((stderr, "  ok   %s", "Space"));
    return YES;
L311:
    _index=index309; yythunkpos=yythunkpos310;
    yyprintf((stderr, "  fail %s", "Space"));
    return NO;
}

- (BOOL) matchSpacing
{
    NSUInteger index317=_index, yythunkpos318=yythunkpos;
    yyprintf((stderr, "%s", "Spacing"));
    ;
    NSUInteger index320, yythunkpos321;
L322:
    index320=_index; yythunkpos321=yythunkpos;
    NSUInteger index324=_index, yythunkpos325=yythunkpos;
    if (![self matchSpace]) goto L327;
    goto L326;
L327:
    _index=index324; yythunkpos=yythunkpos325;
    if (![self matchComment]) goto L323;
    goto L326;
L326:
    goto L322;
L323:
    _index=index320; yythunkpos=yythunkpos321;
    yyprintf((stderr, "  ok   %s", "Spacing"));
    return YES;
L319:
    _index=index317; yythunkpos=yythunkpos318;
    yyprintf((stderr, "  fail %s", "Spacing"));
    return NO;
}

- (BOOL) matchSuffix
{
    NSUInteger index328=_index, yythunkpos329=yythunkpos;
    yyprintf((stderr, "%s", "Suffix"));
    if (![self matchPrimary]) goto L330;
    NSUInteger index333=_index, yythunkpos334=yythunkpos;
    NSUInteger index337=_index, yythunkpos338=yythunkpos;
    if (![self matchQUESTION]) goto L340;
    [self yyDo:@selector(yy_1_Suffix:)];
    goto L339;
L340:
    _index=index337; yythunkpos=yythunkpos338;
    if (![self matchSTAR]) goto L343;
    [self yyDo:@selector(yy_2_Suffix:)];
    goto L339;
L343:
    _index=index337; yythunkpos=yythunkpos338;
    if (![self matchPLUS]) goto L335;
    [self yyDo:@selector(yy_3_Suffix:)];
    goto L339;
L339:
    goto L336;
L335:
    _index=index333; yythunkpos=yythunkpos334;
L336:
    yyprintf((stderr, "  ok   %s", "Suffix"));
    return YES;
L330:
    _index=index328; yythunkpos=yythunkpos329;
    yyprintf((stderr, "  fail %s", "Suffix"));
    return NO;
}

- (BOOL) yyparsefrom:(SEL)startRule
{
    BOOL yyok;
    if (!yythunkslen)
    {
        yythunkslen= 32;
        yythunks= malloc(sizeof(yythunk) * yythunkslen);
        yybegin= yyend= yythunkpos= 0;
    }
    if (!_string)
    {
        _string = [NSString new];
        _limit = 0;
        _index = 0;
    }
    yybegin= yyend= _index;
    yythunkpos= 0;

    NSMethodSignature *sig = [[self class] instanceMethodSignatureForSelector:startRule];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
    [invocation setTarget:self];
    [invocation setSelector:startRule];
    [invocation invoke];
    [invocation getReturnValue:&yyok];
    if (yyok) [self yyDone];
    [self yyCommit];

    [_string release];
    _string = nil;
    [_text release];
    _text = nil;

    return yyok;
}

- (BOOL) yyparse
{
    return [self yyparsefrom:@selector(matchGrammar)];
}


//==================================================================================================
#pragma mark -
#pragma mark NSObject Methods
//==================================================================================================

- (void) dealloc
{
    free(yythunks);

    [_string release];

    [super dealloc];
}


//==================================================================================================
#pragma mark -
#pragma mark Public Methods
//==================================================================================================

- (BOOL) parse
{
    NSAssert(_dataSource != nil, @"can't call -parse without specifying a data source");
    return [self yyparse];
}


- (BOOL) parseString:(NSString *)string
{
    _string = [string copy];
    _limit  = [_string lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    _index  = 0;
    BOOL retval = [self yyparse];
    [_string release];
    _string = nil;
    return retval;
}


@end

