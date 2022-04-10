pipeline {
  options {
    disableConcurrentBuilds()
    skipDefaultCheckout(true)
  }
  triggers {  
    upstream(upstreamProjects: "docs", threshold: hudson.model.Result.SUCCESS)
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
      }
    }
    stage('Increment VERSION') {
      when {
        beforeAgent true
        anyOf {
          changeset "Dockerfile"
          triggeredBy cause: 'UserIdCause'
        }
      }
      steps {
        container('ubuntu') {
          sh 'sh increment-version.sh'
        }
      }
    }
    stage('Check repo for container') {
      when {
        beforeAgent true
        anyOf {
          changeset "VERSION"
          changeset "Dockerfile"
          triggeredBy cause: 'UserIdCause'
        }
      }
      steps {
        container('ubuntu') {
          sh 'skopeo inspect docker://docker.io/robinhoodis/nginx:`cat VERSION` > /dev/null || echo "create new container: `cat VERSION`" > BUILDNEWCONTAINER.txt'
        }
      }
    }
    stage('Build/Push Container') {
      when {
        beforeAgent true
        anyOf {
          changeset "VERSION"
          changeset "Dockerfile"
          triggeredBy cause: 'UserIdCause'
        }
      }
      steps {
        container(name: 'kaniko', shell: '/busybox/sh') {
          script {
            sh ''' 
            [ ! -f BUILDNEWCONTAINER.txt ] || \
            /kaniko/executor --dockerfile=Dockerfile \
                             --context=git://github.com/robinmordasiewicz/nginx.git \
                             --destination=robinhoodis/nginx:`cat VERSION` \
                             --destination=robinhoodis/nginx:latest \
                             --cache=true
            '''
          }
        }
      }
    }
    stage('commit new VERSION') {
      when {
        beforeAgent true
        anyOf {
          changeset "VERSION"
          changeset "Dockerfile"
          triggeredBy cause: 'UserIdCause'
        }
      }
      steps {
        sh 'git config user.email "robin@mordasiewicz.com"'
        sh 'git config user.name "Robin Mordasiewicz"'
        sh 'git add .'
        sh 'git tag -a `cat VERSION` -m "`cat VERSION`"'
        sh 'git diff --quiet && git diff --staged --quiet || git commit -am "`cat VERSION`"'
        withCredentials([gitUsernamePassword(credentialsId: 'github-pat', gitToolName: 'git')]) {
          sh 'git diff --quiet && git diff --staged --quiet || git push origin main'
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
