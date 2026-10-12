# Galaxy S20 FE como console de mesa

Projeto para transformar o Galaxy S20 FE **SM-G780G** (Snapdragon 865, codinome `r8q`) num videogame de mesa ligado à TV, no estilo Batocera: desbloqueia o bootloader, grava o sistema e o aparelho já liga direto no menu de jogos.

Base: LineageOS 23.2 oficial (`r8q` variant1) + root com Magisk, com foco em desempenho de GPU (Adreno 650), frontend de console e emuladores.

O diário completo do projeto (estado do aparelho, procedimentos, problemas investigados e plano por fases) está em [CLAUDE.md](CLAUDE.md).

## O que não está neste repositório

Por segurança e direitos autorais, ficam só no PC local:

- `backup/`: dump das partições do aparelho (inclui `efs`/`persist`, com IMEI)
- `firmware/`: firmware stock da Samsung
- `lineage/*.img`, `*.zip`: imagens do LineageOS e do Magisk (baixe das fontes oficiais; os `SHA256SUMS` estão aqui para conferência)
- `apps/`, `samloader/`, `scrcpy/`, `source/`, `build/`: APKs, ferramentas e código-fonte de terceiros

BIOS e ROMs de jogos não fazem nem farão parte do projeto.

## Aviso

Desbloquear o bootloader e gravar partições pode inutilizar o aparelho e apaga os dados. Faça backup e use por sua conta e risco.
