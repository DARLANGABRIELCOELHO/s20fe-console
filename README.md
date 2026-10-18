# Galaxy S20 FE como console de mesa

Projeto para transformar o Galaxy S20 FE **SM-G780G** (Snapdragon 865, Adreno 650, codinome `r8q`) num videogame de mesa ligado à TV, no estilo Batocera: desbloqueia o bootloader, grava o sistema e o aparelho já liga direto no menu de jogos.

Base: LineageOS 23.2 oficial (`r8q` variant1) + root com Magisk + **kernel próprio**, com foco em desempenho de GPU, frontend de console e emuladores.

O diário técnico completo (logs, hipóteses descartadas, procedimentos passo a passo) está em [CLAUDE.md](CLAUDE.md). Este README é o resumo.

## Onde estamos (2026-10-18)

| Fase | O que é | Situação |
|---|---|---|
| 1 | LineageOS oficial instalado e hardware validado | **Concluída** |
| 2 | Root, kernel próprio e desempenho | **Concluída** |
| 3 | Camada de console (frontend, emuladores, controles) | **Em andamento**: Pegasus + tema próprio + NetherSX2/PPSSPP/RetroArch/Eden + assistente de desempenho |
| 4 | ROM própria "plug and play" | Não iniciada |

**Estado do aparelho agora:** LineageOS 23.2 nightly 20261010 (Android 16), kernel próprio (`s20fe-gpu-oc`) + Magisk 30.7, GPU até 670 MHz (padrão no boot: 625), zram com lz4, limite de carga em 80%, saída de vídeo para a TV funcionando. Pegasus como tela inicial; PS2 via NetherSX2, PSP via PPSSPP, retro via RetroArch, Switch via Eden.

## O que já foi feito

### Fase 1: LineageOS oficial

- Backup de todas as partições críticas (`efs`, `sec_efs`, `persist`, `modemst*`, `fsg`, `fsc`, `boot`, `recovery`, `vbmeta`, `dtbo`) com hash conferido. Ficam só no PC (contêm IMEI).
- Firmware stock oficial G780GXXSHEYJ1 baixado da Samsung (com MD5 conferido) como volta de emergência.
- Instalação seguindo a wiki oficial: `vbmeta` + Lineage Recovery via [samloader-rs](https://github.com/topjohnwu/samloader-rs), formatação e sideload do LineageOS 23.2. Sem Google (GApps).
- Validado: Wi-Fi, controle Bluetooth, carga enquanto sai vídeo (hub com PD) e imagem na TV.

### Saída de vídeo (USB-C → HDMI): investigação

A imagem na TV não aparecia. A investigação levou dois dias e encontrou **dois problemas diferentes**:

1. **Bug de software no kernel** (real e corrigido): logo depois de ligar o vídeo, o Android faz um "desliga e religa" e o driver de DisplayPort desligava o controlador inteiro, sem reinicializar depois. Em alguns casos isso causava *kernel panic*. Correção: ligar `CONFIG_SEC_DISPLAYPORT_RETAIN_LINK_POWER`, opção que o próprio LineageOS já usa nos Galaxy Tab S7 (mesmo chip e driver). Patch em [`kernel/patches/0001`](kernel/patches/).
2. **Defeito de hardware na subplaca da USB-C**: mesmo com o One UI original regravado, o S20 FE não mantinha as vias de vídeo sincronizadas (`interlane_align_done = 0`), enquanto um Galaxy S10 no mesmo hub funcionava. Sem sinal estável, o hub (um repetidor HDCP) nunca completava a autenticação e a TV ficava sem imagem. **Resolvido trocando a subplaca** (2026-10-18).

No caminho foram testados e descartados: desligar o HDCP, forçar criptografia, não escrever o Ainfo, desligar o VSC e mudar a resolução. Os detalhes estão no CLAUDE.md.

### Fase 2: kernel próprio e desempenho

- **Ambiente de build** no Linux Mint (PC com 8 GB de RAM): kernel do LineageOS (`android_kernel_samsung_sm8250`, branch `lineage-23.2`) com o mesmo clang do build oficial (r563880c). O kernel de referência saiu com a **mesma configuração e o mesmo tamanho** do oficial, e o DTB do boot é reproduzido **byte a byte**.
- **GPU (Adreno 650):** dois níveis novos no device tree, acima dos 587 MHz de fábrica. Patch em [`kernel/patches/0002`](kernel/patches/).
  - **625 MHz** com a mesma tensão do 587 (NOM);
  - **670 MHz** com a tensão oficial da Qualcomm para essa frequência (NOM_L1, a do Snapdragon 865 de bin mais alto).
- **Teste de estabilidade** (3DMark Wild Life Extreme Stress, cerca de 20 min cada):

  | GPU | Resultado | GPU (temp.) | Bateria |
  |---|---|---|---|
  | 625 MHz, sem ventilação | estável, 94% do tempo em 625 MHz | pico de 96 °C | 38–39 °C |
  | 670 MHz, com ventilação | **1.240 / 1.230 pontos, estabilidade 99,2%** | média de 86 °C, pico de 91 °C | 37 °C |

  O controle térmico continua ativo: sem ventilação, ele reduz a frequência sozinho.
- **zram com lz4** (mais rápido que o lzo-rle padrão), trocado no boot por um script do Magisk.
- **Limite de carga em 80%** pelo controle de carga oficial do LineageOS. Ao chegar no limite, a carga pausa e o aparelho fica alimentado direto pela fonte, o ideal para um console sempre na tomada.

### Fase 3: início

- **[DroidDeck](https://github.com/Droid-Deck/DroidDeck) 0.4.0** (Steam/Proton ARM64 no Android) instalado, com hash conferido e restrição de processos filhos do Android desligada. Suporte ao Adreno 650 é experimental (jogos DX11 leves).
- Pesquisa de **ports nativos** (decompilação/recompilação, como 2 Ship 2 Harkinian, Dusklight, sm64coopdx e DevilutionX): rodam em ARM64 sem emulador e são preferíveis à emulação quando existem. O usuário fornece os arquivos do próprio jogo.

## Próximos passos

1. ~~**Fechar a Fase 1**~~: ✅ concluída (2026-10-18).
2. ~~**Fechar a Fase 2**~~: ✅ concluída (2026-10-18).
3. **Fase 3, camada de console**:
   - instalar os emuladores que faltam (Dolphin, DuckStation) com driver Turnip onde houver suporte;
   - testar os ports nativos e o DroidDeck com jogos reais;
   - baixar vídeos de preview para o tema;
   - mapear controles e atalhos.
4. **Fase 4, ROM própria**: compilar o LineageOS com o kernel, os scripts e os apps já incluídos, e gerar um pacote de instalação com guia simples. **Bloqueio atual:** o PC tem 8 GB de RAM e HD mecânico; compilar o LineageOS inteiro pede 16–32 GB de RAM e cerca de 300 GB, de preferência em SSD.

## Conteúdo do repositório

- [`CLAUDE.md`](CLAUDE.md): diário técnico e regras de segurança do projeto.
- [`kernel/patches/`](kernel/patches/): patches sobre o kernel do LineageOS (`lineage-23.2`, commit `4478511`). Aplicar com `git am`.
- [`kernel/build-kernel.sh`](kernel/build-kernel.sh): compila o kernel como o build oficial do LineageOS.
- [`kernel/mkboot.sh`](kernel/mkboot.sh): monta o `boot.img` com o kernel novo + ramdisk do Magisk. Os caminhos são do PC de desenvolvimento; ajuste antes de usar.
- [`scripts/`](scripts/): scripts de boot do Magisk (`/data/adb/service.d/`):
  - `zram-lz4.sh`: zram 4 GB com lz4;
  - `gpu-max.sh`: define o limite da GPU no boot (625 MHz);
  - `slim-services.sh`: encerra serviços de hardware sem uso (câmera, biometria, neural networks, NFC);
  - `controller-hotkeys.sh`: atalhos universais no controle e auto-reconexão no Pegasus;
  - `perfd.sh`: assistente de desempenho e telemetria para emulação.
- [`tools/gen-pegasus.py`](tools/gen-pegasus.py): gera os menus do [Pegasus](https://pegasus-frontend.org) a partir das listas de sistemas e emuladores do [ES-DE](https://es-de.org) (licença MIT, cópia em [`tools/esde/`](tools/esde/)), mostrando só os sistemas com emulador instalado e jogos.
- [`theme/s20fe-console/`](theme/s20fe-console/): tema do Pegasus para TV e controle, mistura de Batocera (faixa de sistemas) com PS5 (fileira de capas e fundo com a tela do jogo).
- [`tools/scrape.sh`](tools/scrape.sh): busca capas, vídeos e descrições com o [Skyscraper](https://github.com/Gemba/skyscraper) (ScreenScraper) identificando os jogos pelo nome, sem copiá-los para o PC.
- `lineage/SHA256SUMS`: hashes dos arquivos oficiais do LineageOS usados.

## O que não está neste repositório

Por segurança e direitos autorais, ficam só no PC local:

- `backup/`: dump das partições do aparelho (inclui `efs`/`persist`, com IMEI)
- `firmware/`: firmware stock da Samsung
- `lineage/*.img`, `*.zip`: imagens do LineageOS e do Magisk (baixe das fontes oficiais; os `SHA256SUMS` estão aqui para conferência)
- `apps/`, `samloader/`, `scrcpy/`, `source/`, `build/`: APKs, ferramentas e código-fonte de terceiros

BIOS e ROMs de jogos não fazem nem farão parte do projeto.

## Aviso

Desbloquear o bootloader e gravar partições pode inutilizar o aparelho e apaga os dados. Overclock de GPU é feito por sua conta e risco: cada chip tem uma margem diferente, e sem resfriamento o ganho é limitado pelo controle térmico. Faça backup e use por sua conta e risco.
