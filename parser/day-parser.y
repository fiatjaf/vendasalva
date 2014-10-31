%lex

%s newline
%s any
%s compra
%s comment
%s saldo
%s pagamento
%s lanc

%%

[ \t]+                                 {}

/* the <any> state is the de facto 'venda' state, so things that have special meaning to venda will match */
<any>ramos?                             return 'UNIT'
<any>unidades?                          return 'UNIT'
<any>pacotes?                           return 'UNIT'
<any>pcts?                              return 'UNIT'
<any>pencas?                            return 'UNIT'
<any>bandejas?                          return 'UNIT'
<any>litros?                            return 'UNIT'
<any>caixas?                            return 'UNIT'
<any>sacos?                             return 'UNIT'
<any>ramos?                             return 'UNIT'
<any>"l"                                return 'UNIT'
<any>"u"                                return 'UNIT'
<any>"kg"                               return 'UNIT'
<any>"g"                                return 'UNIT'
<any>"de"                               return 'DE'
<any>"reais"                            return 'BRL'
<any>"real"                             return 'BRL'
<any>"R$"                               return 'BRL'
<any>"BRL"                              return 'BRL'
<any>cent(avo)?s?                       return 'BRL'

/* inside <compra>, a NEWLINE does not reset the state */
<compra>\n                              return 'NEWLINE'
<compra>"+"                             return 'PLUS'
<compra>"="                             return 'EQUALS'
<compra>"total"                         return 'TOTAL'

/* directives that start new states */
<newline>"saldo"                        {this.begin('saldo'); return 'SALDO'}
<newline>"caixa"                        {this.begin('saldo'); return 'SALDO'}
<newline>pag(amento|o|uei)?             {this.begin('pagamento'); return 'PAGAMENTO'}
<newline>sa[ií]das?                     {this.begin('lanc')}; return 'SAIDA'}
<newline>retiradas?                     {this.begin('lanc')}; return 'SAIDA'}
<newline>entradas?                      {this.begin('lanc')}; return 'ENTRADA'}
<newline>[-A-Za-z\u0080-\u00FF0-9 ]+:\n {this.begin('compra')}

/* any typing will push you into <any> state */
<newline>[^\n]                          this.begin('any')

":"                                     return 'COLON'
";"                                     return 'SEMICOLON'
", "                                    return 'COMMASPACED'
","                                     return 'COMMA'
"|"                                     return 'VERTICAL'
"/"                                     return 'SLASH'
"-"                                     return 'HYPHEN'
"("                                     return 'OPENP'
")"                                     return 'CLOSEP'
<<EOF>>                                 return 'EOF'
[0-9]+                                  return 'NUMBER'
\D[-A-Za-z\u0080-\u00FF0-9 ]*           return 'STRING'

/* a newline resets the state */
\n                                      {this.begin('newline'); return 'NEWLINE'}

%options case-insensitive

/lex

%right NEWLINE
%left  DE
%right OPENP
%left  CLOSEP
%right SLASH

%start input

%% /* language grammar */

input
  : input EOF { return res }
  | input NEWLINE
  | input NEWLINE lanc { res.push($3); }
  | input NEWLINE venda { res.push($3); }
  | input NEWLINE saldo { res.push($3); }
  | input NEWLINE compra { res.push($3); }
  | input NEWLINE comment { res.push($3); }
  | input NEWLINE pagamento { res.push($3); }
  | lanc { res = [$1] }
  | venda { res = [$1] }
  | comment { res = [$1] }
  | pagamento { res = [$1] }
  | saldo { res = [$1] }
  | compra { res = [$1] }
  ;

saldo
  : SALDO sep value {$$ = $3; $$.kind = 'saldo'}
  | SALDO sep value {$$ = $3; $$.kind = 'saldo'}
  ;

comment
  : STRING {$$ = {note: $1, kind: 'comment', lineno: @$.first_line}}
  ;

lanc
  : SAIDA sep value {$$ = {kind: 'caixa', item: $1, value: -$3}}
  | ENTRADA sep value {$$ = {kind: 'caixa', item: $1, value: $3}}
  | SAIDA sep pagamento_descr {$$ = $3; $$.kind = 'caixa'; $$.value = -$$.value}
  | ENTRADA sep pagamento_descr {$$ = $3; $$.kind = 'caixa'}
  ;

compra
  : STRING COLON NEWLINE compra_descr NEWLINE {$$ = $4; $$.fornecedor = $1; $$.kind = 'compra'}
  | STRING COLON NEWLINE compra_descr {$$ = $4; $$.fornecedor = $1; $$.kind = 'compra'}
  ;

venda
  : item note {$$ = $1; $$.note = $2; $$.kind = 'venda'}
  | item {$$ = $1; $$.kind = 'venda'}
  ;

pagamento
  : PAGAMENTO sep pagamento_descr {$$ = $3; $$.kind = 'pagamento'}
  | pagamento_descr sep PAGAMENTO {$$ = $1; $$.kind = 'pagamento'}
  ;

pagamento_descr
  : STRING sep value {$$ = {value: $3, item: $1}}
  | value sep STRING {$$ = {value: $1, item: $3}}
  ;

compra_descr
  : itemgroup extras total { $$ = {items: $1, extras: $2, total: $3} }
  | itemgroup extras { $$ = {items: $1, extras: $2} }
  | itemgroup total { $$ = {items: $1, total: $2} }
  | itemgroup { $$ = {items: $1} }
  ;

itemgroup
  : item NEWLINE itemgroup {$$.push ? $$.push($1) : $$ = [$1]}
  | item NEWLINE {$$ = [$1]}
  ;

item
  : item_quant {$$ = $1}
  | item_quant sep value {$$ = $1; $$.value = $3}
  | value sep item_quant {$$ = $3; $$.value = $1}
  ;

item_quant
  : quant post_quant_sep STRING {$$ = $1; $$.item = $3}
  | quant STRING {$$ = $1; $$.item = $2}
  | STRING COMMASPACED quant {$$ = $3; $$.item = $1}
  | num STRING  {$$ = {}; $$.q = $1; $$.u = 'u'; $$.item = $2}
  ;

total
  : TOTAL sep value {$$ = $3}
  | EQUALS value {$$ = $2}
  ;

extras
  : extra NEWLINE extras {$$.push ? $$.push($1) : $$ = [$1]}
  | extra NEWLINE {$$ = [$1]}
  ;

extra
  : PLUS STRING sep value {$$ = {item: $2, value: $4}}
  | PLUS STRING {$$ = {item: $2}}
  ;
  
sep
  : HYPHEN
  | COLON
  | COMMA
  | VERTICAL
  ;

post_quant_sep
  : DE
  | SEMICOLON
  ;

quant
  : num UNIT {$$ = {q: $1, u: $2}}
  ;

value
  : BRL num {$$ = $2}
  | num BRL {$$ = $1}
  | num CENT {$$ = $1/100}
  | num
  ;

num
  : NUMBER COMMA NUMBER {$$ = $1 + '.' + $3}
  | NUMBER SLASH NUMBER {$$ = parseFloat($1)/parseFloat($3)}
  | NUMBER num {$$ = parseFloat($1) + parseFloat($2)}
  | NUMBER
  ;

note
  : OPENP superstring CLOSEP {$$ = $2}
  ;

superstring
  : superstring STRING {$$ = $1 + $2}
  | superstring COMMA {$$ = $1 + $2}
  | superstring COLON {$$ = $1 + $2}
  | superstring SEMICOLON {$$ = $1 + $2}
  | superstring NUMBER {$$ = $1 + $2}
  | STRING {$$ = $1}
  ;
