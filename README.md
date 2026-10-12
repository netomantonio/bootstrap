# bootstrap / initio

`initio` é uma CLI única em bash que recria o ambiente de desenvolvimento (WSL/Ubuntu) de uma máquina do zero e mantém esse ambiente versionado: pacotes por perfil, dotfiles (chezmoi), repositórios, segredos cifrados e configuração/histórico de agentes de IA.

Este repositório é **público e não contém segredo**. Tudo que é sensível fica cifrado com [age](https://github.com/FiloSottile/age) (senha) em um repositório privado (`cofre`) e numa pasta local. Uma trava no `publicar-boot` bloqueia a publicação se algo parecer segredo.

## Máquina nova

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/netomantonio/bootstrap/main/install.sh)
```

Use `bash <(...)` (process substitution) e não `curl | bash`, para o terminal continuar interativo.

Fluxo: senha do sudo → instala git/curl/age/gh e baixa o initio → **todas as perguntas juntas** (perfis a instalar etc.) → login no GitHub (código no celular) → senha do cofre → roda sozinho.

Variáveis opcionais, definidas antes, que pulam a pergunta correspondente: `PERFIS="base go"`, `ACEITO_TOS_CONDA=1`.

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
| `initio repos catalogar \| listar \| clonar \| duplicados \| reparar \| eliminar` | Catálogo de repositórios (url + branch) e manutenção. `eliminar` só age depois de conferir que tudo está no GitHub: sem commit sem push, sem stash, sem edição pendente e sem segredo/config local sem resgate. Sem `--aplicar` só mostra; com `--aplicar` move para `_QUARENTENA`; com `--aplicar --apagar` apaga de vez. `--ok-resgatado` aceita repo já resgatado e `--ok-ignorados` dispensa a checagem de segredo/config (use só se já conferiu). |
| `initio repos resgatar [--aplicar] [--publico] [--sem-grandes] [--tudo] <pasta>...` | Antes de apagar uma máquina: stash e trabalho não commitado viram branches `backup/*` (enviados ao GitHub só se o repo for privado, ou com `--publico`; senão vão em `bundle` no cofre). Dos arquivos ignorados pelo git só vai para o cofre, cifrado, o que importa (ver "O que conta como importante"). `--tudo` lista todos os itens em vez dos 12 primeiros. Depois `eliminar --ok-resgatado` aceita o repo, só enquanto nada mudou desde o resgate. Sem `--aplicar` só mostra o plano. |

Flags globais: `--dry` (não altera nada), `-q` (silencioso), `-v` (verboso, padrão em terminal).

## Perfis

Cada perfil é um arquivo `perfis/<nome>.conf` com `DESC` e as listas de pacotes. Perfis atuais: `base`, `ai-agents`, `devops`, `devsecops`, `genai-train`, `go`, `java-kotlin`, `node-web`, `pentest`, `python-dev`, `rust`, `virt` e `extras` (sobras da captura; não instala sozinho — classifique com `initio perfil add`).

## Repositórios: dois catálogos

- `projetos-repos.tsv`: repos que moram em `PROJETOS_DIR` (por exemplo `B:\projetos`, lista plana). `initio repos clonar` clona e devolve `.env` e itens resgatados.
- `repos.tsv`: repos que moram na home (por exemplo `~/projects/...`, Linux-only). `initio restore` clona cada um em `~/<caminho>`; o `snapshot`/`sync` regera a lista a partir do que existe na home. Um repo deve estar em um catálogo só, senão fica duplicado.

## O que conta como importante

Do que o git ignora, só é guardado e só bloqueia o `eliminar` o que for segredo ou configuração local sem a qual a execução local quebra: `.env*`, `.envrc`, `.dev.vars`, `.npmrc`, `.netrc`, `.pypirc`, `.kube`, `.aws`, `.ssh`, `.gnupg`, chaves e certificados (`*.pem`, `*.key`, `*.p12`, `*.pfx`, `*.jks`, `id_*`), `*.tfvars`, `*.tfstate`, bancos locais (`*.db`, `*.sqlite*`) e arquivos de conta de serviço. Lockfile, `.vscode`, mídia, zip e cache são descartáveis: o `eliminar` os lista, mas não bloqueia e não os guarda. Para somar padrões, defina `INITIO_IMPORTANTE_EXTRA` (regex) em `~/.config/initio/env`.

## O que é preservado

- **Dotfiles** (chezmoi): `.zshrc`, `.zshenv`, `.zprofile`, `.zfunc`, `.bashrc`, `.gitconfig`, `.tmux.conf`, starship, e as configs de cada perfil. Scripts próprios de `~/.local/bin` entram só se o repositório de dotfiles for privado (o initio confere).
- **Plugins de zsh** (`zsh-autosuggestions`, `zsh-syntax-highlighting`): reinstalados pelo perfil `base`.
- **Cofre cifrado**: chaves e credenciais (`.ssh`, `.aws`, `.kube`...), históricos de shell e os `.env`/`.dev.vars` de todos os repositórios em `PROJETOS_DIR` (devolvidos a cada repo em `initio repos clonar`) e de `~/projects` (voltam junto com o `restore`).

## Onde ficam os dados

| O quê | Onde |
|---|---|
| Este código (initio, perfis, install.sh) | este repositório, público |
| Dotfiles | chezmoi (repositório próprio) |
| Segredos e histórico de IA, cifrados com age | repositório privado `cofre` (releases do GitHub) e uma pasta local (`~/.local/state/initio/cofre`, ou `INITIO_COFRE_DIR`) |
| Código dos projetos | `PROJETOS_DIR` (padrão `~/projetos`); GitHub é a fonte da verdade |


## Limites conhecidos

- **Docker**: fora da WSL o `initio` instala o dockerd nativo (perfil `devops`). Dentro da WSL ele pula o docker: o engine vem do Docker Desktop (Windows) com a integração ativada para a distro, porque dois engines na mesma VM derrubavam a distro em ~90 s. `initio doctor` falha se achar `docker-ce` instalado na WSL.
- O perfil `devsecops` instala só `gitleaks` e `bandit`. O `pentest` instala as ferramentas por `apt`, o `strix` e o env conda `security`. Ferramentas como `trivy`, `grype`, `syft`, `cosign`, `hadolint`, `opengrep`, `nuclei`, `subfinder` e `httpx` ainda não estão em nenhum perfil.
- `initio repos eliminar` não trata repos com submódulos: confira à mão.

- O `age` não aceita senha por variável de ambiente; a senha do cofre é lida do terminal (`/dev/tty`). Rodar o `restore` por pipe sem terminal falha de propósito.
- Release do GitHub aceita arquivo de até ~2 GB; o pacote completo de IA pode passar disso — use `initio ia salvar --leve` para publicar.
- A restauração de IA no Windows (`.claude`/`.codex` do usuário Windows) é guardada em `~/.local/state/initio/ia-windows`; a cópia de volta é manual.

## Variáveis de ambiente

`INITIO_HOME`, `INITIO_COFRE_DIR`, `INITIO_COFRE_REPO` (padrão `netomantonio/cofre`), `INITIO_BOOT_REPO` (padrão `netomantonio/bootstrap`), `PROJETOS_DIR`, `INITIO_REPO_ROOTS` (`dir1:dir2`), `INITIO_IMPORTANTE_EXTRA` (regex de itens ignorados que também devem ser guardados).

## Configuração pessoal (fora deste repositório)

O initio lê, se existirem, `~/.config/initio/env` (shell; exporte aqui `PROJETOS_DIR`, `INITIO_COFRE_DIR`...) e `~/.config/initio/plugins/*.sh` (comandos extras privados). Os dois entram no cofre cifrado e voltam no `initio restore`. Nada disso é publicado.
