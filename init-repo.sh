#!/usr/bin/env bash
# Bootstrap: convierte esta carpeta en un repo git listo para subir a GitHub.
# Uso:
#   chmod +x init-repo.sh
#   ./init-repo.sh https://github.com/TU_USUARIO/lomafood-ruta-diaria.git
#
# Si no pasás URL, deja todo commiteado localmente y te muestra los comandos manuales.

set -e

REMOTE_URL="${1:-}"

cd "$(dirname "$0")"

if [ -d .git ]; then
  echo "Ya existe .git/ — saltando 'git init'."
else
  git init -b main
fi

git add .
git status

if git diff --cached --quiet; then
  echo "No hay cambios para commitear."
else
  git commit -m "Initial commit: LOMAFOOD daily route automation"
fi

if [ -n "$REMOTE_URL" ]; then
  if git remote get-url origin >/dev/null 2>&1; then
    git remote set-url origin "$REMOTE_URL"
  else
    git remote add origin "$REMOTE_URL"
  fi
  echo
  echo "Subiendo a $REMOTE_URL ..."
  git push -u origin main
  echo "Listo."
else
  echo
  echo "Repo local listo. Para subirlo a GitHub:"
  echo "  1) Crear un repo VACÍO en https://github.com/new (sin README, sin .gitignore, sin LICENSE)"
  echo "  2) git remote add origin https://github.com/TU_USUARIO/lomafood-ruta-diaria.git"
  echo "  3) git push -u origin main"
fi
