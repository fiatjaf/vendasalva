%lex
%%

[ \t]+                                 {}
\n                                     return 'NEWLINE'
[0-9]+                                 return 'NUMBER'
pag(amento|o|uei)?                     return 'PAGAMENTO'
ramos?                                 return 'UNITY'
unidades?                              return 'UNITY'
pacotes?                               return 'UNITY'
pcts?                                  return 'UNITY'
pencas?                                return 'UNITY'
bandejas?                              return 'UNITY'
litros?                                return 'UNITY'
caixas?                                return 'UNITY'
sacos?                                 return 'UNITY'
ramos?                                 return 'UNITY'
"l"                                    return 'UNITY'
"u"                                    return 'UNITY'
"kg"                                   return 'UNITY'
"g"                                    return 'UNITY'
"de"                                   return 'DE'
"+"                                    return 'PLUS'
":"                                    return 'COLON'
";"                                    return 'SEMICOLON'
", "                                   return 'COMMASPACED'
"-"                                    return 'HYPHEN'
","                                    return 'COMMA'
"/"                                    return 'SLASH'
"total"                                return 'TOTAL'
"="                                    return 'EQUALS'
"por"                                  return 'POR'
"reais"                                return 'BRL'
"real"                                 return 'BRL'
"R$"                                   return 'BRL'
"BRL"                                  return 'BRL'
cent(avo)?s?                           return 'BRL'
"("                                    return 'OPENP'
")"                                    return 'CLOSEP'
<<EOF>>                                return 'EOF'
[-A-Za-z\u0080-\u00FF0-9 ]+            return 'STRING'

%options case-insensitive

/lex

%right NEWLINE
%left  STRING
%right BRL
%left  DE
%right POR
%right OPENP
%left  CLOSEP
%right SLASH

%start input

%% /* language grammar */

input
  : input EOF {return res}
  | input NEWLINE
  | input NEWLINE venda { res.push($3); }
  | input NEWLINE compra { res.push($3); }
  | input NEWLINE comment { res.push($3); }
  | input NEWLINE pagamento { res.push($3); }
  | venda { res = [$1] }
  | comment { res = [$1] }
  | pagamento { res = [$1] }
  | compra { res = [$1] }
  ;

comment
  : STRING {$$ = {note: $1, kind: 'comment'}}
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
  : PAGAMENTO value_sep pagamento_descr {$$ = $3; $$.kind = 'pagamento'}
  | pagamento_descr value_sep PAGAMENTO {$$ = $1; $$.kind = 'pagamento'}
  ;

pagamento_descr
  : STRING value_sep value {$$ = {value: $3, item: $1}}
  | value value_sep STRING {$$ = {value: $1, item: $3}}
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
  | item_quant value_sep value {$$ = $1; $$.value = $3}
  | value value_sep item_quant {$$ = $3; $$.value = $1}
  ;

item_quant
  : quant post_quant_sep STRING  {$$ = $1; $$.item = $3}
  | quant STRING {$$ = $1; $$.item = $2}
  | STRING COMMASPACED quant {$$ = $3; $$.item = $1}
  | num STRING  {$$ = {}; $$.q = $1; $$.u = 'u'; $$.item = $2}
  ;

total
  : TOTAL value_sep value {$$ = $3}
  | EQUALS value {$$ = $2}
  ;

extras
  : extra NEWLINE extras {$$.push ? $$.push($1) : $$ = [$1]}
  | extra NEWLINE {$$ = [$1]}
  ;

extra
  : PLUS STRING value_sep value {$$ = {item: $2, value: $4}}
  | PLUS STRING {$$ = {item: $2}}
  ;
  
value_sep
  : HYPHEN
  | COLON
  | POR
  ;

post_quant_sep
  : DE
  | SEMICOLON
  ;

quant
  : num UNITY {$$ = {q: $1, u: $2}}
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








