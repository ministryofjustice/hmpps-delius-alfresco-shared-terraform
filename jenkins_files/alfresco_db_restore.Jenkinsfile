def project = [:]
project.alfresco  = 'hmpps-delius-alfresco-shared-terraform'
project.branch = 'issue_88_alfresco_db_restore'

def environments = [
  'delius-training-test',
  'delius-test',
  'delius-po-test1',
  'delius-po-test2',
  'alfresco-dev'
]

def prepare_env() {
    sh '''
    #!/usr/env/bin bash
    docker pull mojdigitalstudio/hmpps-base-psql:0.0.166-alpha
    '''
}

def do_alfresco_db_restore_dry_run(env_name, git_project_dir) {
    wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'XTerm']) {
        sh """
        #!/usr/env/bin bash
        echo "Alfresco DB Restore for ${env_name}"
        set +e
        cd "${git_project_dir}"
        pwd
        CURRENT_DIR=\$(pwd)
        # set region
        docker run --rm -v \$(pwd):/home/tools/data \
          -v \${HOME}/.aws:/home/tools/.aws \
          -e RUN_MODE=false \
          mojdigitalstudio/hmpps-base-psql:0.0.166-alpha sh scripts/alfresco_db_restore.sh ${env_name}
        set -e
        """
        return readFile("${git_project_dir}/plan_ret").trim()
    }
}



def do_alfresco_db_restore_full_run(env_name, git_project_dir) {
    wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'XTerm']) {
        sh """
        #!/usr/env/bin bash
        echo "Alfresco DB Restore for ${env_name}"
        set +e
        cd "${git_project_dir}"
        CURRENT_DIR=\$(pwd)
        # set region
        docker run --rm -v \$(pwd):/home/tools/data \
          -v \${HOME}/.aws:/home/tools/.aws \
          -e RUN_MODE=true \
          mojdigitalstudio/hmpps-base-psql:0.0.166-alpha sh scripts/alfresco_db_restore.sh ${env_name}
        set -e
        """
    }
}

def do_alfresco_db_restore(env_name, git_project_dir) {
    if (do_alfresco_db_restore_dry_run(env_name, git_project_dir) == "2") {
        confirm()
        if (env.Continue == "true") {
            do_alfresco_db_restore_full_run(env_name, git_project_dir)
        }
    }
    else {
        env.Continue = true
    }
}

def confirm() {
    try {
        timeout(time: 5, unit: 'MINUTES') {
            env.Continue = input(
                id: 'Proceed1', message: 'Perform DB Restore?', parameters: [
                    [$class: 'BooleanParameterDefinition', defaultValue: true, description: '', name: 'Do DB restore']
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

        stage('setup') {
            steps {
                slackSend(message: "Build started on \"${environment_name}\" - ${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL.replace(':8080','')}|Open>)")
                dir( project.alfresco ) {
                  git url: 'git@github.com:ministryofjustice/' + project.alfresco, branch: project.branch, credentialsId: 'f44bc5f1-30bd-4ab9-ad61-cc32caf1562a'
                }

				                prepare_env()
				            }
				        }

				        stage('Alfresco | DB Restore') {
				          steps {
				            script {
				              do_alfresco_db_restore(environment_name, project.alfresco)
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
