pipeline {
  agent { label 'centos-lxc-ci-2' }
  options {
    buildDiscarder(logRotator(daysToKeepStr:'14'))
  }
  environment {
    DOCKER_IO_CREDS=credentials('docker_creds')
    DOCKER_CONFIG="${WORKSPACE}/.docker"
    TEST_IMAGE="mobile-app-tools-test:${BUILD_TAG}"
    TEST_PATHS='^tools/|^analysis/|^phone/packages/theme_schema/|^Dockerfile$|^\\.dockerignore$|^\\.jenkins/gerrit_check_tools\\.groovy$'
  }
  triggers {
    gerrit(serverName: 'git.portaone.com',
         gerritProjects: [[
           compareType: 'PLAIN',
           pattern: 'porta-phone/mobile-app',
           branches: [[ compareType: 'REG_EXP', pattern: '.*' ]],
           disableStrictForbiddenFileVerification: false
         ]],
         triggerOnEvents: [patchsetCreated()]
    )
  }
  stages {
    stage('Check changed paths') {
      steps {
        script {
          // Every patchset triggers this job, so every patchset gets a vote. One that touches
          // none of TEST_PATHS has nothing to test here: the job passes without the tests.
          env.RUN_TESTS = sh(returnStatus: true,
              script: 'git diff --name-only HEAD~1 HEAD | grep -qE "$TEST_PATHS"') == 0 ? 'true' : 'false'
          echo(env.RUN_TESTS == 'true' ? 'The patchset changes tested paths: running the tests.'
                                       : 'The patchset changes none of the tested paths: nothing to test.')
        }
      }
    }
    stage('Login to Docker Hub') {
      when { environment name: 'RUN_TESTS', value: 'true' }
      steps {
        sh label: "Docker Hub login", script:
          "echo ${DOCKER_IO_CREDS_PSW} | docker login --username ${DOCKER_IO_CREDS_USR} --password-stdin"
      }
    }
    stage('Run unit tests') {
      when { environment name: 'RUN_TESTS', value: 'true' }
      steps {
        sh 'docker build --target tools-test -t "$TEST_IMAGE" .'
        sh 'docker run --rm "$TEST_IMAGE"'
      }
      post {
        always {
          sh 'docker rmi "$TEST_IMAGE" || true'
          sh "docker logout"
        }
      }
    }
  }
  post {
    always {
      cleanWs()
    }
  }
}
