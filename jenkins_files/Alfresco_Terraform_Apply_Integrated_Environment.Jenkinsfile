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
        if [ "\$exitcode" == '1' ]; then exit 1; else exit 0; fi
        set -e
        """
        return readFile("${git_project_dir}/plan_ret").trim()
    }
}

def apply_submodule(env_name, git_project_dir, submodule_name) {
    wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'XTerm']) {
        sh """
        #!/usr/env/bin bash
        echo "TF APPLY for ${env_name} | ${submodule_name} - component from git project ${git_project_dir}"
        set +e
        cd "${git_project_dir}"
        CURRENT_DIR=\$(pwd)
        python docker-run.py --env ${env_name} --component ${submodule_name} --action apply
        set -e
        """
    }
}

def plan_apply_submodule(env_name, git_project_dir, submodule_name) {
    wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'XTerm']) {
        sh """
        #!/usr/env/bin bash
        echo "TF APPLY for ${env_name} | ${submodule_name} - component from git project ${git_project_dir}"
        set +e
        cd "${git_project_dir}"
        CURRENT_DIR=\$(pwd)
        python docker-run.py --env ${env_name} --component ${submodule_name} --action plan
        python docker-run.py --env ${env_name} --component ${submodule_name} --action apply
        source \${CURRENT_DIR}/${submodule_name}_plan_ret
        echo "\$exitcode" > plan_ret
        if [ "\$exitcode" == '1' ]; then exit 1; else exit 0; fi
        set -e
        """
    }
}

def confirm() {
    try {
        timeout(time: 15, unit: 'MINUTES') {
            env.Continue = input(
                id: 'Proceed1', message: 'Apply plan?', parameters: [
                    [$class: 'BooleanParameterDefinition', defaultValue: true, description: '', name: 'Apply Terraform']
                ]
            )
        }
    } catch(err) { // timeout reached or input false
        def user = err.getCauses()[0].getUser()
        env.Continue = false
        if('SYSTEM' == user.toString()) { // SYSTEM means timeout.
            echo "Timeout"
            error("Build failed because confirmation timed out")
        } else {
            echo "Aborted by: [${user}]"
        }
    }
}

def do_terraform(env_name, git_project, component) {
    plancode = plan_submodule(env_name, git_project, component)
    if (plancode == "2") {
        if ("${confirmation}" == "true") {
            confirm()
        } else {
            env.Continue = true
        }
        if (env.Continue == "true") {
            apply_submodule(env_name, git_project, component)
        }
    }
    else if (plancode == "3") {
        apply_submodule(env_name, git_project, component)
        env.Continue = true
    }
    else {
        env.Continue = true
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

        stage('Alfresco | Common') { steps { script { plan_apply_submodule(environment_name, project.alfresco, 'common')}}}
        stage('Alfresco | AmazonMQ') {
            when {
                expression { "${environment_name}" ==~ /(alfresco-dev|alfresco-sbx)/ }
            }
            steps {
                script { do_terraform(environment_name, project.alfresco, 'amazonmq')}
            }
        }
        stage('Alfresco | S3 Buckets') { steps { script { do_terraform(environment_name, project.alfresco, 's3buckets')}}}
        stage('Alfresco | Certs') { steps { script { do_terraform(environment_name, project.alfresco, 'certs')}}}
        stage('Alfresco | IAM') { steps { script { do_terraform(environment_name, project.alfresco, 'iam')}}}
        stage('Alfresco | Security Groups') { steps { script { plan_apply_submodule(environment_name, project.alfresco, 'security-groups')}}}
        stage('Alfresco | EFS') { steps { script { do_terraform(environment_name, project.alfresco, 'efs')}}}
        stage('Alfresco | RDS') { steps { script { do_terraform(environment_name, project.alfresco, 'rds')}}}
        stage('Alfresco | ElastiCache') { steps { script { do_terraform(environment_name, project.alfresco, 'elasticache-memcached')}}}
        stage('Alfresco | ES Migration') { steps { script { do_terraform(environment_name, project.alfresco, 'elk-migration')}}}
        stage('Alfresco | ASG') { steps { script { do_terraform(environment_name, project.alfresco, 'asg')}}}
        stage('Alfresco | ES Admin') { steps { script { do_terraform(environment_name, project.alfresco, 'es_admin')}}}
        stage('Alfresco | Cloudwatch Exporter') { steps { script { do_terraform(environment_name, project.alfresco, 'cloudwatch_exporter')}}}

        stage('Smoke test') {
            when {
                expression { "${environment_name}" == "delius-auto-test"}
            }
            steps {
                build job: "DAMS/Environments/${environment_name}/Alfresco/Smoke_tests"
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
