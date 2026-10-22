# Software: ferramentas da cena DeX, modo desktop do Android e celular como console

Levantado em 2026-10-22.

## Ferramentas que os criadores de box DeX usam (One UI)
| Ferramenta | Para quê | Serve no LineageOS? |
|---|---|---|
| **Shizuku** | Dá a outros apps permissões de sistema via ADB, sem root | Funciona, mas temos root (Magisk) |
| **Galaxy Max Hz** (tribalfs, <https://github.com/tribalfs/GalaxyMaxHzPub>) | Controla a taxa de atualização em Samsung (120 Hz, mínimo, tela desligada) | Não: é para One UI. No LineageOS usamos `peak_refresh_rate`/`min_refresh_rate` (travado em 60 Hz) |
| **SamHelper** | Citado pelo DEX LOR para 120 Hz junto com o Shizuku; não achei documentação | Não |
| **K2er**, **GG Mouse Pro** | Mapeiam teclado/mouse para jogos Android (FPS). O GG Mouse Pro dá erro no Android 14–15 | Fora do foco (emuladores) |
| **Key Mapper** (+ Shizuku) | Remapeia teclas/botões | Alternativa ao nosso `controller-hotkeys.sh`, se precisar |
| **Activity Launcher** | Abre o DeX escondido na linha Galaxy A | Não |
| **Gadesk** | DeX na própria tela do Fold, sem monitor | Não |
| **Termux + ADB sem fio + scrcpy** | Simular tela externa para o DeX na tela interna do Fold (One UI 8) | Ideia útil: scrcpy cria tela virtual (já usamos scrcpy) |

- "**Bateria virtual**" (pin ảo) e o "**cadeado da morte**" do DEX LOR são truques de One UI para aparelho sem tela/sem bateria; não encontrei texto explicando.
- O **Wireless DeX** funciona com TVs Samsung de 2018 em diante e com Miracast; os criadores preferem cabo (menos atraso).

## Modo desktop oficial do Android (o "DeX do Google")
- **Android 16 QPR3** (GA em março de 2026): ao ligar uma tela externa, abre uma **sessão desktop** com barra de tarefas e janelas livres; foi construído **sobre a base do Samsung DeX**. Oficialmente só Pixel 8/9/10 e Samsung recentes (S26, Fold7, Flip7, Tab S11).
- No AOSP existe desde o Android 10 a opção de desenvolvedor **"Forçar modo desktop"** (com janelas de formato livre), feita para testar apps em várias telas; precisa reiniciar e funciona com tela por DisplayPort Alt Mode.
- **Para nós:** o console usa **espelhamento** de propósito (Pegasus em tela cheia na TV, `tv-mode.sh`). O modo desktop só interessaria a um "modo PC" opcional. **A testar** se o LineageOS 23.2 do r8q expõe essas opções.

## Projetos de console com celular (fora da cena DeX)
- **Pixel 8 com linha rosa → console retrô** (r/EmulationOnAndroid, usuário Prior_Explanation_52): o Google recusou o reparo; virou console na TV com **hub USB de 4 portas, ventoinha de PC de 50 mm ligada no hub, carregador de 45 W, dois controles com fio, ES-DE**. Leitores sugeriram root/ROM própria para ganhar desempenho, que é exatamente o nosso caminho.
- **XDA, Galaxy S21 FE (SD888) como "PC gamer" no DeX:** **GameNative** (jogos de Windows da Steam/Epic/GOG com Wine/Proton + DXVK/VKD3D), dock USB-C, **carregador PPS de 45–65 W**, controle XInput, TV em modo jogo, **DeX com cabo** (o sem fio adiciona compressão e atraso), 1080p60 no DeX e 720p30 no jogo. Leves rodam bem (Dead Cells, Portal 2); pesados a ~30 fps em resolução baixa. **O problema principal é o calor.** Paralelo: nós temos o DroidDeck (Steam/Proton) instalado.
- **Galaxy S10 (SD855) como console de emulação** (vídeo de 2023): barato no usado, DeX e vídeo pela USB; PS2, PSP, Dreamcast e Wii testados.
- **Samsung Galaxy Upcycling at Home** (2021, beta EUA/Reino Unido/Coreia): programa oficial para virar S9 e posteriores em aparelho de casa inteligente (SmartThings). Mostra que a própria Samsung já incentivou reaproveitar aparelhos.

## Dicas de "handheld/celular no dock da TV" (Joey's Retro Handhelds)
- Hub USB-C com HDMI e PD basta; começar em **1080p60**.
- Usar **frontend** (Daijisho/ES-DE/Pegasus) e não navegar no Android pela TV.
- Layout Xbox × Nintendo troca A/B: corrigir por emulador. Dolphin: "Create Mappings for Other Devices"; NetherSX2/DuckStation: "Add New" na porta 1; Eden: Auto-map (refazer ao trocar de controle); PPSSPP: botão + no mapeamento.
- Dolphin e Eden quase não têm atalho para sair do jogo pelo controle (o nosso `controller-hotkeys.sh` resolve com `force-stop`).
- **Sair sempre pelo menu do emulador**: fechar à força pode corromper saves. Bate com o nosso "sair salvando" no NetherSX2.

## Fontes
- <https://github.com/tribalfs/GalaxyMaxHzPub>
- <https://forum.xda-developers.com/t/app-galaxy-max-hz-refresh-rate-control-quick-resolution-switcher-force-lowest-refresh-rate-on-screen-off-aod-adaptive-mod-and-more.4220423/>
- <https://docs.keymapper.club/user-guide/shizuku/>
- <https://samsung.gadgethacks.com/how-to/how-to-use-samsung-dex-on-galaxy-z-fold-internal-screen/>
- <https://www.androidpolice.com/my-galaxy-z-fold-8-dex-desktop-attempt-failed/>
- <https://developer.android.com/blog/posts/android-devices-extend-seamlessly-to-connected-displays>
- <https://www.thurrott.com/mobile/android/333445/android-16-qpr3-delivers-long-awaited-desktop-mode>
- <https://source.android.com/docs/core/display/multi_display/testing-dev-environment>
- <https://notebookcheck.net/google-refused-to-fix-this-pixel-8-so-its-owner-turned-it-into-a-retro-gaming-console.1301967.0.html>
- <https://wccftech.com/damaged-pixel-8-turned-into-console-with-controllers-support-and-cooling//amp/>
- <https://www.xda-developers.com/turned-old-galaxy-phone-gaming-pc-samsung-dex-hidden-feature/>
- <https://www.xda-developers.com/dex-makes-old-samsung-galaxy-phone-a-desktop-pc/>
- <https://yt.d0.cx/v/yt/zP1M-WWZDqM> (Galaxy S10 emulação)
- <https://news.samsung.com/us/samsung-electronics-expands-its-galaxy-upcycling-program-to-enable-consumers-to-repurpose-galaxy-smartphones-into-smart-home-devices>
- <https://www.joeysretrohandhelds.com/?p=9122>
- <https://www.samsung.com/us/apps/dex/>
