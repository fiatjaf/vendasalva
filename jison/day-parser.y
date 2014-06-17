%lex
%%

[ \t]+                                 {}
\n                                     return 'NEWLINE'
[0-9]+                                 return 'NUMBER'
ramos?                                 return 'UNITY'
unidades?                              return 'UNITY'
pacotes?                               return 'UNITY'
pcts?                                  return 'UNITY'
pencas?                                return 'UNITY'
bandejas?                              return 'UNITY'
"u"                                    return 'UNITY'
"kg"                                   return 'UNITY'
"g"                                    return 'UNITY'
"de"                                   return 'DE'
"por"                                  return 'POR'
":"                                    return 'COLON'
";"                                    return 'SEMICOLON'
", "                                   return 'COMMASPACED'
"-"                                    return 'HYPHEN'
","                                    return 'COMMA'
"reais"                                return 'BRL'
"real"                                 return 'BRL'
"R$"                                   return 'BRL'
"BRL"                                  return 'BRL'
"("                                    return 'OPENP'
")"                                    return 'CLOSEP'
<<EOF>>                                return 'EOF'
[-A-Za-z\u0080-\u00FF0-9 ]+            return 'STRING'

/lex

%left  DE
%left  POR
%right OPENP
%left  CLOSEP

%start input

%% /* language grammar */

input
  : input EOF {return res}
  | input NEWLINE venda {res.push($3); console.log($3)}
  | venda {res = [$1]}
  ;

venda
  : venda note {$$ = $1; $$.note = $2}
  | item_quant
  | item_quant value_sep value {$$ = $1; $$.value = $3}
  | value value_sep item_quant {$$ = $3; $$.value = $1}
  ;

item_quant
  : quant post_quant_sep STRING  {$$ = $1; $$.item = $3}
  | quant STRING {$$ = $1; $$.item = $2}
  | STRING COMMASPACED quant {$$ = $3; $$.item = $1}
  | num STRING  {$$ = {}; $$.q = $1; $$.u = 'u'; $$.item = $2}
  ;
  
value_sep
  : POR
  | HYPHEN
  | COLON
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
  | num
  ;

num
  : NUMBER COMMA NUMBER {$$ = $1 + '.' + $3}
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








