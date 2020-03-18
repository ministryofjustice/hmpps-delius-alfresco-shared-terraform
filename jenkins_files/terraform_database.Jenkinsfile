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
    options {
        ansiColor('xterm')
    }
    stages {
        stage('setup') {
            steps{
                prepare_env()
            }
        }
        // stage('Alfresco | AMI Update') {steps {do_terraform(environment_name, 'ami_permissions')}}
        // stage('Alfresco | Common') {steps {do_terraform(environment_name, 'common')}}
        // stage('Alfresco | AmazonMQ') {steps {do_terraform(environment_name, 'amazonmq')}}
        // stage('Alfresco | S3 Buckets') { steps { script { do_terraform(environment_name, 's3buckets')}}}
        // stage('Alfresco | Certs') { steps { script { do_terraform(environment_name, 'certs')}}}
        // stage('Alfresco | IAM') { steps { script { do_terraform(environment_name, 'iam')}}}
        // stage('Alfresco | Security Groups') { steps { script { do_terraform(environment_name, 'security-groups')}}}
        // stage('Alfresco | EFS') { steps { script { do_terraform(environment_name, 'efs')}}}
        stage('Alfresco | RDS') { steps { script { do_terraform(environment_name, 'database')}}}
        // stage('Alfresco | ElastiCache') { steps { script { do_terraform(environment_name, 'elasticache-memcached')}}}
        // stage('Alfresco | ES Migration') { steps { script { do_terraform(environment_name, 'elk-migration')}}}
        stage('Alfresco | ASG') { steps { script { do_terraform(environment_name, 'asg')}}}
        stage('Alfresco | WAF') { steps { script { do_terraform(environment_name, 'waf')}}}
        // stage('Alfresco | ES Admin') { steps { script { do_terraform(environment_name, 'es_admin')}}}
        // stage('Alfresco | Cloudwatch Exporter') { steps { script { do_terraform(environment_name, 'cloudwatch_exporter')}}}
        // stage('Alfresco | Monitoring') { steps { script { do_terraform(environment_name, 'monitoring')}}}
    }
    post {
        always {
            deleteDir()
        }
    }
}
