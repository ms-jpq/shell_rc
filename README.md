## Conventions

`role_` -> Abstract Role, never invoke in playbooks

`_var_` -> Shared Consts

`_var` -> Private

`var` -> Input

## Roles

```
shell
  |--shell_macos
  |--shell_ubuntu
macos_
  |--macos__base
  |--macos_dev
  |--macos_personal
ubuntu_
  |--ubuntu__base
  |--ubuntu_docker
  |--ubuntu_x11vnc
windows_
  |--windows__base
  |--windows_auto_login
  |--windows_hyper_v
  |--windows_ssh
```
