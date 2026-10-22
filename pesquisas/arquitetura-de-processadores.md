# Arquitetura de processadores: fundamentos e aplicação ao S20 FE

Levantamento feito em **2026-10-22**. O foco é explicar como um processador executa código, de onde vem o desempenho e como esses conceitos se aplicam ao Snapdragon 865 do console S20 FE. “Arquitetura” aqui inclui tanto a interface visível ao software quanto a organização interna do chip.

## Resumo executivo

- **ISA** é o contrato de instruções e estados que o software usa; **microarquitetura** é a implementação física desse contrato. Dois chips podem executar o mesmo programa e a mesma ISA, mas ter desempenho, consumo e comportamento térmico diferentes.
- O desempenho de uma tarefa depende de mais que frequência: conta o trabalho por ciclo, paralelismo disponível, previsibilidade dos desvios, acertos de cache, latência da memória, escalonamento e limites de energia/temperatura.
- CPUs modernas sobrepõem etapas do trabalho (pipeline), executam várias operações por ciclo (superscalar) e podem reordenar instruções internamente (execução fora de ordem), preservando a ordem arquitetural observada pelo programa.
- Um processador móvel heterogêneo combina núcleos de capacidades distintas. O sistema operacional decide onde executar tarefas e em que frequência; manter todos os núcleos no máximo não é uma estratégia sustentável.
- No S20 FE, o Snapdragon 865 integra CPU Kryo 585, GPU Adreno 650 e outros blocos do SoC. Os grupos de frequência observados no aparelho são 1,80 GHz, 2,42 GHz e 2,84 GHz. Em emulação, um thread crítico pode limitar o jogo mesmo quando outros núcleos e a GPU estão folgados.
- Para um console de mesa, a métrica útil é o desempenho **sustentado** no jogo real, com temperatura e estabilidade monitoradas — não apenas o pico de frequência ou um benchmark curto.

## 1. O que significa “arquitetura de processador”

O termo cobre várias camadas, que não devem ser confundidas:

| Camada | O que define | Exemplo |
|---|---|---|
| ISA (Instruction Set Architecture) | Instruções, registradores, modos de execução, exceções e regras que compiladores e sistemas precisam respeitar | AArch64, a arquitetura de 64 bits da família Arm |
| Microarquitetura | Como o núcleo implementa a ISA: pipeline, unidades de execução, predição, filas e caches | Um núcleo Arm Cortex-A77 |
| Organização do processador | Como núcleos e caches se agrupam e se comunicam | Clusters de núcleos de alto e baixo consumo |
| SoC (System on Chip) | Integra CPU, GPU, memória, controladores de tela, imagem, áudio, rádio e interconexões | Qualcomm Snapdragon 865 |
| Sistema completo | SoC, memória, firmware, kernel, escalonador, refrigeração e fonte de energia | Galaxy S20 FE executando LineageOS |

**Consequência:** conhecer a ISA permite entender compatibilidade; conhecer a microarquitetura ajuda a explicar o desempenho; e conhecer o sistema inteiro é necessário para explicar o resultado sustentado de um jogo.

### ISA não é sinônimo de “RISC” ou “CISC”

RISC e CISC descrevem tradições de desenho de conjuntos de instruções, não uma previsão direta de velocidade. A ISA pode oferecer instruções simples ou complexas, mas a microarquitetura pode decodificá-las, combiná-las ou traduzi-las em operações internas. O custo real depende da implementação, do compilador e do programa. AArch64, x86-64 e RISC-V são ISAs distintas; nenhuma, isoladamente, determina qual chip será mais rápido em qualquer tarefa.

## 2. Como um núcleo executa instruções

Em termos simplificados, o núcleo busca instruções, decodifica-as, identifica dependências, executa operações e torna seus resultados visíveis ao programa.

### Pipeline

O pipeline divide a execução em etapas e trabalha em várias instruções simultaneamente, cada uma em uma etapa diferente. Isso aumenta a **vazão** (trabalho concluído ao longo do tempo), mas não faz uma única instrução atravessar o pipeline instantaneamente. Dependências, desvios mal previstos e falta de dados podem interromper ou esvaziar etapas.

### Superscalar e execução fora de ordem

Um núcleo superscalar pode iniciar mais de uma operação por ciclo, quando há unidades disponíveis e instruções independentes. A execução fora de ordem permite adiantar instruções que já têm operandos prontos enquanto uma operação anterior aguarda memória. Renomeação de registradores e estruturas como filas de instruções e reorder buffer ajudam a evitar dependências artificiais e a preservar o resultado arquitetural correto.

Isso não significa que o programa inteiro possa ser paralelizado automaticamente: dependências verdadeiras, sincronização e trabalho serial continuam limitando o ganho.

### Desvios e especulação

Desvios condicionais dificultam saber qual instrução buscar em seguida. Preditores tentam antecipar o caminho provável. Se acertarem, o pipeline mantém o fluxo; se errarem, o trabalho especulativo é descartado e há custo de recuperação. A especulação é uma técnica de desempenho, não uma garantia de que o caminho previsto será executado.

### SIMD e operações vetoriais

SIMD (Single Instruction, Multiple Data) aplica uma instrução a vários elementos de dados em paralelo. Em Arm, a família Advanced SIMD/NEON é usada em processamento de imagem, áudio, matemática e partes de bibliotecas. O ganho depende de o programa ter dados adequados, alinhamento e código compilado para usar essas instruções; SIMD não acelera automaticamente qualquer aplicação.

## 3. Hierarquia de memória

A CPU costuma operar muito mais rápido do que a memória externa. O sistema usa níveis de armazenamento menores e mais próximos do núcleo para manter dados acessados recentemente:

1. **Registradores:** operandos diretamente usados pelas instruções; poucos e muito rápidos.
2. **Caches L1:** normalmente próximos de cada núcleo, separados ou organizados para instruções e dados.
3. **Caches L2:** mais capacidade; podem ser privados por núcleo ou compartilhados conforme o projeto.
4. **Cache de último nível (LLC):** pode ser compartilhado por vários núcleos ou blocos do SoC.
5. **RAM:** grande capacidade, mas latência maior; conectada por controladores e interconexões.
6. **Armazenamento:** ainda mais lento; não é memória de trabalho da CPU.

Os detalhes de compartilhamento, tamanhos e latências dependem do chip específico; não se devem deduzir apenas pelo nome da ISA ou da família de núcleos.

- **Localidade temporal:** dados usados recentemente tendem a ser usados novamente.
- **Localidade espacial:** dados próximos aos acessados tendem a ser necessários em seguida.
- **Cache miss:** dado não está no nível consultado, então a busca prossegue em níveis mais lentos. Muitos misses podem deixar unidades de execução ociosas.
- **TLB:** cacheia traduções de endereços virtuais para físicos. Um TLB miss pode exigir consultas às tabelas de páginas.
- **Coerência de cache:** mantém uma visão consistente dos dados quando vários núcleos guardam cópias em seus caches. A coerência tem tráfego e custo; sincronização mal planejada pode prejudicar desempenho.

Por isso, frequência maior não resolve uma tarefa limitada por latência de memória. Também importa distinguir **latência** (tempo para uma resposta) de **largura de banda** (quantidade de dados transferida por unidade de tempo).

## 4. Métricas: frequência, IPC e desempenho real

Uma aproximação para a vazão de instruções é:

> **instruções por segundo ≈ IPC × frequência**

IPC significa instruções concluídas por ciclo. Essa relação é útil para raciocinar, mas não compara diretamente programas diferentes: instruções de ISAs distintas podem realizar trabalhos diferentes, e IPC muda com o código, caches, desvios, concorrência e frequência.

Outras métricas importantes:

- **Latência:** tempo para completar uma tarefa ou operação.
- **Vazão/throughput:** quantidade de trabalho concluído por unidade de tempo.
- **CPI:** ciclos médios por instrução; aproximadamente o inverso do IPC em medições comparáveis.
- **Utilização:** fração de tempo em que um recurso está ocupado. Não mede, por si só, quanto trabalho útil ele conclui.
- **Desempenho por watt:** trabalho útil para a energia consumida; essencial em aparelhos limitados por bateria, fonte e temperatura.
- **Desempenho sustentado:** desempenho após o aquecimento e a estabilização dos limites de potência e temperatura.

A Lei de Amdahl lembra que acelerar apenas uma parte do programa tem retorno limitado:

> **speedup total = 1 / (s + (1 − s) / N)**

` s ` é a fração serial do trabalho e ` N ` o fator de aceleração da parte paralelizável. Se um thread principal precisa executar sequencialmente, adicionar núcleos ou aumentar a velocidade de outra parte não elimina esse gargalo.

## 5. Núcleos heterogêneos, escalonamento e energia

Em processadores móveis, todos os núcleos não são necessariamente equivalentes. Uma configuração heterogênea pode combinar núcleos menores, eficientes em tarefas leves, e núcleos maiores, capazes de maior vazão por thread ao custo de maior potência.

O escalonador do sistema operacional precisa considerar carga, capacidade relativa dos núcleos, afinidade, latência desejada, frequência e estado térmico. A utilização aparente varia com frequência e capacidade: o mesmo trabalho pode ocupar uma proporção diferente de um núcleo mais rápido ou mais lento.

O subsistema CPUFreq do Linux separa, em linhas gerais, o núcleo comum, os algoritmos de seleção (governors) e o driver específico do hardware. Políticas podem agrupar CPUs que compartilham controle de frequência. Portanto, `policy0`, `policy4` etc. são grupos de controle observados pelo kernel, não nomes universais de microarquiteturas.

### DVFS e temperatura

DVFS (Dynamic Voltage and Frequency Scaling) ajusta frequência e tensão conforme a demanda e os limites do sistema. Elevações de frequência podem reduzir o tempo de execução, mas normalmente aumentam potência e calor. Como aproximação didática, a potência dinâmica de um circuito CMOS cresce com a atividade, a capacitância, a tensão ao quadrado e a frequência (`Pdinâmica ∝ α × C × V² × f`); a potência total também inclui fugas e outros blocos.

O controle térmico reduz desempenho ou muda a operação quando necessário para manter o aparelho dentro de limites seguros. Em um telefone, o resultado é determinado pelo conjunto de chip, dissipação, ambiente, carregador e política térmica. **Não se deve desativar o controle térmico**: isso pode danificar o aparelho e não cria capacidade de refrigeração.

## 6. Aplicação ao Snapdragon 865 do Galaxy S20 FE

O S20 FE SM-G780G usa o SoC Qualcomm Snapdragon 865 (SM8250), com CPU da família Kryo 585 e GPU Adreno 650. O perfil do aparelho levantado neste projeto registra três faixas de frequência de CPU: até **1,80 GHz**, **2,42 GHz** e **2,84 GHz**. Essas frequências são dados deste aparelho/kernel, não uma regra geral para todo telefone com Snapdragon 865.

O SoC é mais do que a CPU: GPU, memória, controladores, interconexão e blocos especializados compartilham o orçamento de potência e a capacidade térmica do aparelho. Uma carga gráfica pesada pode reduzir a margem térmica disponível para a CPU, e vice-versa.

### Identificação do chip e da variante do aparelho

O código **SM8250**, nome de plataforma **Kona**, identifica a família do Snapdragon 865. O telefone **SM-G780G** é a variante 4G/LTE do S20 FE com esse Snapdragon; não deve ser confundida com os S20 FE Exynos nem com a variante 5G. A Qualcomm comercializou o 865 como plataforma 5G, mas isso não transforma o G780G em telefone 5G: a plataforma usa o sistema de modem-RF Snapdragon X55, enquanto conectividade efetivamente disponível depende do projeto e da certificação de cada aparelho. A ficha do aparelho lista SM-G780G entre os modelos LTE e associa a versão Snapdragon à CPU A77/A55 e à Adreno 650 [GSMArena — Galaxy S20 FE](https://www.gsmarena.com/samsung_galaxy_s20_fe-10428.php); a página da [Qualcomm — Snapdragon 865](https://www.qualcomm.com/smartphones/products/8-series/snapdragon-865-5g-mobile-platform) descreve os recursos da plataforma, não a configuração de rádio de cada telefone.

### CPU Kryo 585: o arranjo real de oito núcleos

O Kryo 585 é a implementação da Qualcomm baseada em núcleos Arm, não uma ISA diferente. A configuração do S20 FE é:

| Grupo | Núcleos | Microarquitetura | Frequência máxima observada no aparelho | Papel típico |
|---|---:|---|---:|---|
| Desempenho principal | 1 | Arm Cortex-A77 | 2,84 GHz | Thread crítico e rajadas de alto desempenho |
| Desempenho | 3 | Arm Cortex-A77 | 2,42 GHz | Trabalho paralelo exigente |
| Eficiência | 4 | Arm Cortex-A55 | 1,80 GHz | Tarefas leves e trabalho de menor consumo |

É uma topologia **1+3+4** (o marketing por vezes a descreve como “1+3+4 Kryo 585”), não oito núcleos iguais. A Arm posiciona o Cortex-A77 para alto desempenho e o A55 para eficiência; os limites de frequência acima são os expostos pelo firmware/kernel deste telefone, não máximos universais desses núcleos. A topologia e a hierarquia de cache declaradas para Kona também aparecem no [device tree do kernel LineageOS](https://github.com/LineageOS/android_kernel_samsung_sm8250/blob/lineage-23.2/arch/arm64/boot/dts/vendor/qcom/kona.dtsi): caches L1 e L2 por CPU e uma L3 compartilhada referenciada pelos clusters. Esse arquivo não fornece, por si só, tamanhos nem latências; por isso não atribuo capacidades numéricas de cache sem uma fonte específica para o silício.

No aparelho, as políticas CPUFreq agrupam os núcleos nas faixas `policy0`, `policy4` e `policy7`. O scheduler ainda pode migrar threads entre CPUs e alterar clocks conforme carga, energia e temperatura. “Fixar” um thread no núcleo 7 não aumenta a capacidade total do chip e pode atrapalhar o balanceamento se houver contenção; só faz sentido quando uma medição repetível do jogo demonstra benefício.

### GPU Adreno 650 e o que os clocks significam aqui

A Adreno 650 é o bloco gráfico integrado ao SM8250. A frequência máxima observada em configura é **587 MHz**; os níveis medidos incluem 305, 400, 441,6, 490, 525 e 587 MHz. O device tree Qualcomm/Kona do kernel documenta os pontos de operação e os níveis de tensão associados; esse é um retrato da tabela configurada no software, não garantia de que qualquer unidade sustente o ponto máximo continuamente.

Neste projeto, o kernel personalizado acrescentou 625 e 670 MHz ao speed-bin 0 do aparelho (silício v2.1). 625 MHz usa o nível de tensão do ponto de 587 MHz; 670 MHz usa `NOM_L1`, nível já utilizado na tabela Qualcomm para o speed-bin 1. A referência de implementação é [`kona-v2-gpu.dtsi`](https://github.com/LineageOS/android_kernel_samsung_sm8250/blob/lineage-23.2/arch/arm64/boot/dts/vendor/qcom/kona-v2-gpu.dtsi), complementada pelas alterações locais deste projeto. Isso descreve o que foi configurado e testado nesta unidade, não uma especificação oficial de overclock para o SM-G780G.

Resultados locais de 2026-10-12, com o controle térmico mantido:

- **625 MHz:** 20 minutos de 3DMark Wild Life Extreme Stress sem erro de GPU; sem cooler, a temperatura reportada pela GPU atingiu 96 °C.
- **670 MHz:** teste ventilado, resultado de 1.240/1.230 e estabilidade de 99,2%; GPU média de 86 °C e pico de 91 °C, bateria a 37 °C. Não extrapolar esse resultado ventilado para o aparelho fechado ou para sessões mais longas.
- O limite normal escolhido para este aparelho é **625 MHz**. O teto de 670 MHz é experimental e depende de refrigeração e monitoramento; não se deve desativar nem contornar a proteção térmica.

Um clock maior só ajuda se a GPU for o recurso limitante. Se o emulador aguarda um thread de CPU, sincronização ou preparação de comandos, aumentar a Adreno não corrige a causa; tampouco uma GPU em baixa utilização prova que o jogo não esteja limitado por latência/esperas do driver.

### Memória e demais blocos do SoC

Os 6 GB de RAM deste aparelho são memória do sistema, não memória dedicada exclusivamente à GPU. CPU, GPU e outros clientes de hardware disputam largura de banda e energia do subsistema de memória. A plataforma Snapdragon 865 admite LPDDR5 e LPDDR4X, mas isso não basta para concluir o tipo, a organização dos canais ou a largura de banda efetiva do módulo instalado em cada revisão do SM-G780G; esses valores não são tratados aqui como medição do telefone. Do mesmo modo, a capacidade de armazenamento UFS não deve ser confundida com RAM: armazenamento mais rápido reduz tempos de carga, mas não aumenta a largura de banda da memória usada durante a emulação.

Além de CPU e GPU, a Qualcomm enumera no 865:

- **Hexagon 698 / 5ª geração do Qualcomm AI Engine:** DSP com aceleradores escalar, vetorial (HVX) e tensorial; a Qualcomm anuncia até 15 TOPS para a plataforma. TOPS é uma métrica de operações de IA, não uma medida de FPS em jogos.
- **Spectra 480 ISP:** processador de imagem para câmeras, anunciado com processamento de até 2 gigapixels por segundo. Ele não é o renderizador dos jogos.
- **Snapdragon X55 Modem-RF:** capacidade de modem 5G da plataforma; a presença desse bloco não implica suporte 5G no SKU G780G.

Esses blocos especializados podem acelerar suas tarefas próprias, mas não substituem CPU ou GPU para um emulador que não os utiliza. A descrição de capacidades vem da [ficha oficial da Qualcomm](https://www.qualcomm.com/smartphones/products/8-series/snapdragon-865-5g-mobile-platform); números de marketing são máximos da plataforma, não desempenho garantido dentro do telefone.

### Limites práticos e conclusões para este console

O SM8250 é um SoC de telefone de 2020: ainda oferece CPU de alto desempenho, oito núcleos e uma GPU capaz, mas precisa caber no orçamento elétrico e térmico de um aparelho fino. O resultado sustentado é determinado também por dissipador, carcaça, temperatura ambiente, carregador e política térmica do kernel. Um benchmark curto, um clock máximo momentâneo ou o rótulo “865” não predizem por si só como um jogo rodará após aquecimento.

No uso observado neste projeto, o NetherSX2 atingiu cerca de 99% de velocidade média no Guitar Hero III com folga de GPU. Isso aponta para a importância do caminho de emulação e da distribuição de trabalho, e não para uma necessidade geral de elevar clocks. Para um jogo específico, medir a mesma cena em condições térmicas equivalentes é mais informativo que comparar especificações ou resultados de outros modelos.

**Dados deliberadamente não extrapolados:** não atribuo ao SM-G780G tamanhos/latências de cache, largura de banda de RAM medida, potência elétrica máxima do SoC ou clocks sustentáveis universais. As fontes públicas consultadas descrevem o chip ou a plataforma em abstrato; a confirmação desses detalhes exigiria documentação do componente ou medição direta da unidade.

### O que isso significa para emulação

- Emulação frequentemente precisa executar em tempo real uma sequência de operações dependentes para imitar o console original. Um thread crítico pode limitar o quadro mesmo que haja outros núcleos ociosos.
- Muitos núcleos ajudam quando o emulador consegue distribuir trabalho independente, mas não substituem desempenho por thread para partes serializadas.
- A GPU pode ficar pouco ocupada enquanto a CPU prepara cada quadro; elevar a frequência da GPU não resolve um gargalo de CPU.
- O inverso também acontece: resolução interna, filtros ou efeitos podem tornar a GPU limitante, mesmo que a CPU tenha folga.
- Afinidade forçada pode ajudar um workload específico ou piorar o balanceamento do escalonador; deve ser avaliada por jogo e medida sob condições repetíveis.
- Para medir, compare a mesma cena/trecho, resolução, configuração, estado térmico e duração. Registre FPS/velocidade do emulador, uso e frequência de CPU/GPU, temperaturas e estabilidade. Um pico de benchmark curto não substitui essa medição.

No histórico deste projeto, o NetherSX2 alcançou aproximadamente **99% de velocidade média** no Guitar Hero III, enquanto o ARMSX2 mostrou limitações em threads de CPU/GS em testes anteriores. Esse exemplo ilustra que o emulador e o caminho de execução importam tanto quanto a especificação do SoC; não é um benchmark universal nem uma comparação controlada de todas as versões.

### Implicações para o console de mesa

1. Priorizar estabilidade térmica e desempenho sustentado durante sessões longas.
2. Medir jogos reais antes de alterar frequência, afinidade ou qualidade gráfica.
3. Identificar se o limite é CPU, GPU, memória, sincronização do emulador ou temperatura antes de escolher um ajuste.
4. Tratar overclock como margem experimental, não como aumento garantido de desempenho: tensão, calor e limites do chip podem anular o ganho.
5. Preservar as proteções térmicas e avaliar alterações de uma em uma, com possibilidade de reversão.

## 7. Vocabulário essencial

| Termo | Significado prático |
|---|---|
| Núcleo (core) | Unidade capaz de executar instruções; vários núcleos podem trabalhar em tarefas distintas |
| Thread | Fluxo de execução de software; o sistema pode escaloná-lo em núcleos diferentes |
| Clock/frequência | Ciclos por segundo, normalmente expressos em GHz; não equivale diretamente a instruções por segundo |
| Pipeline | Etapas sobrepostas de execução |
| IPC | Instruções concluídas por ciclo, dependente da carga |
| Cache miss | Dado não encontrado no nível de cache consultado |
| Latência | Tempo para obter uma resposta |
| Largura de banda | Volume de dados transferido por unidade de tempo |
| DVFS | Ajuste dinâmico de tensão/frequência |
| Throttling | Redução de desempenho para respeitar limites térmicos ou elétricos |
| SoC | Chip que integra CPU, GPU e outros componentes do sistema |
| Acelerador | Bloco especializado, como GPU/NPU, otimizado para classes específicas de operações |

## 8. Roteiro de estudo sugerido

1. Diferenciar ISA, microarquitetura, CPU e SoC.
2. Estudar pipeline, hazards, predição de desvios, execução fora de ordem e SIMD.
3. Aprender hierarquia de memória, caches, TLB, coerência e memória virtual.
4. Comparar latência, vazão, IPC, frequência e desempenho por watt.
5. Estudar paralelismo, escalonamento heterogêneo, DVFS e limites térmicos.
6. Aplicar os conceitos a um jogo, usando medições sustentadas e variando uma configuração por vez.

Para uma comparação dessas ideias em consoles clássicos e portáteis, consulte [arquitetura-processadores-consoles.md](arquitetura-processadores-consoles.md), que aborda PS2, PSP, PS Vita, Xbox 360 e Nintendo Switch.

## Fontes

Fontes primárias e documentação técnica consultadas. As páginas de referência da Arm redirecionam para o portal de documentação; podem exigir navegação ou conta para acessar o manual completo.

- [Arm — arquitetura de CPU](https://www.arm.com/architecture/cpu): visão geral das famílias Cortex-A, Cortex-R, Cortex-M e Neoverse.
- [Arm — Cortex-A77](https://developer.arm.com/Processors/Cortex-A77) e [documentação técnica Cortex-A77](https://developer.arm.com/documentation/100798/latest/).
- [Arm — Cortex-A55](https://developer.arm.com/Processors/Cortex-A55) e [documentação técnica Cortex-A55](https://developer.arm.com/documentation/100442/latest/).
- [Qualcomm — Snapdragon 865 5G Mobile Platform](https://www.qualcomm.com/smartphones/products/8-series/snapdragon-865-5g-mobile-platform): recursos declarados da plataforma, incluindo Kryo 585, Adreno 650, Hexagon 698, Spectra 480 e X55.
- [LineageOS — device tree Kona](https://github.com/LineageOS/android_kernel_samsung_sm8250/blob/lineage-23.2/arch/arm64/boot/dts/vendor/qcom/kona.dtsi) e [tabela de pontos de operação da GPU](https://github.com/LineageOS/android_kernel_samsung_sm8250/blob/lineage-23.2/arch/arm64/boot/dts/vendor/qcom/kona-v2-gpu.dtsi): topologia e configuração de hardware expostas pelo kernel; não substituem documentação elétrica do fabricante.
- [GSMArena — Samsung Galaxy S20 FE](https://www.gsmarena.com/samsung_galaxy_s20_fe-10428.php): fonte secundária usada para distinguir os modelos e conferir especificações do SM-G780G; não é documentação primária da Samsung.
- [Arm — tecnologia big.LITTLE](https://www.arm.com/technologies/big-little): motivação para combinar núcleos de desempenho e eficiência.
- [Qualcomm — Snapdragon 865 5G Mobile Platform](https://www.qualcomm.com/products/mobile/snapdragon/smartphones/snapdragon-8-series-mobile-platforms/snapdragon-865-5g-mobile-platform): descrição oficial da plataforma.
- [Linux kernel — CPU Performance Scaling](https://docs.kernel.org/admin-guide/pm/cpufreq.html): frequência, drivers, governors e políticas CPUFreq.
- [Linux kernel — Scheduler capacity awareness](https://docs.kernel.org/scheduler/sched-capacity.html): capacidade heterogênea e utilização de tarefas.
- [Linux kernel — Thermal framework](https://docs.kernel.org/driver-api/thermal/index.html): infraestrutura térmica do kernel.
- [RISC-V International — especificações ratificadas](https://riscv.org/specifications/ratified/): exemplo de especificação pública de ISA, útil para separar ISA de microarquitetura.
- [MIT OpenCourseWare — 6.823 Computer System Architecture](https://ocw.mit.edu/courses/6-823-computer-system-architecture-fall-2005/pages/lecture-notes/): material universitário de arquitetura de sistemas.

As frequências e observações de emulação do S20 FE nesta pesquisa vêm do levantamento técnico registrado no projeto; não foram inferidas das páginas de marketing dos fabricantes.
