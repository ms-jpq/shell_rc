#################### ########## ####################
#################### ZSH Region ####################
#################### ########## ####################
set -o pipefail
export PROMPT_EOL_MARK=""


#################### #################### ####################
#################### Instant Promp Region ####################
#################### #################### ####################
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]
then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

zrc_targets=(
  framework
  shared
  distro
)

for target ($zrc_targets)
do
  rcs="$HOME/zsh/$target"
  for rc ("$rcs"/**/*.zsh)
  do
    echo "$rcs/$rc"
  done
done
