# Introduction
This project is a quick demo of the usage of Terraform Cloud as a backend.  The intent is to have a lightweight project that can help you put something (anything) on AWS quickly while managing it all with Terraform config using Terraform Cloud as a backend.

# Why Use a Remote Backend?
Out of the box, Terraform manages the state of its objects by placing a `tfstate` file in your repo, which is problematic for the following reasons...

* This file contains secrets, and you might accidentally commit it.
* You might blow out your Git repo locally and lose that state file.
* If you're on a team, you run the risk of having everybody working with different (and likely out of sync) state files.
* You can have conflicts if more than one team member is applying at the same time.

Using a local state file is fine when you're taking a Terraform class, but once you get beyond that, working with a remote backend will mitigate all of these concerns.

# Why Choose Terraform Cloud?
My first attempts at a remote backend involved the creation of separate Terraform config to create an S3 bucket for state and a DynamoDB table to handle locking.  I eventually got that to work, but it had the following downsides...

* Where do I put **that** state?
* Aside from the bucket and the table, there was a lot of IAM policy stuff that also had to be added.  It seemed like a lot of boilerplate config for such a common use case.

At this point, I switched to Terraform Cloud.  It addresses these issues, and it allows you to set your variables there, including ones that have sensitive data.  As a result, I was able to do everything in this project without dealing with a bunch of `tfvars` files and potentially committing those accidentally.  It also made my Terraform commands much simpler.

# Initial Terraform Cloud Setup
To get started, you'll first need to create an account on the [Terraform Cloud](https://app.terraform.io) site.  Once you do that, you'll need to setup the ability for your Terraform commands to authenticate by doing the following...

* Click on your avatar and go into User Settings.
* Click on Tokens.
* Click Create an API token.
* Give it a description.  I just named it after my laptop which will be doing the authenticating.
* Copy the token that gets generated.  This will be your only chance to copy it.
* Edit your `.terraformrc` file and add your newly added token.  It will look similar the following example...

```hcl
credentials "app.terraform.io" {
  token = "Cn9dLYcAD70Yfw.atlasv1.UbJDXesSIpZizdz58AuaO09X6k6xEhWQWtyGVIXeQGDjmV22PfdkAhQyw7OQ0ZdMS3M"
}
```

# How To Get it Working
For the purposes of these instructions, I'm going to assume that you already have an AWS Account with an IAM user who serves as an admin who can do just about anything.  I also assume that you have already set that user up with an Access Key and a Secret Key.

### Configuring the Provider and Input Variables
The top portion of the config is just some initial setup where I define the AWS provider and pass in the authentication of the IAM user.

```hcl
variable "aws_access_key_id" {}
variable "aws_secret_access_key" {}

provider "aws" {
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
  region     = "us-west-1"
}
```

### Configuring the Backend
* Choose an organization name.  This could be your GitLab repo, the website you're working on, or your company.  It has to be unique within Terraform Cloud.  In this documentation, I used Docker's [random name generator](https://frightanic.com/goodies_content/docker-names.php) and settled on `sleepy-hypatia`
* Under workspaces, choose a prefix.  If you have multiple folders in your GitLab repo, and you run separate terraform commands under each one, then you might name your prefix after the folder you're currently in.  In this example, I went with `main-`.

```hcl
terraform {
  backend "remote" {
    organization = "sleepy-hypatia"

    workspaces {
      prefix = "main-"
    }
  }
}
```

### Adding your Object
The object you put out there in AWS isn't really important for this demo.  Here, we're more interested in the way that object is managed with Terraform Cloud.  Here's the DynamoDB config I used...

```hcl
resource "aws_dynamodb_table" "funtimes" {
  name           = "funtimes"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "alpha"

  attribute {
    name = "alpha"
    type = "S"
  }
}
```

### Terraform Cloud Setup
* Go to the [Terraform Cloud](https://app.terraform.io) site.
* Under the Organization dropdown, click "Create New Organization".  Organization Name will be `sleepy-hypatia`.
* It will ask you to connect to a Version Control Provider.  I skipped this by selecting No VCS Connection.  I haven't explored Version Control Providers, but for the time being, I'm content to run my Terraform commands from my local machine.
* Workspace Name is a little tricky.  You need to combine the prefix you have in the remote config above (`main-`) with the local workspace name we want to start with (we'll go with `dev`).  For this example, the Workspace Name will be `main-dev`.
* Go into `main-dev` and then click Configure variables.  Under the Terraform Variables section, add the `aws_access_key_id` and `aws_secret_access_key` of the IAM user that will build these components.  Make sure to mark both variables as sensitive.

### Running the Terraform Commands
* Back at your terminal, go to the folder that contains your Terraform config.
* Run `terraform init`.  You'll get prompted to enter a workspace.  In our case, the only choice is `dev` since that's the one we setup with the initial creation of the organization.  Once you choose `dev`, the local workspace will be `dev`, and it will be linked to the remote workspace called `main-dev`.
* Run `terraform apply`.  This will actually run on Terraform Cloud, so your client machine doesn't need to stay online while it's running.
* You can go out to the AWS console and verify that the DynamoDB table gets created.

### Teardown
* To tear down the AWS infrastructure, simply run `terraform destroy`.
* You can tear down the organization in Terraform Cloud by clicking Settings and then Delete Organization.

# Optional - Simulating a Team
Once you get the hang of this, one thing you can try is to clone this repo twice.  Then, you can play around with running one command from one repo and another command from another repo.  Everything should work fine with no conflicts and nothing getting out of sync.
