export PATH="/snap/bin:$PATH"

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

export FZF_PREVIEW="[[ -d {} ]] \
                    && tree \
                    --noreport \
                    --dirsfirst \
                    -C -x -L 2 {}\
                    || bat --color always {}"
