@Library('jenkins_shared_library') _

pipeline{
  agent {
    label 'ec2-cloud'
  }

    environment {
        repo = '412284733352.dkr.ecr.ap-southeast-1.amazonaws.com/ros'
        default_tag = 'ros1_bridge'
        BITBUCKET_COMMON_CREDS = credentials('kabam-jenkins-bitbucket-creds')
    }

    stages {
        stage('Prepare') {
            when {
                expression { env.CHANGE_TARGET == 'develop' || env.CHANGE_TARGET == null }
            }
            steps{
                script{
                    jobName = pipelineUtils.getJobName()
                    echo "jobName is ${jobName}"
                }
            }
        }
        stage('Build & Push Image') {
            when {
                expression { env.CHANGE_TARGET == 'develop' || env.CHANGE_TARGET == null }
            }
            steps {
                echo "Building and pushing docker image"
                script {
                    sh(script: """
                        aws ecr get-login-password --region ap-southeast-1 | docker login --username AWS --password-stdin 412284733352.dkr.ecr.ap-southeast-1.amazonaws.com
                        find . -type f -name "*.repos" -exec sed -i 's|git@bitbucket.org:cognicept|https://${BITBUCKET_COMMON_CREDS}@bitbucket.org/cognicept|g' {} +
                        if [ "${jobName}" == "develop" ];then
                            docker buildx build --push -f Dockerfile -t ${repo}:${default_tag} .
                        else
                            docker buildx build --push -f Dockerfile -t ${repo}:${default_tag}_${jobName} .
                        fi
                    """)
                }
            }
        }

        stage('Archive') {
            steps {
                sh """
                    echo 'JOB_NAME: ${env.JOB_NAME}
                    BUILD_NUMBER: ${env.BUILD_NUMBER}
                    GIT_COMMIT: ${env.GIT_COMMIT}
                    IMAGE_TAG: ${repo}:${default_tag}_${env.GIT_COMMIT}'
                    > build.yaml
                """
            }
        }

        stage('Cleanup') {
            steps {
                script {
                    dockerUtils.dockerBuildPrune()
                }
            }
        }
    }

  post {
    always {
      script {
        jobName = pipelineUtils.getJobName()
        slackUtils.sendSlackNotification(
            jobName,
            'promote_to_production',
            "",
            "",
            ""
        )
      }
      archiveArtifacts artifacts:'build.yaml'
    }
  }
}