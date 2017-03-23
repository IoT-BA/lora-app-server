node {
    def image
    stage('Build') {
        echo 'Building..'
        checkout scm
        image = docker.build("iotba/lora-app-server")
    }
    stage('Test') {
        image.inside {
            sh "grep 'ENV LORASERVER_VERSION' Dockerfile | tr -d '\r' | awk '//{print \$3}' > version"
            sh 'lora-app-server -v'
        }
    }
    stage('Deploy') {
        def version = readFile 'version'
        def imageName = image.imageName()
        echo "Deploying version: ${version}"
        sh "docker tag ${imageName} ${imageName}:${version}"

        withCredentials([usernamePassword(credentialsId: 'hub.docker.com', passwordVariable: 'DOCKER_PASS', usernameVariable: 'DOCKER_USER')]) {
            sh "docker login -u='$DOCKER_USER' -p='$DOCKER_PASS'"
            sh "docker push ${imageName}:${version}"
            sh "docker push ${imageName}"
        }
    }
}
