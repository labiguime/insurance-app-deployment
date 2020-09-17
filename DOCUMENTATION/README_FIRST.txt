1) Create a new application in beanstalk and two environment (default Docker): 1 worker and 1 web server with a Classic Load Balancer
2) Create an RDS instance and give access rights to beanstalk environments' roles
3) Create an Elasticache instance (for redis) and make it accessible by the two environments
4) Create an S3 storage folder to keep public assets
5) Create an Elastic Container Registry instance
6) Change both Dockerrun files to reflect new ECR name
7) Change PACKAGE/.platform/hooks/postdeploy/02_pull_assets.sh to reflect new S3 name
8) Create the pipeline
9) Give permissions (s3_policy.json) to S3
     /!\ Make sure to modify s3_policy to reflect the name of the s3 storage folder
 && the name of the roles that will be able to access it (the pipeline will need to be able to access it too)
10) For the ECR instance, let beanstalk and codebuild access it (change permission)
11) Obviously, copy the files in PACKAGE inside your app
12) Run the pipeline (add commit and push the new files)
13) While the app is loading add the env variables to the environments

ENVIRONMENT VARIABLES NEEDED:

RAILS_MASTER_KEY
REDIS_URL
DATABASE_HOST
DATABASE_NAME
DATABASE_USERNAME
DATABASE_PASSWORD

14) - Configure SSL
   - Make sure that Loadbalancer is enabled in the beanstalk app
