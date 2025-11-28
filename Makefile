MSVC_VERS = 16 15 14 12 11 10 9
WINE_VER = 10.0.0.0
DOCKERCMD = docker
VAGRANTCMD = vagrant
VAGRANTARGS = 

default: msvc14

define build-targets
  build/msvc$1/snapshots/CMP: build/msvc$1/snapshots/CMP/.CACHETAG
  build/msvc$1/snapshots/CMP/.CACHETAG: Vagrantfile
		$(VAGRANTCMD) up $(VAGRANTARGS) --provision win-msvc$1
		$(VAGRANTCMD) halt win-msvc$1
		chmod +w build/msvc$1/snapshots/CMP
		touch "$@"
		chmod -w build/msvc$1/snapshots/CMP

  buildsnapshot$1: build/msvc$1/snapshots/CMP/.CACHETAG

  buildmsvc$1: buildsnapshot$1 Dockerfile
		$(DOCKERCMD) build -f Dockerfile -t msvc:$1 --build-arg WINE_VER=$(WINE_VER) --build-arg MSVC=$1 .

  msvc$1: buildsnapshot$1 buildwine buildmsvc$1
endef

$(foreach element,$(MSVC_VERS),$(eval $(call build-targets,$(element))))
build/msvc14_iso: build/msvc14_iso/.CACHETAG

build/msvc14_iso/.CACHETAG: build/vs2015.com_enu.iso
	test -d build/msvc14_iso && chmod +w -R build/msvc14_iso || true
	xorriso -osirrox on -indev build/vs2015.com_enu.iso -extract / build/msvc14_iso
	chmod +w -R build/msvc14_iso
	touch "$@"

build/vs2015.com_enu.iso:
	mkdir -p build
	wget "http://download.microsoft.com/download/0/B/C/0BC321A4-013F-479C-84E6-4A2F90B11269/vs2015.com_enu.iso" -O $@

buildsnapshot14: build/msvc14_iso

.PHONY: clean

clean:
	rm -rf build/msvc*
	$(VAGRANTCMD) destroy --force || true
	$(VAGRANTCMD) global-status --prune || true

buildwine: Dockerfile.wine
	$(DOCKERCMD) build -f Dockerfile.wine -t wine:$(WINE_VER) --build-arg WINE_VER=$(WINE_VER) .
