# Ligar sozinho ao conectar a energia (S20 FE + LineageOS)

Pesquisa iniciada em 2026-10-22 (passo 1 dos "Próximos passos" do `auxiliar.md`). **Nada foi gravado no aparelho**; o celular não estava conectado.

## Como o S20 FE entra no modo de carga desligado (confirmado no código)
1. Aparelho desligado + cabo → o bootloader da Samsung inicia o Android com **`androidboot.mode=charger`** na cmdline.
2. O kernel lê isso: `sec_bat_is_lpm_check()` em `drivers/battery_v2/sec_battery.c` (LineageOS `android_kernel_samsung_sm8250`, branch `lineage-23.2`, linhas 246–256) põe `lpcharge = 1` ("Low power charging mode").
3. O init do AOSP processa as seções **`on charger`**. Na árvore do LineageOS (`android_device_samsung_sm8250-common`, `lineage-23.2`): `init/init.qcom.rc:754` (`start qcom-post-boot`) e `init/init.target.rc:182` (`start vendor.power_off_alarm`, USB).
→ Basta acrescentar uma ação em `on charger` que reinicie em modo normal. O bootloader só usa `charger` quando o boot vem do "desligado com cabo"; um reboot comum inicia o sistema.

## O módulo `magisk-autoboot` (anasfanani)
- Repositório: <https://github.com/Magisk-Modules-Alt-Repo/magisk-autoboot> (cópia; original `anasfanani/magisk-autoboot`). v1.0.1, último push 2024-01-12, 28 estrelas. Licença: README diz MIT, o GitHub mostra "Other".
- O README lista Redmi 4X, Samsung J3 2016 e Redmi Note 11, mas **no XDA o módulo foi criado a partir de um S20 FE G780G/DS** (tparaizo, One UI + Magisk, "funcionando muito bem"; o limite de bateria veio dele, que usou 30 %) e há relato de **S10e com LineageOS 20** funcionando, inclusive com carga sem fio. Ver [foruns-e-comunidades.md](foruns-e-comunidades.md#62-ligar-sozinho-ao-conectar-xda).
- Comportamento abaixo do mínimo (relato do S20 FE): **fica parado na tela de boot carregando**, sem mostrar a %, e liga sozinho ao atingir o mínimo — confirma que o `exec` segura o init (a animação de carga não aparece), mas a carga continua.
- **O núcleo é pequeno**: coloca 2 arquivos no `overlay.d` do ramdisk do Magisk (o `magiskinit` injeta os `.rc` de `overlay.d` no init e copia `overlay.d/sbin/*` para o tmpfs do Magisk):
  - `overlay.d/init.autoboot.rc`:
    ```
    on charger
     exec u:r:magisk:s0 -- /system/bin/sh ${MAGISKTMP}/autoboot.sh 000
    ```
  - `overlay.d/sbin/autoboot.sh`: lê `/sys/class/power_supply/battery/capacity`; se > `MIN_CAPACITY=5`, faz `setprop ro.bootmode normal` + `setprop sys.powerctl reboot`; senão espera de 60 em 60 s.
- **Por que NÃO instalar o módulo como está** (lido em `customize.sh` e `scripts/boot_patch.sh`):
  1. O instalador **regrava a partição `boot` sozinho** (`flash_image`), sem conferência de hash — contraria a regra 1 do `CLAUDE.md`.
  2. Reescreve o `config` do Magisk no ramdisk (`KEEPVERITY`, `PATCHVBMETAFLAG`…) com valores próprios.
  3. Roda `magiskboot dtb … patch` no DTB — **o nosso DTB tem os níveis de GPU de 625/670 MHz** (`s20fe-dtb.img`); qualquer alteração ali precisa ser nossa e conferida.
  4. A desinstalação **regrava o boot com o backup feito na instalação** → se o kernel tiver sido atualizado depois, volta um kernel velho.
  5. `exec` bloqueia o init até o script terminar; com bateria abaixo do mínimo, o laço de espera trava o processamento do `on charger` (a animação de carga pode não aparecer).
- **Conclusão:** usar só a ideia (2 arquivos no `overlay.d`) dentro do **nosso** processo de montagem do boot (`kernel/mkboot.sh`, ramdisk do Magisk em `~/s20fe-build/pieces/magisk/`), com backup e hash como sempre.

## Outros relatos do mesmo método
- **Galaxy S5 com LineageOS 14 (yaky.dev, 2024)**: o Magisk Autoboot **funcionou**; `fastboot oem off-mode-charge` não existe em Samsung; com bateria muito baixa entra em **laço de reinicialização** (por isso o mínimo de bateria). Mais em [foruns-e-comunidades.md](foruns-e-comunidades.md#3-ligar-sozinho-ao-conectar-relatos-práticos).
- Galaxy Tab S2 com LineageOS 16: `on charger` → `setprop sys.powerctl reboot,leaving-off-mode-charging` no `.rc` do healthd; **OTA desfaz** (no nosso caso as OTAs estão desligadas).
- Galaxy S5: `setprop ro.bootmode "normal"` + `sys.powerctl`. Galaxy S7 / LineageOS 17: funcionou editando o init Samsung do vendor. S3 mini: falhou.
- LineageOS 22.2: depois de uma atualização, funcionou inserindo a linha em `/system/etc/init/hw/init.rc` com `sed`.
- Android 10+: o `init.rc` não fica mais na raiz do ramdisk; por isso o caminho do Magisk (`overlay.d`) é o mais limpo.
- Galaxy S7/Alpha (fórum polonês, LPM antigo): manter o **mesmo inode** e usar **LF** (CRLF impediu o boot).
- Issue LineageOS #5773 (FxTec Pro1-X): o problema inverso (sempre liga) — mostra que o comportamento depende do aparelho.

## Rascunho para o S20 FE (a validar, não aplicado)
`overlay.d/s20fe-autoboot.rc` — serviço em vez de `exec`, para não travar o init:
```
service s20fe-autoboot /system/bin/sh ${MAGISKTMP}/s20fe-autoboot.sh
    user root
    seclabel u:r:magisk:s0
    oneshot
    disabled

on charger
    start s20fe-autoboot
```
`overlay.d/sbin/s20fe-autoboot.sh` (LF):
```sh
#!/system/bin/sh
# Modo de carga desligado: reinicia em modo normal quando a bateria passar do mínimo.
MIN=10
while [ "$(cat /sys/class/power_supply/battery/capacity)" -lt "$MIN" ]; do
    sleep 30
done
sleep 2
setprop sys.powerctl reboot
```

## Perguntas em aberto (testar no aparelho)
1. O `magiskinit` processa o `overlay.d` no modo `charger` deste aparelho? (O módulo diz que sim nos aparelhos testados.) Conferir com log (`/proc/last_kmsg` ou `dmesg` do boot seguinte) ou deixando o script gravar um arquivo em `/dev`/tmpfs.
2. O contexto `u:r:magisk:s0` existe no modo de carga (o sepolicy do Magisk é carregado nele)?
3. Motivo do reboot: `reboot` puro ou `reboot,leaving-off-mode-charging`? No Samsung, motivos estranhos podem cair no modo Download/recovery.
4. **Desligar de verdade com a fonte ligada** passa a ser impossível (religa na hora). Opções: aceitar ("desligar = tirar da tomada"); ou um aviso gravado antes do desligamento num lugar legível no modo de carga (no `charger` a `/data` não é montada; ver `/metadata`, `/cache` ou `/mnt/vendor/persist` — **`persist` é proibida para gravar**, regra 4).
5. Bateria muito baixa: o limite mínimo evita o laço "liga → desliga por bateria fraca → modo de carga → liga".
6. Interação com o limite de carga de 80 % (o controle do LineageOS só age com o sistema ligado; no modo de carga ele carrega até 100 % — irrelevante, porque o reboot acontece logo).

## Plano de teste (precisa de confirmação na hora)
1. Pré-requisito de segurança: **ter no PC atual o caminho de volta** — backup do boot atual (`boot-gpuoc-magisk.img` + SHA-256) e o samloader 2.1.0 no Linux (modo Download). Este PC Windows não tem `C:\s20fe` (sem backups nem samloader).
2. Montar o boot novo: ramdisk do Magisk atual + os 2 arquivos (no Linux pelo `mkboot.sh`, ou no aparelho com `/data/adb/magisk/magiskboot cpio`), sem tocar no kernel nem no DTB; conferir com `magiskboot cpio … test`/`unpack` que só o ramdisk mudou.
3. Gravar o boot com `dd` (backup antes, hash no celular antes e leitura de volta depois — exceção da regra 1 vale para a partição `boot`; avisar antes).
4. Teste: desligar com o cabo ligado → deve aparecer a animação de carga por alguns segundos e reiniciar no sistema.
5. Volta: `dd` do boot anterior (ou samloader `-p BOOT` no modo Download, se o sistema não subir).

## Achado lateral: "slate mode" (bypass de carga da Samsung)
O driver tem `batt_slate_mode` e `normal_mode_bypass` em `/sys/class/power_supply/battery/` (`sec_battery_sysfs.c:2020`, permissões em `init.samsung.battery.rc`). O "slate mode" suspende a carga/entrada USB (`sec_battery.c:6773`: "slate mode on or set usb suspend"). **Não confundir com o modo "pausar carga e rodar do carregador"**: suspender a entrada pode fazer o aparelho consumir a bateria. Só estudar; o nosso limite de 80 % já usa `charging_enabled`.

## Fontes
- <https://github.com/Magisk-Modules-Alt-Repo/magisk-autoboot> (README, `customize.sh`, `scripts/boot_patch.sh`, `scripts/files/*`)
- <https://mmrl.dev/repository/magtrenv2/magisk-autoboot>
- <https://xdaforums.com/t/module-magisk-autoboot-auto-power-on-android-when-charger-connected.4645951/>
- <https://xdaforums.com/t/lineage-os-auto-boot-on-charge-connected.3626364/page-3> (bloqueado para leitura automática; resumo pela busca)
- <https://xdaforums.com/t/auto-boot-start-on-charge-different-devices.3233767/>
- <https://xdaforums.com/t/how-can-i-auto-start-lineageos-16-when-charger-is-plugged-in.3934772/>
- <https://gitlab.com/LineageOS/issues/android/-/issues/5773>
- <https://github.com/LineageOS/android_kernel_samsung_sm8250/blob/lineage-23.2/drivers/battery_v2/sec_battery.c>
- <https://github.com/LineageOS/android_device_samsung_sm8250-common/tree/lineage-23.2/init>
- <https://forum.android.com.pl/topic/369427-automatyczne-uruchamianie-telefonu-po-podłączeniu-ładowarki>
- AOSP charger: <https://gerrit.omnirom.org/plugins/gitiles/android_system_core/+/f48b23688c1303212c65e470af9f9f3892e98f8e>
