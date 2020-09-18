# Rails Web App Deployment for Hawyward Insurance Brokerage

Here is a collection of files that I produced while I was working on deploying the Web App to AWS.
First I will answer a few questions, and then I will explain the technologies that I used and what I did.

## Q&A

### Why did the website need to be migrated from Heroku to AWS?
  + The servers needed to be in Canada for legal reasons. Since Heroku only offers servers in the US, we chose AWS.
  
### Why Beanstalk?
  + This application is developed and maintained by a single developer so I had to choose a technology that they could easily use and understand. While setting everything up is technical, it becomes more intuitive to use Beanstalk when everything is already running.

### What is Hatchbox.io and what was wrong with it?
  + Hatchbox simplifies the deployment process to AWS by providing the user with pre-made config files and an easy-to-use interface. While it allows you to deploy quickly the drawbacks are: monthly, less control over the deployment structure and thus also the costs.
  
## What was accomplished

### Docker
The whole project was Dockerized using different techniques to minimize the size of the image. Multi-staging was experimented and one of the challenges was to cache the Dockerfile as CodeBuild is not efficient at hitting the cache. We used S3 to store the assets so that they would not have to be recompiled everytime and we wrote a shell script to check for a change.
The docker image was uploaded to Elastic Container Registry in an effort to centralize all the services as much as possible. (Even though one could argue against)
One of the major challenges was the environment variables that we wanted to completely isolate from the pipeline and CodeBuild we give pipeline access to another user. The RAILS MASTER KEY is necessary to compile the assets so we had to use a placeholder in order to compile them and the MASTER KEY would be later overwritten by Beanstalk.

### CodePipeline (CI/CD)
Two complex pipeline were created as there were two environment to deploy, namely 'staging' and production. The customer wanted to deploy to staging first and be able to test it and only when he would be confident with staging would we deploy to production.
The pipeline had a source coming from Github and then a Build phase involving CodeBuild since the Docker image had to be built everytime. With efficient techniques, we were hitting the cache and simply modifying Rails code (without touching the assets) would only take 30 seconds for the image to be built.
The deployment stage involved deploying to staging and then a manual check would be the trigger for the second pipeline which would then reuse the Docker image from staging to quickly deploy to production and then the worker environment.

### Cron jobs & assets with postdeploy hooks, and NGINX config
To launch cron jobs, we would use postdeploy hooks to connect to the Docker container running inside our EC2 instance and manually start the service on each instance. We also used a postdeploy hook to place the assets in the right folder for NGINX to be able to serve them.
NGINX was configured through an ebextension as it needed some customization.

### Other services
 In addition to these services, we also used Elasticache Redis clusters to connect the workers with the web applications, we created several custom policies to give access rights to many services. We also configured SSL and created robust security groups within the VPC.
 More information is available in the **DOCUMENTATION** folder, which details the key step to get the app running (operational but not secure and complete). Also you can learn more by exploring the rest of the files.
