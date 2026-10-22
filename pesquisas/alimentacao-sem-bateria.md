# Alimentação: sem bateria, bateria falsa, ligar sozinho e bypass de carga

Levantado em 2026-10-22. **Nada disto foi testado no S20 FE.** Mexer na bateria ou no circuito de proteção é hardware arriscado (Li-ion pode inchar ou pegar fogo se for furada ou posta em curto ao desmontar).

## Por que os boxes tiram a bateria
- Celular ligado na tomada 24/7 **incha a bateria** (relatos de BOINC: caixa do celular rachou; Lemmy: "risco de incêndio").
- A solução mais citada **sem** mexer no hardware é **limitar a carga em 20–80 %** (Tasker + tomada inteligente, ou a função do sistema). **Nós já fazemos isso:** controle de carga do LineageOS em 80 % (ver `CLAUDE.md`, Fase 2), que pausa a carga e deixa o aparelho alimentado pelo carregador.

## Como rodar sem bateria (o que está documentado)

### Galaxy S5 como servidor de impressora 3D (yaky.dev, 2022) — o relato mais completo
- **Terminais:** (+), (−) e **T (termistor)**. **Sem o T ligado, o aparelho não liga** (proteção).
- **Termistor:** a bateria original mede **~2.350 Ω entre T e (−)** à temperatura ambiente → simulado com 2.200 Ω + 150 Ω em série.
- **Tensão:** a Li-ion vai de ~3,4 V (vazia) a 4,2–4,4 V (cheia). Ele usou **+5 V → diodo de silício → (+)**, que dá ~4,2–4,3 V com carga (4,8 V sem carga no multímetro).
- **Corrente:** carregador abaixo de 1 A **não termina o boot**; ~2 A funciona. **Picos (USB, câmera) derrubam o aparelho** se a fonte não aguentar.
- Mitigações: **capacitor de 1.000 µF** entre +5 V e GND, economia de bateria ativada abaixo de 75 %, câmera desligada.
- Montagem: placa num bloco de madeira no lugar da bateria, pinos encostando nos contatos de mola, entrada por JST. Estável por semanas.
- **Riscos:** o resistor fixo **engana a proteção térmica da bateria** (o sistema sempre "vê" 25 °C); a queda do diodo varia com a corrente; o capacitor descarregado puxa um pico da fonte ao ligar.

### Manter a placa de proteção (BMS) da bateria — OnePlus 6T (CrackOverflow, método do GreatScott!)
- Separar a **BMS** (plaquinha no topo da bateria) da célula e **reaproveitá-la**: ela continua "conversando" com o aparelho como se a bateria existisse.
- USB-C 5 V → **diodo MUR460** (queda de ~0,7 V) → entradas da BMS. Descarregar a bateria a 0 % antes de tirar.
- Vantagem sobre o resistor fixo: preserva a identificação/sensor da própria bateria. Mais métodos e fóruns em [foruns-e-comunidades.md](foruns-e-comunidades.md#2-rodar-sem-bateria--o-que-os-fóruns-dizem).

### Casos Samsung no Reddit (2026)
- S21+: BMS + step-down a **3,85 V** + 4.700 µF; S9/S9+: 5 V na BMS 24/7 (outros recomendam ~4 V); S10: BMS + step-down. Detalhes e links em [foruns-e-comunidades.md](foruns-e-comunidades.md#61-rodar-sem-bateria-reddit-rsamsungdex-raskelectronics).
- **Armadilha:** o medidor de carga continua descontando e a % cai a 0 em ~1 dia → o Android desliga. Quem usa fixa a leitura com root (`dumpsys battery`).
- Um **S20 FE com bateria inchando** está tentando o mesmo (r/SamsungDex) — é exatamente o gatilho que definimos para fazer isso no nosso.

### Outros relatos
- Fóruns (All About Circuits, EEVblog, PieFed): resultados **inconsistentes**. Uns modelos ligam sem bateria, outros desligam na hora; o celular às vezes usa a bateria como reforço de corrente no boot. Ideia citada: manter a bateria e alimentar pelos contatos dela.
- Instructables: "Power an Android Phone Without Battery" (mesmo princípio).
- **DEX LOR (Z Fold 3)**: além da fonte direta, há um **truque para contornar a proteção da bateria** e ligar sem o USB-C "acordar" a carga; depois ele corrigiu o **desligamento com o alto-falante no máximo** (pico de corrente — o mesmo fenômeno do yaky.dev). Detalhes não publicados.
- Lojas vietnamitas (Hải Âu DIY DeX, Rudson no Brasil) usam **entrada de 12 V (DC 5,5 mm) + step-down**, que aguenta melhor os picos do que um USB de 5 V.

### O que valeria para o S20 FE (ideias, não validadas)
- A bateria do S20 FE tem conector de pressão na placa (ver `hardware/README.md`). Teria que descobrir a pinagem (provavelmente +, −, termistor/ID; o esquema `hardware/fotos/Samsung_ S20_G780F_Schematic_Diagram.pdf` pode ajudar) e o valor do termistor a ~25 °C.
- Fonte: step-down de qualidade de 12 V → ~4,0–4,2 V, **≥ 3 A** (o SD865 com a GPU a 670 MHz consome bem mais que um S5), mais capacitor de reserva.
- **Perda:** o controle térmico perde a temperatura real da bateria. A temperatura do SoC continua protegida (regra 5 do `CLAUDE.md`), mas `thermal-engine`/`sec-thermal` usam a bateria em algumas regras.
- **Decisão sugerida:** só fazer se a bateria mostrar desgaste/inchaço. Hoje o limite de 80 % resolve.

## Ligar sozinho quando chega energia
Essencial para o "plug and play" (ligar na tomada = console liga).

- **Samsung não faz isso por padrão**: com o aparelho desligado e o cabo ligado, entra no **modo de carga desligado (LPM)**. Na comunidade da Samsung, um usuário pede a opção há anos sem resposta. Nos Galaxy Watch existe "Ligar automaticamente"; em celular só pelo **Knox (KPE, pago)**.
- `fastboot oem off-mode-charge 0` funciona em vários Android, mas **Samsung não tem fastboot** (modo Download/Odin) → não serve.
- **Módulo Magisk `magisk-autoboot`** (anasfanani, v1.0.1, 2023-12): "liga o aparelho automaticamente quando detecta USB/carregador"; precisa do Magisk no boot (é o nosso caso); tem limite mínimo de bateria (`MIN_CAPACITY=5`). Sem README; **ler os scripts antes de instalar**. <https://mmrl.dev/repository/magtrenv2/magisk-autoboot>, issues em <https://github.com/Magisk-Modules-Alt-Repo/magisk-autoboot/issues>.
- **Galaxy S7/Alpha (forum.android.com.pl)**: editou o arquivo de sistema do **LPM** para disparar reboot (sysrq). Dicas dele: manter o **mesmo inode** (sobrescrever o conteúdo, não trocar o arquivo) e **usar LF** (um arquivo CRLF impediu o boot).
- **Replicant**: o kernel Samsung, ao desligar com cabo, reinicia em modo de carga (é esse comportamento que os truques contornam).
- No **LineageOS**, o modo de carga desligado é o `charger` do AOSP (o boot recebe `androidboot.mode=charger` e o init roda a seção `on charger`). **A investigar** para a ROM própria (Fase 4): trocar a ação dessa seção por um reboot normal quando houver energia e bateria mínima.
- Vietnamitas anunciam o mesmo recurso ("tự khởi động khi có nguồn"): Hải Âu DIY DeX (Fold 3), Hedra Farm ("automatizar o ligar do box"), MON DIY.

## Bypass de carga oficial da Samsung (só One UI)
- "**Pausar carregamento USB PD ao jogar**" (Game Booster), desde o S23 / One UI 5.1, levado depois a S22 e Folds: com carregador **PD PPS** e bateria > 20 %, o aparelho roda direto do carregador e a bateria fica parada. Teste citado: consumo no jogo de **17 W → 6 W** e menos calor.
- No LineageOS o equivalente mais próximo é o controle de carga (pausa a carga e segue alimentado). Não há bypass PPS de verdade.

## Fontes
- <https://yaky.dev/2022-09-06-smartphone-without-battery/>
- <https://www.instructables.com/Power-an-Android-Phone-Without-Battery/>
- <https://forum.allaboutcircuits.com/threads/samsung-galaxy-s7-power-without-battery.149822/>
- <https://www.eevblog.com/forum/beginners/powering-up-cellphone-on-usb-power-only-without-battery/>
- <https://piefed.jeena.net/post/379141>
- <https://discover.worldcommunitygrid.org/forums/wcg/viewthread_thread,42418>
- <https://community.openhab.org/t/android-tablets-without-battery/150373/2>
- <https://us.community.samsung.com/t5/Suggestions/Auto-on/td-p/3439877>
- <https://www.hexnode.com/forums/topic/power-on-kiosk-devices-when-plugged/>
- <https://www.tapatalk.com/groups/macrodroid/how-to-switch-on-device-when-charger-is-connected-t6889.html>
- <https://mmrl.dev/repository/magtrenv2/magisk-autoboot>
- <https://forum.android.com.pl/topic/369427-automatyczne-uruchamianie-telefonu-po-podłączeniu-ładowarki>
- <https://redmine.replicant.us/issues/2157>
- <https://www.androidcentral.com/apps-software/how-use-bypass-charging-galaxy-phone>
- <https://www.samsung.com/th/support/apps-services/pause-usb-pd-power-delivery-charging-when-gaming-feature-on-your-galaxy-device/>
- <https://www.sammobile.com/news/galaxy-s23-charging-bypass-feature-gamers/>
