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
          allOf {
            not {changeset "VERSION"}
            changeset "Dockerfile"
          }
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
          //expression {
          //  sh(returnStatus: true, script: 'git status --porcelain | grep --quiet "BUILDNEWCONTAINER.txt"') == 1
          //}
          expression {
            sh(returnStatus: true, script: '[ -f BUILDNEWCONTAINER.txt ]') == 0
          }
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
    stage('Commit new VERSION') {
      when {
        beforeAgent true
        anyOf {
          allOf {
            not {changeset "VERSION"}
            changeset "Dockerfile"
          }
          triggeredBy cause: 'UserIdCause'
        }
      }
//      when {
//        beforeAgent true
//        anyOf {
//          // not {changeset "VERSION"}
//          // not {changeset "Jenkinsfile"}
//          expression {
//            sh(returnStatus: true, script: 'git status --porcelain | grep --quiet "VERSION"') == 1
//          }
//          expression {
//            sh(returnStatus: true, script: '[ -f BUILDNEWCONTAINER.txt ]') == 0
//          }
//        }
//      }
      steps {
        sh 'git config user.email "robin@mordasiewicz.com"'
        sh 'git config user.name "Robin Mordasiewicz"'
        // sh 'git add .'
        sh 'git diff --quiet && git diff --staged --quiet || git commit -am "`cat VERSION`"'
        sh 'git tag -a `cat VERSION` -m "`cat VERSION`" || echo "Tag: `cat VERSION` already exists"'
        withCredentials([gitUsernamePassword(credentialsId: 'github-pat', gitToolName: 'git')]) {
          sh 'git diff --quiet && git diff --staged --quiet || git push origin main'
          sh 'git push --tags'
        }
      }
    }
    stage('create new manifest') {
      steps {
        sh 'mkdir argocd'
        dir ( 'argocd' ) {
          git branch: 'main', url: 'https://github.com/robinmordasiewicz/argocd.git'
          sh 'sh increment-nginx-version.sh'
        }
      }
    }
    stage('commit new manifest') {
      steps {
        dir ( 'argocd' ) {
          sh 'git config user.email "robin@mordasiewicz.com"'
          sh 'git config user.name "Robin Mordasiewicz"'
          sh 'git add .'
          sh 'git diff --quiet && git diff --staged --quiet || git commit -am "NGINX Manifest `cat nginx/VERSION`"'
          withCredentials([gitUsernamePassword(credentialsId: 'github-pat', gitToolName: 'git')]) {
            // sh 'git diff --quiet && git diff --staged --quiet || git push origin main'
            sh 'git push origin main'
          }
        }
      }
    }
    stage('clean up') {
      steps {
        sh 'rm -rf argocd'
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
