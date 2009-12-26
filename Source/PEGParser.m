//
//  PEGParser.m
//  preggers
//
//  Created by Matt Diephouse on 12/17/09.
//  This code is in the public domain.
//

#import "PEGParser.h"

#import "Compiler.h"

@interface PEGParser ()

- (BOOL) _matchDot;
- (BOOL) _matchChar:(int)c;
- (BOOL) _matchString:(char *)s;
- (BOOL) _matchClass:(unsigned char *)bits;
- (BOOL) matchEndOfLine;
- (BOOL) matchComment;
- (BOOL) matchSpace;
- (BOOL) matchRange;
- (BOOL) matchChar;
- (BOOL) matchIdentCont;
- (BOOL) matchIdentStart;
- (BOOL) matchEND;
- (BOOL) matchBEGIN;
- (BOOL) matchAction;
- (BOOL) matchDOT;
- (BOOL) matchClass;
- (BOOL) matchLiteral;
- (BOOL) matchCLOSE;
- (BOOL) matchOPEN;
- (BOOL) matchPLUS;
- (BOOL) matchSTAR;
- (BOOL) matchQUESTION;
- (BOOL) matchPrimary;
- (BOOL) matchNOT;
- (BOOL) matchSuffix;
- (BOOL) matchAND;
- (BOOL) matchPrefix;
- (BOOL) matchSLASH;
- (BOOL) matchSequence;
- (BOOL) matchExpression;
- (BOOL) matchLEFTARROW;
- (BOOL) matchIdentifier;
- (BOOL) matchEndOfFile;
- (BOOL) matchDefinition;
- (BOOL) matchSpacing;
- (BOOL) matchGrammar;

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

#ifndef YY_BEGIN
#define YY_BEGIN	( yybegin= yypos, 1)
#endif

#ifndef YY_END
#define YY_END		( yyend= yypos, 1)
#endif

#ifdef matchDEBUG
# define yyprintf(args)	fprintf args
#else
# define yyprintf(args)
#endif

- (BOOL) _refill
{
    int yyn;
    while (yybuflen - yypos < 512)
    {
        yybuflen *= 2;
        yybuf= realloc(yybuf, yybuflen);
    }
    NSUInteger max_size = yybuflen - yypos;
    if (_string && self.dataSource)
    {
        _string = [[self.dataSource nextString] copy];
        _loc = 0;
    }
    if (!_string)
        yyn = 0;
    else
    {
        NSUInteger len = [_string lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        yyn = len - _loc;
        if (yyn > max_size)
            yyn = max_size;
        const char *string = [[_string substringWithRange:NSMakeRange(_loc, yyn)] UTF8String];
        memcpy(yybuf + yypos, string, yyn);
        if (yyn == len - _loc)
        {
            [_string release];
            _string = nil;
        }
        _loc += yyn;
    }
    yyprintf((stderr, "<%s>", yybuf + yypos));
    if (!yyn) return NO;
    yylimit += yyn;
    return YES;
}

- (BOOL) _matchDot
{
    if (yypos >= yylimit && ![self _refill]) return NO;
    ++yypos;
    return YES;
}

- (BOOL) _matchChar:(int)c
{
    if (yypos >= yylimit && ![self _refill]) return NO;
    if (yybuf[yypos] == c)
    {
        ++yypos;
        yyprintf((stderr, "  ok   _matchChar(%c) @ %s\n", c, yybuf+yypos));
        return YES;
    }
    yyprintf((stderr, "  fail _matchChar(%c) @ %s\n", c, yybuf+yypos));
    return NO;
}

- (BOOL) _matchString:(char *)s
{
    int yysav= yypos;
    while (*s)
    {
        if (yypos >= yylimit && ![self _refill]) return NO;
        if (yybuf[yypos] != *s)
        {
            yypos= yysav;
            return NO;
        }
        ++s;
        ++yypos;
    }
    return YES;
}

- (BOOL) _matchClass:(unsigned char *)bits
{
    int c;
    if (yypos >= yylimit && ![self _refill]) return NO;
    c= yybuf[yypos];
    if (bits[c >> 3] & (1 << (c & 7)))
    {
        ++yypos;
        yyprintf((stderr, "  ok   _matchClass @ %s\n", yybuf+yypos));
        return YES;
    }
    yyprintf((stderr, "  fail _matchClass @ %s\n", yybuf+yypos));
    return NO;
}

- (void) yyDo:(SEL)action from:(int)begin to:(int)end
{
    while (yythunkpos >= yythunkslen)
    {
        yythunkslen *= 2;
        yythunks= realloc(yythunks, sizeof(yythunk) * yythunkslen);
    }
    yythunks[yythunkpos].begin=  begin;
    yythunks[yythunkpos].end=    end;
    yythunks[yythunkpos].action= action;
    ++yythunkpos;
}

- (int) yyText:(int)begin to:(int)end
{
    int yyleng= end - begin;
    if (yyleng <= 0)
        yyleng= 0;
    else
    {
        while (yytextlen < (yyleng - 1))
        {
            yytextlen *= 2;
            yytext= realloc(yytext, yytextlen);
        }
        memcpy(yytext, yybuf + begin, yyleng);
    }
    yytext[yyleng]= '\0';
    return yyleng;
}

- (void) yyDone
{
    int pos;
    for (pos= 0;  pos < yythunkpos;  ++pos)
    {
        yythunk *thunk= &yythunks[pos];
        [self yyText:thunk->begin to:thunk->end];
        yyprintf((stderr, "DO [%d] %p %s\n", pos, thunk->action, yytext));
        [self performSelector:thunk->action withObject:[NSString stringWithUTF8String:yytext]];
    }
    yythunkpos= 0;
}

- (void) yyCommit
{
    if ((yylimit -= yypos))
    {
        memmove(yybuf, yybuf + yypos, yylimit);
    }
    yybegin -= yypos;
    yyend -= yypos;
    yypos= yythunkpos= 0;
}

- (BOOL) yyAccept:(int)tp0
{
    if (tp0)
    {
        fprintf(stderr, "accept denied at %d\n", tp0);
        return NO;
    }
    else
    {
        [self yyDone];
        [self yyCommit];
    }
    return YES;
}

#define	YYACCEPT	[self yyAccept:yythunkpos0]

- (void) yy_7_Primary:(NSString *)text
{
    yyprintf((stderr, "do yy_7_Primary\n"));
    [self.compiler endCapture]; ;
}

- (void) yy_6_Primary:(NSString *)text
{
    yyprintf((stderr, "do yy_6_Primary\n"));
    [self.compiler beginCapture]; ;
}

- (void) yy_5_Primary:(NSString *)text
{
    yyprintf((stderr, "do yy_5_Primary\n"));
    [self.compiler parsedAction:text]; ;
}

- (void) yy_4_Primary:(NSString *)text
{
    yyprintf((stderr, "do yy_4_Primary\n"));
    [self.compiler parsedDot]; ;
}

- (void) yy_3_Primary:(NSString *)text
{
    yyprintf((stderr, "do yy_3_Primary\n"));
    [self.compiler parsedClass:text]; ;
}

- (void) yy_2_Primary:(NSString *)text
{
    yyprintf((stderr, "do yy_2_Primary\n"));
    [self.compiler parsedLiteral:text]; ;
}

- (void) yy_1_Primary:(NSString *)text
{
    yyprintf((stderr, "do yy_1_Primary\n"));
    [self.compiler parsedIdentifier:text]; ;
}

- (void) yy_3_Suffix:(NSString *)text
{
    yyprintf((stderr, "do yy_3_Suffix\n"));
    [self.compiler parsedPlus]; ;
}

- (void) yy_2_Suffix:(NSString *)text
{
    yyprintf((stderr, "do yy_2_Suffix\n"));
    [self.compiler parsedStar]; ;
}

- (void) yy_1_Suffix:(NSString *)text
{
    yyprintf((stderr, "do yy_1_Suffix\n"));
    [self.compiler parsedQuestion]; ;
}

- (void) yy_2_Prefix:(NSString *)text
{
    yyprintf((stderr, "do yy_2_Prefix\n"));
    [self.compiler parsedNegativeLookAhead]; ;
}

- (void) yy_1_Prefix:(NSString *)text
{
    yyprintf((stderr, "do yy_1_Prefix\n"));
    [self.compiler parsedLookAhead]; ;
}

- (void) yy_1_Sequence:(NSString *)text
{
    yyprintf((stderr, "do yy_1_Sequence\n"));
    [self.compiler append]; ;
}

- (void) yy_1_Expression:(NSString *)text
{
    yyprintf((stderr, "do yy_1_Expression\n"));
    [self.compiler parsedAlternate]; ;
}

- (void) yy_1_Definition:(NSString *)text
{
    yyprintf((stderr, "do yy_1_Definition\n"));
    [self.compiler parsedRule:text]; ;
}

- (BOOL) matchEndOfLine
{  int yypos0= yypos, yythunkpos0= yythunkpos;
    yyprintf((stderr, "%s\n", "EndOfLine"));
    {  int yypos2= yypos, yythunkpos2= yythunkpos;  if (![self _matchString:"\r\n"]) goto l3;  goto l2;
    l3:;	  yypos= yypos2; yythunkpos= yythunkpos2;  if (![self _matchChar:'\n']) goto l4;  goto l2;
    l4:;	  yypos= yypos2; yythunkpos= yythunkpos2;  if (![self _matchChar:'\r']) goto l1;
    }
l2:;	
    yyprintf((stderr, "  ok   %s @ %s\n", "EndOfLine", yybuf+yypos));
    return 1;
l1:;	  yypos= yypos0; yythunkpos= yythunkpos0;
    yyprintf((stderr, "  fail %s @ %s\n", "EndOfLine", yybuf+yypos));
    return 0;
}

- (BOOL) matchComment
{  int yypos0= yypos, yythunkpos0= yythunkpos;
    yyprintf((stderr, "%s\n", "Comment"));  if (![self _matchChar:'#']) goto l5;
l6:;	
    {  int yypos7= yypos, yythunkpos7= yythunkpos;
        {  int yypos8= yypos, yythunkpos8= yythunkpos;  if (![self matchEndOfLine]) goto l8;  goto l7;
        l8:;	  yypos= yypos8; yythunkpos= yythunkpos8;
        }  if (![self _matchDot]) goto l7;  goto l6;
    l7:;	  yypos= yypos7; yythunkpos= yythunkpos7;
    }  if (![self matchEndOfLine]) goto l5;
    yyprintf((stderr, "  ok   %s @ %s\n", "Comment", yybuf+yypos));
    return YES;
l5:;	  yypos= yypos0; yythunkpos= yythunkpos0;
    yyprintf((stderr, "  fail %s @ %s\n", "Comment", yybuf+yypos));
    return NO;
}

- (BOOL) matchSpace
{  int yypos0= yypos, yythunkpos0= yythunkpos;
    yyprintf((stderr, "%s\n", "Space"));
    {  int yypos10= yypos, yythunkpos10= yythunkpos;  if (![self _matchChar:' ']) goto l11;  goto l10;
    l11:;	  yypos= yypos10; yythunkpos= yythunkpos10;  if (![self _matchChar:'\t']) goto l12;  goto l10;
    l12:;	  yypos= yypos10; yythunkpos= yythunkpos10;  if (![self matchEndOfLine]) goto l9;
    }
l10:;	
    yyprintf((stderr, "  ok   %s @ %s\n", "Space", yybuf+yypos));
    return YES;
l9:;	  yypos= yypos0; yythunkpos= yythunkpos0;
    yyprintf((stderr, "  fail %s @ %s\n", "Space", yybuf+yypos));
    return NO;
}

- (BOOL) matchRange
{  int yypos0= yypos, yythunkpos0= yythunkpos;
    yyprintf((stderr, "%s\n", "Range"));
    {  int yypos14= yypos, yythunkpos14= yythunkpos;  if (![self matchChar]) goto l15;  if (![self _matchChar:'-']) goto l15;  if (![self matchChar]) goto l15;  goto l14;
    l15:;	  yypos= yypos14; yythunkpos= yythunkpos14;  if (![self matchChar]) goto l13;
    }
l14:;	
    yyprintf((stderr, "  ok   %s @ %s\n", "Range", yybuf+yypos));
    return YES;
l13:;	  yypos= yypos0; yythunkpos= yythunkpos0;
    yyprintf((stderr, "  fail %s @ %s\n", "Range", yybuf+yypos));
    return NO;
}

- (BOOL) matchChar
{  int yypos0= yypos, yythunkpos0= yythunkpos;
    yyprintf((stderr, "%s\n", "Char"));
    {  int yypos17= yypos, yythunkpos17= yythunkpos;  if (![self _matchChar:'\\']) goto l18;  if (![self _matchClass:(unsigned char *)"\000\000\000\000\204\000\000\000\000\000\000\070\000\100\024\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"]) goto l18;  goto l17;
    l18:;	  yypos= yypos17; yythunkpos= yythunkpos17;  if (![self _matchChar:'\\']) goto l19;  if (![self _matchClass:(unsigned char *)"\000\000\000\000\000\000\007\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"]) goto l19;  if (![self _matchClass:(unsigned char *)"\000\000\000\000\000\000\377\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"]) goto l19;  if (![self _matchClass:(unsigned char *)"\000\000\000\000\000\000\377\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"]) goto l19;  goto l17;
    l19:;	  yypos= yypos17; yythunkpos= yythunkpos17;  if (![self _matchChar:'\\']) goto l20;  if (![self _matchClass:(unsigned char *)"\000\000\000\000\000\000\377\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"]) goto l20;
        {  int yypos21= yypos, yythunkpos21= yythunkpos;  if (![self _matchClass:(unsigned char *)"\000\000\000\000\000\000\377\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"]) goto l21;  goto l22;
        l21:;	  yypos= yypos21; yythunkpos= yythunkpos21;
        }
    l22:;	  goto l17;
    l20:;	  yypos= yypos17; yythunkpos= yythunkpos17;
        {  int yypos23= yypos, yythunkpos23= yythunkpos;  if (![self _matchChar:'\\']) goto l23;  goto l16;
        l23:;	  yypos= yypos23; yythunkpos= yythunkpos23;
        }  if (![self _matchDot]) goto l16;
    }
l17:;	
    yyprintf((stderr, "  ok   %s @ %s\n", "Char", yybuf+yypos));
    return YES;
l16:;	  yypos= yypos0; yythunkpos= yythunkpos0;
    yyprintf((stderr, "  fail %s @ %s\n", "Char", yybuf+yypos));
    return NO;
}

- (BOOL) matchIdentCont
{  int yypos0= yypos, yythunkpos0= yythunkpos;
    yyprintf((stderr, "%s\n", "IdentCont"));
    {  int yypos25= yypos, yythunkpos25= yythunkpos;  if (![self matchIdentStart]) goto l26;  goto l25;
    l26:;	  yypos= yypos25; yythunkpos= yythunkpos25;  if (![self _matchClass:(unsigned char *)"\000\000\000\000\000\000\377\003\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"]) goto l24;
    }
l25:;	
    yyprintf((stderr, "  ok   %s @ %s\n", "IdentCont", yybuf+yypos));
    return YES;
l24:;	  yypos= yypos0; yythunkpos= yythunkpos0;
    yyprintf((stderr, "  fail %s @ %s\n", "IdentCont", yybuf+yypos));
    return NO;
}

- (BOOL) matchIdentStart
{  int yypos0= yypos, yythunkpos0= yythunkpos;
    yyprintf((stderr, "%s\n", "IdentStart"));  if (![self _matchClass:(unsigned char *)"\000\000\000\000\000\000\000\000\376\377\377\207\376\377\377\007\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"]) goto l27;
    yyprintf((stderr, "  ok   %s @ %s\n", "IdentStart", yybuf+yypos));
    return YES;
l27:;	  yypos= yypos0; yythunkpos= yythunkpos0;
    yyprintf((stderr, "  fail %s @ %s\n", "IdentStart", yybuf+yypos));
    return NO;
}

- (BOOL) matchEND
{  int yypos0= yypos, yythunkpos0= yythunkpos;
    yyprintf((stderr, "%s\n", "END"));  if (![self _matchChar:'>']) goto l28;  if (![self matchSpacing]) goto l28;
    yyprintf((stderr, "  ok   %s @ %s\n", "END", yybuf+yypos));
    return YES;
l28:;	  yypos= yypos0; yythunkpos= yythunkpos0;
    yyprintf((stderr, "  fail %s @ %s\n", "END", yybuf+yypos));
    return NO;
}

- (BOOL) matchBEGIN
{  int yypos0= yypos, yythunkpos0= yythunkpos;
    yyprintf((stderr, "%s\n", "BEGIN"));  if (![self _matchChar:'<']) goto l29;  if (![self matchSpacing]) goto l29;
    yyprintf((stderr, "  ok   %s @ %s\n", "BEGIN", yybuf+yypos));
    return YES;
l29:;	  yypos= yypos0; yythunkpos= yythunkpos0;
    yyprintf((stderr, "  fail %s @ %s\n", "BEGIN", yybuf+yypos));
    return NO;
}

- (BOOL) matchAction
{  int yypos0= yypos, yythunkpos0= yythunkpos;
    yyprintf((stderr, "%s\n", "Action"));  if (![self _matchChar:'{']) goto l30;  [self yyText:yybegin to:yyend];  if (!(YY_BEGIN)) goto l30;
l31:;	
    {  int yypos32= yypos, yythunkpos32= yythunkpos;  if (![self _matchClass:(unsigned char *)"\377\377\377\377\377\377\377\377\377\377\377\377\377\377\377\337\377\377\377\377\377\377\377\377\377\377\377\377\377\377\377\377"]) goto l32;  goto l31;
    l32:;	  yypos= yypos32; yythunkpos= yythunkpos32;
    }  [self yyText:yybegin to:yyend];  if (!(YY_END)) goto l30;  if (![self _matchChar:'}']) goto l30;  if (![self matchSpacing]) goto l30;
    yyprintf((stderr, "  ok   %s @ %s\n", "Action", yybuf+yypos));
    return YES;
l30:;	  yypos= yypos0; yythunkpos= yythunkpos0;
    yyprintf((stderr, "  fail %s @ %s\n", "Action", yybuf+yypos));
    return NO;
}

- (BOOL) matchDOT
{  int yypos0= yypos, yythunkpos0= yythunkpos;
    yyprintf((stderr, "%s\n", "DOT"));  if (![self _matchChar:'.']) goto l33;  if (![self matchSpacing]) goto l33;
    yyprintf((stderr, "  ok   %s @ %s\n", "DOT", yybuf+yypos));
    return YES;
l33:;	  yypos= yypos0; yythunkpos= yythunkpos0;
    yyprintf((stderr, "  fail %s @ %s\n", "DOT", yybuf+yypos));
    return NO;
}

- (BOOL) matchClass
{  int yypos0= yypos, yythunkpos0= yythunkpos;
    yyprintf((stderr, "%s\n", "Class"));  if (![self _matchChar:'[']) goto l34;  [self yyText:yybegin to:yyend];  if (!(YY_BEGIN)) goto l34;
l35:;	
    {  int yypos36= yypos, yythunkpos36= yythunkpos;
        {  int yypos37= yypos, yythunkpos37= yythunkpos;  if (![self _matchChar:']']) goto l37;  goto l36;
        l37:;	  yypos= yypos37; yythunkpos= yythunkpos37;
        }  if (![self matchRange]) goto l36;  goto l35;
    l36:;	  yypos= yypos36; yythunkpos= yythunkpos36;
    }  [self yyText:yybegin to:yyend];  if (!(YY_END)) goto l34;  if (![self _matchChar:']']) goto l34;  if (![self matchSpacing]) goto l34;
    yyprintf((stderr, "  ok   %s @ %s\n", "Class", yybuf+yypos));
    return YES;
l34:;	  yypos= yypos0; yythunkpos= yythunkpos0;
    yyprintf((stderr, "  fail %s @ %s\n", "Class", yybuf+yypos));
    return NO;
}

- (BOOL) matchLiteral
{  int yypos0= yypos, yythunkpos0= yythunkpos;
    yyprintf((stderr, "%s\n", "Literal"));
    {  int yypos39= yypos, yythunkpos39= yythunkpos;  if (![self _matchClass:(unsigned char *)"\000\000\000\000\200\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"]) goto l40;  [self yyText:yybegin to:yyend];  if (!(YY_BEGIN)) goto l40;
    l41:;	
        {  int yypos42= yypos, yythunkpos42= yythunkpos;
            {  int yypos43= yypos, yythunkpos43= yythunkpos;  if (![self _matchClass:(unsigned char *)"\000\000\000\000\200\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"]) goto l43;  goto l42;
            l43:;	  yypos= yypos43; yythunkpos= yythunkpos43;
            }  if (![self matchChar]) goto l42;  goto l41;
        l42:;	  yypos= yypos42; yythunkpos= yythunkpos42;
        }  [self yyText:yybegin to:yyend];  if (!(YY_END)) goto l40;  if (![self _matchClass:(unsigned char *)"\000\000\000\000\200\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"]) goto l40;  if (![self matchSpacing]) goto l40;  goto l39;
    l40:;	  yypos= yypos39; yythunkpos= yythunkpos39;  if (![self _matchClass:(unsigned char *)"\000\000\000\000\004\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"]) goto l38;  [self yyText:yybegin to:yyend];  if (!(YY_BEGIN)) goto l38;
    l44:;	
        {  int yypos45= yypos, yythunkpos45= yythunkpos;
            {  int yypos46= yypos, yythunkpos46= yythunkpos;  if (![self _matchClass:(unsigned char *)"\000\000\000\000\004\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"]) goto l46;  goto l45;
            l46:;	  yypos= yypos46; yythunkpos= yythunkpos46;
            }  if (![self matchChar]) goto l45;  goto l44;
        l45:;	  yypos= yypos45; yythunkpos= yythunkpos45;
        }  [self yyText:yybegin to:yyend];  if (!(YY_END)) goto l38;  if (![self _matchClass:(unsigned char *)"\000\000\000\000\004\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"]) goto l38;  if (![self matchSpacing]) goto l38;
    }
l39:;	
    yyprintf((stderr, "  ok   %s @ %s\n", "Literal", yybuf+yypos));
    return YES;
l38:;	  yypos= yypos0; yythunkpos= yythunkpos0;
    yyprintf((stderr, "  fail %s @ %s\n", "Literal", yybuf+yypos));
    return NO;
}

- (BOOL) matchCLOSE
{  int yypos0= yypos, yythunkpos0= yythunkpos;
    yyprintf((stderr, "%s\n", "CLOSE"));  if (![self _matchChar:')']) goto l47;  if (![self matchSpacing]) goto l47;
    yyprintf((stderr, "  ok   %s @ %s\n", "CLOSE", yybuf+yypos));
    return YES;
l47:;	  yypos= yypos0; yythunkpos= yythunkpos0;
    yyprintf((stderr, "  fail %s @ %s\n", "CLOSE", yybuf+yypos));
    return NO;
}

- (BOOL) matchOPEN
{  int yypos0= yypos, yythunkpos0= yythunkpos;
    yyprintf((stderr, "%s\n", "OPEN"));  if (![self _matchChar:'(']) goto l48;  if (![self matchSpacing]) goto l48;
    yyprintf((stderr, "  ok   %s @ %s\n", "OPEN", yybuf+yypos));
    return YES;
l48:;	  yypos= yypos0; yythunkpos= yythunkpos0;
    yyprintf((stderr, "  fail %s @ %s\n", "OPEN", yybuf+yypos));
    return NO;
}

- (BOOL) matchPLUS
{  int yypos0= yypos, yythunkpos0= yythunkpos;
    yyprintf((stderr, "%s\n", "PLUS"));  if (![self _matchChar:'+']) goto l49;  if (![self matchSpacing]) goto l49;
    yyprintf((stderr, "  ok   %s @ %s\n", "PLUS", yybuf+yypos));
    return YES;
l49:;	  yypos= yypos0; yythunkpos= yythunkpos0;
    yyprintf((stderr, "  fail %s @ %s\n", "PLUS", yybuf+yypos));
    return NO;
}

- (BOOL) matchSTAR
{  int yypos0= yypos, yythunkpos0= yythunkpos;
    yyprintf((stderr, "%s\n", "STAR"));  if (![self _matchChar:'*']) goto l50;  if (![self matchSpacing]) goto l50;
    yyprintf((stderr, "  ok   %s @ %s\n", "STAR", yybuf+yypos));
    return YES;
l50:;	  yypos= yypos0; yythunkpos= yythunkpos0;
    yyprintf((stderr, "  fail %s @ %s\n", "STAR", yybuf+yypos));
    return NO;
}

- (BOOL) matchQUESTION
{  int yypos0= yypos, yythunkpos0= yythunkpos;
    yyprintf((stderr, "%s\n", "QUESTION"));  if (![self _matchChar:'?']) goto l51;  if (![self matchSpacing]) goto l51;
    yyprintf((stderr, "  ok   %s @ %s\n", "QUESTION", yybuf+yypos));
    return YES;
l51:;	  yypos= yypos0; yythunkpos= yythunkpos0;
    yyprintf((stderr, "  fail %s @ %s\n", "QUESTION", yybuf+yypos));
    return NO;
}

- (BOOL) matchPrimary
{  int yypos0= yypos, yythunkpos0= yythunkpos;
    yyprintf((stderr, "%s\n", "Primary"));
    {  int yypos53= yypos, yythunkpos53= yythunkpos;  if (![self matchIdentifier]) goto l54;
        {  int yypos55= yypos, yythunkpos55= yythunkpos;  if (![self matchLEFTARROW]) goto l55;  goto l54;
        l55:;	  yypos= yypos55; yythunkpos= yythunkpos55;
        }  [self yyDo:@selector(yy_1_Primary:) from:yybegin to:yyend];  goto l53;
    l54:;	  yypos= yypos53; yythunkpos= yythunkpos53;  if (![self matchOPEN]) goto l56;  if (![self matchExpression]) goto l56;  if (![self matchCLOSE]) goto l56;  goto l53;
    l56:;	  yypos= yypos53; yythunkpos= yythunkpos53;  if (![self matchLiteral]) goto l57;  [self yyDo:@selector(yy_2_Primary:) from:yybegin to:yyend];  goto l53;
    l57:;	  yypos= yypos53; yythunkpos= yythunkpos53;  if (![self matchClass]) goto l58;  [self yyDo:@selector(yy_3_Primary:) from:yybegin to:yyend];  goto l53;
    l58:;	  yypos= yypos53; yythunkpos= yythunkpos53;  if (![self matchDOT]) goto l59;  [self yyDo:@selector(yy_4_Primary:) from:yybegin to:yyend];  goto l53;
    l59:;	  yypos= yypos53; yythunkpos= yythunkpos53;  if (![self matchAction]) goto l60;  [self yyDo:@selector(yy_5_Primary:) from:yybegin to:yyend];  goto l53;
    l60:;	  yypos= yypos53; yythunkpos= yythunkpos53;  if (![self matchBEGIN]) goto l61;  [self yyDo:@selector(yy_6_Primary:) from:yybegin to:yyend];  goto l53;
    l61:;	  yypos= yypos53; yythunkpos= yythunkpos53;  if (![self matchEND]) goto l52;  [self yyDo:@selector(yy_7_Primary:) from:yybegin to:yyend];
    }
l53:;	
    yyprintf((stderr, "  ok   %s @ %s\n", "Primary", yybuf+yypos));
    return YES;
l52:;	  yypos= yypos0; yythunkpos= yythunkpos0;
    yyprintf((stderr, "  fail %s @ %s\n", "Primary", yybuf+yypos));
    return NO;
}

- (BOOL) matchNOT
{  int yypos0= yypos, yythunkpos0= yythunkpos;
    yyprintf((stderr, "%s\n", "NOT"));  if (![self _matchChar:'!']) goto l62;  if (![self matchSpacing]) goto l62;
    yyprintf((stderr, "  ok   %s @ %s\n", "NOT", yybuf+yypos));
    return YES;
l62:;	  yypos= yypos0; yythunkpos= yythunkpos0;
    yyprintf((stderr, "  fail %s @ %s\n", "NOT", yybuf+yypos));
    return NO;
}

- (BOOL) matchSuffix
{  int yypos0= yypos, yythunkpos0= yythunkpos;
    yyprintf((stderr, "%s\n", "Suffix"));  if (![self matchPrimary]) goto l63;
    {  int yypos64= yypos, yythunkpos64= yythunkpos;
        {  int yypos66= yypos, yythunkpos66= yythunkpos;  if (![self matchQUESTION]) goto l67;  [self yyDo:@selector(yy_1_Suffix:) from:yybegin to:yyend];  goto l66;
        l67:;	  yypos= yypos66; yythunkpos= yythunkpos66;  if (![self matchSTAR]) goto l68;  [self yyDo:@selector(yy_2_Suffix:) from:yybegin to:yyend];  goto l66;
        l68:;	  yypos= yypos66; yythunkpos= yythunkpos66;  if (![self matchPLUS]) goto l64;  [self yyDo:@selector(yy_3_Suffix:) from:yybegin to:yyend];
        }
    l66:;	  goto l65;
    l64:;	  yypos= yypos64; yythunkpos= yythunkpos64;
    }
l65:;	
    yyprintf((stderr, "  ok   %s @ %s\n", "Suffix", yybuf+yypos));
    return YES;
l63:;	  yypos= yypos0; yythunkpos= yythunkpos0;
    yyprintf((stderr, "  fail %s @ %s\n", "Suffix", yybuf+yypos));
    return NO;
}

- (BOOL) matchAND
{  int yypos0= yypos, yythunkpos0= yythunkpos;
    yyprintf((stderr, "%s\n", "AND"));  if (![self _matchChar:'&']) goto l69;  if (![self matchSpacing]) goto l69;
    yyprintf((stderr, "  ok   %s @ %s\n", "AND", yybuf+yypos));
    return YES;
l69:;	  yypos= yypos0; yythunkpos= yythunkpos0;
    yyprintf((stderr, "  fail %s @ %s\n", "AND", yybuf+yypos));
    return NO;
}

- (BOOL) matchPrefix
{  int yypos0= yypos, yythunkpos0= yythunkpos;
    yyprintf((stderr, "%s\n", "Prefix"));
    {  int yypos71= yypos, yythunkpos71= yythunkpos;  if (![self matchAND]) goto l72;  if (![self matchSuffix]) goto l72;  [self yyDo:@selector(yy_1_Prefix:) from:yybegin to:yyend];  goto l71;
    l72:;	  yypos= yypos71; yythunkpos= yythunkpos71;  if (![self matchNOT]) goto l73;  if (![self matchSuffix]) goto l73;  [self yyDo:@selector(yy_2_Prefix:) from:yybegin to:yyend];  goto l71;
    l73:;	  yypos= yypos71; yythunkpos= yythunkpos71;  if (![self matchSuffix]) goto l70;
    }
l71:;	
    yyprintf((stderr, "  ok   %s @ %s\n", "Prefix", yybuf+yypos));
    return YES;
l70:;	  yypos= yypos0; yythunkpos= yythunkpos0;
    yyprintf((stderr, "  fail %s @ %s\n", "Prefix", yybuf+yypos));
    return NO;
}

- (BOOL) matchSLASH
{  int yypos0= yypos, yythunkpos0= yythunkpos;
    yyprintf((stderr, "%s\n", "SLASH"));  if (![self _matchChar:'/']) goto l74;  if (![self matchSpacing]) goto l74;
    yyprintf((stderr, "  ok   %s @ %s\n", "SLASH", yybuf+yypos));
    return YES;
l74:;	  yypos= yypos0; yythunkpos= yythunkpos0;
    yyprintf((stderr, "  fail %s @ %s\n", "SLASH", yybuf+yypos));
    return NO;
}

- (BOOL) matchSequence
{  int yypos0= yypos, yythunkpos0= yythunkpos;
    yyprintf((stderr, "%s\n", "Sequence"));
    {  int yypos76= yypos, yythunkpos76= yythunkpos;  if (![self matchPrefix]) goto l76;  goto l77;
    l76:;	  yypos= yypos76; yythunkpos= yythunkpos76;
    }
l77:;	
l78:;	
    {  int yypos79= yypos, yythunkpos79= yythunkpos;  if (![self matchPrefix]) goto l79;  [self yyDo:@selector(yy_1_Sequence:) from:yybegin to:yyend];  goto l78;
    l79:;	  yypos= yypos79; yythunkpos= yythunkpos79;
    }
    yyprintf((stderr, "  ok   %s @ %s\n", "Sequence", yybuf+yypos));
    return YES;
l75:;	  yypos= yypos0; yythunkpos= yythunkpos0;
    yyprintf((stderr, "  fail %s @ %s\n", "Sequence", yybuf+yypos));
    return NO;
}

- (BOOL) matchExpression
{  int yypos0= yypos, yythunkpos0= yythunkpos;
    yyprintf((stderr, "%s\n", "Expression"));  if (![self matchSequence]) goto l80;
l81:;	
    {  int yypos82= yypos, yythunkpos82= yythunkpos;  if (![self matchSLASH]) goto l82;  if (![self matchSequence]) goto l82;  [self yyDo:@selector(yy_1_Expression:) from:yybegin to:yyend];  goto l81;
    l82:;	  yypos= yypos82; yythunkpos= yythunkpos82;
    }
    yyprintf((stderr, "  ok   %s @ %s\n", "Expression", yybuf+yypos));
    return YES;
l80:;	  yypos= yypos0; yythunkpos= yythunkpos0;
    yyprintf((stderr, "  fail %s @ %s\n", "Expression", yybuf+yypos));
    return NO;
}

- (BOOL) matchLEFTARROW
{
    int yypos0= yypos, yythunkpos0= yythunkpos;
    yyprintf((stderr, "%s\n", "LEFTARROW"));  if (![self _matchString:"<-"]) goto l83;  if (![self matchSpacing]) goto l83;
    yyprintf((stderr, "  ok   %s @ %s\n", "LEFTARROW", yybuf+yypos));
    return YES;
l83:;	  yypos= yypos0; yythunkpos= yythunkpos0;
    yyprintf((stderr, "  fail %s @ %s\n", "LEFTARROW", yybuf+yypos));
    return NO;
}

- (BOOL) matchIdentifier
{  int yypos0= yypos, yythunkpos0= yythunkpos;
    yyprintf((stderr, "%s\n", "Identifier"));  [self yyText:yybegin to:yyend];  if (!(YY_BEGIN)) goto l84;  if (![self matchIdentStart]) goto l84;
l85:;	
    {  int yypos86= yypos, yythunkpos86= yythunkpos;  if (![self matchIdentCont]) goto l86;  goto l85;
    l86:;	  yypos= yypos86; yythunkpos= yythunkpos86;
    }  [self yyText:yybegin to:yyend];  if (!(YY_END)) goto l84;  if (![self matchSpacing]) goto l84;
    yyprintf((stderr, "  ok   %s @ %s\n", "Identifier", yybuf+yypos));
    return YES;
l84:;	  yypos= yypos0; yythunkpos= yythunkpos0;
    yyprintf((stderr, "  fail %s @ %s\n", "Identifier", yybuf+yypos));
    return NO;
}

- (BOOL) matchEndOfFile
{  int yypos0= yypos, yythunkpos0= yythunkpos;
    yyprintf((stderr, "%s\n", "EndOfFile"));
    {  int yypos88= yypos, yythunkpos88= yythunkpos;  if (![self _matchDot]) goto l88;  goto l87;
    l88:;	  yypos= yypos88; yythunkpos= yythunkpos88;
    }
    yyprintf((stderr, "  ok   %s @ %s\n", "EndOfFile", yybuf+yypos));
    return YES;
l87:;	  yypos= yypos0; yythunkpos= yythunkpos0;
    yyprintf((stderr, "  fail %s @ %s\n", "EndOfFile", yybuf+yypos));
    return NO;
}

- (BOOL) matchDefinition
{  int yypos0= yypos, yythunkpos0= yythunkpos;
    yyprintf((stderr, "%s\n", "Definition"));  if (![self matchIdentifier]) goto l89;  if (![self matchLEFTARROW]) goto l89;  if (![self matchExpression]) goto l89;  [self yyDo:@selector(yy_1_Definition:) from:yybegin to:yyend];
    yyprintf((stderr, "  ok   %s @ %s\n", "Definition", yybuf+yypos));
    return YES;
l89:;	  yypos= yypos0; yythunkpos= yythunkpos0;
    yyprintf((stderr, "  fail %s @ %s\n", "Definition", yybuf+yypos));
    return NO;
}

- (BOOL) matchSpacing
{
    yyprintf((stderr, "%s\n", "Spacing"));
l91:;	
    {  int yypos92= yypos, yythunkpos92= yythunkpos;
        {  int yypos93= yypos, yythunkpos93= yythunkpos;  if (![self matchSpace]) goto l94;  goto l93;
        l94:;	  yypos= yypos93; yythunkpos= yythunkpos93;  if (![self matchComment]) goto l92;
        }
    l93:;	  goto l91;
    l92:;	  yypos= yypos92; yythunkpos= yythunkpos92;
    }
    yyprintf((stderr, "  ok   %s @ %s\n", "Spacing", yybuf+yypos));
    return YES;
}

- (BOOL) matchGrammar
{
    int yypos0= yypos, yythunkpos0= yythunkpos;
    yyprintf((stderr, "%s\n", "Grammar"));  if (![self matchSpacing]) goto l95;  if (![self matchDefinition]) goto l95;
l96:;	
    {  int yypos97= yypos, yythunkpos97= yythunkpos;  if (![self matchDefinition]) goto l97;  goto l96;
    l97:;	  yypos= yypos97; yythunkpos= yythunkpos97;
    }  if (![self matchEndOfFile]) goto l95;
    yyprintf((stderr, "  ok   %s @ %s\n", "Grammar", yybuf+yypos));
    return YES;
l95:;	  yypos= yypos0; yythunkpos= yythunkpos0;
    yyprintf((stderr, "  fail %s @ %s\n", "Grammar", yybuf+yypos));
    return NO;
}

- (BOOL) yyparsefrom:(SEL)startRule
{
    BOOL yyok;
    if (!yybuflen)
    {
        yybuflen= 1024;
        yybuf= malloc(yybuflen);
        yytextlen= 1024;
        yytext= malloc(yytextlen);
        yythunkslen= 32;
        yythunks= malloc(sizeof(yythunk) * yythunkslen);
        yybegin= yyend= yypos= yylimit= yythunkpos= 0;
    }
    yybegin= yyend= yypos;
    yythunkpos= 0;
    
    NSMethodSignature *sig = [[self class] instanceMethodSignatureForSelector:startRule];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
    [invocation setTarget:self];
    [invocation setSelector:startRule];
    [invocation invoke];
    [invocation getReturnValue:&yyok];
    if (yyok) [self yyDone];
    [self yyCommit];
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
    free(yybuf);
    free(yytext);
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
    BOOL retval = [self yyparse];
    [_string release];
    _string = nil;
    return retval;
}


@end
