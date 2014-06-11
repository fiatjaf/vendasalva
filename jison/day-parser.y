%lex
%%

[ \t]+
[0-9]+                                 return 'NUMBER'
[a-zA-Z ]+                             return 'STRING'
ramos?                                 return 'UNITY'
unidades?                              return 'UNITY'
pacotes?                               return 'UNITY'
u                                      return 'UNITY'
pct                                    return 'UNITY'
kg                                     return 'UNITY'
g                                      return 'UNITY'
[:;,-]                                 return 'SEPARATOR'
<<EOF>>                                return 'EOF'

/lex

%start input

%% /* language grammar */

input
  : /**/ {return []}
  | input '\n' {return $1}
  | input expr '\n' {$$ = $1; $$.push($2); return $$}
  ;

expr
  : STRING SEPARATOR quant {console.log($1, $2, $3); return [$1, $3]}
  ;
  
quant
  : NUMBER UNITY {return {q: $1, u: $2}}
  | NUMBER {return {q: $1, u: 'u'}}
  ;

value
  : NUMBER {return $1}
  ;

note
  : '(' NAME ')' {return $2}
  ;









