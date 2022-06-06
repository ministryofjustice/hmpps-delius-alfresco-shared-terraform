def project = [:]
project.network   = 'hmpps-delius-network-terraform'
project.dcore     = 'hmpps-delius-core-terraform'
project.alfresco  = 'hmpps-delius-alfresco-shared-terraform'

def environments = [
  'alfresco-dev',
  'alfresco-sbx',
  'delius-core-dev',
  'delius-training-test',
  'delius-test',
]

def prepare_env() {
    sh '''
    #!/usr/env/bin bash
    docker pull mojdigitalstudio/hmpps-terraform-builder:latest
    '''
}

def get_configs(git_project_dir) {
    wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'XTerm']) {
        sh """
        #!/usr/env/bin bash
        cd "${git_project_dir}"
        git clone https://github.com/ministryofjustice/hmpps-env-configs.git env_configs
        set -e
        """
    }
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
        python docker-run.py --env ${env_name} --component ${submodule_name} --action apply
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
    if (plan_submodule(env_name, git_project, component) == "2") {
        confirm()
        if (env.Continue == "true") {
            apply_submodule(env_name, git_project, component)
        }
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

    parameters {
        choice(
          name: 'environment_name',
          choices: environments,
          description: 'Select environment for creation or updating.'
        )
    }

    stages {

        stage('Alfresco | Get Configs') { steps { script { get_configs(project.alfresco)}}}

        stage('setup') {
            steps {
                slackSend(message: "Build started on \"${environment_name}\" - ${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL.replace(':8080','')}|Open>)")

                dir( project.network ) {
                  git url: 'git@github.com:ministryofjustice/' + project.network, branch: 'master', credentialsId: 'f44bc5f1-30bd-4ab9-ad61-cc32caf1562a'
                }
                dir( project.alfresco ) {
                  git url: 'git@github.com:ministryofjustice/' + project.alfresco, branch: 'issue-67-add-copy-scripts', credentialsId: 'f44bc5f1-30bd-4ab9-ad61-cc32caf1562a'
                }

                prepare_env()
            }
        }

        stage('Delius | Alfresco Common') {
          steps {
            script {
              do_terraform(environment_name, project.alfresco, 'common')
            }
          }
        }

        stage('Delius | Alfresco Dynamodb') {
          steps {
            script {
              do_terraform(environment_name, project.alfresco, 'dynamodb')
            }
          }
        }

        stage('Delius | Alfresco S3 Buckets') {
          steps {
            script {
              do_terraform(environment_name, project.alfresco, 's3buckets')
            }
          }
        }

        stage('Delius | Alfresco Certs') {
          steps {
            script {
              do_terraform(environment_name, project.alfresco, 'certs')
            }
          }
        }

        stage('Delius | Alfresco IAM') {
          steps {
            script {
              do_terraform(environment_name, project.alfresco, 'iam')
            }
          }
        }

        stage('Delius | Alfresco Security Groups') {
          steps {
            script {
              do_terraform(environment_name, project.alfresco, 'security-groups')
            }
          }
        }

        stage('Delius | Alfresco RDS') {
          steps {
            script {
              do_terraform(environment_name, project.alfresco, 'rds')
            }
          }
        }

        stage('Delius | Alfresco ElastiCache') {
          steps {
            script {
              do_terraform(environment_name, project.alfresco, 'elasticache-memcached')
            }
          }
        }

        stage('Delius | Alfresco ASG') {
          steps {
            script {
              do_terraform(environment_name, project.alfresco, 'asg')
            }
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
