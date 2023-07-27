VERSION=$(shell cat internal/VERSION)
YUM_LABS?=$(wildcard ../yum-labs)

default:

%.md: %.md.j2 docs/auto-privileges-doc.py ldap2pg/defaults.py Makefile
	echo '<!-- GENERATED FROM $< -->' > $@.tmp
	python docs/auto-privileges-doc.py $< >> $@.tmp
	mv -f $@.tmp $@

.PHONY: docs
docs: docs/wellknown.md
	mkdocs build --clean --strict

readme-sample:
	@ldap2pg --config docs/readme/ldap2pg.yml --real
	@psql -f docs/readme/reset.sql
	@echo '$$ cat ldap2pg.yml'
	@cat docs/readme/ldap2pg.yml
	@echo '$$ ldap2pg --real'
	@ldap2pg --color --config docs/readme/ldap2pg.yml --real 2>&1 | sed s,${PWD}/docs/readme,...,g
	@echo '$$ '
	@echo -e '\n\n\n\n'

changelog:
	sed -i 's/^# Unreleased$$/# ldap2pg $(VERSION)/' docs/changelog.md

.PHONY: build
build:
	go build -o build/ldap2pg.amd64 -trimpath -buildvcs -ldflags -s ./cmd/ldap2pg

release: changelog VERSION
	git commit internal/VERSION docs/changelog.md -m "Version $(VERSION)"
	git tag $(VERSION)
	git push git@github.com:dalibo/ldap2pg.git
	git push --tags git@github.com:dalibo/ldap2pg.git
	@echo Now wait for CI and run make push-rpm;

release-notes:  #: Extract changes for current release
	FINAL_VERSION="$(shell echo $(VERSION) | grep -Po '([^a-z]{3,})')" ; sed -En "/Unreleased/d;/^#+ ldap2pg $$FINAL_VERSION/,/^#/p" CHANGELOG.md  | sed '1d;$$d'

rpm deb:
	VERSION=$(VERSION) nfpm package --packager $@

publish-rpm: rpm
	cp build/ldap2pg-$(VERSION).x86_64.rpm $(YUM_LABS)/rpms/RHEL8-x86_64/
	cp build/ldap2pg-$(VERSION).x86_64.rpm $(YUM_LABS)/rpms/RHEL7-x86_64/
	cp build/ldap2pg-$(VERSION).x86_64.rpm $(YUM_LABS)/rpms/RHEL6-x86_64/
	@make -C $(YUM_LABS) push createrepos clean

reset-%:
	docker-compose up --force-recreate --no-deps --renew-anon-volumes --detach $*
