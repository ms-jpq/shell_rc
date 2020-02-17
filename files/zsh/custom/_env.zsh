#################### ########## ####################
#################### Env Region ####################
#################### ########## ####################

export PATH="$HOME/.scripts:$PATH"

export EDITOR=micro
export PAGER=tee

# export TIME_STYLE="+%Y/%m/%d %H:%M"
export TIME_STYLE="long-iso"

export LESS="-KQRi"

# export BAT_THEME=GitHub
export BAT_STYLE=plain


export FZF_PREVIEW="[ -d {} ] \
                    && exa \
                    --color=always \
                    --group-directories-first \
                    -T -L 2 {} \
                    || bat --color always {}"
