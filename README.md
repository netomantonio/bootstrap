# bootstrap / initio

`initio` é uma CLI única em bash que recria o ambiente de desenvolvimento (WSL/Ubuntu) de uma máquina do zero e mantém esse ambiente versionado: pacotes por perfil, dotfiles (chezmoi), repositórios, segredos cifrados e configuração/histórico de agentes de IA.

Este repositório é **público e não contém segredo**. Tudo que é sensível fica cifrado com [age](https://github.com/FiloSottile/age) (senha) em um repositório privado (`cofre`) e na nuvem pessoal do dono. Uma trava no `publicar-boot` bloqueia a publicação se algo parecer segredo.

## Máquina nova

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/netomantonio/bootstrap/main/install.sh)
```

Use `bash <(...)` (process substitution) e não `curl | bash`, para o terminal continuar interativo.

Fluxo: senha do sudo → instala git/curl/age/gh e baixa o initio → **todas as perguntas juntas** (perfis a instalar etc.) → login no GitHub (código no celular) → senha do cofre → roda sozinho.

Variáveis opcionais, definidas antes, que pulam a pergunta correspondente: `PERFIS="base go"`, `ACEITO_TOS_CONDA=1`, `INITIO_SEM_ONEDRIVE=1`.

## Comandos

| Comando | O que faz |
|---|---|
| `initio restore [cofre] [chave]` | Máquina nova: abre o cofre, restaura a chave, dotfiles e repositórios. |
| `initio <perfil>... \| all \| bootstrap` | Instala perfis (o `base` entra sempre primeiro). |
| `initio list` | Lista os perfis e suas descrições. |
| `initio sync [--upgrade] [--dry] [-q]` | Captura esta máquina, publica nos dotfiles, aplica e instala o que falta. |
| `initio snapshot [--dry]` | Só a captura: configs e dependências novas vão para `extras.conf`. |
| `initio perfil add <perfil> <apt\|npm\|pip\|cargo\|pipx> <pacote>` | Adiciona um pacote a um perfil. |
| `initio cofre salvar \| publicar \| abrir` | Segredos em arquivo `age`; `publicar` cria uma release no repositório privado. |
| `initio ia inventario \| salvar [--leve]` | Histórico, memória, sessões, MCPs, skills e configs de claude/codex/gemini, cifrados. `--leve` omite as sessões do codex. |
| `initio ssh-github` | Cadastra/usa uma chave SSH no GitHub. |
| `initio doctor` | Diagnóstico. |
| `initio publicar-boot` | Espelha initio, perfis, `install.sh` e este README neste repositório público. |
| `initio repos catalogar \| listar \| clonar \| duplicados \| reparar \| eliminar` | Catálogo de repositórios (url + branch) e manutenção. `eliminar` só move para `_QUARENTENA` depois de conferir que tudo está no GitHub; sem `--aplicar` só mostra. |
| `initio arquivos duplicados` | Acha arquivos idênticos (sha256) entre os discos e o OneDrive. Só leitura. |
| `initio arquivos consolidar [--aplicar]` | Junta duplicatas; sem `--aplicar` só mostra o plano. |
| `initio arquivos limpar-onedrive [--aplicar \| --desfazer <log>]` | Tira código e backups do OneDrive para a quarentena local. |

Flags globais: `--dry` (não altera nada), `-q` (silencioso), `-v` (verboso, padrão em terminal).

## Perfis

Cada perfil é um arquivo `perfis/<nome>.conf` com `DESC` e as listas de pacotes. Perfis atuais: `base`, `ai-agents`, `devops`, `devsecops`, `genai-train`, `go`, `java-kotlin`, `node-web`, `pentest`, `python-dev`, `rust`, `virt` e `extras` (sobras da captura; não instala sozinho — classifique com `initio perfil add`).

## Onde ficam os dados

| O quê | Onde |
|---|---|
| Este código (initio, perfis, install.sh) | este repositório, público |
| Dotfiles | chezmoi (repositório próprio) |
| Segredos e histórico de IA, cifrados com age | repositório privado `cofre` (releases) e pasta `_cofre` na nuvem pessoal |
| Código dos projetos | `B:\projetos` (`/mnt/b/projetos`); GitHub é a fonte da verdade |

Código nunca fica na nuvem pessoal: ela guarda só documentos e mídia.

## Limites conhecidos

- O `age` não aceita senha por variável de ambiente; a senha do cofre é lida do terminal (`/dev/tty`). Rodar o `restore` por pipe sem terminal falha de propósito.
- Release do GitHub aceita arquivo de até ~2 GB; o pacote completo de IA pode passar disso — use `initio ia salvar --leve` para publicar.
- A restauração de IA no Windows (`.claude`/`.codex` do usuário Windows) é guardada em `~/.local/state/initio/ia-windows`; a cópia de volta é manual.
- Arquivos só-na-nuvem do OneDrive não são lidos pelas ferramentas de duplicados (para não disparar download).

## Variáveis de ambiente

`INITIO_HOME`, `INITIO_COFRE_DIR`, `INITIO_COFRE_REPO` (padrão `netomantonio/cofre`), `INITIO_BOOT_REPO` (padrão `netomantonio/bootstrap`), `INITIO_SEM_ONEDRIVE`.
