define MACH_DETECT
case "$$MACHTYPE" in
aarch64*)
  printf -- '%s' aarch64
  ;;
x86_64*)
  printf -- '%s' x86_64
  ;;
*)
  exit 1
  ;;
esac
endef

define OS_DETECT
case "$$OSTYPE" in
darwin*)
  printf -- '%s' darwin
  ;;
linux*)
  printf -- '%s' linux
  ;;
*msys*)
  printf -- '%s' nt
  ;;
*)
  exit 1
  ;;
esac
endef

MACHTYPE := $(shell $(MACH_DETECT))
OS := $(shell $(OS_DETECT))

ifeq ($(MACHTYPE), aarch64)
	GOARCH := arm64
else
	GOARCH := amd64
endif
