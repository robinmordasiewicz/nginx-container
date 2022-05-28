pipeline {
  options {
    disableConcurrentBuilds()
    skipDefaultCheckout(true)
  }
  agent {
    kubernetes {
      yaml '''
        apiVersion: v1
        kind: Pod
        spec:
          containers:
          - name: ubuntu
            image: robinhoodis/ubuntu:latest
            imagePullPolicy: Always
            command:
            - cat
            tty: true
          - name: kaniko
            image: gcr.io/kaniko-project/executor:debug
            imagePullPolicy: IfNotPresent
            command:
            - /busybox/cat
            tty: true
            volumeMounts:
              - name: kaniko-secret
                mountPath: /kaniko/.docker
          restartPolicy: Never
          volumes:
            - name: kaniko-secret
              secret:
                secretName: regcred
                items:
                  - key: .dockerconfigjson
                    path: config.json
        '''
    }
  }
  stages {
    stage('INIT') {
      steps {
        cleanWs()
        checkout scm
        echo "${currentBuild.buildCauses}"
        echo "${currentBuild.getBuildCauses('hudson.model.Cause$UserCause')}"
        echo "${currentBuild.getBuildCauses('hudson.triggers.TimerTrigger$TimerTriggerCause')}"
        echo "isTriggeredByIndexing = ${currentBuild.getBuildCauses('jenkins.branch.BranchIndexingCause').size()}"
        echo "isTriggeredByCommit = ${currentBuild.getBuildCauses('com.cloudbees.jenkins.GitHubPushCause').size()}"
        echo "isTriggeredByUser = ${currentBuild.getBuildCauses('hudson.model.Cause$UserIdCause').size()}"
        echo "isTriggeredByTimer = ${currentBuild.getBuildCauses('hudson.triggers.TimerTrigger$TimerTriggerCause').size()}"
      }
    }
    stage('html changeset'){
      when {
        beforeAgent true
        anyOf {
          changeset "html/*"
        }
      }
      steps {
        sh 'echo "------------- html in the changeset -------------------"'
      }
    }
    stage('Jenkinsfile changeset'){
      when {
        beforeAgent true
        anyOf {
          changeset "Jenkinsfile"
        }
      }
      steps {
        sh 'echo "------------- Jenkinsfile in the changeset -------------------"'
      }
    }
    stage('VERSION changeset'){
      when {
        beforeAgent true
        anyOf {
          changeset "VERSION"
        }
      }
      steps {
        sh 'echo "------------- VERSION in the changeset -------------------"'
      }
    }
    stage('Increment VERSION') {
      when {
        beforeAgent true
        allOf {
          anyOf {
            changeset "Dockerfile"
            changeset "html/*"
            changeset "html/**"
            // changeset "Jenkinsfile"
            // changeset "increment-version.sh"
          }
          not { changeset "VERSION" }
          // triggeredBy cause: 'UserIdCause'
        }
      }
      steps {
        container('ubuntu') {
          sh 'sh increment-version.sh'
        }
      }
    }
    stage('Build/Push Container') {
      when {
        beforeAgent true
        expression {
          container('ubuntu') {
            sh(returnStatus: true, script: 'skopeo inspect docker://docker.io/robinhoodis/nginx:`cat VERSION`') == 1
          }
        }
      }
      steps {
        container(name: 'kaniko', shell: '/busybox/sh') {
          script {
            sh ''' 
            /kaniko/executor --dockerfile=Dockerfile \
                             --context=`pwd` \
                             --destination=robinhoodis/nginx:`cat VERSION` \
                             --destination=robinhoodis/nginx:latest \
                             --cache=true
            '''
          }
        }
      }
    }
    stage('Commit new VERSION') {
      when {
        beforeAgent true
        allOf {
          anyOf {
            changeset "Dockerfile"
            changeset "html/*"
            changeset "html/**"
            // changeset "Jenkinsfile"
            // changeset "increment-version.sh"
          }
          not { changeset "VERSION" }
          // triggeredBy cause: 'UserIdCause'
        }
      }
      steps {
        sh 'git config user.email "nginx@example.com"'
        sh 'git config user.name "nginx pipeline"'
        sh 'git add VERSION'
        sh 'git commit -m "`cat VERSION`"'
        // sh 'git add VERSION && git diff --quiet && git diff --staged --quiet || git commit -m "`cat VERSION`"'
        // sh 'git tag -a `cat VERSION` -m "`cat VERSION`" || echo "Tag: `cat VERSION` already exists"'
        withCredentials([gitUsernamePassword(credentialsId: 'github-pat', gitToolName: 'git')]) {
          //sh 'git diff --quiet && git diff --staged --quiet || git push origin main'
          sh 'git push origin HEAD:main'
          sh 'git push --tags'
        }
      }
    }
  }
  post {
    always {
      cleanWs(cleanWhenNotBuilt: false,
            deleteDirs: true,
            disableDeferredWipeout: true,
            notFailBuild: true,
            patterns: [[pattern: '.gitignore', type: 'INCLUDE'],
                       [pattern: '.propsfile', type: 'EXCLUDE']])
    }
  }
}
