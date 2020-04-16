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
	/* If necessary, add code for other states here, e.g:
	   case COMMENT:
	   ...
	   break;
	*/
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

LineTerminator = \r|\n|\r\n
InputCharacter = [^\r\n]
WhiteSpace     = {LineTerminator} | [ \t\f]

/* comments */
// Comment can be the last line of the file, without line terminator.
EndOfLineComment     = "--" {InputCharacter}* {LineTerminator}?
Comment = {EndOfLineComment}

Identifier = [:jletter:] [:jletterdigit:]*

%%

<YYINITIAL>\"			    { string_buf.setLength(0); yybegin(STRING); }
<STRING> {  
    \"                              {   yybegin(YYINITIAL);
                                    return new Symbol(TokenConstants.STR_CONST, new StringSymbol(string_buf.toString(), string_buf.toString().length(), 0)); }
    [^\n\r\"\\]+                   { string_buf.append( yytext() ); }
    \\t                            { string_buf.append('\t'); }
    \\n                            { string_buf.append('\n'); }

    \\r                            { string_buf.append('\r'); }
    \\\"                           { string_buf.append('\"'); }
    \\                             { string_buf.append('\\'); }
}

<YYINITIAL>"(*"			    {yybegin(MLCOMMENT); }
<MLCOMMENT> {  
    "*)"	                       { yybegin(YYINITIAL); }
    .                           {}
    \n                            { }
}

<YYINITIAL>"=>"			    { return new Symbol(TokenConstants.DARROW); }
<YYINITIAL>{WhiteSpace}		{ }
<YYINITIAL>"{"			    { return new Symbol(TokenConstants.LBRACE); }
<YYINITIAL>"*"              { return new Symbol(TokenConstants.MULT); }
<YYINITIAL>"INHERITS"       { return new Symbol(TokenConstants.INHERITS); }
<YYINITIAL>"POOL"           { return new Symbol(TokenConstants.POOL); }
<YYINITIAL>"CASE"           { return new Symbol(TokenConstants.CASE); }
<YYINITIAL>"("              { return new Symbol(TokenConstants.LPAREN); }
<YYINITIAL>";"              { return new Symbol(TokenConstants.SEMI); }
<YYINITIAL>"-"              { return new Symbol(TokenConstants.MINUS); }
<YYINITIAL>")"              { return new Symbol(TokenConstants.RPAREN); }
<YYINITIAL>"NOT"            { return new Symbol(TokenConstants.NOT); }
<YYINITIAL>"TYPEID"         { return new Symbol(TokenConstants.TYPEID); }
<YYINITIAL>"<"             { return new Symbol(TokenConstants.LT); }
<YYINITIAL>"IN"             { return new Symbol(TokenConstants.IN); }
<YYINITIAL>","              { return new Symbol(TokenConstants.COMMA); }
<YYINITIAL>"CLASS"          { return new Symbol(TokenConstants.CLASS); }
<YYINITIAL>"FI"             { return new Symbol(TokenConstants.FI); }
<YYINITIAL>"/"              { return new Symbol(TokenConstants.DIV); }
<YYINITIAL>"LOOP"           { return new Symbol(TokenConstants.LOOP); }
<YYINITIAL>"+"              { return new Symbol(TokenConstants.PLUS); }
<YYINITIAL>"<-"         { return new Symbol(TokenConstants.ASSIGN); }
<YYINITIAL>"IF"             { return new Symbol(TokenConstants.IF); }
<YYINITIAL>"."              { return new Symbol(TokenConstants.DOT); }
<YYINITIAL>"LE"             { return new Symbol(TokenConstants.LE); }
<YYINITIAL>"OF"             { return new Symbol(TokenConstants.OF); }
<YYINITIAL>[0-9]+           { return new Symbol(TokenConstants.INT_CONST, new IntSymbol(yytext(), yytext().length(), 0)); }
<YYINITIAL>"NEW"            { return new Symbol(TokenConstants.NEW); }
<YYINITIAL>"ISVOID"         { return new Symbol(TokenConstants.ISVOID); }
<YYINITIAL>"="              { return new Symbol(TokenConstants.EQ); }
<YYINITIAL>":"              { return new Symbol(TokenConstants.COLON); }
<YYINITIAL>"~"              { return new Symbol(TokenConstants.NEG); }
<YYINITIAL>"{"              { return new Symbol(TokenConstants.LBRACE); }
<YYINITIAL>"ELSE"           { return new Symbol(TokenConstants.ELSE); }
<YYINITIAL>"=>"             { return new Symbol(TokenConstants.DARROW); }
<YYINITIAL>"WHILE"          { return new Symbol(TokenConstants.WHILE); }
<YYINITIAL>"ESAC"           { return new Symbol(TokenConstants.ESAC); }
<YYINITIAL>"LET"            { return new Symbol(TokenConstants.LET); }
<YYINITIAL>"}"              { return new Symbol(TokenConstants.RBRACE); }
<YYINITIAL>"THEN"           { return new Symbol(TokenConstants.THEN); }
<YYINITIAL>[t]rue|[f]alse   { return new Symbol(TokenConstants.BOOL_CONST, yytext()); }
<YYINITIAL>"@"              { return new Symbol(TokenConstants.AT); }
<YYINITIAL>{Identifier}     { return new Symbol(TokenConstants.OBJECTID, new IdSymbol(yytext(), yytext().length(), 0)); }
<YYINITIAL>{Comment} { }
.                           { System.err.println("LEXER BUG - UNMATCHED: " + yytext()); }