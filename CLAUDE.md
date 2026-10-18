# Projeto: Galaxy S20 FE como console de mesa

Objetivo: transformar o Galaxy S20 FE (Snapdragon) num videogame de mesa ligado à TV, com o máximo de desempenho possível. O resultado final deve ser um sistema **"plug and play" no estilo Batocera**: desbloqueia o bootloader de qualquer S20 FE SM-G780G, grava o sistema e o aparelho já liga direto no menu de jogos.

Idioma: responda sempre em português do Brasil.

## Regras de segurança (obrigatórias)

1. **Nunca grave nenhuma partição** (boot, recovery, vbmeta, dtbo, system etc.) nem rode samloader `flash`, Odin, `dd` ou sideload sem eu confirmar explicitamente naquele momento. Antes de pedir a confirmação, diga o que vai gravar, onde, e como voltar atrás.
   - **Exceção autorizada em 2026-10-12:** gravar **kernels de teste na partição `boot`** (via `dd` com root) sem pedir confirmação, desde que: haja backup do boot atual, o hash da imagem seja conferido no celular antes e a partição seja lida de volta e conferida depois. Mesmo assim, avisar antes o que vai gravar e como voltar atrás. Qualquer outra partição continua exigindo confirmação.
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
- Estado atual (2026-10-12, reinstalado após o teste no One UI): **LineageOS 23.2 nightly 20261010** com o **kernel próprio `s20fe-gpu-oc`** (retain + GPU 625/670 MHz; boot = `~/s20fe-build/images/boot-gpuoc-magisk.img`, hash conferido na partição; anterior: `boot-retain-magisk.img`) + Magisk 30.7. Patches e scripts de build também em `kernel/` neste repositório. Antes (2026-10-11): **LineageOS 23.2 nightly 20261010** (Android 16, patch 2026-10-01), Lineage Recovery, vbmeta do LineageOS, sem GApps, **root com Magisk 30.7** (boot em `lineage/magisk/magisk_patched-30700_JopyK.img`; boot oficial sem root em `lineage/boot.img`, SHA-256 conferido), bootloader desbloqueado. Firmware/bootloader continuam G780GXXSHEYJ1.

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
- `samloader/` → samloader-rs 2.2.0 (github.com/topjohnwu/samloader-rs). **No Linux usar a 2.1.0** (`~/s20fe-build/tools/samloader/samloader`): a 2.2.0 falha no S20 FE com "Dynamic partition pre-flight check failed" (issue #43) ao gravar firmware stock. Aceita várias `-p PART arquivo` na mesma sessão. É a ferramenta que a wiki do LineageOS indica para o modo Download. Substitui o Odin: grava `.img` direto (sem empacotar em tar) e também firmware stock (`--AP --BL --CP --CSC`). Os drivers USB da Samsung já estão instalados no PC (backend padrão `vcom`).
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
- **No Linux Mint** (desde 2026-10-12): usar o `adb` do apt (`android-sdk-platform-tools`), o único instalado; a regra do `adb.exe` do scrcpy vale só no Windows. Usuário no grupo `plugdev` (regras udev de `android-sdk-platform-tools-common`). **scrcpy 5.0.1** oficial em `/opt/scrcpy-linux-x86_64-v5.0.1` (hash conferido), chamado por `/usr/local/bin/scrcpy`, que força `ADB=/usr/bin/adb`; o scrcpy 1.25 do apt não funciona no Android 16. Há também um S10 que às vezes fica no mesmo PC: usar `-s RX8T10JEJXY` (S20 FE).

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
   - [x] Imagem na TV pelo adaptador USB-C → HDMI → **funciona desde 2026-10-18, depois da troca da subplaca USB-C** (kernel próprio com `RETAIN_LINK_POWER`). Antes da troca não funcionava (ver "Problema: saída de vídeo" abaixo)
   - [x] Carregar enquanto sai vídeo (hub com PD)
   - [x] Controle Bluetooth
   - [x] Wi-Fi
   - [x] Áudio pela TV (confirmado em 2026-10-18)
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
- **Revisão do código em 2026-10-12 (descartou as hipóteses anteriores):**
  - BIT(14)/VSC: **descartado**. `dp_panel_hw_cfg()` programa e liga o VSC SDP (GEN0) sempre que o sink anuncia VSC, ao ligar o stream.
  - ASSR BIT(10): **descartado**. `dp_panel_config_ctrl()` reescreve o `DP_CONFIGURATION_CTRL` inteiro (bit 10 = 0) ao ligar o vídeo, no stock e no LineageOS.
  - TU com `link_params`/`link_info`: no hub (máx. = negociado, 1 lane HBR2) dá o mesmo valor. O SW reset só age no desligamento. → no hub, o caminho do sinal no kernel é praticamente igual ao do stock.
  - O "**[205h] port0: out of sync, reset!**" **não é perda de sinal**: é um contorno da Samsung (`secdp_reset_link_status`) que roda em `dp_display_hdcp_cb_work` logo antes de iniciar a autenticação HDCP 1.x e só força o bit no status guardado.
  - O HDCP começa **3,5 s depois** de o stream ligar (`secdp_hdcp_start_work`, agendado em `dp_display_enable`), o que bate com o "~4 s depois".
- **Testes de kernel em 2026-10-12** (branches em `~/s20fe-build/kernel`, imagens em `~/s20fe-build/images/`):
  1. `s20fe-dp-nohdcp` (`SECDP_HDCP_DISABLE`): sem HDCP, mas sem imagem. O log mostrou o **defeito 1**: ~50 ms depois de ligar o vídeo, o Android faz um "desliga e religa" (modeset); o `dp_display_unprepare` trata como `SRC_PWRDN` e desliga o controlador inteiro (`host_deinit`); o `dp_display_prepare` não reinicializa (só faz se `CONFIGURED`), tenta o link com `core_clks_on: off` e o `enable` desiste com "host not ready". Religar a tela/reconectar nesse estado deu **kernel panic** (SError/NOC em `dp_catalog_panel_config_sdp`, reset_reason WPON).
  2. `s20fe-dp-retain`: liga `CONFIG_SEC_DISPLAYPORT_RETAIN_LINK_POWER=y` no `r8q.config` (o LineageOS já liga isso nos Tab S7 `gts7*`, mesmo chip/driver; commit `29c21e0abd`). **Corrige o defeito 1** ("retain link power during source initiated unprepare", vídeo religa limpo, sem panic). Ainda sem imagem.
  3. `s20fe-dp-retain-nohdcp`: retain + sem HDCP: kernel 100% ok no log, ainda sem imagem.
- **Comparação com um S10 (SM-G973F, Exynos, One UI 4 com Magisk) no mesmo hub e TV** (log em `~/s20fe-build/dmesg-s10-oneui.txt`): o hub se identifica como **VID 0x057E / PID 0x2003** (dock "Nintendo Switch") e é um **repetidor HDCP 1.3**: o S10 autentica (R0 → liga criptografia → "HDCP repeater Start" → `device count = 1` em ~0,6 s → "2nd Auth done") e só então a TV mostra imagem. O hub **não envia CP_IRQ**. → **O conversor só repassa vídeo com HDCP autenticado** (por isso desligar o HDCP não adianta).
- **Defeito 2 (HDCP no S20 FE/LineageOS):** os TAs `hdcp1/hdcp2p2/hdcpsrm` existem em `/vendor/firmware_mnt/image`. A 1ª tentativa de part1 falha (R0' sem mensagem), as seguintes dão `part1: SUCCESSFUL` (as chaves funcionam), mas a part2 falha com `DS KSV not ready` após 5 s (Bstatus READY, DPCD `0x68029` bit 0, nunca aparece), em loop a cada 6 s. Código HDCP (`sde_hdcp_1x.c`, `sde_hdcp_2x.c`) é **idêntico** ao do kernel Samsung do S20 FE.
  4. `s20fe-dp-retain-hdcpenc`: `force_encryption` = true no DP (liga a criptografia antes da autenticação, como o HDMI e o S10). A criptografia liga sem erro, mas **não resolveu**.
  5. `s20fe-dp-hdcp-noainfo` : o driver Qualcomm escreve `Ainfo=1` (DPCD `0x6803B`, REAUTHENTICATION_ENABLE_IRQ_HPD) nos repetidores; o driver Exynos do S10 (`displayport_hdcp13.c`, em `~/s20fe-build/ref-exynos/`, de LineageOS/android_kernel_samsung_exynos9820) **nunca escreve o Ainfo**. Teste: não escrever o Ainfo + logar o Bstatus durante a espera.
  6. `s20fe-dp-hdcp-encafter` (criptografia ligada depois do part1) e `s20fe-dp-novsc` (VSC desligado): sem efeito, mesmo loop `DS KSV not ready`.
- **Teste decisivo (2026-10-12): One UI stock G780GXXSHEYJ1 regravado no S20 FE** (samloader 2.1.0, HOME_CSC) → **também sem imagem**, com TV e com o monitor HORIZON, com e sem DeX: mesmo loop de HDCP. No S20 FE todas as conexões mostram `[204h] interlane_align_done is zero` e, numa orientação do plugue, o treino a 2,7 Gbps falha e cai para 1,62; o S10 no mesmo hub treina a 2,7 Gbps com `interlane_align_done = 1`.
- **Conclusão: defeito de hardware na subplaca da USB-C do S20 FE** (confirmado pelo usuário; **resolvido em 2026-10-18 com a troca da subplaca: imagem na TV OK**). Sinal de vídeo instável → o conversor do hub não gera HDMI → o HDCP downstream nunca completa. A investigação de software está encerrada. Depois de trocar a subplaca, testar de novo com o kernel `retain` (o defeito 1 é real e continua corrigido nele).
- O desligamento travou uma vez (>9 min) com o kernel `encafter`; foi preciso forçar pelos botões. Não se repetiu.

### Fase 2: root e desempenho
- **Progresso em 2026-10-12** (kernel próprio, branch `s20fe-gpu-oc` = `retain` + GPU; boot `~/s20fe-build/images/boot-gpuoc-magisk.img`, gravado e conferido):
  - zram com **lz4**: o kernel já tinha lz4/zstd; troca feita no boot por `/data/adb/service.d/zram-lz4.sh` (cópia em `scripts/`). Sem recompilar.
  - GPU: níveis novos no speed-bin 0 (`kona-v2-gpu.dtsi`): **625 MHz em NOM** (tensão do 587) e **670 MHz em NOM_L1** (tensão oficial do speed-bin 1). O chip é **v2.1, speed-bin 0**. O DTB do boot = `kona-v2.1.dtb + kona-v2.dtb + kona.dtb` (reproduzido byte a byte); `mkboot.sh` usa `out-<nome>/s20fe-dtb.img` se existir.
  - **625 MHz estável**: 20 min de 3DMark Wild Life Extreme Stress, loop 1 ≈ loop 12, sem erro de GPU; 94% do tempo a 625, pico de 96 °C na GPU **sem cooler** (bateria 38–39 °C). Limite padrão no boot = 625 por `/data/adb/service.d/gpu-max.sh`. **670 MHz estável com ventilação** (2026-10-12, ambiente ventilado): Wild Life Extreme Stress **1.240 / 1.230, estabilidade 99,2%**, 99% do tempo a 670, GPU média 86 °C e pico 91 °C, bateria 37 °C, sem erro de GPU.
- Magisk no boot do LineageOS.
- Conferir se o DTB continua embutido no boot (`magiskboot unpack`). Se sim, testar o **KonaBess** (github.com/libxzr/KonaBess): GPU **625 MHz** com a mesma tensão do 587, testar estabilidade e depois **670 MHz** (frequência do 865+). Não passar de 670 sem motivo.
- Kernel próprio a partir do **kernel do LineageOS para sm8250** (GitHub, org LineageOS), compilado no Linux instalado no HD (ver "PC de desenvolvimento"), dentro de `~` (ext4), nunca numa partição NTFS. Extras: lz4 no zram (`CONFIG_CRYPTO_LZ4`), níveis extras de GPU no device tree.
- Limite de carga da bateria (o aparelho vai ficar sempre na tomada): **ativado em 2026-10-12** pelo controle de carga oficial do LineageOS (Configurações → Bateria → Controle de carga), modo **Limite 80%** (`lineagesettings/system`: `charging_control_enabled=1`, `charging_control_mode=3`, `charging_control_charging_limit=80`). O HAL `vendor.lineage.health` escreve em `/sys/class/power_supply/battery/charging_enabled`, que só pausa a carga: o aparelho segue alimentado pelo carregador. Retoma ao cair ~1% abaixo do limite. Alternativa no kernel Samsung: `batt_full_capacity` (para em X, retoma em X−2). **Falta conferir que parou em 80%.**
- Teste de estabilidade: 20–30 min de 3DMark Wild Life Stress ou um jogo pesado de PS2/GameCube, monitorando a temperatura.

### Fase 3: camada de console
- Frontend como launcher padrão, iniciando direto nele: **ES-DE** ou **Daijisho**.
- Emuladores: RetroArch, Dolphin, NetherSX2/AetherSX2, PPSSPP, DuckStation, entre outros. Usar drivers Turnip via AdrenoTools nos emuladores que suportam.
- **DroidDeck 0.4.0** (github.com/Droid-Deck/DroidDeck, GPL-3.0; Steam/Proton ARM64 no Android) instalado em 2026-10-18 (`com.droiddeck.launcher`, APK e `SHA256SUMS.txt` da release em `apps/droiddeck-0.4.0/`, hash conferido). Suporte ao Adreno 650 é experimental (DX11 leve; DX12 tende a falhar). Restrição de processos filhos desligada: `settings put global settings_enable_monitor_phantom_procs false` + `device_config put activity_manager max_phantom_processes 2147483647` (com `set_sync_disabled_for_tests persistent`).
- **Organização dos jogos (2026-10-18, alternativa A: cartão continua portátil, exFAT 64 GB "49D1-0CA8"):** PS2 no interno `/storage/emulated/0/Games/ps2` (9 jogos, 30 GB, copiados do cartão com MD5 conferido; os originais continuam no cartão em `ROM/FULL-PACK-BIOS-BATOCERA-V38-MINICAKETV/bios/pcsx2/`, aguardando o usuário decidir se apaga); BIOS do PS2 em `Games/bios/ps2`; PSP no cartão `/storage/49D1-0CA8/Games/psp` (12 jogos, movidos dentro do cartão). Memory Stick do PPSSPP em `Games/psp/PSP` no cartão.
- **Cartão SD caiu uma vez** (2026-10-18 06:47, `slot status change` oscilando + `bad_removal`; antes um `error -5` na inicialização). Voltou depois de recolocar a gaveta. Suspeita: contato da gaveta/leitor (a subplaca foi trocada no mesmo dia). Se repetir: testar outro cartão e depois o leitor.
- Emuladores: **ARMSX2 2.8.4** (PS2, GPL-3.0, `com.armsx2`, APK `a15-armv8.2-sdk35` em `apps/emuladores/`, hash conferido) — Black rodou bem; PPSSPP 1.20.4 (instalado pelo usuário via Aurora); o usuário também instalou Daijisho e AetherSX2/NetherSX2.
- **Pegasus** (build contínuo alpha16-106, `org.pegasus_frontend.android`, hash conferido): `game_dirs.txt` em `/storage/emulated/0/pegasus-frontend/`; `metadata.pegasus.txt` escrito à mão em cada pasta de jogos. Lançar com `am start --user 0 -n <pacote/atividade> -a android.intent.action.VIEW -d {file.uri}` **funciona** no ARMSX2 e no PPSSPP. **Gerador pronto:** `tools/gen-pegasus.py` (usa `tools/esde/`, cópia do ES-DE com LICENSE/ORIGEM/SHA256SUMS). Varre `Games/<sistema>` no interno e em cada cartão montado, escolhe o 1º emulador instalado do ES-DE (padrão do console: ps2=ARMSX2; trocar com `--emu sistema=NOME`), grava o `metadata.pegasus.txt` e o `game_dirs.txt`. Rodar de novo sempre que instalar emulador, baixar núcleo ou criar pasta de sistema. Padrões: ps2=ARMSX2, psp=PPSSPP (Standalone) (onde estão os saves). Confere com root se o núcleo libretro existe em `/data/data/com.retroarch/cores` e pula para o próximo se não. **Validado em 2026-10-18:** PS2 (ARMSX2), PSP (PPSSPP) e GBC via RetroArch (`--es ROM {file.path}`, nome com espaços e "µ") abrem direto pelo Pegasus.
- **Capas (Skyscraper 3.21.1, fork Gemba, compilado com Qt6 e instalado em `/usr/local/bin`; fonte em `~/s20fe-build/tools/skyscraper-src`):** `tools/scrape.sh [sistema]` cria no PC arquivos **vazios** com os nomes dos jogos do aparelho (`~/s20fe-build/skyscraper/roms/`), busca no ScreenScraper pelo nome (funciona: 20 de 21 jogos com 100%) e gera `-f pegasus` em `~/s20fe-build/skyscraper/out/<sistema>/`; o `gen-pegasus.py` junta os blocos `game:` (caminhos viram relativos) e envia `media/`. Apelidos de busca em `~/.skyscraper/aliasMap.csv` (ex.: `"Midnight Club 3 (USA)";"Midnight Club 3 DUB Edition"`). Sem capa: `GTA SA Definitive Edition` (mod de fã).
  - Login do ScreenScraper: a API pede o **apelido** (não o e-mail); com o apelido funciona (conta gratuita = 1 thread). Credenciais só em `~/.skyscraper/config.ini` (chmod 600, fora do repo). O usuário deve trocar a senha, que apareceu no chat.
  - O metadata usa `files:` (lista explícita dos jogos da pasta principal), porque o ARMSX2 usa `Games/ps2` como pasta de dados e o cache dele (`cache/*.bin`) e a BIOS (`bios/*.bin`) apareciam como jogos.
- **Tema próprio "S20FE Console"** (`theme/s20fe-console/`, QML, mistura Batocera + PS5): faixa de sistemas com cor por console (Android sempre no fim), fileira de capas com a selecionada maior e borda branca, fundo com a tela do jogo desfocada (QtGraphicalEffects), logo/ano/estúdio/gênero/descrição, imagem do jogo e **vídeo após 1,5 s** (QtMultimedia; os vídeos ainda não foram baixados), relógio e bateria (verde = carregando), lembra sistema/jogo (`api.memory`). Controles: ←/→ jogo, LB/RB ou ↑/↓ sistema, A joga, Y favorito, Start = menu do Pegasus. No aparelho: `/storage/emulated/0/pegasus-frontend/themes/s20fe-console/`; ativado em Configurações → Tema (escrever `general.theme` no `settings.txt` não bastou). Testar pelo adb: `input keyevent KEYCODE_DPAD_*`/`KEYCODE_ESCAPE` + `screencap`. Fonte sem "☰" e "⚡" (aparecem como quadrado).
- **Pegasus é a tela inicial** (2026-10-18): `cmd package set-home-activity org.pegasus_frontend.android/.MainActivity`. O Trebuchet (`com.android.launcher3`) **não foi desinstalado** de propósito: ele é o `mRecentsComponentName` (Recentes) e cuida dos gestos de navegação (o aparelho usa `navigation_mode=2`, gestos); removê-lo quebraria Recentes e o gesto de início. Para voltar: `cmd package set-home-activity com.android.launcher3/.uioverrides.QuickstepLauncher`.
- **Espelhamento sem diálogo de confirmação:** `setprop persist.sys.display.enable_on_connect.external true` (root). O `ExternalDisplayPolicy` do Android 16 só respeita essa propriedade em build `userdebug`/`eng`; o LineageOS é `userdebug`. Na ROM própria (Fase 4): colocar no `build.prop`/`vendor.prop`.
- **RetroArch 1.22.2** do F-Droid (`com.retroarch`, hash do índice do F-Droid; o buildbot da libretro não publica hash), APK em `apps/emuladores/`. Núcleos baixados pelo usuário: fbneo, genesis_plus_gx, mednafen_supergrafx, mesen, mgba, mupen64plus_next_gles3, numero, ppsspp, snes9x, swanstation.
- Jogo de teste: **µCity** (GBC, GPL-3.0, github.com/AntonioND/ucity v1.3, hash conferido) em `Games/gbc`; cópia em `apps/homebrew/`. Pastas = nomes de sistema do ES-DE (`snes`, `gba`, `psx`, `n64`, `gc`...).
- Ports nativos (decomp/recomp, ex.: 2 Ship 2 Harkinian, Dusklight, Gen1Recomp, sm64coopdx, DevilutionX) são preferíveis à emulação quando existem; o usuário fornece os arquivos do jogo.
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

## PC de desenvolvimento (levantado em 2026-10-11)
- Windows 11 Pro, boot **UEFI**. RAM: **8 GB** (depois de retirar o pente defeituoso).
- Disco 1: SSD NVMe 256 GB (GPT) → Windows `C:` (131 GB livres) + partição EFI do Windows.
- Disco 0: HD Toshiba 1 TB (**MBR**) → `D:` NTFS, praticamente vazio (só pastas do app Xbox: `WindowsApps`, `.GamingRoot`).
- WSL abandonado: a tentativa de rodar Linux no Windows quebrou o Windows. Plano: **Linux nativo em dual boot numa partição do HD** (D:).
- 8 GB de RAM bastam para compilar o **kernel**. O LineageOS inteiro (Fase 4) pede 16–32 GB: com 8 GB, só com muito swap e muito lento → rever antes da Fase 4.

### Linux (instalado em 2026-10-11)
- **Linux Mint 22.3** em `sda2` (ext4, 440 GB) no HD; `sda1` continua NTFS. 16 threads. **Swap de 16 GB** em `/swapfile` (no `/etc/fstab`). Pacotes de build do kernel instalados (bison, flex, libssl-dev, libelf-dev, lz4, dwarves etc.).
- O HD é **mecânico** (`rotational=1`): bom para o kernel, péssimo para o LineageOS inteiro (Fase 4).
- A pasta do projeto fica no NTFS do SSD (`/media/steve/98288B51288B2CF6/s20fe`, montado pelo ntfs-3g). Em 2026-10-11 o ntfs-3g caiu ("Ponto final de transporte não está conectado"); remontado com `udisksctl mount -b /dev/nvme0n1p3` e todos os hashes reconferidos OK.

### Build do kernel (em `~/s20fe-build/`, ext4)
- `kernel/`: clone raso de LineageOS/android_kernel_samsung_sm8250, branch `lineage-23.2` (commit `4478511`, o mesmo do aparelho). Branches de teste locais: `s20fe-dp-retain` (**a base atual**, só o `RETAIN_LINK_POWER` no `r8q.config`) e os testes de DP/HDCP (`s20fe-dp-nohdcp`, `-retain-nohdcp`, `-retain-hdcpenc`, `-hdcp-noainfo`, `-hdcp-encafter`, `-novsc`). `mkboot.sh <out-nome> <saida.img>` monta o boot com o ramdisk/DTB do Magisk (`pieces/magisk/`).
- `clang-r563880c/`: clang 21 do AOSP (`prebuilts/clang/host/linux-x86`, branch `android16-qpr2-release`), o mesmo do build oficial (`ClangDefaultVersion` do soong lineage-23.2). SHA-256 do tarball em `clang-r563880c.tar.gz.sha256`.
- `build-kernel.sh [nome] [jobs]`: reproduz o `kernel.mk` do LineageOS (sem GCC: `CC=clang LD=ld.lld LLVM=1 LLVM_IAS=1`; defconfig `vendor/kona-perf_defconfig` + merge de `vendor/samsung/kona-sec-common.config` e `vendor/samsung/r8q.config`). Saída em `out-<nome>/`. ~16 min com `-j8`.
- **Validado:** o kernel de referência (`out-ref`) tem o mesmo tamanho (55.767.064 bytes), a mesma versão `4.19.325-cip136-st20-perf-g4478511c4b37`, o mesmo clang e a **mesma config embutida** (ikconfig) do kernel do `lineage/boot.img`. Os bytes diferem só por caminho/usuário/data (normal com LTO).
- Kernel monolítico (nenhum `=m`): trocar o kernel não exige módulos compatíveis.
- `tools/mkbootimg/`: mkbootimg/unpack_bootimg do AOSP. O boot do Magisk **não altera o kernel nem o DTB**, só o ramdisk. Remontar o boot do Magisk com as peças dele dá um arquivo **byte a byte idêntico** (os 271 bytes finais da imagem de 64 MB são o rodapé AVB). Parâmetros: `--header_version 2 --os_version 16.0.0 --os_patch_level 2026-10 --pagesize 0x1000 --base 0 --kernel_offset 0x8000 --ramdisk_offset 0x01000000 --tags_offset 0x100 --dtb_offset 0x01f00000` + a cmdline do `BoardConfigCommon.mk`.
