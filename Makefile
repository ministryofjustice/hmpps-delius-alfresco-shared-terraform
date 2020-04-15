default: build
.PHONY: build

get_configs:
	rm -rf env_configs
	git clone -b $(ENV_CONFIGS_VERSION) https://github.com/ministryofjustice/hmpps-env-configs.git env_configs

plan: 
	sh run.sh $(ENVIRONMENT_NAME) plan $(component)

build: plan
	sh run.sh $(ENVIRONMENT_NAME) apply $(component)

task_handler:
	docker-compose -f restore/$(COMPOSE_FILE_NAME) up --exit-code-from $(TASK_NAME) $(TASK_NAME)
