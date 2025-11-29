WINE_VER = 10.0.0.0
DOCKERCMD = docker
VAGRANTCMD = vagrant
VAGRANTARGS = 

msvc14: buildsnapshot14 buildwine buildmsvc14

build/msvc14/snapshots/CMP: build/msvc14/snapshots/CMP/.CACHETAG
build/msvc14/snapshots/CMP/.CACHETAG: Vagrantfile build/msvc14_iso
	$(VAGRANTCMD) up $(VAGRANTARGS) --provision win-msvc14
	$(VAGRANTCMD) halt win-msvc14
	chmod +w build/msvc14/snapshots/CMP
	touch "$@"
	chmod -w build/msvc14/snapshots/CMP

buildsnapshot14: build/msvc14/snapshots/CMP/.CACHETAG

buildmsvc14: buildsnapshot14 Dockerfile
	$(DOCKERCMD) build -f Dockerfile -t msvc:14 --build-arg WINE_VER=$(WINE_VER) --build-arg MSVC=14 .




build/msvc14_iso: build/msvc14_iso/.CACHETAG
build/msvc14_iso/.CACHETAG: build/vs2015.com_enu.iso
	test -d build/msvc14_iso && chmod +w -R build/msvc14_iso || true
	xorriso -osirrox on -indev build/vs2015.com_enu.iso -extract / build/msvc14_iso
	chmod +w -R build/msvc14_iso
	touch "$@"

build/vs2015.com_enu.iso:
	mkdir -p build
	wget "http://download.microsoft.com/download/0/B/C/0BC321A4-013F-479C-84E6-4A2F90B11269/vs2015.com_enu.iso" -O $@


.PHONY: clean

clean:
	rm -rf build/msvc*
	$(VAGRANTCMD) destroy --force || true
	$(VAGRANTCMD) global-status --prune || true

buildwine: Dockerfile.wine
	$(DOCKERCMD) build -f Dockerfile.wine -t wine:$(WINE_VER) --build-arg WINE_VER=$(WINE_VER) dockertools

exports: .exports/wine.docker.tar.gz .exports/msvc.docker.tar.gz .exports/snapshots.tar.gz

.exports/wine.docker.tar.gz:
	@mkdir -p .exports
	-docker image save wine:$(WINE_VER) | gzip > "$@"

.exports/msvc.docker.tar.gz:
	@mkdir -p .exports
	-docker image save msvc:14 | gzip > "$@"

.exports/snapshots.tar.gz:
	@mkdir -p .exports
	-tar -cvzf "$@" build/msvc14/snapshots

imports: imports/wine.docker.tar.gz imports/msvc.docker.tar.gz imports/snapshots.tar.gz

imports/wine.docker.tar.gz:
	-docker image load < .exports/wine.docker.tar.gz
imports/msvc.docker.tar.gz:
	-docker image load < .exports/msvc.docker.tar.gz
imports/snapshots.tar.gz:
	-tar -xvzf .exports/snapshots.tar.gz