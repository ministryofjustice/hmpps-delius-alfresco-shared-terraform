def project = [:]
project.alfresco  = 'hmpps-delius-alfresco-shared-terraform'


def prepare_env() {
    sh '''
    #!/usr/env/bin bash
    docker pull mojdigitalstudio/hmpps-terraform-builder:latest
    '''
}

def plan_submodule(env_name, git_project_dir, submodule_name) {
    wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'XTerm']) {
        sh """
        #!/usr/env/bin bash
        echo "TF PLAN for ${env_name} | ${submodule_name} - component from git project ${git_project_dir}"
        set +e
        cd "${git_project_dir}"
        CURRENT_DIR=\$(pwd)
        python docker-run.py --env ${env_name} --component ${submodule_name} --action plan
        source \${CURRENT_DIR}/${submodule_name}_plan_ret
        echo "\$exitcode" > plan_ret
        if [ "\$exitcode" != '0' ]; then exit \$exitcode; else exit 0; fi
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

                dir( project.alfresco ) {
                  git url: 'git@github.com:ministryofjustice/' + project.alfresco, branch: 'master', credentialsId: 'f44bc5f1-30bd-4ab9-ad61-cc32caf1562a'
                }

                prepare_env()
            }
        }

        stage('Alfresco | Common') { steps { script { plan_submodule(environment_name, project.alfresco, 'common')}}}
        stage('Alfresco | AmazonMQ') { steps { script { plan_submodule(environment_name, project.alfresco, 'amazonmq')}}}
        stage('Alfresco | S3 Buckets') { steps { script { plan_submodule(environment_name, project.alfresco, 's3buckets')}}}
        stage('Alfresco | Certs') { steps { script { plan_submodule(environment_name, project.alfresco, 'certs')}}}
        stage('Alfresco | IAM') { steps { script { plan_submodule(environment_name, project.alfresco, 'iam')}}}
        stage('Alfresco | Security Groups') { steps { script { plan_submodule(environment_name, project.alfresco, 'security-groups')}}}
        stage('Alfresco | EFS') { steps { script { plan_submodule(environment_name, project.alfresco, 'efs')}}}
        stage('Alfresco | RDS') { steps { script { plan_submodule(environment_name, project.alfresco, 'rds')}}}
        stage('Alfresco | ElastiCache') { steps { script { plan_submodule(environment_name, project.alfresco, 'elasticache-memcached')}}}
        stage('Alfresco | ES Migration') { steps { script { plan_submodule(environment_name, project.alfresco, 'elk-migration')}}}
        stage('Alfresco | ASG') { steps { script { plan_submodule(environment_name, project.alfresco, 'asg')}}}
        stage('Alfresco | ES Admin') { steps { script { plan_submodule(environment_name, project.alfresco, 'es_admin')}}}
        stage('Alfresco | Cloudwatch Exporter') { steps { script { plan_submodule(environment_name, project.alfresco, 'cloudwatch_exporter')}}}
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
