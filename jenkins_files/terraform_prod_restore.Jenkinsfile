def prepare_env() {
    sh '''
    #!/usr/env/bin bash
    docker pull mojdigitalstudio/hmpps-terraform-builder:latest
    '''
}

def do_terraform(env_name, comp) {
    wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'XTerm']) {
        sh """
        #!/usr/env/bin bash
        echo "TF PLAN for ${env_name} | ${comp} - component"
        set +e
        CURRENT_DIR=\$(pwd)
        python docker-run.py --env ${env_name} --component ${comp} --action plan
        source \${CURRENT_DIR}/${comp}_plan_ret
        echo "\$exitcode" > plan_ret
        if [ "\$exitcode" == '1' ]; then exit 1; else echo "plan passed"; fi
        if [ "${env_name}" != "alfresco-dev" ]; then exit 1; else echo "environment is dev environment, applying"; fi
        python docker-run.py --env ${env_name} --component ${comp} --action apply
        source \${CURRENT_DIR}/${comp}_plan_ret
        if [ "\$exitcode" != '0' ]; then exit \$exitcode; else echo "apply passed"; fi
        set -e
        """
        return readFile("plan_ret").trim()
    }
}

pipeline {
    agent { label "jenkins_slave" }
    environment {
        environment_name = "alfresco-dev"
    }
    options {
        ansiColor('xterm')
    }
    stages {
        stage('setup') {
            steps{
                slackSend(message: "Build started on \"${environment_name}\" - ${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL.replace(':8080','')}|Open>)")
                prepare_env()
            }
        }
        stage('Alfresco | RDS') { steps { script { do_terraform(environment_name, 'database')}}}
        stage('Alfresco | ASG') { steps { script { do_terraform(environment_name, 'asg')}}}
        stage('Alfresco | ES Admin') { steps { script { do_terraform(environment_name, 'es_admin')}}}
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
