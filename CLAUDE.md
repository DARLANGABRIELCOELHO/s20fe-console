# Projeto: Galaxy S20 FE como console de mesa

Objetivo: transformar o Galaxy S20 FE (Snapdragon) num videogame de mesa ligado à TV, com o máximo de desempenho possível. O resultado final deve ser um sistema **"plug and play" no estilo Batocera**: desbloqueia o bootloader de qualquer S20 FE SM-G780G, grava o sistema e o aparelho já liga direto no menu de jogos.

Idioma: responda sempre em português do Brasil.

## Regras de segurança (obrigatórias)

1. **Nunca grave nenhuma partição** (boot, recovery, vbmeta, dtbo, system etc.) nem rode samloader `flash`, Odin, `dd` ou sideload sem eu confirmar explicitamente naquele momento. Antes de pedir a confirmação, diga o que vai gravar, onde, e como voltar atrás.
2. **Nunca formate nem apague dados** do aparelho sem a minha confirmação.
3. **Sempre tenha backup** de qualquer partição antes de alterá-la.
4. **Nunca grave** as partições `efs`, `sec_efs`, `modemst1`, `modemst2`, `fsg`, `fsc` e `persist` (IMEI e dados de rádio). Elas só são lidas para backup.
5. **Não desative o controle térmico.** Ele protege a bateria e o chip.
6. Não use `rm` em nada do celular fora de `/data/local/tmp/`.
7. Se algo der errado, **pare e me explique** antes de tentar consertar.
8. Antes de cada fase, confira as instruções oficiais atualizadas (wiki do LineageOS). Elas mudam.

## Aparelho

- Modelo: **SM-G780G** (S20 FE 4G), Snapdragon 865 / SM8250 "kona", GPU Adreno 650, codinome **r8q**, LineageOS **variant1**
- RAM: 6 GB
- Firmware stock instalado: **G780GXXSHEYJ1**, região **ZTO** (Brasil), Android 13 / One UI 5.1, patch 2025-10, bootloader revisão **H**
- Estado atual (2026-10-11): **LineageOS 23.2 nightly 20261010** (Android 16, patch 2026-10-01), Lineage Recovery, vbmeta do LineageOS, sem GApps, **root com Magisk 30.7** (boot em `lineage/magisk/magisk_patched-30700_JopyK.img`; boot oficial sem root em `lineage/boot.img`, SHA-256 conferido), bootloader desbloqueado. Firmware/bootloader continuam G780GXXSHEYJ1.

## Dados levantados no LineageOS (em repouso, sem root)
- Kernel `4.19.325-cip136-st20-perf`. `thermal-engine` e `sec-thermal` rodando.
- GPU: `max_gpuclk` = **587 MHz** em repouso (no One UI caía para 441,6). Outros nós do kgsl e do zram exigem root.
- CPU máx.: 1,80 / 2,42 / 2,84 GHz (policy0/4/7).
- MemAvailable ~3,1 GB (no One UI com debloat era ~2,6 GB).
- Temperaturas: CPU 35 °C, GPU 34 °C, bateria 31 °C.
- DRM tem o conector `card0-DP-1` (DisplayPort pela USB-C).
- Não existe MHL neste aparelho. A saída de vídeo é **DisplayPort Alt Mode** pela USB-C (adaptador USB-C → HDMI). No LineageOS funciona como espelhamento, sem DeX.

## Estrutura desta pasta (C:\S20FE)

- `CLAUDE.md` → este arquivo
- `backup/` → dump das partições feito com `dd` em 2026-10-11: `boot.img` (64 MB, One UI com Magisk), `efs.img`, `sec_efs.img`, `modemst1.img`, `modemst2.img`, `fsg.img`, `fsc.img`, `persist.img`, e também (antes do LineageOS) `vbmeta.img` (64 KB), `recovery.img` (79 MB, stock) e `dtbo.img` (10 MB). Hashes conferidos em `backup/SHA256SUMS`. `modemst1`, `modemst2`, `fsg` e `fsc` são só zeros no aparelho (normal, não é erro do dump).
- `firmware/` → firmware stock G780GXXSHEYJ1 (AP, BL, CP, CSC, HOME_CSC). É a volta de emergência para o One UI (HOME_CSC mantém dados, CSC limpa; **nunca re-particionar**).
  - `firmware/samsung/` → pacote oficial baixado dos servidores da Samsung com `samloader download` (versão G780GXXSHEYJ1/G780GOWOHEYJ1/G780GXXSHEYJ1/G780GXXSHEYJ1), zip + os 5 `.tar.md5` extraídos. **MD5 dos 5 conferido em 2026-10-11.**
  - Antes de gravar qualquer firmware: `samloader verify-md5 <arquivos>`.

## Incidente: RAM defeituosa no PC (2026-10-11)
- Um pente de RAM com defeito trocava bits isolados (0x08 e 0x40) em arquivos grandes, na gravação e às vezes na leitura. Os dois primeiros downloads do AP (SamFw e Samsung) vieram corrompidos por isso. O pente foi retirado após teste de memória, e o firmware foi baixado de novo, agora íntegro.
- Já reconferido depois da troca: backups (`backup/SHA256SUMS`), arquivos do LineageOS (`lineage/SHA256SUMS`), samloader e scrcpy/adb (idênticos às releases oficiais).
- **Regra prática:** todo arquivo baixado ou gerado no PC tem que ter o hash conferido antes de ir para o celular.
- `scrcpy/` → scrcpy para Windows (github.com/Genymobile/scrcpy/releases). **Use o `adb.exe` daqui para tudo** e não instale outro, para evitar o conflito "adb server version doesn't match".
- `samloader/` → samloader-rs 2.2.0 (github.com/topjohnwu/samloader-rs), a ferramenta que a wiki do LineageOS indica para o modo Download. Substitui o Odin: grava `.img` direto (sem empacotar em tar) e também firmware stock (`--AP --BL --CP --CSC`). Os drivers USB da Samsung já estão instalados no PC (backend padrão `vcom`).
- `odin/` → vazia. O Odin não é mais usado (só existe em sites não oficiais).
- `lineage/` → LineageOS 23.2 nightly 20261010: `lineage-23.2-20261010-nightly-r8q-signed.zip`, `recovery.img`, `vbmeta.img` e `SHA256SUMS` (conferidos com a API oficial)
- `apps/` → APKs do frontend e dos emuladores. Já tem: Magisk v30.7, KonaBess 0.23 beta-25, AuroraStore 4.8.4 (copiados do celular antes do reset).
- `source/` → código-fonte (kernel e, depois, LineageOS). Já tem o fonte stock da Samsung (`Kernel.tar.gz`, `Platform.tar.gz`, `README_Kernel.txt`, `README_Platform.txt`), útil como referência. A Fase 2 usa o kernel do LineageOS.

## Acesso ao celular

- Cabo USB sempre conectado, depuração USB ligada, PC autorizado ("sempre permitir"), "Desativar tempo limite de autorizações adb" ligado.
- Root pelo adb: `adb shell su -c "<comando>"`. O Magisk precisa liberar root para o Shell.
- No PC, chamar sempre `C:\s20fe\scrcpy\adb.exe` pelo caminho completo (há outro adb no PATH, em `C:\Program Files\platform-tools`). No Git Bash, usar `export MSYS_NO_PATHCONV=1`, senão caminhos como `/data/local/tmp` viram caminhos do Windows. No PowerShell, `$(...)` dentro do comando é expandido localmente: prefira o Bash para comandos de shell do celular.
- Erro conhecido com `pm` via `su -c`: `Failed transaction (2147483646)`. Solução: redirecionar a entrada e a saída:
  `pm ... </dev/null >/data/local/tmp/r.txt 2>&1; cat /data/local/tmp/r.txt`
- Modos especiais:
  - **Download (samloader):** aparelho desligado, segurar Volume + e Volume − e conectar o cabo
  - **Recovery:** aparelho desligado, segurar Volume + e Power com o cabo conectado
  - **Forçar desligamento:** Volume − e Power por 8–10 s
- Botões físicos só eu consigo apertar. Avise quando precisar.

## Dados técnicos levantados (no One UI)

- Boot image: header **v2**, kernel raw, ramdisk gzip, **DTB embutido no boot.img** (~1,5 MB), flags SAMSUNG_SEANDROID + VBMETA. Existe partição `dtbo` separada. Não há `vendor_boot`.
- GPU, frequências de fábrica: 587, 525, 490, 441,6, 400 e 305 MHz.
- Em repouso o `max_gpuclk` caía para 441,6 MHz por política de energia da Samsung (não por temperatura).
- Temperaturas em repouso: CPU 39–44 °C, GPU 35–38 °C, bateria 32 °C.
- zram de 3 GB com `lzo-rle` (o kernel stock não tem lz4). RAM Plus estava desligado.
- Overclock de CPU no SD865 provavelmente não é viável: a tabela vem do firmware/hardware (cpufreq-hw). O foco é a **GPU**.
- Sysfs úteis:
  - `/sys/class/kgsl/kgsl-3d0/gpu_available_frequencies`, `max_gpuclk`, `gpuclk`, `min_pwrlevel`
  - `/sys/devices/system/cpu/cpufreq/policy*/scaling_cur_freq`, `scaling_min_freq`
  - `/sys/class/thermal/thermal_zone*/type` e `temp` (em milésimos de °C)

## Plano: Caminho 1, ROM Android de console baseada em LineageOS

LineageOS oficial: **r8q variant1** (SM-G780G e SM-G780G/DS), versão atual **23.2 (Android 16)**, mantenedor ata-kaner.
- Wiki: https://wiki.lineageos.org/devices/r8q/variant1/
- Instalação: https://wiki.lineageos.org/devices/r8q/install/variant1/
- Requisito: firmware stock **Android 13**, a versão mais recente (G780GXXSHEYJ1 atende)
- O LineageOS pede para **não remover apps do sistema**. Ele já é enxuto.

### Fase 1: instalar o LineageOS oficial e validar o hardware
Procedimento conferido na fonte da wiki (github.com/LineageOS/lineage_wiki, `_data/devices/r8q_variant1.yml`, `install_method: samloader_rs`) em 2026-10-11. A wiki em si bloqueia acesso automático (HTTP 403).

1. [x] Baixar para `lineage/` o zip, o `recovery.img` e o `vbmeta.img` (feito, SHA-256 conferido). Baixar o samloader-rs para `samloader/` (feito).
2. [x] Firmware stock íntegro em `firmware/samsung/`, com MD5 verificado (rede de segurança antes de qualquer gravação).
3. [x] Eu salvo o que quiser e removo a conta Google do aparelho (evita o FRP). **O passo 4 apaga tudo.**
4. [x] Modo Download → `samloader flash --partition VBMETA vbmeta.img`. Feito em 2026-10-11: o samloader não mostra progresso para arquivo pequeno, mas o hash da partição conferiu com o vbmeta do LineageOS. Como o bootloader já estava desbloqueado, o aparelho **não pediu reset** e iniciou normal no One UI; OEM Unlock continuou ligado. O aparelho reinicia e pede reset de fábrica: aceitar, pular a configuração, ligar o Wi-Fi, reativar as Opções do desenvolvedor e confirmar que o "OEM Unlock" continua ligado.
5. [x] Modo Download → `samloader flash --partition RECOVERY recovery.img --no-reboot`. Feito em 2026-10-11, entrou no Lineage Recovery. (No recovery o adb aparece como "unauthorized" fora do modo sideload; é normal.) A tela continua em "Downloading..." mesmo depois de terminar. Forçar o desligamento (Volume − + Power, soltar **assim que a tela apagar**) e **entrar no recovery imediatamente** (Volume + e Power com o cabo). Se iniciar o sistema antes, o recovery stock sobrescreve o Lineage Recovery.
6. [x] Lineage Recovery: Factory Reset > Format data / factory reset. Voltar ao menu, Apply update > Apply from ADB > `adb -d sideload <zip>`. **Não reiniciar para o sistema** antes de terminar. Feito em 2026-10-11 (adb para em 47% com "Total xfer: 1.00x", é normal).
7. [x] GApps: **sem Google** (decidido em 2026-10-11). Apps e emuladores via Obtainium/GitHub/F-Droid.
8. [ ] Validar e anotar os resultados aqui:
   - [ ] Imagem na TV pelo adaptador USB-C → HDMI → **NÃO FUNCIONA** (ver "Problema: saída de vídeo" abaixo)
   - [x] Carregar enquanto sai vídeo (hub com PD)
   - [x] Controle Bluetooth
   - [x] Wi-Fi
   - [ ] Áudio pela TV
   - [ ] Temperaturas em jogo

### Problema: saída de vídeo no LineageOS (investigado em 2026-10-11)
- Hub e monitor (HORIZON Z24, 1080p60; também TV Philips 1360×768) funcionavam com DeX no One UI.
- No LineageOS: o kernel lê o EDID, o **link training passa** (HBR2 5,4 Gbps, **1 lane** — o conversor do hub anuncia só 1 lane), o Android cria o display e o espelhamento (`ContentRecordingSession`), o stream 1920×1080@60 liga (`mainlink READY`)… e ~4 s depois: `secdp_reset_link_status: [205h] port0: out of sync, reset!` + `HDCP_STATE_AUTH_FAIL` em loop a cada 6 s. Monitor: "sem sinal".
- Descartado: tempo de espera no diálogo (aceitar em 1 s não muda), bloquear/desbloquear a tela, resolução 1280×720.
- Só existe diálogo "Aceitar espelhar / Dispensar". Para logar com o hub conectado: `adb tcpip 5555` + `adb connect <ip>:5555` (a única USB-C fica no hub).
- Kernel do aparelho = commit `4478511` de LineageOS/android_kernel_samsung_sm8250 (lineage-23.2). Fonte do driver DP baixado em `source/lk/`, fonte Samsung extraído em `source/samsung-kernel/`.
- Diferenças do driver DP (LineageOS × Samsung stock), candidatas: (1) `dp_catalog.c` passou a zerar o BIT(10) ASSR do `DP_CONFIGURATION_CTRL` (CAF); (2) `dp_ctrl.c`/`dp_panel.c` calculam TU/bpp com `link_params` em vez de `link_info`; (3) `1b0507b695` tirou o SW reset do controlador no desligamento; (4) `29c21e0abd` RETAIN_LINK_POWER (inativo: não está no defconfig). Configs de DP do kernel iguais ao stock.
- Nenhum relato público encontrado (nem de funcionar, nem de bug).
- Com a TV Philips o link usa pin assignment **D** (2 lanes) a RBR 1,62 Gbps e dá o **mesmo** erro → não depende de velocidade/lanes. `/sys/class/dp_sec/dp_error_info` (com root) mostra o resumo da última conexão.
- O kernel do LineageOS **não tem debugfs** (não está em /proc/filesystems) e os nós de teste do secdp são só de kernel ENG → não há TPG nem desligar HDCP em tempo de execução.
- **Hipótese principal:** `dp_panel_config_misc()` liga `BIT(14)` (MISC1 bit 6 = "colorimetria vem no VSC SDP") sempre que o sink anuncia VSC (`misc settings = 0x4021`), mas o VSC SDP (GEN0) só é programado via `set_colorspace` (HWC define colorspace do conector) ou HDR. Se o HWC do LineageOS não define o colorspace, o conversor recebe MISC1 bit6 sem VSC SDP → "out of sync". Código idêntico ao stock → no One UI o HWC da Samsung provavelmente definia o colorspace. **Teste:** kernel com o `misc_val |= BIT(14)` removido (ou condicionado a VSC SDP ativo).
- (Antigo) Próximo passo de diagnóstico: com root, usar o debugfs do DP (gerador de padrão de teste/TPG, desligar HDCP) para separar problema de link/stream de problema do compositor (SDE/HWC). Depois, se for kernel: compilar com os candidatos revertidos (precisa WSL → **virtualização desligada na BIOS do PC**, WSL não instalado).

### Fase 2: root e desempenho
- Magisk no boot do LineageOS.
- Conferir se o DTB continua embutido no boot (`magiskboot unpack`). Se sim, testar o **KonaBess** (github.com/libxzr/KonaBess): GPU **625 MHz** com a mesma tensão do 587, testar estabilidade e depois **670 MHz** (frequência do 865+). Não passar de 670 sem motivo.
- Kernel próprio a partir do **kernel do LineageOS para sm8250** (GitHub, org LineageOS), compilado no WSL (Ubuntu, dentro de `~`, nunca em `/mnt/c`). Extras: lz4 no zram (`CONFIG_CRYPTO_LZ4`), níveis extras de GPU no device tree.
- Limite de carga da bateria (o aparelho vai ficar sempre na tomada): 60–80%.
- Teste de estabilidade: 20–30 min de 3DMark Wild Life Stress ou um jogo pesado de PS2/GameCube, monitorando a temperatura.

### Fase 3: camada de console
- Frontend como launcher padrão, iniciando direto nele: **ES-DE** ou **Daijisho**.
- Emuladores: RetroArch, Dolphin, NetherSX2/AetherSX2, PPSSPP, DuckStation, entre outros. Usar drivers Turnip via AdrenoTools nos emuladores que suportam.
- Mapeamento de controles, hotkeys e configurações otimizadas para o SD865.
- **Não incluir BIOS nem ROMs** no sistema (direitos autorais). O usuário adiciona.

### Fase 4: ROM própria "plug and play"
- Compilar o LineageOS a partir do código-fonte com: kernel com OC, frontend como launcher padrão, emuladores pré-instalados e configs prontas.
- Gerar o pacote de instalação (recovery + zip, ou pacote para o Odin) e um guia de instalação simples.
- Requisito de PC para compilar o LineageOS inteiro: ~300 GB livres e de preferência 32 GB de RAM. Verificar antes de começar.

### Caminho 2 (futuro): ROCKNIX / Linux mainline
O ROCKNIX (estilo Batocera) já roda no SD865 (Retroid Pocket 5). Existe Linux mainline bootando no r8q (github.com/Itzkristis/r8q-arch). Portar só depois que o Caminho 1 estiver pronto. O ponto crítico a testar é a saída de vídeo pela USB-C.

## Hardware do console
- Hub USB-C com HDMI + entrada de carga PD (25 W ou mais).
- Tampa traseira removida. Dissipador + cooler de CPU direto na blindagem metálica, com thermal pad de 1–1,5 mm. Ventoinha 5 V alimentada pelo hub, ou 12 V com fonte separada. Sem Peltier (condensação).
- Case com entrada e saída de ar, acesso à USB-C e ao botão power.
- Controles por Bluetooth.
