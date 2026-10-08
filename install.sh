#!/usr/bin/env bash
# install.sh - maquina nova (WSL/Ubuntu): UM comando. Este arquivo e PUBLICO: nao contem segredo nenhum.
#   bash <(curl -fsSL https://boot.antoniomiranda.pro)      # use process substitution: mantem o terminal interativo
#   PERFIS="devsecops python-dev" bash <(curl -fsSL ...)    # opcional (padrao: all)
# Perguntas, todas juntas no inicio: senha do sudo, termos do conda, login do GitHub (codigo no celular, com 2FA).
# Depois pede a senha do cofre (age) e roda sozinho.
set -eu
BOOT_REPO="${INITIO_BOOT_REPO:-netomantonio/bootstrap}"
export INITIO_COFRE_REPO="${INITIO_COFRE_REPO:-netomantonio/cofre}"

printf '\n>>> SENHA DO SUDO (digite e Enter; nao aparece na tela). Pedida so esta vez:\n'
sudo -v
r=n; printf 'Conda exige aceitar os Termos de Servico dos canais da Anaconda. Aceitar em seu nome? [s/N] '
if { : </dev/tty; } 2>/dev/null; then read -r r </dev/tty; fi
case "$r" in s|S|sim|SIM) export ACEITO_TOS_CONDA=1;; *) export ACEITO_TOS_CONDA=0;; esac

echo ">>> instalando git, curl, age, gh"
sudo apt-get update -y
sudo apt-get install -y git curl ca-certificates age gh

if ! gh auth status >/dev/null 2>&1; then
  echo ">>> login no GitHub: o terminal vai mostrar um codigo e uma URL; abra no celular e autentique (2FA normal)"
  gh auth login --hostname github.com --git-protocol https --web
fi
gh auth setup-git >/dev/null 2>&1 || true

BOOT="$HOME/.local/share/initio-boot"
rm -rf "$BOOT"; git clone --depth 1 "https://github.com/$BOOT_REPO.git" "$BOOT"
export INITIO_HOME="$BOOT"
bash "$BOOT/initio" restore
bash "$BOOT/initio" ${PERFIS:-all}
echo ">>> pronto. Abrindo um shell de login novo (PATH e shell padrao atualizados); rode: initio doctor"
exec "$(getent passwd "$USER" | cut -d: -f7)" -l
