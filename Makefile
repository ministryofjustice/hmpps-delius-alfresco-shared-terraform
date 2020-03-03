default: build
.PHONY: build

get_configs:
	rm -rf env_configs
	git clone -b $(GIT_BRANCH) https://github.com/ministryofjustice/hmpps-env-configs.git env_configs

build: 
	sh run.sh $(ENVIRONMENT_NAME) plan $(component)
	sh run.sh $(ENVIRONMENT_NAME) apply $(component)
