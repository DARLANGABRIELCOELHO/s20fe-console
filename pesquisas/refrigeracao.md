# Refrigeração em boxes e gabinetes de celular

Levantado em 2026-10-22. O nosso plano atual está em `hardware/README.md` (dissipador de cobre de 45 × 45 × 30 mm + ventoinha de 80 mm controlada pelo `fanctl.sh`).

## O que a cena DeX usa
| Quem | Solução |
|---|---|
| DEX LOR | Box com **caminho de ar pensado** (entrada e saída), o vídeo mais visto dele (1,3 mi) |
| Dex Max, @samsungdex29 | **Peltier** ("sò lạnh") no 8 Gen 2 e no Z Fold 4, **com controle automático contra condensação** |
| Dex Max | Capa com ventoinha e alimentação integradas para uso 24/7 |
| Hải Âu DIY DeX | Ventoinha com liga/desliga |
| Brothers Repair, "Gabinete CPU DEX" (TikTok Shop) | Gabinete estilo PC com **cooler de 80 mm** e RGB |
| Rudson | Coolers + step-down + fonte de 5 V/12 V |
| Jonathan Miranda | Gabinete impresso em 3D com **cooler USB** |
| Pixel 8 do Reddit | **Ventoinha de PC de 50 mm** ligada no hub |
| Samsung DeX Station (2017) | Dock oficial já tinha **ventoinha embutida** |

## Peltier (célula termoelétrica) — por que continuamos sem
- O lado frio pode ficar **abaixo do ponto de orvalho** → água condensada na placa (curto). Um vendedor chega a dizer que "condensação é normal".
- Soluções documentadas: medir **temperatura + umidade, calcular o ponto de orvalho e cortar o Peltier** (patente publicada no USPTO; projeto acadêmico i-MagArctic: 44 °C → 35,9 °C num teste de só 20 min).
- O Dex Max vende justamente o "Peltier automático para não esquecer ligado e condensar".
- Consumo alto: as capas Peltier chegam a ~10 °C abaixo do ambiente **só por pouco tempo**, até o próprio celular limitar a potência.
- **Conclusão:** confirma a decisão do `CLAUDE.md` ("Sem Peltier (condensação)").

## Dissipador e pad térmico — relatos
- Calço de cobre + pasta sobre o SoC (XDA): AnTuTu de 31.438 → 36.099 e máxima de 73 → 64 °C.
- Nexus 5X com placa de cobre: curva de throttling "ainda não é uma reta, mas bem melhor".
- Nexus 9: pouco ganho → o dissipador só ajuda se tocar uma superfície que realmente conduz o calor do chip.
- **Espessura do pad:** 2 mm foi grosso demais; recomendação de **1–1,5 mm no máximo** (bate com o nosso plano).
- Ventoinha colada no celular acumula poeira; cobre volumoso **piorou o sinal** de um iPhone (antenas). No S20 FE o Wi-Fi já cai fora do chassi (−66/−70 dBm, `hardware/README.md`): prever antena.

## Lições para o nosso case
1. Entrada e saída de ar definidas (fluxo de um lado ao outro), como no box do DEX LOR e nos gabinetes de 80 mm.
2. Ventoinha controlada pela temperatura (já temos: Pico 2 + `fanctl.sh`) e **filtro de poeira** na entrada.
3. Não bloquear antenas com metal; testar Wi-Fi/BT com o case fechado.
4. Sem Peltier.

## Fontes
- <https://www.tiktok.com/discover/s%C6%A1-%C4%91%E1%BB%93-l%C3%A0m-box-samsung-dex>
- <https://www.tiktok.com/discover/samsung-dex-delta-force>
- <https://www.tiktok.com/discover/gabinete-dex>
- <https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/12471243>
- <https://teamdesign.kfupm.edu.sa/media/poster/TEAM_M109.pdf>
- <https://grandavehousing.calpoly.edu/news/ice-cooler-hp-ultimate-guide>
- <https://www.formulamod.net/de/products/barrow-mobile-phone-semiconductor-rapid-cooler-for-gaming-cellphone-heat-sink-cooling-fan-radiator>
- <https://forum.xda-developers.com/showpost.php?p=54768272>
- <https://forum.xda-developers.com/showthread.php?p=59822678>
- <https://reddit.birdcat.cafe/r/nexus5x/comments/vpn9r5/copper_modding_the_nexus_5x>
- <https://electronics.alibaba.com/question/do-phone-cooling-cases-actually-work>
- <https://www.techspot.com/community/topics/modder-attaches-ssd-coolers-to-iphone-17-pro-max-for-unprecedented-benchmark-results.294940/>
- <https://androidcentral.com/galaxy-s8-dex-desktop-dock-leaks-shows-4k-support-and-built-fan>
