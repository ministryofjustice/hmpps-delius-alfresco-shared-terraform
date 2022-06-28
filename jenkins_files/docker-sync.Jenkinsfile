def project = [:]
project.alfresco  = 'hmpps-delius-alfresco-shared-terraform'
project.branch = 'master'

def environments = [
  'delius-test'
]

def prepare_env() {
    sh '''
    #!/usr/env/bin bash
    docker pull mojdigitalstudio/hmpps-terraform-builder:latest
    '''
}

def do_s3_sync_dry_run(env_name, git_project_dir) {
    wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'XTerm']) {
        sh """
        #!/usr/env/bin bash
        echo "AWS SYNC for ${env_name}"
        set +e
        cd "${git_project_dir}"
        CURRENT_DIR=\$(pwd)
        # set region
        docker run --rm -v \$(pwd):/home/tools/data \
          -v \${HOME}/.aws:/home/tools/.aws \
          -e RUN_MODE=false \
          mojdigitalstudio/hmpps-terraform-builder sh scripts/s3_copy_contents.sh ${env_name}
        set -e
        """
        return readFile("${git_project_dir}/plan_ret").trim()
    }
}

def do_s3_sync_full_run(env_name, git_project_dir) {
    wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'XTerm']) {
        sh """
        #!/usr/env/bin bash
        echo "AWS SYNC for ${env_name}"
        set +e
        cd "${git_project_dir}"
        CURRENT_DIR=\$(pwd)
        # set region
        docker run --rm -v \$(pwd):/home/tools/data \
          -v \${HOME}/.aws:/home/tools/.aws \
          -e RUN_MODE=true \
          mojdigitalstudio/hmpps-terraform-builder sh scripts/s3_copy_contents.sh ${env_name}
        set -e
        """
    }
}

def do_s3_sync(env_name, git_project_dir) {
    if (do_s3_sync_dry_run(env_name, git_project_dir) == "2") {
        confirm()
        if (env.Continue == "true") {
            do_s3_sync_full_run(env_name, git_project_dir)
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
                id: 'Proceed1', message: 'Sync s3 buckets?', parameters: [
                    [$class: 'BooleanParameterDefinition', defaultValue: true, description: '', name: 'Do s3bucket sync']
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

        stage('Alfresco | Sync S3 Buckets') {
          steps {
            script {
              do_s3_sync(environment_name, project.alfresco)
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
