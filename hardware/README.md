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
- Ventoinha controlada pela temperatura: só se a ventoinha tiver PWM e houver como comandá-la
  (ex.: um microcontrolador USB lendo a temperatura pelo adb). Ideia para depois.

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
2. **A1:** ventoinha soprando a **traseira** (tampa da placa-mãe).
3. **A2:** ventoinha soprando a **frente** (tela) — o caminho principal do calor, pela seção 2.
4. **A3:** ar nas duas faces (duas ventoinhas, ou uma com o celular em pé no meio do fluxo).
5. Só se A3 não atingir a meta: **B** (dissipador sobre a tampa) e depois **C**.

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
- [ ] Teste de antena: Wi-Fi/BT com e sem a tampa da placa-mãe.

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
