MSVC_VERS = 16 15 14 12 11 10 9
WINE_VER = 4.0
DOCKERCMD = docker
VAGRANTCMD = vagrant
VAGRANTARGS = 

default: msvc14

define build-targets
  buildsnapshot$1: Vagrantfile
		$(VAGRANTCMD) up $(VAGRANTARGS) --provision win-msvc$1
		$(VAGRANTCMD) halt win-msvc$1

  buildmsvc$1: Dockerfile dockercheck
		$(DOCKERCMD) build -f Dockerfile -t msvc:$1 --build-arg WINE_VER=$(WINE_VER) --build-arg MSVC=$1 .

  msvc$1: dockercheck buildsnapshot$1 buildwine buildmsvc$1
endef

$(foreach element,$(MSVC_VERS),$(eval $(call build-targets,$(element))))

build/msvc14_iso: build/vs2015.com_enu.iso
	xorriso -osirrox on -indev build/vs2015.com_enu.iso -extract / $@

build/vs2015.com_enu.iso:
	mkdir -p build
	wget "http://download.microsoft.com/download/0/B/C/0BC321A4-013F-479C-84E6-4A2F90B11269/vs2015.com_enu.iso" -O $@

buildsnapshot14: build/msvc14_iso

.PHONY: clean dockercheck

clean:
	rm -rf build/msvc*
	$(VAGRANTCMD) destroy --force || true
	$(VAGRANTCMD) global-status --prune || true
	VBoxManage list vms || true

dockercheck:
	$(DOCKERCMD) images

buildwine: Dockerfile.wine dockercheck
	$(DOCKERCMD) build -f Dockerfile.wine -t wine:$(WINE_VER) --build-arg WINE_VER=$(WINE_VER) .