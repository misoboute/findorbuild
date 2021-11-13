# /usr/sh
ROOT=$(dirname $0)/..
SQUASH_MSG=$ROOT/.git/SQUASH_MSG
git checkout main
git merge --squash $1
echo Merging $1 to main: $'\n' > $SQUASH_MSG
git log --reverse --pretty="Commit %h at %ai%n%w(0,4,6)%B%n" --abbrev-commit main..$1 >> $ROOT/.git/SQUASH_MSG
