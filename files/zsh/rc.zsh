#################### ############## ####################
#################### Loading Region ####################
#################### ############## ####################
zrc_targets=(
  intrinsic
  shared
  distro
  plugins
)

for target in "${zrc_targets[@]}"
do
  rcs="$XDG_CONFIG_HOME/zsh/$target"
  for rc in "$rcs"/**/*.zsh
  do
    source "$rc"
  done
done

