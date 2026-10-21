# Integração com ferramentas da NookieAI

Notas para usar as ferramentas da [NookieAI](https://github.com/NookieAI) no preparo da biblioteca do console S20 FE.

## Ferramentas relacionadas

- [RetroForge](https://github.com/NookieAI/RetroForge): prepara bibliotecas retro no computador, com capas, descrições, organização de nomes e exportação para frontends como ES-DE. É relevante para sistemas retro presentes em `Games/<sistema>`.
- [Kura](https://github.com/NookieAI/kura): identifica arquivos PlayStation pelos metadados internos e organiza bibliotecas PS1, PS2 e PSP, além de outros consoles PlayStation. A transferência de rede descrita pelo Kura é voltada a consoles PlayStation; para este projeto, o uso previsto é organizar e conferir arquivos no PC antes de copiá-los para o S20 FE.

## RetroForge → Pegasus

O RetroForge exporta listas de jogos no formato ES-DE. O script [`import_retroforge.py`](import_retroforge.py) converte uma exportação `gamelist.xml` para os blocos `game:` e as mídias que `tools/gen-pegasus.py` já importa.

```sh
# Um sistema; use o código ES-DE, não o nome exibido na interface.
python tools/integracao-nookie/import_retroforge.py /caminho/para/snes --system snes

# Verifique o resultado do gerador antes de gravar metadados no aparelho.
python tools/gen-pegasus.py --media ~/s20fe-build/nookieai/out --dry-run
```

Para uma exportação com uma pasta por sistema, passe a pasta raiz sem `--system`; os nomes das subpastas serão usados como códigos de sistema. A saída fica em `~/s20fe-build/nookieai/out` por padrão. O conversor não copia jogos nem altera a origem. Ele copia as mídias referenciadas para a pasta de saída e preserva os campos encontrados no XML: título, descrição, desenvolvedor, publicadora, gênero, jogadores, data, nota, capa, logo, vídeo e outras imagens compatíveis.

O gerador do Pegasus ainda precisa de ADB para consultar os sistemas e jogos no aparelho. `--dry-run` impede gravações, mas não elimina essas consultas.

## Android e ARM64

- `import_retroforge.py` usa apenas a biblioteca padrão do Python, portanto pode rodar em ARM64 pelo Python do Termux. Ele prepara os metadados no formato consumido pelo `tools/gen-pegasus.py`; o fluxo documentado ainda termina no PC, onde o gerador consulta e atualiza o Pegasus via ADB.

### O que “portar para ARM/Android” significa

| Caminho | O que entrega | Estado e limite |
| --- | --- | --- |
| Python no Termux | Conversor RetroForge → metadados Pegasus | Viável agora em ARM64; não executa a interface do RetroForge/Kura e ainda depende do gerador Pegasus no PC. |
| Linux ARM64 no Android | Aplicativo desktop dentro de um userland Linux, como Debian no Termux/PRoot | Experimento possível se existir um build Linux ARM64. Continua sendo aplicativo Linux, exige ambiente gráfico e bibliotecas Linux. |
| Linux x86-64 via Box64 | Aplicativo Linux x86-64 traduzido durante a execução | Possível em alguns programas, não é recompilação nem APK; compatibilidade de Electron, módulos nativos, bibliotecas e interface gráfica precisa ser validada. |
| APK Android ARM64 | Aplicativo instalado e integrado ao Android | Requer portar a interface, armazenamento e recursos do sistema para Android e empacotar bibliotecas na ABI `arm64-v8a`; não sai de uma simples troca de arquitetura. |

ARM64 descreve a CPU, mas não torna equivalentes um executável Linux e um aplicativo Android. O NDK empacota bibliotecas nativas por ABI, como `arm64-v8a`; o build Electron Linux ARM64 continua dependendo do ambiente Linux. O Kura marca o projeto como Electron, e a documentação do Electron lista builds para Windows, macOS e Linux, não uma plataforma Android. Um APK nativo exigiria uma camada Android própria, além da compilação ARM64.

### O que falta para portar os aplicativos Nookie

- As árvores públicas consultadas não trazem o código das aplicações. O [RetroForge](https://github.com/NookieAI/RetroForge/tree/v0.6.4) tem README e imagens; o [Kura](https://github.com/NookieAI/kura/tree/v1.6.50) tem README e changelog. Os arquivos “Source code” automáticos do GitHub representam essas árvores e não incluem o projeto de aplicação necessário para recompilar.
- As releases oferecem AppImages Linux sem a arquitetura no nome. O utilitário [`inspect_appimage_arch.py`](inspect_appimage_arch.py) lê o cabeçalho ELF localmente, sem executar o arquivo:

  ```sh
  python tools/integracao-nookie/inspect_appimage_arch.py /caminho/RetroForge-linux.AppImage
  ```

  Nesse caso, o resultado identifica o ELF externo do AppImage. Para listar os ELFs internos, passe uma AppDir já extraída. Ainda não há binário da release neste workspace, então não presumo que seja x86-64 ou ARM64.
- Para um APK próprio, seria necessário obter os fontes reais (ou uma autorização e um pacote com fontes do mantenedor), identificar módulos nativos e trocar as operações de arquivos por fluxos compatíveis com o armazenamento Android, incluindo o Storage Access Framework quando necessário.

Fontes técnicas: [ABIs do Android NDK](https://developer.android.com/ndk/guides/abis), [arquiteturas e plataformas do Electron](https://www.electronjs.org/docs/latest/tutorial/installation) e [Box64](https://github.com/ptitSeb/box64).

## Fluxo previsto

1. Baixar a versão apropriada para Windows, Linux ou macOS nas páginas oficiais de [releases do RetroForge](https://github.com/NookieAI/RetroForge/releases) e [releases do Kura](https://github.com/NookieAI/kura/releases).
2. Apontar cada aplicativo para a pasta da biblioteca que ele consegue tratar. Fazer primeiro uma cópia de segurança dos arquivos importantes.
3. Usar RetroForge nos sistemas retro compatíveis e exportar para ES-DE; converter a pasta exportada com `import_retroforge.py`.
4. Usar Kura para identificar e organizar a biblioteca PlayStation no PC. Conferir nomes, capas e caminhos antes de copiar os resultados para `Games/<sistema>` no aparelho.
5. Gerar os metadados com `tools/gen-pegasus.py --media ~/s20fe-build/nookieai/out` e validar no S20 FE se os jogos abrem no emulador correto e se as imagens aparecem no Pegasus.

## Limites e validação

- Os aplicativos são ferramentas desktop independentes; esta pasta não contém cópias dos aplicativos nem integração por API. O conversor usa o arquivo ES-DE exportado pelo RetroForge.
- O RetroForge foi criado para cartões de consoles retro. Confirmar os sistemas e formatos aceitos na versão instalada antes de processar a biblioteca do telefone.
- O Kura pode identificar muitos formatos PlayStation, mas a documentação pública descreve transferência direta para PS4/PS5. Não presumir transferência direta para Android; usar cópia local/ADB e o Pegasus deste projeto.
- A integração ainda precisa ser validada com as pastas e os jogos reais do S20 FE.
- BIOS e jogos não são fornecidos por este projeto. Use somente arquivos que você tenha direito de usar.
