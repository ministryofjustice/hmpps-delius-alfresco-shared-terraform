def project = [:]
project.config    = 'hmpps-env-configs'
project.network   = 'hmpps-delius-network-terraform'
project.alfresco  = 'hmpps-delius-alfresco-shared-terraform'

def prepare_env() {
    sh '''
    #!/usr/env/bin bash
    docker pull mojdigitalstudio/hmpps-terraform-builder:latest
    '''
}

def plan_submodule(config_dir, env_name, git_project_dir, submodule_name) {
    wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'XTerm']) {
        sh """
        #!/usr/env/bin bash
        echo "TF PLAN for ${env_name} | ${submodule_name} - component from git project ${git_project_dir}"
        set +e
        cp -R -n "${config_dir}" "${git_project_dir}/env_configs"
        cd "${git_project_dir}"
        docker run --rm \
            -v `pwd`:/home/tools/data \
            -v ~/.aws:/home/tools/.aws mojdigitalstudio/hmpps-terraform-builder \
            bash -c "\
                source env_configs/${env_name}/${env_name}.properties; \
                if [ -f "env_configs/${env_name}/sub-projects/alfresco.properties" ]; then source env_configs/${env_name}/sub-projects/alfresco.properties; fi; \
                cd ${submodule_name}; \
                if [ -d .terraform ]; then rm -rf .terraform; fi; sleep 5; \
                terragrunt init; \
                terragrunt plan > tf.plan.out; \
                exitcode=\\\"\\\$?\\\"; \
                cat tf.plan.out; \
                if [ \\\"\\\$exitcode\\\" == '1' ]; then exit 1; fi; \
                parse-terraform-plan -i tf.plan.out | jq '.changedResources[] | (.action != \\\"update\\\") or (.changedAttributes | to_entries | map(.key != \\\"tags.source-hash\\\") | reduce .[] as \\\$item (false; . or \\\$item))' | jq -e -s 'reduce .[] as \\\$item (false; . or \\\$item) == false'" \
            || exitcode="\$?"; \
            echo "\$exitcode" > plan_ret; \
            if [ "\$exitcode" == '1' ]; then exit 1; else exit 0; fi
        set -e
        """
        return readFile("${git_project_dir}/plan_ret").trim()
    }
}


def debug_env() {
    sh '''
    #!/usr/env/bin bash
    pwd
    ls -al
    '''
}

pipeline {

    agent { label "jenkins_slave" }

    stages {

        stage('setup') {
            steps {
                slackSend(message: "Build started on \"${environment_name}\" - ${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL.replace(':8080','')}|Open>)")

                dir( project.config ) {
                  git url: 'git@github.com:ministryofjustice/' + project.config, branch: 'master', credentialsId: 'f44bc5f1-30bd-4ab9-ad61-cc32caf1562a'
                }
                dir( project.network ) {
                  git url: 'git@github.com:ministryofjustice/' + project.network, branch: 'master', credentialsId: 'f44bc5f1-30bd-4ab9-ad61-cc32caf1562a'
                }
                dir( project.alfresco ) {
                  git url: 'git@github.com:ministryofjustice/' + project.alfresco, branch: 'master', credentialsId: 'f44bc5f1-30bd-4ab9-ad61-cc32caf1562a'
                }

                prepare_env()
            }
        }

        stage('Alfresco') {
            parallel {
                stage('Plan Alfresco common')          { steps { script {plan_submodule(project.config, environment_name, project.alfresco, 'common')}}}
                stage('Plan Alfresco DynamoDB')        { steps { script {plan_submodule(project.config, environment_name, project.alfresco, 'dynamodb')}}}
                stage('Plan Alfresco S3 buckets')      { steps { script {plan_submodule(project.config, environment_name, project.alfresco, 's3buckets')}}}
                stage('Plan Alfresco certs')           { steps { script {plan_submodule(project.config, environment_name, project.alfresco, 'certs')}}}
                stage('Plan Alfresco IAM')             { steps { script {plan_submodule(project.config, environment_name, project.alfresco, 'iam')}}}
                stage('Plan Alfresco security groups') { steps { script {plan_submodule(project.config, environment_name, project.alfresco, 'security-groups')}}}
                stage('Plan Alfresco RDS')             { steps { script {plan_submodule(project.config, environment_name, project.alfresco, 'rds')}}}
                stage('Plan Alfresco elasticache')     { steps { script {plan_submodule(project.config, environment_name, project.alfresco, 'elasticache-memcached')}}}
                stage('Plan Alfresco ASG')             { steps { script {plan_submodule(project.config, environment_name, project.alfresco, 'asg')}}}
            }
        }

    }

    post {
        always {
            deleteDir()
        }
        success {
            slackSend(message: "Build completed on \"${environment_name}\" - ${env.JOB_NAME} ${env.BUILD_NUMBER} ", color: 'good')
        }
        failure {
            slackSend(message: "Build failed on \"${environment_name}\" - ${env.JOB_NAME} ${env.BUILD_NUMBER} ", color: 'danger')
        }
    }

}
