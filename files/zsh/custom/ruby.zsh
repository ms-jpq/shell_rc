#################### ########### ####################
#################### Ruby Region ####################
#################### ########### ####################


if command -v rbenv > /dev/null
then
  eval "$(rbenv init -)"
fi

gem() {
  if command -v rbenv > /dev/null && rbenv local > /dev/null 2>&1
  then
    command gem "$@"
  else
    echo "Not in rbenv - require explicit:"
    echo
    echo "command gem $@"
    echo
  fi
}
