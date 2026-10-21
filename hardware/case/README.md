# Case do console — revisão 0

Primeiro estudo paramétrico de volume para a placa do S20 FE fora do chassi e sem a tela. A
decisão de arquitetura e as medidas vêm de `hardware/README.md`, seção 11. O arquivo
`concept.scad` mostra o envelope, a posição aproximada dos módulos e duas peças separadas:
bandeja (`part = "tray"`) e tampa frontal (`part = "lid"`).

## Envelope de partida

- Corpo: **90 × 180 × 79,6 mm**; com tampa, **90 × 180 × 82 mm**.
- Placa-mãe: envelope de **63 × 51 mm**, na parte superior.
- Bateria: **61 × 73 mm**, abaixo da placa; espessura de 8 mm usada só como estimativa.
- Flex MAIN–SUB: **18 × 81 mm**, passando sobre a bateria.
- Subplaca USB-C: **43 × 22 mm**, com a porta voltada para a base.
- Dissipador: envelope de **45 × 45 × 30 mm**, sobre a marca de pasta térmica do SoC.
- Ventoinha: **80 × 80 × 25 mm**, na tampa, alinhada sobre o dissipador.

O conjunto fica em formato retrato. A tampa tem recorte e furação para a ventoinha, grelha
simples e quatro furos de fixação ao corpo. A bandeja reserva aberturas nas extremidades para
entrada e saída de ar e uma abertura inferior para USB-C.

## Precisão e limites

Este é um **estudo de volume**, não uma peça pronta para imprimir com eletrônica instalada. As
medidas da placa, da bateria e da subplaca foram estimadas pelas fotos sobre papel milimetrado e
podem errar 1–2 mm. A espessura da bateria, as alturas dos componentes, o centro exato do SoC,
os furos originais da placa e as dimensões do hub sem carcaça ainda precisam ser medidos. Os
mockups retangulares representam envelopes, não o contorno real das placas.

Por isso, o modelo ainda não cria apoios que possam pressionar componentes nem furos para a
placa-mãe. A posição do dissipador e o fluxo final do ar também dependem de medidas e dos testes
térmicos. Não imprimir a bandeja completa para montar o telefone nesta revisão; ela serve para
visualizar o volume e orientar a próxima rodada de medições.

## Próximas medidas para fechar o encaixe

1. Contorno da placa e coordenadas dos furos originais, medidos a partir de dois cantos.
2. Alturas nos dois lados da placa, incluindo conectores, blindagens e a folga para o pad/pasta.
3. Espessura real da bateria escolhida e posição segura do cabo.
4. Posição da USB-C em relação ao contorno da subplaca e sua altura.
5. Dimensões do ZEN1 sem carcaça e do Pico 2, para definir o espaço de montagem.
6. Dimensões reais do dissipador, distância até a ventoinha e direção de entrada/saída de ar.

Depois dessas medidas, a primeira peça física deve ser um gabarito baixo de contorno e furos;
o corpo completo vem após conferir o encaixe e os cabos flexíveis.

## Referências visuais

As referências que o usuário passou e os elementos aproveitáveis estão em
[`REFERENCIAS.md`](REFERENCIAS.md). A revisão 0 mantém o foco em volume e refrigeração; a forma
externa e o acabamento ficam para a próxima rodada de design.
