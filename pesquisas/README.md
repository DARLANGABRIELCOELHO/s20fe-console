# Pesquisas: celular como "box" / mini PC / console (estilo DeX)

Levantamento feito em **2026-10-22**, a partir do perfil **DEX LOR (@samsungdexlor)** e ampliado para tudo o que achei na internet sobre transformar celular (sobretudo Samsung) em box de mesa: criadores de conteúdo, produtos, alimentação sem bateria, refrigeração e software.

> Limitações: o TikTok só mostra legendas sem login (o conteúdo dos vídeos não foi visto); números de seguidores/visualizações são os exibidos em 2026-10-22. Fóruns e TikTok são relatos, não testes controlados.

## Arquivos

| Arquivo | Assunto |
|---|---|
| [criadores-box-dex.md](criadores-box-dex.md) | Quem faz box/gabinete DeX: Vietnã (DEX LOR, Dex Max, Hedra Farm…), Brasil (Brothers Repair, MeuNerdOFC, Rudson…), outros países |
| [alimentacao-sem-bateria.md](alimentacao-sem-bateria.md) | Rodar o celular direto na fonte, bateria falsa, ligar sozinho ao receber energia, bypass de carga |
| [refrigeracao.md](refrigeracao.md) | Ventoinha, dissipador, Peltier ("sò lạnh") e condensação, gabinetes com cooler |
| [foruns-e-comunidades.md](foruns-e-comunidades.md) | Reddit, XDA, 4PDA, EEVblog, Clube do Hardware, Lemmy etc.: **ETA Prime com um S20 FE**, métodos sem bateria, inchaço, ligar ao conectar, tela quebrada |
| [ligar-ao-conectar.md](ligar-ao-conectar.md) | Ligar sozinho ao receber energia: análise do `magisk-autoboot`, como o S20 FE entra no modo de carga, rascunho e plano de teste |
| [software-dex-e-console.md](software-dex-e-console.md) | Ferramentas que os criadores usam (Shizuku, SamHelper, Galaxy Max Hz, K2er), modo desktop do Android 16, projetos de console com celular, dicas de dock na TV |
| [arquitetura-de-processadores.md](arquitetura-de-processadores.md) | Fundamentos de CPU/SoC, desempenho, energia e aplicação ao Snapdragon 865 do S20 FE |
| [arquitetura-processadores-consoles.md](arquitetura-processadores-consoles.md) | Arquiteturas de CPU, GPU e aceleradores do PS2, PSP, PS Vita, Xbox 360 e Nintendo Switch |

## Resumo em 10 linhas

1. Existe uma **cena grande e comercial** de "box DeX": no **Vietnã** (lojas que recebem o celular do cliente e devolvem montado num box, desde ~1.000.000 VND) e no **Brasil** ("mobilador", "setup DeX", "gabinete DeX"; Brothers Repair tem 333,8 mil seguidores).
2. O aparelho típico é **Samsung com tela quebrada** (Z Fold 2–5, S10, S20/S20+, S21, Note 20). **O S20 FE aparece várias vezes nos gabinetes brasileiros** (MeuNerdOFC, DexLab).
3. Quase todos usam **One UI + DeX** e apps Android com teclado/mouse (PUBG, Delta Force). Ninguém achado usa ROM própria, kernel com OC de GPU ou frontend de emulação como nós.
4. Os vietnamitas mais avançados fazem **alimentação direta sem bateria**, **ligar sozinho quando chega energia** e ventoinha controlável. Os detalhes técnicos não são publicados (atendem "no privado").
5. Quem roda sem bateria relata **desligamentos em picos de consumo** (DEX LOR com alto-falante no máximo; o Galaxy S5 do yaky.dev com a câmera). Solução documentada: fonte de ≥ 2 A, diodo, termistor simulado e capacitor.
6. **Peltier** é usado (Dex Max, "Samsung DeX" @samsungdex29) com controle automático contra condensação — confirma o motivo de termos descartado o Peltier.
7. Os gabinetes brasileiros usam **cooler de 80 mm**, step-down e fonte de 5 V/12 V, o mesmo caminho da nossa opção B (ver `hardware/README.md`).
8. O **Android 16 QPR3** trouxe modo desktop oficial em telas externas (base do DeX), mas só em Pixel e Samsung recentes; no AOSP existe a opção de desenvolvedor "Forçar modo desktop".
9. Projeto mais parecido com o nosso fora da cena DeX: **Pixel 8 com tela defeituosa virou console retrô** (hub, ventoinha de 50 mm, ES-DE, controles com fio).
10. **ETA Prime** (1,4 mi de inscritos) fez um mini PC com um **S20 FE de tela quebrada** (US$ 70 no eBay, case de Raspberry Pi com cooler torre): God of War II no NetherSX2 a 2x com quedas (sugere 1,75x), GameCube bom, sem throttling com o cooler. Ver [foruns-e-comunidades.md](foruns-e-comunidades.md).
11. Ideias para o nosso console: ligar sozinho ao receber energia (Fase 4 / módulo Magisk), rodar sem bateria (só se a bateria inchar; arriscado), e referências de gabinete.

## O que pode entrar no projeto (a avaliar, nada foi feito)

- **Ligar ao conectar a fonte** — essencial para o "plug and play". Opções: módulo `magisk-autoboot` (anasfanani) ou alterar o modo de carga (LPM/`charger`) na ROM própria. Ver [alimentacao-sem-bateria.md](alimentacao-sem-bateria.md#ligar-sozinho-quando-chega-energia).
- **Gabinete**: comparar o nosso projeto de case (`hardware/README.md`) com os gabinetes da Brothers Repair, do Rudson e o impresso em 3D do Jonathan Miranda.
- **Sem bateria**: manter o limite de carga em 80% (já ativo). A bateria falsa só faz sentido se a bateria degradar/inchar, e desliga a proteção térmica da bateria (contraria a regra 5 do `CLAUDE.md` se for mal feita).
