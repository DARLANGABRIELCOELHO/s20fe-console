# Fóruns e comunidades de entusiastas

Levantado em 2026-10-22: Reddit, XDA, 4PDA (Rússia), Clube do Hardware (Brasil), EEVblog, All About Circuits, Electronics-Lab, Lemmy/PieFed, yaky.dev, Hackaday, X e imprensa de tecnologia.

> **Acesso:** Reddit, XDA, 4PDA e Clube do Hardware bloqueiam leitura automática. Em 2026-10-22 o usuário passou a verificação do Reddit no próprio Chrome e eu li os tópicos por essa janela: **Reddit, XDA e Clube do Hardware lidos na íntegra** (seção 6). O **4PDA** continua na verificação ("Um momento…").

## Destaques da leitura direta (2026-10-22)
1. **`magisk-autoboot` funciona num S20 FE G780G/DS** — o módulo nasceu dessa conversa no XDA (usuário tparaizo, 2023). Também confirmado no **Galaxy S10e com LineageOS 20** (até carga sem fio) e no Note 8 ("versão simples"). Detalhes na seção 6.2.
2. **Sem bateria, consenso dos fóruns:** reaproveitar a **placa de proteção (BMS) da bateria original** e alimentá-la com **~4,0–4,2 V** de um step-down, com capacitor grande; vários casos rodando 24/7 (S9, S10, S21+, S23). Há um **S20 FE com bateria inchando** querendo fazer o mesmo (r/SamsungDex).
3. **Peltier abandonado** por um construtor de mini PC DeX (condensação) → dissipador de Raspberry Pi + 2 ventoinhas de 5 V + chapa de alumínio, abraçando a placa (esfria também o PMIC do outro lado).
4. **Turnip "Z"** para Snapdragon 865 (experimental, 2026-10-11): +15–35 % de FPS no Eden; testado num Retroid Pocket 5 com **GPU a 905 MHz**; relatos de falhas gráficas.

## 1. O caso mais próximo do nosso: ETA Prime com um S20 FE
- **ETA Prime** (YouTube, 1,4 mi de inscritos, referência em emulação): "I Turned This Broken Phone into a DeX-Powered Mini PC!" — <https://www.youtube.com/watch?v=TZrrmwKLPEE> (≈1 mi de visualizações; repercutiu em Notebookcheck, hardware.com.br, Yanko Design, Geeky Gadgets, TechEBlog em 02–03/2026).
- **Aparelho:** **Galaxy S20 FE (Snapdragon 865, 6 GB)** com tela quebrada, comprado no eBay por **< US$ 70**; com a tela boa, ~US$ 99. Atualizado até o patch de outubro/2025.
- **Montagem:** placa dentro de um **case torre de Raspberry Pi com cooler torre** (Amazon), adaptador USB-C → HDMI (Anker 310 citado), dock DeX recomendado, controle Xbox por Bluetooth. Gravou 3,5 h da montagem; o vídeo completo ainda não saiu.
- **Software:** One UI + DeX. **1440p no DeX via Good Lock → MultiStar → "I ♥ Samsung DeX" → alta resolução em tela externa** (também 1200p 16:10 e 2560×1080 21:9; 4K pode cair para 30 Hz). Limite de 5 apps abertos (o MultiStar libera; ele não liberou por causa dos 6 GB).
- **Desempenho relatado:**
  - **PS2: God of War II no NetherSX2 a 2x** com algumas quedas → sugere **1,75x**. (Nós usamos NetherSX2 a 2x como padrão e o perfd baixa para 1x quando falta GPU.)
  - GameCube/Wii: "ótimo"; Automobilista a 720p estável a 60 fps; F-Zero GX com upscale sofre.
  - Dreamcast, PSP, Saturn: tranquilos.
  - GameNative (Steam): Hollow Knight Silksong roda bem (algum tearing); Cyberpunk nem a 30. Minecraft e Roblox ok; Destiny Rising em janela.
  - Recomenda um **cooler preso atrás** (US$ 10–15). As matérias dizem que, com o cooler, não houve throttling.
- **Relevância:** confirma o S20 FE (SD865) como base boa e barata; nós vamos além (LineageOS, GPU a 625/670 MHz, frontend, salvar ao sair).
- Fontes: <https://www.notebookcheck.net/YouTuber-converts-cracked-smartphone-into-under-100-mini-PC-for-gaming-and-emulation.1232561.0.html>, <https://www.hardware.com.br/noticias/youtuber-transforma-galaxy-s20-fe-quebrado-mini-pc-samsung-dex/>, <https://www.yankodesign.com/2026/02/23/the-cheapest-mini-pc-costs-under-100-and-uses-an-old-samsung-phone-to-run-steam-and-ps2-games/>, <https://www.geeky-gadgets.com/broken-phone-desktop-build/>, <https://www.techeblog.com/samsung-galaxy-s20-fe-smartphone-mini-pc-mod/>, <https://smartoutlets.com.br/2026/02/25/galaxy-s20-fe-quebrado-mini-pc-samsung-dex/>

## 2. Rodar sem bateria — o que os fóruns dizem
### Métodos
| Método | Quem | Detalhes |
|---|---|---|
| **Bateria falsa** (diodo + resistor no termistor) | yaky.dev (Galaxy S5) | 5 V → diodo → (+); ~2.350 Ω no T; 1.000 µF; fonte ≥ 2 A |
| **Manter a placa de proteção (BMS) da própria bateria** e alimentá-la por diodo | CrackOverflow (OnePlus 6T + postmarketOS; método do canal **GreatScott!**) | Separa a BMS da célula (não jogar fora: ela "simula a bateria"), USB-C 5 V → **diodo MUR460** → BMS; cola quente. Aviso: descarregar a bateria a 0 % antes de tirar |
| **Célula externa** | SeanB (EEVblog) | Tirar a placa de proteção da bateria inchada e ligar uma **18650** externa aos contatos originais |
| **Fonte de bancada nos terminais** | EEVblog, iFixit (Note, 3,7–4,2 V) | Funciona pelo conector da bateria; **só pela USB, sem bateria, não liga** |
| **Fonte direta + step-down** | Vietnã (Z Fold), Clube do Hardware (LM317), Lemmy | Baixar 5 V/12 V para ~3,8–4,2 V |
| **Capacitores no lugar da bateria** | 4PDA, All About Circuits | **Não funciona** em aparelhos modernos (só muito antigos) |

### Lições recorrentes
- **Termistor/ID é o bloqueio**: sem resistência no pino T o aparelho não liga (yaky.dev; Electronics-Lab: 6,8 kΩ em outro modelo). Alguns aparelhos identificam o **tipo de bateria pela resistência**.
- **Baterias com 4 pinos** podem ter NFC (Samsung antigos) ou comunicação de dados; se o aparelho conversa com a bateria, resistor não basta (iFixit, Electronics-Lab).
- **Picos de corrente**: no rádio o celular passa de **2 A**; fonte fraca derruba o aparelho (Electronics-Lab, yaky.dev). Fios curtos + eletrolítico perto do conector (EEVblog).
- 4PDA: sem bateria, alguns aparelhos puxam só **até 500 mA** de carregador genérico; para Samsung, citam **2,5 V em D+/D−** para o modo de carga "nativo" (identificação de carregador Samsung).
- Samsung até o **S5** rodava pela USB sem bateria (Lemmy); modelos novos não.
- **Riscos**: furar/curto na célula ao desmontar; perda da proteção térmica da bateria; "qualquer equipamento modificado pode virar risco de incêndio" (EEVblog).
- 🔒 4PDA: "Андроид без батареи?" <https://4pda.to/forum/index.php?showtopic=499874&st=380> e "Включение устройств без аккумулятора" <https://4pda.to/forum/index.php?showtopic=653649>.
- 🔒 Clube do Hardware: <https://www.clubedohardware.com.br/forums/topic/1477776-ligar-celular-sem-bateria-direto-carregador/> (Samsung sem bateria: diodos em série ou LM317 para ~3,8 V).
- Vietnã (YouTube): "Hướng Dẫn Đấu Nối Nguồn Trực Tiếp Cho Samsung Dex" <https://www.youtube.com/watch?v=dRGV4bivBYc> (Z Fold, step-down, +/−).

### Inchaço com o aparelho sempre na tomada (relatos)
- Galaxy antigos (antes do S20) **parados** incharam em massa em 2024 (Android Police, SamMobile, Tom's Guide); aparelhos em uso regular, menos.
- Engenheiro da Lenovo: plugado 24/7 por anos aumenta a chance de inchaço, e **calor acelera** (Yahoo Tech).
- iPhone 7 como servidor de mídia inchou (MacRumors); BOINC: celulares 24/7 incharam, um rachou a carcaça.
- Netgear (roteador M1 24/7): orienta rodar **só no adaptador, sem bateria**.
- Galaxy S22 24/7 como painel de energia solar com limite de 80 % (Lemmy) — o mesmo que fazemos.
- Resumo: **calor + carga cheia constante** são os vilões. Nosso console: 80 % + ventoinha.

## 3. Ligar sozinho ao conectar (relatos práticos)
- **yaky.dev "Volty MIR" (Galaxy S5, LineageOS 14, carro)**: `fastboot oem off-mode-charge 0` **não funciona em Samsung**; **Magisk Autoboot funcionou** no LineageOS 14 (falhou numa ROM Android 7 específica); o truque `playlpm`/`lpm` (trocar o binário da animação de carga por um script de reboot) só existia no S3. Com bateria muito baixa: **laço de reinicialização**. Abre o app no boot com Termux:Boot; desliga por condição com `su -c "reboot -p"` (o `svc power shutdown` falhou no cron); depois trocou por **ACC** (Advanced Charging Controller). <https://yaky.dev/2024-05-16-android-boot-on-plug-launch-app-shutdown-on-condition>
- **XDA "Lineage OS auto boot on charge connected"** 🔒 <https://xdaforums.com/t/lineage-os-auto-boot-on-charge-connected.3626364/> — `on charger` + `setprop sys.powerctl reboot,leaving-off-mode-charging` (Tab S2, LOS 16; OTA desfaz); LOS 22.2: `sed` no `/system/etc/init/hw/init.rc`; Android 10+: editar o `init.rc` do ramdisk não adianta.
- **XDA "Auto Boot / Start on charge (different devices)"** 🔒 <https://xdaforums.com/t/auto-boot-start-on-charge-different-devices.3233767/>; **tópico do módulo** 🔒 <https://xdaforums.com/t/module-magisk-autoboot-auto-power-on-android-when-charger-connected.4645951/>.
- **forum.android.com.pl** (Galaxy S7/Alpha): editar o arquivo do LPM mantendo o **inode** e com **LF** (CRLF mandou para o recovery).
- **postmarketOS issue #2858**: Samsung sempre liga ao carregar no pmOS — o comportamento depende de quem trata o `charger`. <https://gitlab.postmarketos.org/postmarketOS/pmaports/-/issues/2858>
- Comunidade Samsung: pedidos de "ligar ao conectar" sem resposta; só Knox (pago) e relógios têm a opção.
- Detalhes da nossa análise: [ligar-ao-conectar.md](ligar-ao-conectar.md).

## 4. Tela quebrada / sem tela
- Bloqueio de tela é o maior obstáculo; quem quebrou a tela sem depuração USB autorizada fica preso (Comunidade Samsung, Manjaro). Um usuário passou do bloqueio com **teclado (Tab/Enter)** no espelhamento da TV.
- **scrcpy `--new-display=1920x1080/284`** abre uma sessão DeX virtual no One UI 8 (Android 16) — vários guias (DEV, Substack, PhoneArena); no Pixel exige tela física. <https://proandroiddev.com/enable-a-desktop-style-experience-samsung-dex-on-any-android-device-unlocking-the-power-of-scrcpy-b91d28d685fc>
- Nós já resolvemos o nosso caso (tela de bloqueio desligada; módulo `s20fe-sem-tela` para bootar sem o painel).

## 5. X (Twitter), Facebook, Discord
- Não achei pelo buscador perfis/grupos relevantes no X ou no Facebook sobre "box DeX" / "gabinete DeX"; a cena vive no **TikTok e YouTube** (ver [criadores-box-dex.md](criadores-box-dex.md)). ETA Prime divulga no X como @theetaprime.
- Grupos de Facebook e Discord precisam de busca manual logada.

## 6. Leitura direta (Reddit, XDA, Clube do Hardware) — 2026-10-22

### 6.1 Rodar sem bateria (Reddit r/SamsungDex, r/AskElectronics)
| Relato | Aparelho | Como fez | Observações |
|---|---|---|---|
| Dan1Rojas | **S21+** | BMS original + **step-down a 3,85 V** + **capacitor de 4.700 µF/16 V** | "Não funcionou sem a BMS"; precisou de um USB separado para o step-down |
| Wonderwall_1516 | **S9 / S9+** (3 aparelhos) | **5 V** direto na BMS (sem regular) + outra fonte para o USB/tablet | 24/7 há meses sem problema. Outros alertam: 5 V é sobretensão para a BMS — usar ~4 V |
| Ok_Blacksmith2941 | **S10** | Tira a BMS da célula, 2 fios (+/−) da BMS para um step-down regulado | "Não tem muito segredo" |
| Helpful-Piece6201 | S23 Ultra (pesquisa) | Fonte 12 V 2–3 A → regulador → BMS | Cita o caminho, não testou |
| Bruce_Wynn | S23 mini PC | Com bateria; diz que sem bateria precisa de **buck + capacitores + BMS da Samsung** | |
| outofpaper | — | "Manter a bateria é como ter um **no-break**" | |
| Status-Document-2150 | — | BMS + **buck-boost** (o consumo varia); fios curtos e grossos; **`dumpsys battery` fixando 100 %** via ADB | Sem o comando, a % cai até 0 e o Android desliga |
| njugaa | celular antigo | USB soldado na BMS (4,5 V) | **A porcentagem cai para 0 em ~1 dia** (o medidor de carga continua contando) |
| momo__ib | Samsung | Sem a BMS, com buck maior e entrada de 12 V | Funcionou; desliga quando falta energia |
| Sudden_Capital_288 | S8 | "Salve a BMS e dê 4 V" | **"Não ligue carregador na USB do celular depois"** |
| SquareOrbits | Pixel 3a | BMS + ~4 V | Funcionou |
| MrInka / Pentium4Powerhouse | — | O aparelho espera **dados da bateria (ID) + termistor**; tensão de 4–4,5 V | |
| E4M3p / Luxim | — | Contra resistor fixo no termistor ("vira bomba" num aparelho que carrega bateria); reaproveitar a proteção existente | |
| dr100 | — | Linha **XCover Pro / Tab Active Pro** funciona sem bateria **oficialmente** ("No battery mode") | Guia em vídeo para S10e: <https://www.youtube.com/watch?v=7f8SliNGeDM> |
| LpoolmNEW | **S20 FE** | Quer tirar a bateria porque **está inchando** | Pedido de ajuda (r/SamsungDex, 2026-07) |
| Unfair-Laugh-7928 | **S20 FE** (mini PC DeX) | Estendeu bateria + BMS; a BMS "não pegava solda" → trocou a solda; dica: **cortar o flex e raspar a trilha** | Guia citado: <https://www.youtube.com/watch?v=gtd3Tx_yd_E> |

- Tópicos: <https://www.reddit.com/r/SamsungDex/comments/1ttuhl0/samsung_dex_mini_pc_build_with_s23_components/>, <https://www.reddit.com/r/SamsungDex/comments/1vkxkgc/s8_with_a_spicy_pillow_can_i_use_dex_without_a/>, <https://www.reddit.com/r/SamsungDex/comments/1rb65q6/i_love_samsung_dex/>, <https://www.reddit.com/r/SamsungDex/comments/1va91t4/how_to_setup_voltage_regulator_so_no_need_for_a/>, <https://www.reddit.com/r/SamsungDex/comments/1x02x64/dex_s20_fe_mini_pc_help/>, <https://www.reddit.com/r/AskElectronics/comments/1w04bsn/trying_to_power_a_smartphone_without_battery/>, <https://www.reddit.com/r/AskElectronics/comments/1terhvs/phone_battery_bypass_to_run_as_server/>, <https://www.reddit.com/r/AskElectronics/comments/1lz504j/is_the_thermistor_wire_from_the_battery_being/>, <https://blog.kedio.co/post/how-to-run-a-oneplus-6t-without-battery/>
- **Clube do Hardware** (Samsung J4 como rastreador no carro, sem bateria): 1 diodo 1N4007 → 4,35 V (funciona); 2 diodos → não liga. Solução recomendada: **step-down LM2596 ajustável** direto dos 12 V até ~3,8 V + **capacitor ≥ 1.000 µF** perto do aparelho; diodos rápidos (UF400x) ou LM317 como alternativa. <https://www.clubedohardware.com.br/forums/topic/1477776-ligar-celular-sem-bateria-direto-carregador/>
- **Lição para nós:** sem bateria é preciso (1) BMS original, (2) ~4,0–4,2 V estável com reserva de corrente, (3) **resolver a porcentagem** (o medidor de carga continua descontando e o Android desliga em 0 %) — com root dá para fixar a leitura, mas isso também esconde problemas reais.

### 6.2 Ligar sozinho ao conectar (XDA)
- **S20 FE G780G/DS** (tparaizo, 2023-09 a 2023-11; One UI com TWRP OrangeFox + Magisk): tentou fastboot (não existe), editar `init.rc` (somente leitura) e desempacotar o ramdisk (falhou) → **o `magisk-autoboot` funcionou "muito bem"**. Problema: **bateria a 0 % → reinicia sem parar e não passa de 1 %**. Solução dele (incorporada ao módulo): script com mínimo de carga (ele usou **30 %**); abaixo do mínimo **fica parado na tela de boot carregando** (sem mostrar a %) e liga sozinho ao atingir o mínimo.
- **Galaxy S10e SM-G970N, Android 13, LineageOS 20** (steven@, 2024-04): "funcionando perfeito", **inclusive com carga sem fio**.
- Note 8 N950F/N950N (2025): o módulo completo falhou num, a **"versão simples"** (só `setprop ro.bootmode normal` + `setprop sys.powerctl reboot` no `overlay.d`) funcionou nos dois.
- Galaxy Note 4 / S5 / I9500 com LineageOS: `on charger` → `setprop ro.bootmode "normal"` + `setprop sys.powerctl "reboot"` (2021–2022). S3 mini: não funcionou.
- **Galaxy S7, LineageOS 17** (mathius, 2024): `setprop sys.powerctl reboot,leaving-off-mode-charging` no fim do `on charger` de `/system/vendor/etc/init/hw/init.samsung.rc`; o arquivo certo varia por build (`grep` por "charger").
- Poco F1, LineageOS 22.2 (2026-03): `sed` inserindo `setprop sys.powerctl reboot` em `/system/etc/init/hw/init.rc` (exige `/system` gravável — no S20 FE com partições dinâmicas não é o caminho).
- **Não usar** `class_stop charger` + `trigger late-init` (Moto G / LOS 16): liga **sem terminar o boot direito** (touch sem funcionar, só chamadas de emergência).
- Outro (alfanveykov, Oppo/J320G): o `setprop` funcionou, mas "com o aparelho ligado o carregador não era detectado"; trocou por `sys.boot_from_charger_mode=1` no `default.prop`. Para conferir no nosso teste.
- Em aberto no XDA (2025-11): alguém montando **central multimídia de carro com S20** quer ligar ao receber 4 V direto nos pinos da bateria (sem USB). Sem resposta — com alimentação pela BMS, o "conectar" é o próprio ligar da fonte, então o evento `charger` pode não acontecer.
- Tópicos: <https://xdaforums.com/t/module-magisk-autoboot-auto-power-on-android-when-charger-connected.4645951/>, <https://xdaforums.com/t/lineage-os-auto-boot-on-charge-connected.3626364/page-3>, <https://xdaforums.com/t/auto-boot-start-on-charge-different-devices.3233767/>; exemplo de `.rc`: <https://github.com/anasfanani/Android-OnCharge-AutoBoot/blob/main/files/init.custom.rc>

### 6.3 Mini PCs DeX e consoles (Reddit)
- **Bruce_Wynn (S23 de tela quebrada, r/SamsungDex, 432 pontos)**: case de compensado; hub com PD de 100 W (um cabo só); 4K60 com Good Lock. Depois **trocou o Peltier por dissipador de Raspberry Pi + 2 ventoinhas de 5 V** e chapa de alumínio — "o dissipador abraça a placa, esfria a CPU e o gerenciador de energia do outro lado"; sem condensação. Vídeos: <https://youtu.be/OEtwiAyaHyM>.
- **S23 Ultra micro PC** (Helpful-Piece6201): tirou cabo da tela, NFC, S-Pen e alto-falante; boota pelo HDMI; placas de cobre de 0,3 mm + Kapton; dúvida pasta × pad × **PTM7950** (não vaza, não precisa manutenção). Desbloqueio: tirou a senha. Após reiniciar, alguns Samsung **exigem desbloqueio antes de liberar USB/DeX**.
- **Ligar pelo botão de um gabinete**: conversor DC-DC com botão → o aparelho liga ao receber energia (Salt_Entertainer_879).
- **Pixel 8 → console** (Prior_Explanation_52, r/EmulationOnAndroid, 937 pontos): ventoinha de 50 mm de PC antigo por baixo, hub de 4 USB (2 controles, mouse, ventoinha) que também alimenta o celular, ES-DE. Comentário mais votado: **desbloquear, ROM + kernel próprios com root** para tirar o limite de desempenho — o nosso caminho.
- **S20 FE como portátil retrô** (makire): GameSir G8+, ES-DE; o RP5 só ganha pela **ventoinha**.
- **S20 FE 5G com dissipador de NVMe** (Elerox9, 2024): tirou a carcaça plástica, dissipador em contato com a **blindagem do SoC** com pad fino; desligou o throttling (não recomendado). Comentário: **"Samsung reduz desempenho pela temperatura da bateria"**.
- **Reinícios do S20 FE no Eden** (Mario Kart 8): resolvido com Nyushu v75 + driver Qualcomm 615.77; no SD865 driver incompatível pode **reiniciar o aparelho** (também no RP5).
- **Coolers de celular**: Peltier bom dá +40 % no 3DMark Wild Life Extreme Stress (S25 FE); Peltier barato é inútil; a potência anunciada é "mentira" (15 W → ~5 W reais).
- **O que o SD865 roda** (r/EmulationOnAndroid): PS2 a 2x+ na maioria, 3DS a 4x, Switch 2D/leve, alguns PC. O RP5 ganha em **desempenho sustentado** (ventoinha e clocks maiores). "Com root, o SD865 é um ótimo overclocker de GPU".
- **Turnip "Z" v1.2** (AlexSanz0902, 2026-10-11, feito com IA, sem revisão da Mesa): <https://github.com/AlexSanz0902/turnip-sd865-z/releases> — SMO 45–50 → 58–60 FPS a 1080p; anisotrópico desligado; vários relatam falhas gráficas. Testar só no Eden, se for o caso.

### 6.4 4PDA — "Como ligar dispositivos sem bateria ou conector de energia | Guia"
Página 1 de 35 do tópico <https://4pda.to/forum/index.php?showtopic=653649>, salva pelo usuário (traduzida pelo Chrome) em `pesquisas/Ligar dispositivos sem bateria ou conector de energia - 4PDA.html`. Guia do usuário Solovass (2015, editado em 2020), pensado para baterias de 3,7 V **sem contatos extras**:
- **Ordem de tentativa:** (a) tirar a bateria e ver se liga só no carregador original; (b) pela USB, sem bateria; (c) alimentar pelos contatos da bateria. Cabo **curto e grosso** faz diferença: cabo ruim limita a corrente e o aparelho desliga sob carga.
- **Detecção de carregador:** carregador genérico/USB de PC → o aparelho puxa **até 500 mA**; o carregador "nativo" é reconhecido pelas linhas de dados (Android: D+ e D− em curto; **alguns Samsung: 2,5 V em D+ e D−**; ver a especificação USB Battery Charging 1.2). (No S20 FE com USB-C/PD isso vale menos, mas explica por que fonte boa importa.)
- **Não jogar 5 V nos contatos da bateria às cegas:** a tensão vai para o **controlador de energia (PMIC)** — num chip o limite é 6,3 V, noutro **4,5 V** — e às vezes direto para outros componentes. Medir sempre; mirar ~4,2–4,3 V.
- **Corrente:** pôr um **amperímetro no positivo** e medir o consumo real em vários modos; **2–3 A com folga** normalmente bastam.
- **Tela piscando / som estalando** = queda de tensão → **capacitores no aparelho, entre + e −**: um eletrolítico grande (ex.: **3.000 µF**) + um de **0,1 µF**; atenção à polaridade.
- Exemplo de fonte: step-down XL2009E1 ajustado para **4,3 V** (resistor de realimentação 4,09 kΩ = 2 × 8,2 kΩ em paralelo). Com bateria junto, limitar a corrente a ~metade da capacidade.
- Atalho: **diodo de silício** (~0,6–0,7 V de queda) em série com 5 V; um conversor DC-DC comum ajustado em **4,2 V** é "perfeito".
- **Ligar sozinho ao receber energia pelos contatos da bateria:** sugestão de **relé temporizador no botão de ligar**; outro usuário (ZTE Z992) ligou o **+ da bateria ao VBUS da USB** e aplicou 4,8 V — o aparelho "vê" carregador e liga.
- Relatos: Samsung antigo não carrega sem bateria (pisca LED vermelho); se a alimentação some com o aparelho ligado, ele segue um tempo "a 100 %". Tablet com controlador de bateria queimado reinicia a cada 5–6 s sem o carregador.
- Alerta de segurança no carro: bateria de lítio parada incha; melhor tirar a bateria e fazer ligar na chave.
- **Relevância:** confirma a receita dos outros fóruns (≈4,2 V, 2–3 A, capacitores) e traz duas ideias para "ligar ao receber energia" sem software (relé no botão; VBUS). O segundo tópico do 4PDA (499874, "Андроид без батареи?") não foi baixado.

## Fontes adicionais (não citadas acima)
- <https://www.eevblog.com/forum/beginners/powering-up-cellphone-on-usb-power-only-without-battery/>
- <https://forum.allaboutcircuits.com/threads/using-a-mobile-phone-without-battery-using-a-capacitor-and-a-resistor.170668/>
- <https://www.electronics-lab.com/forums/threads/powering-up-mobile-phone-with-no-battery.300496/>
- <https://piefed.jeena.net/post/379141>
- <https://crackoverflow.com/docs/system_administration/containerization/turn_android_phone_to_batteryless_home_server/>
- <https://hackaday.com/tag/dummy/>
- <https://www.androidpolice.com/batteries-inside-older-samsung-phones-swelling-disproportionately-high-rate/>
- <https://community.netgear.com/discussions/aircard/nighthawk-m1-too-hot/2102731/replies/2135253>
- <https://tech.yahoo.com/computing/articles/help-laptop-battery-swollen-now-182950410.html>
- <https://forums.macrumors.com/threads/iphone-7-heat-damage.2404659/>
- <https://www.minhaoperadora.com.br/2026/10/seu-celular-pode-funcionar-sem-bateria-e-quase-ninguem-sabe-disso.html>
- <https://us.community.samsung.com/t5/Tablets/Samsung-DeX-during-Android-setup/m-p/3428357/highlight/true>
- <https://www.ifixit.com/Answers/View/754799/Samsung+Galaxy+S20+FE+5G+UW+in+Cloud+Red> (pinagem do conector da bateria varia entre variantes do S20 FE)
