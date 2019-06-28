node {
  def tag_name = env.BRANCH_NAME.split('/').last()
  if ( tag_name == "master" ) {
    tag_name = "production"
  }
  checkout scm
  sh "docker build -t nulib/meadow:${tag_name} ."
  docker.withRegistry('', 'docker-hub-credentials') {
    docker.image("nulib/meadow:${tag_name}").push()
  }
  sh "docker tag \$(docker image ls -q --filter 'label=edu.northwestern.library.stage=deps' --filter 'label=edu.northwestern.library.app=meadow' | head -1) nulib/meadow-deps:${tag_name}"
  sh "docker tag \$(docker image ls -q --filter 'label=edu.northwestern.library.stage=assets' --filter 'label=edu.northwestern.library.app=meadow' | head -1) nulib/meadow-assets:${tag_name}"
  sh "docker image prune -f"
  sh "docker run -t -v /home/ec2-user/.aws:/root/.aws nulib/awscli --profile ${tag_name} ecs update-service --cluster meadow --service meadow --force-new-deployment"
}
