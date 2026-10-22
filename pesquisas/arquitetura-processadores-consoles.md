# Arquitetura dos processadores de PSP, PS Vita, PS2, Xbox 360 e Nintendo Switch

Pesquisa feita em **2026-10-22**. O foco é a arquitetura de CPU e os aceleradores relevantes para jogos, não uma comparação de potência baseada apenas em frequência. Os consoles empregam desenhos de épocas e objetivos diferentes; clocks, memória e recursos variam entre revisões de hardware e políticas de software.

## Visão comparativa

| Console | CPU principal | ISA / família | GPU ou aceleradores principais | Ideia arquitetural |
|---|---|---|---|---|
| PlayStation 2 | Emotion Engine com núcleo Toshiba/Sony R5900; IOP separado | MIPS III estendida, instruções SIMD proprietárias | VU0 e VU1 no Emotion Engine; Graphics Synthesizer separado | CPU e unidades vetoriais especializadas trabalham em paralelo para preparar geometria e renderização |
| PSP | Allegrex, um núcleo principal; Media Engine separado | MIPS32 baseado na família R4000 | VFPU no Allegrex e Graphics Engine dedicado | CPU MIPS compacta com extensão vetorial e bloco de mídia |
| PS Vita | Quatro ARM Cortex-A9 | ARMv7-A, 32 bits | PowerVR SGX543MP4+ e blocos especializados; hardware legado para compatibilidade PSP | Arquitetura móvel multicore mais convencional, com GPU integrada ao SoC |
| Xbox 360 | IBM/Sony/Microsoft Xenon, três núcleos | PowerPC personalizado de 64 bits | SIMD VMX128 em cada núcleo; GPU Xenos separada | Três núcleos in-order com multithreading simultâneo e forte trabalho vetorial |
| Nintendo Switch | Tegra X1/T210, quatro Cortex-A57 acessíveis ao console | ARMv8-A, 64 bits | GPU NVIDIA Maxwell GM20B, 256 núcleos CUDA | SoC móvel ARM com CPU e GPU integradas e memória principal compartilhada |

> **Atenção às comparações:** o “128-bit” associado ao PS2 não significa que ele tenha uma CPU de 128 bits no sentido moderno. É uma referência a caminhos/registros e às operações SIMD de 128 bits. A ISA principal do R5900 é MIPS III de 64 bits, com extensões próprias. Da mesma forma, contar núcleos, medir MHz ou somar FLOPS não prevê sozinho o desempenho em jogos.

## PlayStation 2 — Emotion Engine

### CPU e unidades de cálculo

O **Emotion Engine (EE)**, desenvolvido por Toshiba e Sony, opera em aproximadamente **294,9 MHz**. Seu núcleo principal é o **R5900**, derivado de MIPS, com ISA MIPS III e extensões de MIPS IV e da Sony. O núcleo é superscalar de emissão limitada e execução **in-order**: em geral, não reordena dinamicamente instruções pendentes como fazem CPUs modernas fora de ordem.

O R5900 acrescenta instruções SIMD inteiras chamadas **MMI** (Multimedia Instructions), que operam em registradores de 128 bits divididos em elementos menores — por exemplo, vários inteiros de 32 bits processados em paralelo. Isso acelerava matemática usada em gráficos e animação, mas não transforma a CPU em “128-bit” para endereçamento ou para toda operação.

O EE integra duas **Vector Processing Units (VU0 e VU1)**:

- **VU0** tem uso mais geral e pode trabalhar estreitamente com a CPU.
- **VU1** foi projetada para executar transformações geométricas e outras cargas vetoriais em paralelo, alimentada por programas/microcódigo.
- As listas de comandos geradas pelo EE e pelas VUs seguem ao **Graphics Interface (GIF)** e daí ao **Graphics Synthesizer (GS)**, o chip de renderização separado.

Esse desenho desloca parte do trabalho para unidades vetoriais explícitas. O jogo e o motor gráfico precisam distribuir o trabalho para aproveitá-las; não é uma CPU generalista com muitos núcleos.

### I/O, memória e implicações

O **IOP (Input/Output Processor)** é outro processador, separado do EE, dedicado a entrada/saída e à compatibilidade com componentes da geração anterior. O PS2SDK reflete essa divisão em seus diretórios e ferramentas de EE e IOP. O sistema combina **32 MiB de RDRAM** como memória principal e **4 MiB de eDRAM** local no GS; portanto, “o processador” não descreve sozinho o sistema.

**Para emulação:** um emulador precisa reproduzir não só instruções MIPS, mas também o comportamento das VUs, sincronização entre unidades, DMA, IOP e GS. Uma cena pode ser limitada pela tradução das instruções vetoriais, pelo sincronismo ou pela renderização, e não simplesmente pela velocidade nominal da CPU original.

## PSP — Allegrex e Media Engine

### CPU principal e extensão vetorial

O **Allegrex** é uma implementação personalizada de **MIPS32**, baseada na família MIPS R4000. É um processador de um núcleo com unidade de ponto flutuante e uma **VFPU** (Vector Floating Point Unit), que oferece operações vetoriais para tarefas como transformações 3D.

O clock configurável alcança **333 MHz**, mas a frequência usada por jogos variou com firmware, modelo, política de energia e título. Por isso, 333 MHz deve ser entendido como máximo conhecido da plataforma, não como clock constante de todos os jogos.

### Media Engine e Graphics Engine

A PSP inclui um segundo bloco chamado **Media Engine**, com outro núcleo MIPS e hardware para tarefas de mídia, além de um processador de sinal digital. Ele não é simplesmente “um segundo núcleo de jogo” idêntico e livre para o código principal: sua função e recursos são especializados.

O **Graphics Engine** da PSP é um acelerador gráfico próprio, separado da VFPU. O software pode usar a VFPU para preparar dados e o Graphics Engine para tarefas gráficas; dividir corretamente o trabalho entre CPU, vetores e GPU é importante.

### Memória e implicações

A PSP original tem **32 MiB** de RAM principal; modelos PSP-2000 e posteriores passaram a **64 MiB**. Há também memória embarcada dedicada a componentes gráficos e de mídia, e caches/scratchpad para a CPU.

**Para emulação:** o Allegrex mantém afinidade com MIPS e compartilha conceitos com processadores de consoles anteriores, mas a PSP combina instruções específicas, VFPU, Graphics Engine e Media Engine próprios. Um emulador pode usar JIT para traduzir código MIPS; a compatibilidade e o desempenho também dependem de reproduzir os serviços e sincronização desses aceleradores.

## PS Vita — Cortex-A9 e PowerVR

### CPU e GPU

A CPU principal do PS Vita é um conjunto de **quatro núcleos ARM Cortex-A9 MPCore**, com ISA **ARMv7-A de 32 bits**. É uma mudança importante em relação à linhagem MIPS usada por Sony no PS2 e no PSP. O Cortex-A9 é uma CPU de aplicação generalista, com execução dinâmica mais avançada e suporte a processamento vetorial NEON.

A GPU principal é a **PowerVR SGX543MP4+**, da Imagination Technologies. “MP4” identifica uma configuração multicore da família SGX; não deve ser interpretado como quatro núcleos de CPU. O SoC reúne ainda blocos especializados de mídia, segurança e conectividade.

### Compatibilidade com PSP

O hardware do Vita preserva circuitos da plataforma PSP, incluindo componentes MIPS e o Graphics Engine, para executar software PSP em um ambiente de compatibilidade. Essa parte legada é distinta da CPU Cortex-A9 que roda o sistema Vita. Em outras palavras, a compatibilidade não decorre de o Vita ter uma CPU principal MIPS.

O dispositivo é frequentemente descrito com **512 MiB de RAM principal e 128 MiB de memória gráfica**. Em artigos e diagramas, a memória integrada pode aparecer como cerca de 640 MiB no total; isso não significa que jogos tenham um único bloco irrestrito de memória disponível.

### Clock e implicações

Frequências efetivas dependem de políticas de energia, temperatura e software; valores de clock citados em fóruns ou ferramentas de homebrew não devem ser tratados como especificação oficial universal da Sony.

**Para emulação:** o PS Vita tem CPU ARMv7 e GPU PowerVR, ao passo que o Snapdragon 865 do S20 FE usa ARMv8-A e GPU Adreno. A proximidade da família de instruções pode facilitar certos caminhos de tradução de CPU, mas não garante compatibilidade ou ganho automático: APIs gráficas, chamadas do sistema, segurança e os aceleradores proprietários continuam diferentes.

## Xbox 360 — Xenon e Xenos

### CPU Xenon

O **Xenon**, projetado por IBM para a Microsoft, tem **três núcleos PowerPC personalizados**, operando a **3,2 GHz**. Cada núcleo suporta **dois threads de hardware** por simultaneidade de multithreading (SMT), totalizando até seis threads de hardware.

O Xenon usa execução **in-order**, uma escolha que reduz complexidade e área em relação a um núcleo fora de ordem. A arquitetura procura obter vazão por meio de três núcleos, dois contextos de thread por núcleo e operações vetoriais. Isso desloca parte da responsabilidade para os desenvolvedores: código com dependências longas ou pouca paralelização pode não aproveitar todos os recursos.

Cada núcleo possui unidade vetorial **VMX128**, variante personalizada de VMX/AltiVec com instruções e recursos direcionados aos jogos, incluindo operações de produto escalar. O processador possui caches L1 por núcleo e cache L2 compartilhado; a hierarquia e as políticas foram ajustadas para tráfego de jogos.

### GPU, memória e implicações

A GPU **Xenos**, da ATI, é um componente separado do Xenon. Ela foi notável pela arquitetura de shaders unificados e por **10 MiB de eDRAM** local de alta largura de banda, usada para operações de renderização, como antialiasing. A memória principal de **512 MiB** é compartilhada pelo sistema, embora a divisão de uso entre CPU e GPU seja gerenciada pela plataforma.

**Para emulação:** a ISA PowerPC e as instruções vetoriais personalizadas diferem de ARM e MIPS. Além da CPU de três núcleos e do SMT, um emulador precisa modelar temporização, sincronização e comportamento da GPU Xenos. A frequência de 3,2 GHz não se compara diretamente a 3,2 GHz de uma CPU ARM: microarquitetura, IPC, ISA e características do workload não são iguais.

## Nintendo Switch — NVIDIA Tegra X1

### CPU do SoC e revisões

O Switch original usa um SoC NVIDIA da família **Tegra X1/T210**, com CPU ARMv8 de 64 bits. O Tegra X1 comercial integra dois clusters — quatro **Cortex-A57** e quatro **Cortex-A53** — mas o console de produção usa os núcleos A57; os A53 não são disponibilizados aos jogos como um cluster adicional utilizável. Isso é uma diferença entre a composição geral do SoC e a configuração efetiva do console.

O modelo atualizado do Switch (revisão conhecida como Mariko) usa uma revisão mais eficiente do chip, associada à família Tegra X1+, com processo de fabricação e envelope térmico diferentes. Os clocks de CPU/GPU também são ajustados pela Nintendo conforme modo portátil/dock, temperatura, carga e versão do sistema. Não há um único clock que descreva todos os jogos e estados.

### GPU e memória unificada

A GPU é baseada em **NVIDIA Maxwell**, identificada como GM20B, com **256 núcleos CUDA** no Tegra X1. Esse número é uma contagem de unidades de execução da GPU NVIDIA; não é diretamente comparável à contagem de unidades de outras GPUs.

O Switch tem **4 GiB de LPDDR4** usada como memória de sistema compartilhada entre CPU e GPU. A documentação do Tegra X1 indica suporte a LPDDR4 de 64 bits, com largura de banda teórica de até cerca de **25,6 GB/s** sob a configuração correspondente. A quantidade reservada ao sistema e aos serviços faz com que nem toda a memória física fique disponível para o jogo.

### Implicações

**Para emulação:** o Switch é o mais próximo do S20 FE em família de ISA entre estes cinco consoles: ambos usam software ARM de 64 bits. Isso não torna o Switch trivial de emular. O console tem GPU Maxwell e memória unificada; o S20 FE usa Adreno 650 e uma pilha Android diferente. Tradução de CPU pode aproveitar semelhanças ARM, mas o sistema operacional, APIs gráficas, GPU, firmware e sincronização ainda precisam ser reproduzidos.

## O que muda entre essas arquiteturas

1. **ISA e legado:** PS2 e PSP são baseados em MIPS; Vita usa ARMv7-A; Xbox 360 usa PowerPC personalizado; Switch usa ARMv8-A.
2. **Estilo de paralelismo:** PS2 depende fortemente de VUs e microprogramas vetoriais; PSP combina Allegrex, VFPU e processadores especializados; Vita e Switch têm CPUs ARM multicore generalistas e GPUs integradas ao SoC; Xbox 360 combina três núcleos PowerPC SMT e instruções VMX128.
3. **CPU não é GPU:** Emotion Engine, Allegrex, Cortex-A9, Xenon e Cortex-A57 são CPUs; Graphics Synthesizer, Graphics Engine, SGX543, Xenos e Maxwell são unidades gráficas distintas, embora possam compartilhar memória ou colaborar estreitamente.
4. **Frequência não equivale a desempenho:** IPC, execução in-order/fora de ordem, vetorização, cache, memória, paralelismo, compilador e limites de potência mudam o trabalho por ciclo e a capacidade sustentada.
5. **Emular não é apenas traduzir instruções:** dispositivos, temporização, áudio, GPU, memória, serviços de sistema e comportamento específico de jogos fazem parte da compatibilidade.

## Relação com o S20 FE e o projeto de console

O Snapdragon 865 do S20 FE executa ARMv8-A, como o Switch, mas seus núcleos Cortex-A77/A55 e a GPU Adreno 650 são diferentes dos A57/Maxwell do Tegra X1. Portanto, um emulador para Switch não ganha automaticamente desempenho por “rodar ARM”. Para o restante da biblioteca, a diferença de ISA e de aceleradores importa:

- **PS2:** atenção a VUs, JIT de MIPS, sincronização e configuração gráfica do emulador. O resultado observado no projeto variou bastante entre emuladores; o NetherSX2 foi escolhido após testes do Guitar Hero III e do Black.
- **PSP:** a CPU relativamente simples pode ser traduzida eficientemente, mas VFPU, Graphics Engine, Media Engine e compatibilidade por jogo continuam relevantes.
- **PS Vita:** arquitetura ARMv7 anterior, com GPU PowerVR e ambiente proprietário; instruções ARM compartilhadas em alto nível não significam que jogos Vita sejam diretamente executáveis no Android.
- **Xbox 360:** três núcleos PowerPC e VMX128 tornam a emulação em ARM móvel especialmente dependente de tradução de CPU e de uma implementação de GPU muito completa; a frequência nominal mais alta não é comparável diretamente.
- **Switch:** ISA ARMv8 próxima em categoria, mas GPU e sistema distintos; capacidade de emulação deve ser medida por jogo e versão do emulador.

Esses pontos são orientação arquitetural, não promessa de compatibilidade. Para decidir o que o S20 FE roda bem, o critério correto é teste real em versões específicas, registrando velocidade, FPS, consumo, temperatura e estabilidade — mantendo ativa a proteção térmica.

## Fontes

### Análises técnicas por console

- Rodrigo Copetti, [PlayStation 2 Architecture](https://www.copetti.org/writings/consoles/playstation-2/): Emotion Engine, R5900, VUs e Graphics Synthesizer, com bibliografia técnica.
- Rodrigo Copetti, [PlayStation Portable Architecture](https://www.copetti.org/writings/consoles/playstation-portable/): Allegrex, VFPU, Media Engine, Graphics Engine e memória.
- Rodrigo Copetti, [PlayStation Vita Architecture](https://www.copetti.org/writings/consoles/playstation-vita/): Cortex-A9, SGX543MP4+, componentes legados e organização do SoC.
- Rodrigo Copetti, [Xbox 360 Architecture](https://www.copetti.org/writings/consoles/xbox-360/): Xenon, PowerPC, threads, VMX e contexto da GPU.

### Documentação e referências complementares

- [PS2SDK Documentation](https://ps2dev.github.io/ps2sdk/): separação prática entre SDK e componentes de EE e IOP.
- [PSPSDK Documentation](https://pspdev.github.io/pspsdk/): bibliotecas e interface para o Graphics Engine da PSP.
- [Switchbrew — Tegra X1/X1+ SoC Specifications](https://switchbrew.org/wiki/Tegra_X1): especificações do Tegra, clusters de CPU, caches, memória e GPU; referência comunitária técnica baseada em documentação e engenharia reversa, não uma ficha oficial da Nintendo.
- [NVIDIA — Jetson TX1](https://developer.nvidia.com/embedded/jetson-tx1): referência oficial da plataforma Tegra X1/Maxwell; TX1 é relacionado ao SoC Tegra X1, mas não é o produto Switch.
- [Nintendo — especificações técnicas do Switch](https://www.nintendo.com/us/gaming-systems/switch/tech-specs/): fonte oficial sobre modos de uso e consumo do console; não publica a ficha detalhada de CPU/GPU.

## Limitações e cuidado com números

Os fabricantes não publicaram uma especificação completa e uniforme de todas as microarquiteturas dos consoles. Parte dos detalhes vem de documentação de desenvolvimento, material técnico histórico e análise de hardware. Clocks efetivos de Vita, Switch e PSP variam ou são limitados por software; configurações de memória mudam por revisão e pelo que o jogo pode reservar. Onde os números variam, o texto separa capacidade do SoC, configuração do console e frequência máxima divulgada, em vez de apresentar um único valor como constante.
