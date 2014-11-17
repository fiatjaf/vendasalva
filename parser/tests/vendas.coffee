PEG      = require 'pegjs'
fs       = require 'fs'
path     = require 'path'
should   = require('chai').should()

parser = PEG.buildParser fs.readFileSync path.resolve(__dirname, '../dia.peg'), encoding: 'utf-8'

test = '''
2 pacotes de 1kg de farinha de arroz urbano: R$ 24,50

 1 garrafa de 500ml de vinagre de maçã jatobá : R$ 14
 2 sacos de 2 kg de soja: 7
 2 latas 500ml de pimenta: R$ 20

 3 vidro 500ml molho tomate: R$ 40
 saquinho castanha de caju: 2,20
2 pacotes de 1kg de farinha de arroz urbano: R$ 24,50
banana, 2kg: R$ 20

 leite: R$ 3
 (banana 2,00 -- não pagou, homem do correio)
   vinagre de maçã jatobá: R$ 14,60

bolo de banana, 1kg: 4,80
1kg açúcar mascavo: R$ 13,20
500g de cogumelo: 1 real
1 pacote de uvas: R$ 4,50
1kg de uvas :40 reais
R$ 4: cacau-em-pó, 400g

soja orgânica, 1 pct: 8 reais
2 ramos de alface :50 cents
4 pencas de banana: R$ 2,25
3 pólen-novo: 74,90

1 banana: 20 centavos
'''

res = parser.parse test

