/*
 *  The scanner definition for COOL.
 */

import java_cup.runtime.Symbol;

%%

%{

/*  Stuff enclosed in %{ %} is copied verbatim to the lexer class
 *  definition, all the extra variables/functions you want to use in the
 *  lexer actions should go here.  Don't remove or modify anything that
 *  was there initially.  */

    // Max size of string constants
    static int MAX_STR_CONST = 1025;

    // For assembling string constants
    StringBuffer string_buf = new StringBuffer();

    private int curr_lineno = 1;
    int get_curr_lineno() {
	return curr_lineno;
    }

    private AbstractSymbol filename;

    void set_filename(String fname) {
	filename = AbstractTable.stringtable.addString(fname);
    }

    AbstractSymbol curr_filename() {
	return filename;
    }
    
    private int yy_lexical_state;
    private boolean eof_in_string = false;
    private boolean eof_in_comment = false;
%}

%init{

/*  Stuff enclosed in %init{ %init} is copied verbatim to the lexer
 *  class constructor, all the extra initialization you want to do should
 *  go here.  Don't remove or modify anything that was there initially. */

    // empty for now
%init}

%eofval{

/*  Stuff enclosed in %eofval{ %eofval} specifies java code that is
 *  executed when end-of-file is reached.  If you use multiple lexical
 *  states and want to do something special if an EOF is encountered in
 *  one of those states, place your code in the switch statement.
 *  Ultimately, you should return the EOF symbol, or your lexer won't
 *  work.  */

    switch(yy_lexical_state) {
        case YYINITIAL:
            /* nothing special to do in the initial state */
            break;
        case EOF:
            return new Symbol(TokenConstants.EOF);
        case STRING:
            yy_lexical_state = EOF;
            return new Symbol(
                    TokenConstants.ERROR, new StringSymbol(
                        "EOF in string constant", 22, 0
                    )
                );
        case MLCOMMENT:
            yy_lexical_state = EOF;
            return new Symbol(
                    TokenConstants.ERROR, new StringSymbol(
                        "EOF in comment", 14, 0
                    )
                );
    }
    return new Symbol(TokenConstants.EOF);
%eofval}

%class CoolLexer
%unicode
%line
%column
%cup
%ignorecase

%state STRING
%state MLCOMMENT
%state CLASS
%state INHERITS
%state COLON
%state EOF

LineTerminator = \r|\n|\r\n
InputCharacter = [^\r\n]
WhiteSpace     = {LineTerminator} | [ \t\f]

/* comments */
// Comment can be the last line of the file, without line terminator.
EndOfLineComment     = "--" {InputCharacter}* {LineTerminator}?
Comment = {EndOfLineComment}

Identifier = [:jletter:] [:jletterdigit:]*
digit = ([0] | [0-9]+)

%%

<YYINITIAL>\"			            { yy_lexical_state = STRING; string_buf.setLength(0); yybegin(STRING); }
<STRING> {  
    \"                              {   yy_lexical_state = YYINITIAL; yybegin(YYINITIAL);
                                        if(string_buf.length() > 512){
                                            return new Symbol(
                                                TokenConstants.ERROR, new StringSymbol(
                                                    "String constant too long", 24, 0
                                                )
                                            );
                                        } else {
                                            return new Symbol(
                                                TokenConstants.STR_CONST, new StringSymbol(
                                                    string_buf.toString(), string_buf.toString().length(), 0
                                                )
                                            );
                                        } 
                                    }
    [^\n\r\"\\]+                    {   
                                        string_buf.append( yytext() );
                                    }
    \\t                             { string_buf.append('\t'); }
    \\\n                            { string_buf.append('\n'); }
    \n                              {   yy_lexical_state = YYINITIAL; yybegin(YYINITIAL); 
                                        return new Symbol(
                                                TokenConstants.ERROR, new StringSymbol(
                                                    "Unterminated string constant", 28, 0
                                                )
                                            );
                                    }
    \\r                             { string_buf.append('\r'); }
    \\\"                            { string_buf.append('\"'); }
    \\                              {  }
}

<YYINITIAL>"*)"			            { return new Symbol(
                                                TokenConstants.ERROR, new StringSymbol(
                                                    "Unmatched *)", 12, 0
                                                )
                                            );
                                    }
<YYINITIAL>"(*"			            {yy_lexical_state = MLCOMMENT; yybegin(MLCOMMENT); }
<MLCOMMENT> {  
    "*)"	                        { yy_lexical_state = YYINITIAL; yybegin(YYINITIAL); }
    .                               { }
    \n                              { }
}

<YYINITIAL>"=>"			            { return new Symbol(TokenConstants.DARROW); }
<YYINITIAL>{WhiteSpace}		        { }
<YYINITIAL>"{"			            { return new Symbol(TokenConstants.LBRACE); }
<YYINITIAL>"*"                      { return new Symbol(TokenConstants.MULT); }
<YYINITIAL>"POOL"                   { return new Symbol(TokenConstants.POOL); }
<YYINITIAL>"CASE"                   { return new Symbol(TokenConstants.CASE); }
<YYINITIAL>"("                      { return new Symbol(TokenConstants.LPAREN); }
<YYINITIAL>";"                      { return new Symbol(TokenConstants.SEMI); }
<YYINITIAL>"-"                      { return new Symbol(TokenConstants.MINUS); }
<YYINITIAL>")"                      { return new Symbol(TokenConstants.RPAREN); }
<YYINITIAL>"NOT"                    { return new Symbol(TokenConstants.NOT); }
<YYINITIAL>"TYPEID"                 { return new Symbol(TokenConstants.TYPEID); }
<YYINITIAL>"<"                      { return new Symbol(TokenConstants.LT); }
<YYINITIAL>"IN"                     { return new Symbol(TokenConstants.IN); }
<YYINITIAL>","                      { return new Symbol(TokenConstants.COMMA); }
<YYINITIAL>"CLASS"                  { yybegin(CLASS); 
                                    return new Symbol(TokenConstants.CLASS); }
<CLASS>{
    {WhiteSpace}		            { }                            
    {Identifier}                    {yybegin(YYINITIAL); 
                                    return new Symbol(TokenConstants.TYPEID, new IdSymbol(yytext(), yytext().length(), 0)); }                              
}
<YYINITIAL>"INHERITS"                  { yybegin(INHERITS); 
                                    return new Symbol(TokenConstants.INHERITS); }
<INHERITS>{
    {WhiteSpace}		            { }                            
    {Identifier}                    {yybegin(YYINITIAL); 
                                    return new Symbol(TokenConstants.TYPEID, new IdSymbol(yytext(), yytext().length(), 0)); }                              
}

<YYINITIAL>"FI"                     { return new Symbol(TokenConstants.FI); }
<YYINITIAL>"/"                      { return new Symbol(TokenConstants.DIV); }
<YYINITIAL>"LOOP"                   { return new Symbol(TokenConstants.LOOP); }
<YYINITIAL>"+"                      { return new Symbol(TokenConstants.PLUS); }
<YYINITIAL>"<-"                     { return new Symbol(TokenConstants.ASSIGN); }
<YYINITIAL>"IF"                     { return new Symbol(TokenConstants.IF); }
<YYINITIAL>"."                      { return new Symbol(TokenConstants.DOT); }
<YYINITIAL>"LE"                     { return new Symbol(TokenConstants.LE); }
<YYINITIAL>"OF"                     { return new Symbol(TokenConstants.OF); }
<YYINITIAL>"NEW"                    { return new Symbol(TokenConstants.NEW); }
<YYINITIAL>"ISVOID"                 { return new Symbol(TokenConstants.ISVOID); }
<YYINITIAL>"="                      { return new Symbol(TokenConstants.EQ); }
<YYINITIAL>":"                      { yybegin(COLON); 
                                    return new Symbol(TokenConstants.COLON); }
<COLON>{
    {WhiteSpace}		            { }                            
    {Identifier}                    {yybegin(YYINITIAL); 
                                    return new Symbol(TokenConstants.TYPEID, new IdSymbol(yytext(), yytext().length(), 0)); }                              
}
<YYINITIAL>"~"                      { return new Symbol(TokenConstants.NEG); }
<YYINITIAL>"{"                      { return new Symbol(TokenConstants.LBRACE); }
<YYINITIAL>"ELSE"                   { return new Symbol(TokenConstants.ELSE); }
<YYINITIAL>"=>"                     { return new Symbol(TokenConstants.DARROW); }
<YYINITIAL>"WHILE"                  { return new Symbol(TokenConstants.WHILE); }
<YYINITIAL>"ESAC"                   { return new Symbol(TokenConstants.ESAC); }
<YYINITIAL>"LET"                    { return new Symbol(TokenConstants.LET); }
<YYINITIAL>"}"                      { return new Symbol(TokenConstants.RBRACE); }
<YYINITIAL>"THEN"                   { return new Symbol(TokenConstants.THEN); }
<YYINITIAL>[t]rue|[f]alse           { return new Symbol(TokenConstants.BOOL_CONST, yytext()); }
<YYINITIAL>"@"                      { return new Symbol(TokenConstants.AT); }
<YYINITIAL>[\^>\[\]¨´~`']+[:jletter:]*   { 
                                        return new Symbol(
                                            TokenConstants.ERROR, new StringSymbol(
                                                yytext(), yytext().length(), 0
                                            )
                                        );
                                    }
<YYINITIAL>{digit}+[:jletter:]+     { 
                                        return new Symbol(
                                            TokenConstants.ERROR, new StringSymbol(
                                                yytext(), yytext().length(), 0
                                            )
                                        );
                                    }
<YYINITIAL>{digit}                  { return new Symbol(TokenConstants.INT_CONST, new IntSymbol(yytext(), yytext().length(), 0)); }
<YYINITIAL>{Identifier}             { return new Symbol(TokenConstants.OBJECTID, new IdSymbol(yytext(), yytext().length(), 0)); }
<YYINITIAL>{Comment}                { }
.                                   { System.err.println("LEXER BUG - UNMATCHED: " + yytext()); }