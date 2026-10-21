# Hardware do console: interior do S20 FE, case e dissipação

Levantamento iniciado em 2026-10-20. Valores marcados com **(a confirmar)** vêm de fontes
secundárias ou de estimativa e precisam ser medidos no nosso aparelho.

## 1. Esquemas elétricos

- Os esquemas e o boardview da Samsung (manual de serviço) são **documentos confidenciais**.
  Não há cópia pública oficial. Os caminhos são:
  - **Samsung GSPN** (portal de assistência autorizada), só para centros autorizados.
  - **Ferramentas pagas de reparo** (ZXW, Borneo Schematics, WUXINJI): assinatura, licenciamento
    duvidoso. Se for usar, buscar pelo modelo exato **SM-G780G** (a placa do 4G é diferente da
    do 5G G781B, que tem o modem X55).
  - Não baixamos cópias vazadas de sites de compartilhamento: não dá para conferir a origem do
    arquivo, e o conteúdo é da Samsung.
- **Para o case e a refrigeração, o esquema não é necessário.** O que importa é o layout físico
  (abaixo) e as medições de temperatura. O esquema é necessário para mods elétricos: **trocar a
  subplaca USB-C por um hub integrado** (seção 9) ou tirar a bateria.
- Fonte técnica livre que já temos: o **device tree do kernel** (`kona*.dtsi` e os arquivos do r8q
  no `~/s20fe-build/kernel`, no Linux) lista os termistores (`thermal_zone*`), o PMIC e os
  reguladores. Usar para mapear qual sensor fica perto de quê.

## 2. Interior (iFixit, S20 FE 5G, mesmo chassi)

Guias com fotos: <https://www.ifixit.com/Device/Samsung_Galaxy_S20_FE> (licença CC BY-NC-SA).
Principais: [placa-mãe](https://www.ifixit.com/Guide/160784),
[tampa traseira](https://www.ifixit.com/Guide/160735),
[conjunto de carga sem fio](https://www.ifixit.com/Guide/160738),
[subplaca USB-C](https://www.ifixit.com/Guide/160743),
[tela, SM-G780F](https://www.ifixit.com/Guide/143692).

Ordem das camadas, de trás para a frente:

1. **Tampa traseira** (vidro/plástico colado), **já removida** no nosso console.
2. **Conjunto da carga sem fio = tampa da placa-mãe**: peça de plástico com folha de **grafite**
   (preta, com um quadrado cinza sobre a blindagem grande), bobina de carga sem fio e NFC, e
   alto-falante embaixo. Presa por **16 parafusos Phillips** (9 × 4 mm na tampa, 7 × 4,5 mm no
   alto-falante) e por presilhas. O guia do G780F chama a parte de cima de **"antenna module"**
   e diz que ela tem um conector na placa, ao lado do conector da bateria.
   - Essa peça **segura os conectores de pressão** (bateria, carga sem fio, câmeras). Sem ela, o
     conector da bateria pode soltar com vibração ou com o peso de um dissipador.
3. **Placa-mãe** (lado de trás): duas blindagens metálicas soldadas, uma grande (≈ ⅔ da largura)
   e outra menor ao lado.
4. **Placa-mãe** (lado da tela): blindagem grande coberta por **grafite grosso com pasta
   térmica**, encostada no **chassi intermediário (midframe)**, que fica colado à tela.
5. Chassi intermediário + tela AMOLED.

**Onde está o SoC (a confirmar):** a pasta térmica fica no lado da tela, o que indica que o
Snapdragon 865 (com a LPDDR5 empilhada) aponta para o chassi intermediário. Então **o caminho
principal de calor do aparelho é pelo chassi e pela tela**, não pela traseira. A traseira recebe
calor através da placa e das blindagens. Não há relato confiável de câmara de vapor no S20 FE
(no S20/Note 20 houve unidades com câmara de vapor e outras só com grafite).
→ Confirmar no nosso aparelho: fotografar os dois lados da placa e medir a temperatura de cada
face durante o teste de estresse.

Dimensões externas oficiais: 159,8 × 74,5 × 8,4 mm. **Medir com paquímetro** o tamanho das
blindagens e a altura da tampa da placa-mãe acima delas.

## 3. Situação térmica atual (números do CLAUDE.md)

| Configuração | GPU | Resultado |
|---|---|---|
| 625 MHz, sem cooler | pico 96 °C | estável, 94% do tempo a 625; bateria 38–39 °C |
| 670 MHz, ambiente ventilado | média 86 °C, pico 91 °C | estabilidade 99,2%; bateria 37 °C |

O `perfd` baixa a GPU um nível a partir de 88 °C. **Meta do case:** GPU abaixo de **80 °C**
em 670 MHz por 30 min, com **bateria abaixo de 40 °C**. Isso daria folga para o `perfd` nunca
precisar baixar o clock.

Estimativa grosseira **(a confirmar)**: o SoC no estresse de GPU deve dissipar de 6 a 9 W. O
corpo do celular parado no ar troca calor por convecção natural (h ≈ 10 W/m²·K, ≈ 0,024 m² nas
duas faces) e aguenta uns 3–4 W sem esquentar demais. Com ar forçado nas duas faces
(h ≈ 30–50) a capacidade triplica, **mesmo sem dissipador**.

### Sensores de temperatura do aparelho (lidos em 2026-10-20, em repouso, cabo no PC)

| Zona | Tipo | Repouso | Onde |
|---|---|---|---|
| 5, 6 | `cpuss-0/1-usr` | 40–41 °C | CPU (no SoC) |
| 15, 24 | `gpuss-0/1-usr` | 38–40 °C | GPU (no SoC) |
| 19 | `ddr-usr` | 40 °C | controlador de memória (no SoC) |
| 64, 74 | `pm8150_tz`, `pm8150l_tz` | 40–41 °C | PMICs da Qualcomm (placa-mãe) |
| 54 | `modem-skin-usr` | 37 °C | termistor de "pele" (perto da superfície) |
| 56 | `modem-ambient-usr` | 36 °C | termistor de ambiente interno |
| 48, 49 | `modem-lte-sub6-pa1/pa2` | 36–37 °C | amplificadores de RF |
| 81 | `usb-therm` | 32 °C | **conector USB-C** (provavelmente na subplaca, a confirmar) |
| 82 | `wpc-therm` | −20 °C | bobina de carga sem fio (valor de "ausente"/sem leitura) |
| 83 | `ac` | 37 °C | entrada de carga |
| 84 | `battery` | 38 °C | bateria |

As zonas `mmw*`, `modem-streamer` e `modem-wifi` dão −273/−2 °C: não existem no G780G (4G).
Fontes de energia em `/sys/class/power_supply/`: `max77705-charger`, `max77705-fuelgauge`,
`pca9468-charger`, `sec-direct-charger`, `mfc-charger` (carga sem fio), `usb`, `ac`, `battery`.

## 4. Opções de dissipação (da mais simples para a mais invasiva)

### A. Ventilação nas duas faces, sem abrir mais nada *(começar por aqui)*
- Celular **em pé** (de lado ou na vertical), com ar passando **pela frente (tela) e por trás**.
  Como o calor sai sobretudo pela tela, deitar o celular com a tela para baixo é a pior opção.
- Ventoinha grande e lenta (80–92 mm a 5 V, ou uma de 12 V rodando a 5 V) é mais silenciosa que
  uma de 40 mm em rotação alta.
- Custo zero de risco. Medir antes de partir para B/C.

### B. Dissipador na traseira, sobre a tampa da placa-mãe
- Dissipador de alumínio (tipo de VGA/Raspberry Pi, 40 × 40 mm ou maior) sobre o quadrado cinza
  da tampa, com pad térmico. Ventoinha por cima.
- Ganho limitado: plástico + grafite no meio do caminho. Mas é reversível e não mexe nas antenas.

### C. Placa de alumínio no lugar da tampa da placa-mãe *(maior ganho na traseira)*
- Placa de alumínio de 1,5–2 mm cortada no formato da tampa original, com os mesmos furos
  (parafusos originais) e **espuma pressionando os conectores**, como faz a tampa.
- Pads térmicos (≥ 6 W/m·K) de 1–1,5 mm entre as blindagens e a placa; dissipador + ventoinha
  parafusados **no case**, não no celular (o peso não pode ficar sobre a placa).
- **Riscos que precisam de teste antes:**
  1. **Antenas.** A parte de cima da tampa é um módulo de antena (pelo menos NFC/carga sem fio;
     talvez mais). Metal ali ou perto das bordas do chassi (que são antenas) pode piorar o
     Wi-Fi e o **Bluetooth dos controles**. Teste: tirar a tampa, aparafusar provisoriamente,
     comparar o RSSI do Wi-Fi (`dumpsys wifi`) e o comportamento dos controles BT.
  2. Curto: a placa metálica não pode encostar em componentes fora das blindagens. Usar fita
     Kapton nas áreas sem blindagem.
  3. Não tirar as tampas das blindagens (são soldadas e protegem RF).
- NFC e carga sem fio já não são usados (NFC desligado).

### D. Lado da tela
- O AMOLED não deve receber dissipador colado (vidro conduz mal e o painel não gosta de calor).
  O ganho vem do ar passando pela frente (opção A) e de **gerar menos calor**: na TV, deixar a
  tela do celular no brilho mínimo ou apagada (ver seção 6).

### E. Placa-mãe fora do chassi *(ideia do usuário, 2026-10-20; em avaliação)*
Tirar a placa-mãe do chassi intermediário e montá-la no case, com o dissipador **direto na
blindagem do SoC** (lado da tela, onde está a pasta térmica, seção 2). É o único jeito de o
dissipador tocar o chip sem plástico nem grafite no meio: a meta da seção 3 passa a ser fácil.
- **Dissipador:** com contato direto, o cobre 45 × 45 × 30 mm + ventoinha já sobra para 6–9 W. O cooler
  de PC (ex.: Rise Mode X2, 95 W) também serve, mas preso no case com pressão leve e
  **nunca pendurado na placa** (placa de 0,8 mm + conectores de pressão). Pad ou pasta conforme a
  folga medida; a blindagem é GND, mas nenhum metal pode tocar componentes fora dela.
- **Tela não é necessária:** o usuário confirmou (2026-10-20) que o aparelho funciona sem a
  tela conectada.
- **O que precisa continuar ligado** (cabos flexíveis curtos, de 2 a 5 cm): bateria (o carregador da
  Samsung não liga sem ela e sem o termistor dela), subplaca USB-C (cabo flexível principal),
  botão power/volume (flex no chassi; sem ele, o celular só liga se a carga der boot direto, o
  que exige mexer no modo de carga desligado).
- **Antenas — maior risco:** as bordas metálicas do chassi são antenas, ligadas à placa por
  molas de contato, e a parte de cima da tampa da carga sem fio é um módulo de antena. Fora do
  chassi, **Wi-Fi e Bluetooth dos controles podem cair muito**. Teste antes de qualquer coisa:
  RSSI do Wi-Fi (`dumpsys wifi`) e alcance dos controles BT com a placa apenas levantada.
- **Ganho extra:** a bateria e a tela deixam de receber o calor do SoC.
- **Contras:** difícil de reverter, risco de rasgar flex e de descarga eletrostática (pulseira
  antiestática), e foge do "plug and play" (cada usuário teria que desmontar o aparelho).
- Ordem: medir antes a opção A (ventoinha) — se já bater a meta, E não é necessária. Antes de
  abrir: fotos dos dois lados da placa e medir o comprimento de cada flex (seção 8).

### F. Sem a tela, placa no chassi, dissipador no chassi *(recomendado para o case novo)*
Como o aparelho funciona sem a tela, o chassi intermediário (a placa de metal entre a placa-mãe
e a tela) pode virar o **espalhador de calor**: a blindagem do SoC já encosta nele com pasta
térmica (seção 2). Sem a tela, a face da frente do chassi fica exposta, e o dissipador vai ali,
logo à frente do SoC.
- **Mantém tudo que a opção E arrisca:** antenas nas bordas do chassi, botões, bateria colada,
  subplaca USB-C e os cabos flexíveis nos lugares originais. Nenhum flex fica esticado.
- **Contato:** tirar a tela também tira a folha de cobre/grafite colada atrás dela; limpar a
  cola, achar o ponto em frente ao SoC (marcar pela posição da blindagem vista de trás) e usar
  pasta térmica (superfície plana) ou pad de 0,5–1 mm. O chassi é de alumínio/magnésio e
  conduz bem; o dissipador cobre uma área grande dele, então o cobre 45 × 45 mm já ajuda muito, e
  um dissipador maior (ex.: o do Rise Mode, preso no case) melhor ainda.
- **Tirar a tela do S20 FE em geral a destrói** (AMOLED colado, solto com calor). Guardar o
  aparelho de emergência sem tela: recovery e modo Download continuam funcionando às cegas e
  pelo adb/scrcpy, mas um problema que só aparece na tela fica mais difícil de diagnosticar.
  **Decisão do usuário.**
- A traseira (tampa da placa-mãe) continua no lugar, segurando os conectores; recebe ar da
  mesma ventoinha.

### Descartado por enquanto
- **Peltier**: condensação (já decidido).
- **Tirar a bateria** (alimentar direto): exige esquema, simular termistor/medidor de carga;
  arriscado. O limite de 80% já protege a bateria.
- **Tirar o controle térmico**: proibido pela regra 5 do projeto.

## 5. Case

Ideia de partida: **suporte vertical** ("dock") com o celular em pé, USB-C para baixo ligada
ao hub, ar entrando por baixo e saindo por cima (efeito chaminé + ventoinha).

- Material: se for impresso em 3D, usar **PETG ou ASA** (o PLA amolece perto de 55–60 °C, e a
  região do dissipador pode chegar perto disso).
- Acessos: USB-C (hub), botão power e volume, gaveta do SIM/cartão SD (o cartão já caiu uma vez:
  a gaveta não pode ficar pressionada).
- A ventoinha 5 V puxa energia do hub (USB-A), o que reduz o que sobra para o celular; conferir
  que o hub entrega o suficiente com tudo ligado.
- Manter o celular removível (manutenção, gravar firmware no modo Download).

## 6. Software que reduz calor (sem mexer no hardware)

- Tela do celular no brilho mínimo, ou apagada, enquanto espelha na TV *(a investigar)*.
- Tela já travada em 60 Hz (feito em 2026-10-19).
- Ventoinha controlada pela temperatura: **Raspberry Pi Pico 2 + `scripts/fanctl.sh`**, seção 10.

## 7. Protocolo de medição (igual para toda mudança)

1. Ambiente anotado (temperatura da sala), celular frio (bateria < 32 °C), 80% de carga, na tomada.
2. 3DMark Wild Life Extreme **Stress** (20 min) a 670 MHz, ou o mesmo jogo pesado pelo `perfd`.
3. Anotar: pontuação do 1º e do último loop, estabilidade, % do tempo a 670, GPU média e pico,
   CPU, bateria, `thermal_zone` de pele/placa. Os CSV do `perfd` ficam em `Games/.perf/`.
4. Uma mudança por vez. Registrar na tabela abaixo.

**Ferramenta (2026-10-20):** `scripts/thermlog.sh` (no celular, em `/data/adb/s20fe/bin/`) grava a
cada ~2,5 s clock/uso/teto da GPU, CPU, temperaturas (CPU, GPU, DDR, pele, ambiente interno, USB,
entrada de carga, bateria), carga/corrente/tensão da bateria, tela e TV em
`Games/.perf/termico-<data>-<rótulo>.csv`. Roda sozinho, destacado do adb: dá para iniciar pelo
PC e passar o celular para o hub (a USB-C é uma só). Opcionalmente sobe o teto da GPU durante o
teste e devolve o anterior no fim (o thermal-engine continua ativo). No PC:

```sh
tools/thermal-test.sh start A-ventilado 40 670   # instala/confere o hash e inicia (40 min, teto 670)
#   ... desconectar do PC, ligar no hub, rodar o 3DMark Stress ...
tools/thermal-test.sh status                     # com o celular de volta no PC
tools/thermal-test.sh pull --sala 27             # baixa (hash conferido) para hardware/medicoes/ e resume
```

O resumo (`tools/thermsum.py`) conta como "em carga" as amostras com a GPU acima de 50% de uso
e mostra: tempo em carga, % no teto, GPU média/pico, tempo acima de 80 °C e de 88 °C, picos de
CPU/pele/USB, bateria (temperatura, carga, corrente média: **negativa = descarregando**),
compara com a meta da seção 3 e imprime a linha para a tabela abaixo.

**Pré-requisitos dos testes:**
- **3DMark** reinstalado pela Aurora (foi removido na limpeza de 2026-10-18).
- **Fonte PD de verdade no hub.** No teste de 2026-10-20 o ZEN1 só ofereceu 5 V/1,5 A e a
  bateria descarregava em jogo; nesse caso a bateria esquenta por descarga e o resultado não
  representa o console. A corrente média do resumo mostra se a fonte deu conta.
- Celular em 80% (o limite de carga para aí, e a bateria para de gerar calor de carga).

**Ordem dos testes:**
1. **Base:** celular em pé, sem ventoinha, 670 MHz. Referência para todo o resto.
2. **A1:** ventoinha soprando a **traseira** (tampa da placa-mãe). Com o Pico (seção 10), fixar a
   velocidade em todos os testes A/B (`fanctl.sh fixo 100`) para comparar só a montagem; a curva
   automática fica para o fim.
3. **A2:** ventoinha soprando a **frente** (tela) — o caminho principal do calor, pela seção 2.
4. **A3:** ar nas duas faces (duas ventoinhas, ou uma com o celular em pé no meio do fluxo).
5. **B:** dissipador de cobre sobre a tampa + ventoinha (seção 10). Depois **C**, só se ainda
   faltar.

| Data | Configuração | Sala | GPU méd./pico | Bateria | Estabilidade | Obs. |
|---|---|---|---|---|---|---|
| 2026-10-12 | 625 MHz, sem cooler | ? | ?/96 °C | 38–39 °C | — | 20 min Wild Life Extreme Stress |
| 2026-10-12 | 670 MHz, ventilado | ? | 86/91 °C | 37 °C | 99,2% | 1.240 / 1.230 |

## 8. Próximos passos

- [ ] Fotos dos dois lados da **nossa** placa (SM-G780G) e da tampa da placa-mãe por dentro.
- [ ] Medidas com paquímetro: blindagens, altura da tampa, espaço livre até a borda do chassi.
- [x] Listar os `thermal_zone*` em repouso (2026-10-20, seção 3). Falta: no estresse.
- [x] Modelo do hub: Polares ZEN1 (seção 9).
- [x] IDs USB do ZEN1 (2026-10-20): hub `214b:7260` (USB 2.0), leitor `349c:0418`.
- [ ] Chip conversor DP→HDMI/PD do ZEN1: só abrindo.
- [ ] Repetir a leitura **com a TV ligada** e com a fonte PD certa: conferir os PDOs (9 V?) e se a
      bateria carrega em jogo.
- [x] Registrador térmico + resumo (`scripts/thermlog.sh`, `tools/thermal-test.sh`,
      `tools/thermsum.py`), testados no aparelho em 2026-10-20 (sem carga).
- [ ] Reinstalar o 3DMark (Aurora) e conseguir uma fonte PD que o hub repasse com 9 V.
- [ ] Testes Base, A1, A2, A3 com o protocolo da seção 7.
- [ ] Teste de antena: Wi-Fi/BT com e sem a tampa da placa-mãe (e com o dissipador de cobre).
- [x] Firmware do Pico 2 e serviço `fanctl.sh` (2026-10-20). Serviço instalado no celular,
      curva testada com temperaturas simuladas. **Falta:** montar o circuito, gravar o
      CircuitPython e testar com o Pico de verdade (seção 10).

## 9. Ideia: hub integrado no lugar da subplaca USB-C

Objetivo: em vez de subplaca + plugue USB-C + hub externo, uma placa própria ligada direto no
cabo flexível principal↔subplaca, com saída HDMI, entrada de energia e USB para controles.

**Quem faz o quê hoje (kernel do r8q, `kona-sec-common.config`)** — o "cérebro" do USB-C fica
na **placa-mãe**, não na subplaca:
- **MAX77705** (Maxim): controlador USB-C/PD (`CCIC_MAX77705`, `PDIC_PD30`, `CCIC_ALTERNATE_MODE`
  = negocia o modo DisplayPort), MUIC, carregador, medidor de bateria e motor de vibração.
- **PCA9468**: carregador direto (25 W PPS).
- Saída DP: controlador DisplayPort do SM8250. O defconfig base da Qualcomm também liga o
  redriver **NB7VPQ904M** e a chave de SBU **FSA4480**; **se o r8q usa e em qual placa eles
  ficam é o que o esquema responderia** (a confirmar).
- A subplaca deve ter: receptáculo USB-C, proteções ESD, microfone de baixo, alimentação do
  alto-falante/antena (cabo coaxial azul) e talvez o redriver/FSA4480. O defeito de vídeo que
  tivemos (`interlane_align_done = 0`, resolvido com a troca da subplaca em 2026-10-18) mostra
  que as linhas rápidas do DP passam por ela.

**O que uma placa própria teria que fazer:**
1. Ligar no conector do cabo flexível (pinagem: **precisa do esquema** ou de engenharia reversa).
2. Fazer o papel do hub do outro lado do CC: um controlador PD que **fornece energia** ao
   celular e **anuncia o modo DisplayPort** (Discover Identity/SVIDs, Enter Mode, DP Configure,
   HPD) para o MAX77705, que continua no celular.
3. Conversor DP→HDMI (ex.: Parade PS176, Lontium LT8711; muitas folhas de dados só com NDA).
4. Hub USB 2.0 para controles com fio (as linhas D+/D− continuam disponíveis no modo DP com 2 ou
   4 lanes, mas a 4 lanes não sobra USB 3).
5. Roteamento de alta velocidade (pares de 100 Ω, placa de 4+ camadas) para DP HBR2/HBR3.
6. Não disparar a **detecção de umidade** da Samsung (o MAX77705 mede as linhas do conector e
   pode bloquear a carga se "parecer" molhado).
7. Manter o **`usb-therm`** (termistor do conector, zona 81): o driver de bateria da Samsung usa
   essa leitura para cortar a carga se o conector esquentar. Se o termistor estiver na subplaca,
   a placa própria precisa de um equivalente (ou a carga pode ser bloqueada).

### O hub atual (Polares)

- **Polares ZEN1**, "hub USB-C 7 em 1" cinza (alumínio), vendido no Mercado Livre
  (produto `MLB48918581`). **Portas (conferidas pelo usuário em 2026-10-20):** HDMI, **3× USB-A**,
  leitor **SD** e leitor **microSD**, **1× USB-C só para carregamento** (PD, potência não
  informada) = 7 em 1. Versão USB de cada USB-A a conferir (os anúncios citam USB 3.0 e 2.0).
  Sem ficha técnica do fabricante.
- Se identifica como **VID 0x057E / PID 0x2003** (ID da Nintendo: hubs baratos fingem ser o dock
  do Switch para funcionar no console), é **repetidor HDCP 1.3** e anunciou só **1 lane** de DP a
  HBR2 com o monitor (levantado em 2026-10-12).
- Esse perfil é típico dos hubs com chip conversor "tudo em um" (DP→HDMI + PD), como os
  **Algoltek AG93xx** encontrados em docks genéricos de Switch, com um hub USB simples (ex.:
  Terminus FE1.1). **Hipótese, não confirmada.**
- **Leitura feita em 2026-10-20** (script no aparelho grava em `/data/local/tmp/hub-id.txt`
  enquanto está no hub; o adb pela rede não serviu porque PC e celular estavam em redes
  diferentes, 192.168.0.x × 192.168.1.x):
  - Hub USB: **`214b:7260` "USB2.0 HUB"** (VID 214b, provavelmente Huasheng). **Só USB 2.0**: o
    barramento USB 3 do celular ficou vazio. Apesar dos anúncios, não há USB 3.0 nesse hub.
  - Leitor de cartão: **`349c:0418` "Generic USB2.0 Device"**, `usb-storage`; o cartão apareceu
    como `sde` com a partição `sde1` (montagem no Android ainda não conferida).
  - Parte de vídeo/PD: identidade PD `057e:2003` (`/sys/class/sec/ccic/usbpd_ids`),
    `secdp_adapter_check: venId:0x0000 prodId:0x2003 genuine:0`, modo DP com
    **pin assignment D** (2 lanes de DP + USB 2). Chip conversor ainda desconhecido (precisa abrir).
  - **Energia: o hub ofereceu só 1 PDO, 5 V / 1,5 A (7,5 W)**, sem 9 V, sem PPS:
    `iin` 468 mA, `vbyp` 4,7 V, charger "abnormal", e a bateria chegou a **−1.345 mA** (descarregando)
    a 43 °C. Com a fonte usada nesse teste, **o hub não sustenta o celular em jogo**.
  - O HDMI ficou com **HPD baixo** (`CCIC_NOTIFY_ID_DP_HPD sub1<low>`, `card0-DP-1` = disconnected)
    nas duas conexões: o hub não viu TV ligada nesse teste (TV desligada/sem cabo?).
- Para o caminho **A** (placa do hub dentro do case), ver também se ele tem chip conversor
  grande que esquenta: precisará de ar da mesma ventoinha.
- **O cabo do ZEN1 é soldado na placa** (padrão desses hubs): não encurtar nem cortar (são ~20
  fios, alguns de alta velocidade; refazer a solda pode trazer de volta o problema de sinal do
  DP). No case: tirar ou manter a carcaça de alumínio e **dobrar o cabo** num canal.
- Extras úteis do ZEN1 no console: 3× USB-A para a ventoinha 5 V, controles com fio ou receptor
  2,4 GHz; leitores de cartão como armazenamento extra (a testar no Android). A carga do celular
  entra pela USB-C de energia do hub: a fonte precisa cobrir celular + ventoinha + o que estiver
  nas USB-A.

**Avaliação:** é projetar um dock USB-C do zero, sem o conector USB-C. Possível, mas é o item
mais difícil e mais arriscado do projeto (erro na pinagem ou no VBUS = placa-mãe queimada).

**Caminhos, do mais simples ao mais difícil:**
- **A (recomendado):** tirar a placa de dentro de um hub comprovado (o atual funciona: DP com
  HDCP, PD) e montá-la **dentro do case**, encaixada direto na USB-C do celular, sem cabo. Dá o
  mesmo resultado prático (um aparelho só, sem nada pendurado) sem mexer no celular.
- **B:** engenharia reversa da **subplaca antiga com defeito** (a que foi trocada, se ainda
  existir): fotos dos dois lados + continuidade com multímetro do conector do cabo flexível até
  os pinos do USB-C (pinagem do USB-C é padrão). Dá a pinagem parcial sem esquema e sem risco.
- **C:** com o esquema do **SM-G780G** (não o do G781B) + B, desenhar a placa própria.

## 10. Resfriamento ativo: Pico 2 + ventoinha 80 mm + dissipador de cobre (2026-10-20)

Material do usuário: **Raspberry Pi Pico 2** (RP2350), **dissipador de cobre 45 × 45 × 30 mm** (base 45 × 45, altura 30 com as aletas),
**ventoinha 80 mm 12 V 0,1 A de 2 fios** (vermelho +, preto −; sem sensor de rotação, então o
rpm fica sempre "-").

### Como funciona

```
 celular (root)                         hub ZEN1                     Pico 2
 scripts/fanctl.sh  ── USB-C ──►  USB-A ─────── cabo micro-USB ──►  code.py ── PWM 25 kHz ──► transistor ──► ventoinha
   lê SoC e bateria                                                   ▲  falha segura:
   a cada 2 s manda "F 65"  ◄──── resposta "S 65 rpm dissipador ..." ─┘  sem notícia por 10 s = 100%
```

- **Por que HID e não serial:** o kernel do celular não tem `CONFIG_USB_ACM` (porta serial USB),
  mas tem `CONFIG_HIDRAW=y` (conferido em 2026-10-20). O Pico se apresenta como HID "de
  fabricante" (usage page 0xFF00) chamado **"s20fe S20FE Fan"**: o Android não o trata como
  teclado nem controle, só cria `/dev/hidrawN`. Sem recompilar o kernel.
- **Quem decide é o celular** (as temperaturas do SoC estão lá). Curva (`fanctl.sh`): SoC
  50 °C → 30% … 80 °C → 100%; bateria 35 °C → 30% … 40 °C → 100%; vale o maior. Sobe na hora,
  desce 5% a cada 2 s e só para abaixo de 46 °C (SoC) e 34 °C (bateria). Testada com
  temperaturas simuladas.
- **O Pico protege:** partida a 100% por 1 s (motor parado não arranca com PWM baixo); sem
  pedido do celular por 10 s → 100% (ou curva pelo NTC do dissipador, se instalado). LED aceso
  = celular no controle; piscando = modo de segurança.
- **O controle térmico do Android continua ativo** (regra 5). A ventoinha só soma.
- Estado em `/data/local/tmp/s20fe-fan.txt`; o `thermlog.sh` grava as colunas `fan_pct`,
  `fan_rpm`, `t_dissip` e `fan_modo`, e o `thermsum.py` resume a ventoinha.

### Peças que faltam (baratas)

| Peça | Para quê | Alternativas |
|---|---|---|
| Transistor NPN **BC337** ou **2N2222** | liga a ventoinha (lado do GND) | MOSFET de nível lógico **IRLZ44N**, **IRLB8721** ou **AO3400** (SMD). **Não** usar 2N7000/IRF540 (não abrem direito com 3,3 V) |
| Resistores **1 kΩ** e **10 kΩ** | base do transistor e pull-down | com MOSFET: 100 Ω no gate + 10 kΩ |
| Diodo **1N5819** (ou 1N4148) | protege o transistor do pico de tensão do motor | 1N4007 também serve |
| **Pad térmico 1 mm** (≥ 6 W/m·K) ou fita térmica dupla face | dissipador sobre a tampa | |
| Cabo **micro-USB** curto | Pico 2 ↔ USB-A do hub | |
| *Para 12 V:* módulo **step-up MT3608** (5 → 12 V) | ventoinha na rotação nominal | fonte 12 V separada (GND em comum com o Pico) |
| *Opcional:* **NTC 10 k B3950** + resistor 10 kΩ | temperatura do dissipador; curva própria se o celular parar | |

### Ligações (ventoinha de 2 fios)

Pinos do Pico 2 pela numeração da placa (pino 1 = canto do conector USB, lado do GP0).

```
 +V_FAN ──────────────┬──────────────┐        +V_FAN = VBUS (pino 40) = 5 V   (etapa 1)
                      │              │                ou saída do MT3608 = 12 V (etapa 2)
              vermelho│        catodo│ (faixa)
                ┌─────┴────┐    1N5819
                │ ventoinha│         │
                └─────┬────┘    anodo│
                 preto│              │
                      ├──────────────┘
                      │
                      C
 GP15 (pino 20) ─1kΩ─ B   BC337 / 2N2222   (com a parte plana de frente, pernas em ordem diferente:
          │           E                     BC337 = C B E, 2N2222 = E B C; conferir a folha de dados)
         10kΩ         │
          │           │
 GND (pino 18) ───────┴──── GND do MT3608 / da fonte de 12 V, se houver

 Jumper de edição: GP22 (pino 29) ↔ GND (pino 28)   — só para trocar o code.py
 NTC (opcional):   3V3 (pino 36) ─10kΩ─ GP26 (pino 31) ─NTC─ AGND (pino 33)
```

- Ventoinha de 2 fios tem um circuito interno que gira o motor; o PWM corta a alimentação dele
  25 mil vezes por segundo. Em geral funciona, mas em PWM baixo algumas param ou chiam. Se
  acontecer: subir o `MINIMO`; se ainda chiar, testar `FREQ_PWM` menor (ex.: 100 Hz, que pode
  dar um "tique" baixo).
- Se um dia trocar por uma de 3 fios, o fio amarelo (rpm) **nunca vai direto no Pico** em 12 V
  (pode subir até 12 V com o transistor cortando o GND): usar um diodo Schottky BAT85 (anodo no
  GP14, pino 19). Na de 4 fios, o fio azul (PWM) vai no coletor e `INVERTER = True`.
- **Etapa 1 — 5 V direto do VBUS:** muitas ventoinhas de 12 V giram a ~40% da rotação com 5 V
  (silenciosas, ~40 mA). Testar `fanctl.sh fixo 100` e `fixo 30`: se não arrancar ou não der
  vazão, ir para a etapa 2. Ajustar o `MINIMO` (no `code.py` e no `fanctl.sh`) para o menor
  valor em que ela gira sem parar.
- **Etapa 2 — 12 V pelo MT3608:** entrada no VBUS (pino 40) e GND; **regular a saída para
  12,0 V com o multímetro antes de ligar a ventoinha** (o trimpot vem em qualquer valor e pode
  passar de 20 V). A 12 V a ventoinha consome ~1,2 W, ~0,3 A dos 5 V da porta: isso sai do que o
  hub tem para o celular. Com a fonte de 5 V/1,5 A que o hub recebeu no teste de 2026-10-20 o
  celular já descarregava; **só usar 12 V com uma fonte PD de verdade** (seção 7).
- Montar primeiro em protoboard; ver o Pico funcionando no celular antes de soldar.
- **Pico 1 (RP2040) serve igual:** mesma pinagem, mesmos pinos e o mesmo `boot.py`/`code.py`;
  só o UF2 muda. Diferença: os pinos do RP2040 **não toleram 5 V** (o RP2350 tolera); neste
  circuito nenhum pino recebe mais de 3,3 V, então não importa.

### Gravar o firmware (CircuitPython 10.3.1)

1. Baixar o UF2 oficial **da placa certa** (o de uma não funciona na outra):
   - Pico 2: <https://downloads.circuitpython.org/bin/raspberry_pi_pico2/en_US/adafruit-circuitpython-raspberry_pi_pico2-en_US-10.3.1.uf2>
   - Pico 1: <https://downloads.circuitpython.org/bin/raspberry_pi_pico/en_US/adafruit-circuitpython-raspberry_pi_pico-en_US-10.3.1.uf2>
   - Versões **W** (com Wi-Fi) têm UF2 próprio (`raspberry_pi_pico_w` / `raspberry_pi_pico2_w`).
   O site não publica hash: anotar o SHA-256 aqui na hora (regra prática do projeto).
2. Segurar **BOOTSEL** e ligar o Pico no PC → aparece o drive `RP2350` (Pico 2) ou `RPI-RP2`
   (Pico 1) → copiar o UF2. O Pico reinicia como `CIRCUITPY`.
3. Copiar **`hardware/cooler-pico/code.py`** e por último **`boot.py`** para o `CIRCUITPY`.
4. Desconectar. **Sem o jumper GP22–GND o drive não aparece mais** (de propósito: o Android
   montaria o "pendrive" toda vez). Para editar: pôr o jumper, conectar, editar, tirar o jumper.
5. No Windows, o Pico deve aparecer em "Dispositivos de interface humana". Com o jumper, o
   console serial do CircuitPython (COM) mostra erros do `code.py`.

### No celular

- Serviço **`/data/adb/service.d/fanctl.sh`** (instalado em 2026-10-20, hash conferido; sem o
  Pico só procura o dispositivo a cada 5 s). Log `/data/local/tmp/s20fe-fan.log`.
- Pico ligado numa USB-A do hub, conferir:
  `adb shell su -c "sh /data/adb/service.d/fanctl.sh teste"` → temperaturas, velocidade calculada
  e o estado (`<epoch> <pedido> <aplicado> <rpm> <dissipador> <temp do Pico> <modo>`).
- Velocidade fixa para os testes: `fanctl.sh fixo 100` (ou 0–100); `fanctl.sh fixo auto` volta
  à curva.
- Desligar de vez: apagar `/data/adb/service.d/fanctl.sh` e matar o processo
  (`kill $(cat /data/local/tmp/s20fe-fan.pid)`); o Pico vai para 100% em 10 s (tirá-lo da USB).

### Montagem física

- **Onde vai o cobre:** na traseira, sobre o **quadrado cinza do grafite** da tampa da placa-mãe
  (fica sobre a blindagem grande), com pad térmico de 1 mm. É a opção **B** da seção 4: o ganho
  é limitado pelo plástico + grafite no caminho, por isso medir **A1 (só ventoinha) e B (cobre +
  ventoinha)** com o mesmo protocolo e decidir pelo número.
- **Peso:** o cobre de 45 × 45 × 30 mm deve passar de 100 g (maciço desse tamanho daria ~540 g; com aletas, uma fração disso). Pesar antes de decidir a fixação. Não deixar pendurado no celular: o
  case (ou um elástico/abraçadeira leve) segura o dissipador contra a tampa; a tampa segura os
  conectores de pressão e não deve receber força.
- **Ventoinha:** a 1–3 cm do dissipador, soprando contra as aletas. O centro (motor) de uma
  ventoinha de 80 mm quase não sopra: alinhar as aletas com a coroa das pás, não com o centro.
  O ar que passa do dissipador deve escapar pelas laterais e, se o case permitir, lamber a
  frente (tela), que é o caminho principal do calor (seção 2).
- **Antenas:** cobre é metal. Fazer o teste de Wi-Fi/BT (seção 8) com o dissipador no lugar.
- **Curto:** o cobre só encosta na tampa plástica. Nada de cobre perto de componentes expostos.

## 11. Case novo impresso em 3D, placa fora do chassi *(decidido em 2026-10-20)*

Decisões do usuário: **opção E** (placa-mãe fora do chassi; o aparelho funciona sem a tela),
case **impresso em 3D**. Ainda **não há paquímetro**.

### Testes antes de desmontar de vez (nesta ordem; param o plano se falharem)
1. **Antenas.** Com a tampa da placa-mãe fora, soltar os parafusos e **levantar a placa alguns
   milímetros** do chassi (os contatos de mola das antenas perdem o contato, como no case novo):
   comparar o RSSI do Wi-Fi (`dumpsys wifi | grep -i rssi`) e o alcance dos controles BT com a
   placa no lugar e levantada.
   - Se cair muito, alternativas sem antena do celular: **controles 2,4 GHz com receptor USB**
     no hub (não usam o Bluetooth do celular) e **rede por adaptador USB-Ethernet** (conferir no
     kernel: `CONFIG_USB_RTL8152`, `CONFIG_USB_NET_AX88179_178A`, `CONFIG_USB_NET_CDCETHER`,
     `CONFIG_USB_USBNET`; não deu para ver em 2026-10-20, celular fora do PC).
2. **Botão power.** Ver nas fotos onde fica o flex dos botões laterais (no chassi ou na placa) e
   como o case vai apertá-lo. Sem botão, o aparelho não liga depois de desligado.
3. **Bateria.** Ela fica colada no chassi. Soltar bateria de lítio colada tem **risco de
   perfurar e pegar fogo**: dobrar ou usar ferramenta de metal, nunca. Recomendado: **bateria
   nova** (S20 FE: EB-BG781UBY, 4500 mAh) para o case; a antiga sai com álcool isopropílico
   sob a cola, sem pressa, e vai para descarte correto. O console precisa da bateria (seção 4,
   "Descartado").

### Medidas sem paquímetro
- **Fotos sobre papel milimetrado** (ou com uma régua encostada na peça), câmera **paralela** à
  mesa e de cima, cada lado da placa, subplaca, bateria e hub sem a carcaça. Com o quadriculado
  dá para tirar o contorno com erro de ~0,5 mm.
- Recomendado comprar um **paquímetro digital** (barato) antes de imprimir as peças que
  encaixam: furos, altura dos componentes, espessura do dissipador.
- Imprimir **peças de teste finas** (só o contorno, 2 mm de altura) e ajustar antes do case inteiro.

### Desenho
- Estudo paramétrico de volume rev. 0 em `hardware/case/concept.scad`, com instruções em
  `hardware/case/README.md`. Serve para revisar o arranjo e o envelope; ainda não é peça de
  encaixe nem está pronto para montar a eletrônica.
- Fechar o modelo de encaixe depois das medidas: contorno e furos da placa, alturas dos
  componentes, bateria, posição da USB-C e dimensões do hub.
- Placa presa por **espaçadores nos furos dos parafusos originais**, lado do SoC (tela) para
  o dissipador; o dissipador apertado por **molas/parafusos no case**, nunca pendurado na placa.
- Bateria nova em compartimento próprio, **longe do fluxo de ar quente**; subplaca USB-C presa
  ao case, flex principal sem dobra viva; hub ZEN1 sem carcaça + Pico no mesmo case.
- Ar entrando por baixo, passando no dissipador do SoC e saindo por cima.
- Material: **PETG ou ASA** (PLA amolece a 55–60 °C).

### Medidas pelas fotos (2026-10-20, papel milimetrado, sem paquímetro)
Fotos em `hardware/fotos/2026-10-20-*.jpg`. Escala tirada da grade (linha forte = 10 mm,
média = 5 mm) perto de cada peça; conferida com o chassi (1462 × 672 px na foto da traseira =
167 × 77 mm medidos contra 159,8 × 74,5 mm oficiais: **erro de ~4%**, porque a peça fica acima do
papel e mais perto da câmera). Valores com **±1–2 mm**; conferir com paquímetro antes das peças
de encaixe. Alturas (espessuras) **não** saem das fotos.

| Peça | Medida | Observação |
|---|---|---|
| Placa-mãe (contorno total) | ~63 × 51 mm | formato em "U" com dois braços em cima (SIM e conectores) |
| Blindagem grande, lado da tela | ~46 × 29 mm | coberta de grafite; **marca de pasta no meio = SoC** |
| Flex principal MAIN ↔ SUB | 18 mm de largura, ~81 mm livres entre as placas | peça de **SM-G781B** ("SM-G781B CTC R03"), funciona no G780G |
| Subplaca USB-C | ~43 × 22 mm | furos de fixação: um à esquerda, dois nas abas da USB-C |
| Bateria EB-BG781ABY (4500 mAh) | ~61 × 73 mm | ainda colada no chassi; espessura a medir |
| Ventoinha | 80 × 80 × 25 mm (padrão 8025) | 2 fios |

O que as fotos mostram:
- A placa **já está fora do chassi**; as câmeras ficaram no chassi (não são necessárias).
- **Pasta térmica nos dois lados:** lado da tela = blindagem grande com grafite e pasta no centro
  (o SoC); lado de trás = duas blindagens com pasta cinza (encostavam no grafite da tampa).
  O dissipador principal vai no lado da tela, centrado na marca de pasta.
- **Antenas:** a placa tem conectores coaxiais. O cabo azul vai da placa até uma plaquinha de
  contato (encostava numa antena do chassi); os cabos vermelho e branco vão até a subplaca. Há
  um conector coaxial livre no canto de cima. Para o console importam só **Wi-Fi e Bluetooth**
  (4G e GPS não). Falta descobrir quais contatos são do Wi-Fi/BT.
- **Botões:** o flex dos botões laterais ficou no chassi (lado esquerdo na foto da traseira).
  Falta ver como ele se liga à placa.

### Medidas pelas fotos de 2026-10-21
Fotos `hardware/fotos/2026-10-21-*.jpg`. **A escala foi validada com o Pico 2**, que tem medida
oficial (51 × 21 mm): na foto ele dá ~52 × 21 mm. Fotos seguradas na mão (HDMI) não servem para
medir.

**Correção (2026-10-21):** nas fotos do hub a folha inteira aparece, as linhas de 5 mm quase somem e
a escala automática pegou direto a linha de 10 mm; ela foi dobrada por engano e o hub saiu com
metade do tamanho (~71 mm). Com a escala certa (~7 px/mm) a foto dá ~13,5 × 2,9 cm, coerente com
a régua do usuário (12,8 × 2,8 × 1 cm). **Regra:** sempre conferir qual linha é a de 10 mm
contando as finas num recorte ampliado, e conferir com uma medida conhecida.

| Peça | Medida | Observação |
|---|---|---|
| Bateria EB-BG781ABY | **máx. 6 × 63 × 76 mm** | pelo código da etiqueta **1ICP6/63/76** (norma IEC: espessura/largura/comprimento máximos); foto: ~61 × 73. `concept.scad` atualizado |
| Raspberry Pi Pico 2 | 51 × 21 mm (oficial) | furos M2 nos cantos; micro-USB numa ponta |
| Hub ZEN1, corpo | **128 × 28 × 10 mm** | medido com régua pelo usuário (2026-10-21), sem o cabo. **Vai com a carcaça** de alumínio. Portas num lado comprido (SD, microSD, 3 × USB-A, USB-C de energia, LED) e HDMI numa ponta |
| Hub ZEN1, cabo | ~73 mm de cabo + ~36 mm de plugue (com a capa) | pela foto, tomando o corpo de 128 mm como régua; ~24 cm no total. O cabo **não** pode ser cortado (seção 9) |

**Botões laterais (foto do chassi sem a placa):** o power e o volume são teclas de metal do
chassi apertando um **flex laranja com contatos dourados**, colado na lateral; a ponta do flex
encosta por **pressão** em contatos da placa-mãe (não é conector). Caminhos para o case:
1. descolar esse flex do chassi com cuidado e fazer o case **apertá-lo contra a placa** no mesmo
   ponto, com teclas impressas em 3D por cima das cúpulas (sem solda, reversível);
2. soldar fios finos nos contatos da placa até botões no case (mais firme, exige solda fina).
**Contatos achados (2026-10-21, fotos `-flex-botoes-chassi.jpg` e `-placa-molas-botoes.jpg`):** o
flex dos botões termina numa área com **5 contatos dourados redondos** (1 em cima, 2 no meio,
2 embaixo), e a placa-mãe tem, no canto ao lado de um furo de parafuso, **5 molas de contato** no
mesmo arranjo (1 mola em pé + 4 molas em 2 × 2, com as marcas "8G" e "6G" na placa). É ligação só
por pressão, sem conector. Os 5 sinais devem ser power, volume +, volume −, GND e mais um (a
confirmar). Caminhos sem solda na placa do celular:
1. **Reaproveitar o flex original:** descolar do chassi e o case o aperta contra as 5 molas; teclas
   impressas em 3D por cima das cúpulas do flex.
2. **Plaquinha própria de contato:** 5 ilhas de cobre (placa perfurada ou PCB simples) no lugar do
   flex, com 3 botões de toque (*tact switch*) fechando cada sinal com o GND, apertada pelo case
   contra as molas. Antes, descobrir com o multímetro (modo continuidade, celular desligado e sem
   bateria) qual contato do flex é o GND e qual fecha com ele ao apertar cada tecla.
Distâncias aproximadas entre as molas: ~4 mm na horizontal e ~2 mm na vertical (estimadas pelo
tamanho do anel do furo; **medir com paquímetro** antes de fazer a plaquinha).

### Perfis e placas separadas (2026-10-21)
Fotos `2026-10-21-placas-separadas.jpg`, `-placa-perfil*.jpg`, `-subplaca-perfil-usbc.jpg`.
- **O flex MAIN–SUB solta dos dois lados** (conectores placa-a-placa): placa e subplaca podem ser
  montadas separadas e ligadas por último. Se o case pedir outro comprimento, existe flex
  principal de reposição (conferir que seja do G780G/G781B).
- **Contorno com as placas deitadas** (13,8 px/mm): placa-mãe ~62–65 × 52–54 mm; subplaca
  ~44 × 23–25 mm (as sombras aumentam um pouco a medida de cima para baixo).
- **Espessuras pelo perfil** (peça segurada na mão, mais perto da câmera que o papel: a escala vem
  da própria peça, não da grade):
  - placa-mãe com as blindagens dos dois lados: **~3–4 mm**; até **~5 mm** na região dos
    conectores e do leitor de SIM. A faixa da placa de circuito aparece com ~0,8 mm.
  - subplaca na USB-C: **~3,3–3,5 mm**. O conector é do tipo que atravessa a placa (*mid-mount*);
    a proporção da foto bate com o tamanho padrão do receptáculo USB-C (8,94 × 3,26 mm, ~7,4 mm
    de profundidade).
- `hardware/case/concept.scad` atualizado: placa 64 × 53 mm, blindagem de 1,6 mm de cada lado,
  pad de 0,5 mm (o dissipador agora apoia na blindagem do SoC), subplaca 44 × 23 mm e o bloco da
  USB-C com as medidas padrão. **Não renderizado** (sem OpenSCAD neste PC); folgas conferidas na
  conta: topo do dissipador a 45,9 mm e ventoinha a 54,6 mm (8,7 mm livres).
- Para as peças de encaixe ainda vale o paquímetro: espessura exata da pilha da placa e altura
  dos conectores que encostam no case.

### Manual de serviço do SM-G780F (fornecido pelo usuário em 2026-10-21)
O usuário enviou o *Service Manual* do **SM-G780F** (Exynos 990, rev. 1.0, 2020-08). O documento
é marcado como confidencial da Samsung: **não vai para o repositório** (que está no GitHub); aqui
ficam só as informações úteis ao projeto.

**Cuidado com o modelo:** o nosso é o **SM-G780G (Snapdragon 865)**. O chassi, os cabos flexíveis
e a parte mecânica são os mesmos (a foto do manual mostra o mesmo flex "SM-G781B CTC" do nosso
aparelho), mas a **placa-mãe é outra**: processador, posição dos chips e códigos dos componentes
(U…, ANT…, C…) do manual **não valem** para a nossa placa. Usar só como referência de arranjo.

O que vale para o projeto:
- **Lado do processador:** no G780F, o processador (UCP5000) fica no **mesmo lado do leitor de
  SIM**. Na nossa placa, o lado do leitor de SIM é o da grafite com a marca de pasta (foto
  `2026-10-21-placas-separadas.jpg`), o que confirma: **o SoC fica do lado da tela**, sob a
  blindagem grande. A lista de peças mostra que a blindagem do processador (SC7003) tem um
  material térmico próprio ("NANOTIM"): o calor já é levado do chip até a tampa da blindagem,
  então o dissipador em cima dela funciona.
- **Fixação:** a placa-mãe fica presa no chassi por **1 parafuso** e a subplaca por **1 parafuso**
  (o resto são os 16 parafusos da tampa). A placa-mãe tem **7 conectores** e a subplaca **5**. Os
  furos metalizados da placa ("BOTHHOLE") são os pontos naturais para os espaçadores do case.
- **Tela:** liga no conector de 78 pinos (HDC10000 no G780F). O fluxograma "não liga" do manual
  só pede a tela para o diagnóstico de imagem: confirma que ela não é necessária para ligar.
- **Bateria:** o aparelho só liga com a bateria acima de **3,5 V**. O manual manda aquecer o
  aparelho a **60–70 °C por 5–10 min** antes de soltar as peças coladas (60 °C se a bateria
  estiver acima de 68%). Para tirar a bateria: carga baixa, calor brando e uniforme, nunca
  alavancar a célula.
- **Botões:** o fluxograma "não liga" diz para conferir se, ao apertar o power, o **contato do
  flex fecha curto**. Ou seja, cada tecla só liga um sinal ao GND. Isso confirma a ideia da
  **plaquinha com botões de toque** (seção 11): cada botão fecha o seu contato com o GND. No
  diagrama de blocos, o volume vai ao processador e o power vai ao PMIC.
- **Antenas:** a parte de cima da tampa traseira é a **"SUB ANT"** (antena de diversidade), e a de
  baixo, a antena de NFC/MST/carga sem fio, com um conector na placa. O Wi-Fi e o Bluetooth usam
  **contatos de mola (C-clips) na borda da placa** que encostam nas antenas do chassi; no G780F
  são dois, um em cada lado da placa. **Fora do chassi esses contatos ficam soltos**: é o risco
  de antena já anotado acima. Achar os contatos de Wi-Fi da nossa placa pelas fotos, comparando
  com o manual, e testar.
