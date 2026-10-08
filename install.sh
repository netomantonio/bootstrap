#!/usr/bin/env bash
# install.sh - maquina nova (WSL/Ubuntu): UM comando, sem variaveis para decorar. Este arquivo e PUBLICO: nao contem segredo nenhum.
#   bash <(curl -fsSL https://raw.githubusercontent.com/netomantonio/bootstrap/main/install.sh)
# Fluxo: senha do sudo -> instala git/curl/age/gh e baixa os scripts -> PERGUNTAS (todas juntas) -> login do GitHub
#        (codigo no celular) -> senha do cofre (age) -> roda sozinho.
# Opcional (sem perguntas): PERFIS="base go" ACEITO_TOS_CONDA=1 INITIO_SEM_ONEDRIVE=1 definidos antes pulam a pergunta correspondente.
set -eu
BOOT_REPO="${INITIO_BOOT_REPO:-netomantonio/bootstrap}"
export INITIO_COFRE_REPO="${INITIO_COFRE_REPO:-netomantonio/cofre}"
BOOT="${INITIO_BOOT_DIR:-$HOME/.local/share/initio-boot}"
TTY="${INITIO_TTY:-/dev/tty}"

tem_tty() { { : <"$TTY"; } 2>/dev/null; }
ler() { local _v; if tem_tty; then read -r _v <"$TTY" || _v=""; else _v=""; fi; printf '%s' "$_v"; }

perguntas() {
  local f n i r ok sel tem_conda
  local nomes=() descs=()
  for f in "$BOOT"/perfis/*.conf; do
    n=$(basename "$f" .conf)
    [ "$n" = base ] && continue
    [ "$n" = extras ] && continue
    nomes+=("$n")
    descs+=("$(sed -n 's/^DESC="\(.*\)"$/\1/p' "$f" | head -1 | cut -c1-95)")
  done

  # 1) perfis
  if [ -z "${PERFIS:-}" ]; then
    if tem_tty; then
      printf '\n>>> PERFIS (o "base" sempre entra). Escolha o que instalar nesta maquina:\n'
      for i in "${!nomes[@]}"; do printf '  %2d) %-12s %s\n' $((i+1)) "${nomes[$i]}" "${descs[$i]}"; done
      printf 'Numeros separados por espaco | Enter = todos | 0 = so o base: '
      while :; do
        r=$(ler); ok=1; sel=""
        case "$r" in
          "") PERFIS=all; break;;
          0) PERFIS=base; break;;
          *) for n in $r; do
               case "$n" in *[!0-9]*|"") ok=0; break;; esac
               if [ "$n" -lt 1 ] || [ "$n" -gt "${#nomes[@]}" ]; then ok=0; break; fi
               sel="$sel ${nomes[$((n-1))]}"
             done
             if [ $ok = 1 ]; then PERFIS="base$sel"; break; fi
             printf 'Valor invalido. Tente de novo (1-%d, Enter, ou 0): ' "${#nomes[@]}";;
        esac
      done
    else
      PERFIS=all
    fi
  fi

  # 2) termos do conda: so pergunta se algum perfil escolhido usa conda
  if [ -z "${ACEITO_TOS_CONDA:-}" ]; then
    tem_conda=0
    if [ "$PERFIS" = all ]; then
      grep -qE '^CONDA=\([^)]' "$BOOT"/perfis/*.conf 2>/dev/null && tem_conda=1
    else
      for n in $PERFIS; do
        [ -f "$BOOT/perfis/$n.conf" ] && grep -qE '^CONDA=\([^)]' "$BOOT/perfis/$n.conf" && tem_conda=1
      done
    fi
    ACEITO_TOS_CONDA=0
    if [ $tem_conda = 1 ] && tem_tty; then
      printf '\n>>> Conda exige aceitar os Termos de Servico dos canais da Anaconda. Aceitar em seu nome? [s/N] '
      r=$(ler)
      case "$r" in s|S|sim|SIM) ACEITO_TOS_CONDA=1;; esac
    fi
  fi
  export ACEITO_TOS_CONDA

  # 3) fonte do cofre: so pergunta se existir um cofre no OneDrive do Windows
  if [ -z "${INITIO_SEM_ONEDRIVE:-}" ]; then
    INITIO_SEM_ONEDRIVE=1
    local d achou=0
    for d in /mnt/c/Users/*/OneDrive*/Documentos/Credenciais\ e\ Certificados/_cofre; do [ -d "$d" ] && achou=1; done
    if [ $achou = 1 ] && tem_tty; then
      printf '\n>>> Cofre de segredos: achei uma copia no OneDrive. Usar de onde?\n  1) GitHub (padrao, funciona em qualquer maquina)\n  2) OneDrive\nEscolha [1]: '
      r=$(ler)
      [ "$r" = 2 ] && INITIO_SEM_ONEDRIVE=0
    fi
  fi
  export INITIO_SEM_ONEDRIVE PERFIS
}

main() {
  printf '\n>>> SENHA DO SUDO (digite e Enter; nao aparece na tela). Pedida so esta vez:\n'
  sudo -v

  echo ">>> instalando git, curl, age, gh"
  sudo apt-get update -y
  sudo apt-get install -y git curl ca-certificates age gh

  rm -rf "$BOOT"; git clone --depth 1 "https://github.com/$BOOT_REPO.git" "$BOOT"

  perguntas

  if ! gh auth status >/dev/null 2>&1; then
    echo ">>> login no GitHub: o terminal vai mostrar um codigo e uma URL; abra no celular e autentique (2FA normal)"
    gh auth login --hostname github.com --git-protocol https --web
  fi
  gh auth setup-git >/dev/null 2>&1 || true

  export INITIO_HOME="$BOOT"
  echo ">>> perfis: $PERFIS | cofre: $([ "$INITIO_SEM_ONEDRIVE" = 1 ] && echo GitHub || echo OneDrive) | termos conda: $([ "$ACEITO_TOS_CONDA" = 1 ] && echo aceitos || echo nao)"
  bash "$BOOT/initio" restore
  # shellcheck disable=SC2086
  bash "$BOOT/initio" $PERFIS
  echo ">>> pronto. Abrindo um shell de login novo (PATH e shell padrao atualizados); rode: initio doctor"
  exec "$(getent passwd "$USER" | cut -d: -f7)" -l
}

[ "${INITIO_SOURCE_ONLY:-0}" = 1 ] || main "$@"
