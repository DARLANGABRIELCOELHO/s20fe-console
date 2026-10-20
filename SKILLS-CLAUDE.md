# Skills instaladas no Claude Code (PC Windows)

Levantamento de 2026-10-20. Chamar uma skill: `/<nome>` no chat (as de plugin usam `/<plugin>:<nome>`).

## 1. Skills do usuário

Pasta: `C:\Users\Administrator\.claude\skills\`. Cada uma tem um `ORIGEM.txt` com o repositório e o commit de onde foi copiada.

| Skill | Para que serve | Fonte | Licença |
|---|---|---|---|
| `agent-browser` | Automação de navegador (abrir sites, preencher formulários, prints, raspar dados, testar apps web, apps Electron) | [vercel-labs/agent-browser](https://github.com/vercel-labs/agent-browser/tree/5ee8691339a5a002e4d7454eec95250253bc7419/skills/agent-browser) | Apache-2.0 |
| `claude-automation-recommender` | Analisa o projeto e recomenda automações do Claude Code (hooks, subagentes, skills, plugins, MCP). Só lê, não altera | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official/tree/e68e375d22866ba36c1eb0b4cc46db96c65f6a4e/plugins/claude-code-setup) (plugin claude-code-setup) | Apache-2.0 |
| `design-taste-frontend` | Direção de arte para páginas web e telas de app, evitando o visual "genérico de IA" | [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill/tree/63aba5f43b5056758b15bbe7d683da8c86a7a7ad/skills/taste-skill) | MIT |
| `find-skills` | Procura e instala novas skills | [vercel-labs/skills](https://github.com/vercel-labs/skills/tree/a80e4c9d12d607631249d4d7d059f835d4b2f13a/skills/find-skills) | MIT |
| `grilling` | Faz perguntas duras sobre um plano ou ideia para testá-lo | [mattpocock/skills](https://github.com/mattpocock/skills/tree/5beb35b040e3de97e54fa9e386d7e42d15c295c2/skills/productivity/grilling) | MIT |

## 2. Plugin claude-mem 14.0.1 (`claude-mem@thedotmack`)

Memória entre sessões, só local (sem cloud sync, telemetria desligada). Pasta: `C:\Users\Administrator\.claude\plugins\cache\thedotmack\claude-mem\14.0.1\`.

| Skill | Para que serve |
|---|---|
| `claude-mem:mem-search` | Busca na memória de sessões anteriores |
| `claude-mem:how-it-works` | Explica como o claude-mem funciona |
| `claude-mem:learn-codebase` | Lê o projeto inteiro de uma vez para a memória |
| `claude-mem:smart-explore` | Busca estrutural no código (tree-sitter), gastando menos tokens |
| `claude-mem:knowledge-agent` | Cria "bases de conhecimento" a partir das observações salvas |
| `claude-mem:timeline-report` | Relatório narrativo da história do projeto |
| `claude-mem:weekly-digests` | Resumo semana a semana do projeto |
| `claude-mem:handoff` | Gera um `HANDOFF.md` para continuar o trabalho em outra sessão |
| `claude-mem:make-plan` | Plano de implementação em fases |
| `claude-mem:do` | Executa um plano feito pelo `make-plan` |
| `claude-mem:build` | `make-plan` + `do` + `babysit` automáticos |
| `claude-mem:build-and-release` | Igual ao `build`, com release no fim |
| `claude-mem:babysit` | Acompanha um PR (revisões, CI) até poder fazer merge |
| `claude-mem:childhood` | Acompanha uma versão já publicada |
| `claude-mem:release` | Release automática (`version-bump` + `childhood`) |
| `claude-mem:version-bump` | Versionamento semântico de plugins do Claude Code |
| `claude-mem:standup` | Compara branches/worktrees/PRs e propõe um plano de consolidação |
| `claude-mem:oh-my-issues` | Agrupa issues do GitHub pela causa |
| `claude-mem:pathfinder` | Mapeia o código em fluxogramas e acha duplicações |
| `claude-mem:design-is` | Avalia um design pelos 10 princípios de Dieter Rams |
| `claude-mem:what-the` | Explica algo técnico em linguagem simples |
| `claude-mem:wowerpoint` | Transforma um documento em apresentação |
| `claude-mem:mode-creator` | Cria modos personalizados do que o claude-mem memoriza |
| `claude-mem:agent-cost-report` | Relatório de custo dos agentes num período |
| `claude-mem:ccs-align` | Ciclo de alinhamento do cache de memória e das regras |
| `claude-mem:screenpipe` | Busca no histórico de tela/áudio do Screenpipe |
| `claude-mem:cloud-sync` | Configura a sincronização com o cmem.ai Pro (**não usada**: sync desligado) |

## 3. Skills da Anthropic sincronizadas da conta (`anthropic-skills:`)

Vêm da conta do claude.ai (pasta `C:\Users\Administrator\.claude\skills\synced\`). Não foram instaladas à mão.

| Skill | Para que serve |
|---|---|
| `anthropic-skills:docx` | Criar e editar documentos Word |
| `anthropic-skills:xlsx` | Criar e editar planilhas (xlsx, csv) |
| `anthropic-skills:pptx` | Criar e editar apresentações PowerPoint |
| `anthropic-skills:pdf` | Ler, juntar, dividir, preencher e criar PDFs |
| `anthropic-skills:docs` | Documentos compartilháveis do Claude Docs |
| `anthropic-skills:google-workspace` | Criar/editar arquivos do Google Docs, Sheets e Slides |
| `anthropic-skills:deep-research` | Pesquisa em várias fontes com relatório |
| `anthropic-skills:skill-creator` | Criar, melhorar e testar skills |
| `anthropic-skills:import-memory` | Importar memória de outro assistente de IA |
| `anthropic-skills:morning` | Resumo da manhã |
| `anthropic-skills:built-in-browser` | Navegador embutido do app desktop do Claude |
| `anthropic-skills:chrome-browser` | Extensão Claude in Chrome |
| `anthropic-skills:computer-use` | Controle do computador (apps do desktop) |

## 4. Skills que já vêm com o Claude Code

| Skill | Para que serve |
|---|---|
| `code-review` | Revisão do diff atual ou de um PR (níveis low → max, e `ultra` na nuvem) |
| `security-review` | Revisão de segurança das mudanças da branch |
| `simplify` | Limpeza do código alterado (reuso, simplificação, eficiência) |
| `init` | Cria um `CLAUDE.md` para o projeto |
| `run` | Roda o app do projeto para ver uma mudança funcionando |
| `update-config` | Configura o `settings.json` (permissões, hooks, variáveis) |
| `fewer-permission-prompts` | Libera comandos de leitura frequentes para pedir menos permissão |
| `keybindings-help` | Personaliza atalhos de teclado |
| `loop` | Repete um comando em intervalos |
| `schedule` | Agenda agentes na nuvem (cron ou execução única) |
| `claude-api` | Referência da API do Claude / SDK da Anthropic |
| `plugin-authoring` | Cria mods do Claude (painéis, linha de status, comandos, hooks) |
| `artifact-design`, `artifact-capabilities`, `artifact-diagramming` | Criação de páginas Artifact no claude.ai |
| `dataviz` | Gráficos e painéis de dados |
