# Ideias para evolução

Lista de melhorias e projetos para avaliar no console. Os itens abaixo são propostas, não funcionalidades já implementadas.

## Experiência de uso

- Permitir ligar e desligar o console pelo controle.
- Usar a tela de bloqueio como seletor de perfil.
- Automatizar a configuração dos controles.
- Encerrar ou suspender tarefas em segundo plano ao iniciar um jogo.
- Ocultar os botões virtuais na tela quando um controle físico estiver conectado.
- Manter o aprimoramento do sistema e da experiência de jogo de forma contínua.

## Vídeo

- Adaptar a saída de vídeo às características do monitor ou da TV conectada.
- Ajustar também a resolução e a proporção da imagem dentro do emulador, quando possível.

## Atalhos do controle

- `Start + Select`: fechar o jogo atual.
- `Start + Select + R1 + L1`: abrir as configurações do emulador.

## Anotações

Toda a pesquisa (detalhes e fontes) fica em [pesquisas/](pesquisas/README.md).

- 2026-10-22: existe uma cena grande de "box DeX" (Vietnã e Brasil); o S20 FE já aparece em gabinetes brasileiros.
- 2026-10-22: ligar sozinho ao receber energia é viável no S20 FE (modo `charger` confirmado no código). Usar a ideia do `magisk-autoboot` no nosso boot, **não o módulo pronto**.
- 2026-10-22: sem bateria só se a bateria degradar; Peltier continua descartado.
- 2026-10-22: o ETA Prime fez um mini PC com um S20 FE de tela quebrada (NetherSX2 a 2x com quedas, cooler evita throttling).
- 2026-10-22: com o Chrome do usuário, li Reddit, XDA e Clube do Hardware. O `magisk-autoboot` **já funcionou num S20 FE G780G/DS** (XDA) e num S10e com LineageOS 20.
- 2026-10-22: sem bateria, os fóruns usam a placa de proteção (BMS) original + ~4 V regulados; cuidado com a % caindo a 0.

## Próximos passos

1. **Ligar sozinho ao conectar a energia:**
   - [x] Ler o módulo [magisk-autoboot](https://github.com/Magisk-Modules-Alt-Repo/magisk-autoboot).
   - [x] Confirmar como o S20 FE entra no modo de carga.
   - [ ] Ter neste PC o boot atual + samloader (caminho de volta).
   - [ ] Testar no aparelho (com confirmação na hora).
   - [ ] Decidir o "desligar de verdade" com a fonte ligada.
   - [ ] Definir o mínimo de bateria para ligar.
   - [ ] No teste, conferir se com o sistema ligado o carregador continua sendo detectado (problema relatado no XDA).
2. **Gabinete:** comparar o nosso case com os gabinetes brasileiros.
3. **Sem bateria** (só se a bateria degradar): pinagem do conector e valor do termistor do S20 FE.
4. **Modo desktop:** testar "Forçar modo desktop" no LineageOS 23.2.
5. **4PDA:** página 1 do guia lida (arquivo salvo em `pesquisas/`); faltam as outras 34 páginas e o tópico 499874, se valer a pena.
6. **ETA Prime:** acompanhar o vídeo da montagem completa do S20 FE, quando sair (case, cooler, alimentação).

## Integrações possíveis

- [NookieAI](https://github.com/NookieAI)
- [PS2 Web Recomp](https://github.com/snuri00/ps2-web-recomp)

## Lojas e fontes de aplicativos

### Clientes ou repositórios de código aberto

- [Aurora Store](https://gitlab.com/AuroraOSS/AuroraStore): cliente de código aberto para baixar apps da Google Play; os aplicativos distribuídos continuam sujeitos às licenças dos respectivos autores.
- [F-Droid](https://f-droid.org): catálogo e infraestrutura de distribuição voltados a aplicativos livres e de código aberto.
- [Droid-ify](https://github.com/Droid-ify/client) e [Neo Store](https://github.com/NeoApplications/Neo-Store): clientes de código aberto para repositórios compatíveis com F-Droid.
- [IzzyOnDroid](https://apt.izzysoft.de/fdroid/): repositório independente compatível com clientes F-Droid; verifica e publica apps Android de código aberto.
- [Obtainium](https://github.com/ImranR98/Obtainium): ferramenta de código aberto para acompanhar e instalar versões publicadas diretamente pelos desenvolvedores; não é uma loja centralizada.

### Lojas proprietárias

- [Aptoide](https://en.aptoide.com/), [Aptoide TV](https://tv.aptoide.com/) e [Uptodown](https://www.uptodown.com/): alternativas de distribuição de apps, mas não são lojas de código aberto. Aptoide TV é voltada a Android TV.

## Projetos em uso ou consultados

- [ARMSX2](https://github.com/ARMSX2/ARMSX2)
- [DroidDeck](https://github.com/Droid-Deck/DroidDeck)
- [ES-DE](https://es-de.org)
- [ES-DE no GitLab](https://gitlab.com/es-de/emulationstation-de)
- [Kura](https://github.com/NookieAI/kura)
- [NetherSX2 Classic](https://github.com/Trixarian/NetherSX2-classic)
- [Pegasus Frontend](https://pegasus-frontend.org)
- [PPSSPP](https://github.com/hrydgard/PPSSPP)
- [RetroForge](https://github.com/NookieAI/RetroForge)
- [KonaBess](https://github.com/libxzr/KonaBess)
- [LineageOS](https://github.com/lineageos)
- [samloader-rs](https://github.com/topjohnwu/samloader-rs)
- [Skyscraper](https://github.com/Gemba/skyscraper)
- [RetroArch](https://github.com/libretro/retroarch)
- [AdrenoToolsDrivers](https://github.com/K11MCH1/AdrenoToolsDrivers/releases)
- [Adreno-Tools-Drivers](https://github.com/StevenMXZ/Adreno-Tools-Drivers/releases)
- [Mesa Turnip Android Driver](https://github.com/nihui/mesa-turnip-android-driver)

## Pesquisa técnica

- [Arquitetura de processadores: fundamentos e aplicação ao S20 FE](pesquisas/arquitetura-de-processadores.md)
