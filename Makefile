include configs/common.properties

.PHONY: start

get_configs:
	rm -rf env_configs
	git config --global advice.detachedHead false
	git clone -b $(ENV_CONFIGS_VERSION) $(ENV_CONFIGS_REPO) env_configs || (exit $$?)

get_utils:
	rm -rf utils run.sh
	git clone https://github.com/ministryofjustice/hmpps-engineering-pipelines-utils.git utils
	mv utils/run.sh run.sh

init:
	rm -rf $(COMPONENT)/.terraform/terraform.tfstate

plan: init
	sh run.sh $(ENVIRONMENT_NAME) plan $(COMPONENT) || (exit $$?)

destroy:
	sh run.sh $(ENVIRONMENT_NAME) destroy $(COMPONENT) || (exit $$?)

apply:
	sh run.sh $(ENVIRONMENT_NAME) apply $(COMPONENT) || (exit $$?)

output:
	sh run.sh $(ENVIRONMENT_NAME) output $(COMPONENT) || (exit $$?)

start: restart
	docker-compose exec builder env| sort

stop:
	docker-compose down

cleanup:
	docker-compose down -v --rmi local

restart: stop
	docker-compose up -d

local_plan: restart
	docker-compose exec builder make plan

local_apply: restart
	docker-compose exec builder make apply

local_output: restart
	docker-compose exec builder make output

local_destroy: restart
	docker-compose exec builder make destroy
