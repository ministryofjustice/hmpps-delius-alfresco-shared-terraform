default: build
.PHONY: build

get_configs:
	rm -rf env_configs
	git config --global advice.detachedHead false
	git clone -b $(ENV_CONFIGS_VERSION) $(ENV_CONFIGS_REPO) env_configs

get_package:
	aws s3 cp --only-show-errors s3://$(CONFIG_BUCKET)/deployments/alfresco/$(PACKAGE_VERSION)/$(PACKAGE_NAME) $(PACKAGE_NAME)
	tar xf $(PACKAGE_NAME) --strip-components=1
	cat output.txt

plan: 
	sh run.sh $(ENVIRONMENT_NAME) plan $(component)

build: plan
	sh run.sh $(ENVIRONMENT_NAME) apply $(component)

destroy:
	sh run.sh $(ENVIRONMENT_NAME) destroy $(component)

task_handler:
	docker-compose -f restore/$(COMPOSE_FILE_NAME) up --exit-code-from $(TASK_NAME) $(TASK_NAME)

json: 
	sh run.sh $(ENVIRONMENT_NAME) json $(component)

ansible_task:
	sh run.sh $(ENVIRONMENT_NAME) ansible $(component)
