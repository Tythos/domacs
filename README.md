Software time today, baby! And it's something kind of fun. I swear.

There's a fun project I recently got working that combines a couple of different and interesting technologies, including one of my favorite cloud providers (DigitalOcean); a great way to use their resources (Terraform); and a way to procedurally configure the virtual machines they host (cloud-init). We'll use these technologies to spin up our own Minecraft server!

In the past, I've done this [with Docker on my desktop](https://dev.to/tythos/learning-docker-and-networking-with-minecraft-1lp3), but this comes with a lot of disadvantages. Persistence is something of a bear, and there's a lot of networking configurations (like port forwarding and open firewall rules through your residential ISP) that aren't ideal, especially if you want other people outside your home to be able to play with your family.

## The Fundamental Element

We could, theoretically, go full-up Kubernetes or deploy a container on the cloud provider too. But the fundamental "unit" of most cloud providers is instead a virtual machine of some kind. In the case of DigitalOcean, those VMs are called "droplets". So, let's start by creating a "droplet" specification in Terraform.

We're going to use the [DigitalOcean Terraform provider](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs)  here. This is one of my favorite things about DigitalOcean, by the way--the Terraform provider is well-documented and punches *WAY* above its weight. It's Azure-levels of quality (way above AWS), but without MSFT.

If you look at the `digitalocean_droplet` resource documentation, you'll see it's pretty easy to just define one and spin it up. One thing you will want to consult, though, are the ["slugs" used for key reference labels](https://slugs.do-api.dev/) (like available images and VM sizes). But this is enough for us to define our "core" resource, the VM/droplet, in our first Terraform file, `dodroplet.tf`:

```tf
resource "digitalocean_droplet" "dodroplet" {
  image     = "ubuntu-22-04-x64"
  name      = "dodroplet"
  region    = var.DO_REGION
  size      = "s-4vcpu-8gb"
  ssh_keys  = [digitalocean_ssh_key.dosshkey.id]
  user_data = data.template_file.user_data_yaml.rendered
}
```

Some observations:

* We're going to pass in the "region" as a variable, so anyone deploying from this Terraform specification can chose exactly where it will spin up

* There are a few references, which we haven't defined yet, to resources like an SSH key and a `user_data` field. The `user_data` field is particularly interesting, because this is how we'll pass in our "cloud-init" configuration (more on that later).

* We're using a basic 4-cpu, 8gb-RAM image here; it's not the cheapest one, but only costs about $0.07/hour; this comes out to about $50/month, which is comparable to another virtual private server I have on a different provider.

* Those specs might actually be overkill for our Minecraft server! We could probably get away with a cheaper one if we had to.

![damn the networking, full speed ahead!](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/xur3gcrvhwaghitui0jw.jpg)

Some more words about "cloud-init" and the `user_data` field: For now, know that "cloud-init" is a way to provide a `.YAML`-like specification for how a VM should be configured as it boots. Much like Ansible, "cloud-init" can define specific "playbooks" or blocks of properties and behaviors--like what packages need to be installed. In this case, we're saying this content will come from a template that we'll procedurally "render" during deployment, when Terraform interpolates specific values.

## Project Namespaces

We'll add a `digitalocean_project` resource next. This will help us group our resources together into a logical namespace. A project gives us a nice way to organize related resources and, for ease of cost control purposes, lets us delete everything simply by getting rid of the project when we're done. Here's the contents of `doproject.tf`:

```tf
resource "digitalocean_project" "doproject" {
  name        = "domacs"
  description = "Namespace for encapsulation of cloud resources"
  purpose     = "Demonstration"
  environment = "Development"

  resources = [
    digitalocean_droplet.dodroplet.urn,
    digitalocean_domain.dodomain.urn,
    digitalocean_volume.dovolume.urn
  ]
}
```

(Note we include the droplet, a domain, and a volume; we'll define the other, non-droplet resources in just a moment.)

## Variables and Inputs

If you signed up for DigitalOcean, you've seen the control panel from which you can monitor your resources. Use the "API" section of this page to generate a new token. This token is sensitive, but Terraform will need it in order to have the authority to spin up your resources. Here's a screenshot of what to look for.

![digitalocean dashboard and api tokens](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/fduvn2o5f8603inamjgb.png)

We'll pass this token in as a variable, or input. Create a `variables.tf` file and define what these inputs should be like:

```tf
variable "DO_TOKEN" {
  type        = string
  description = "API token for deployment of DigitalOcean resources"
}

variable "DOMAIN_NAME" {
  type        = string
  description = "Managed domain name (should point to DigitalOcean NS records) used by the VM"
}

variable "ADMIN_USER" {
  type        = string
  description = "Name of user who will initially be able to connect to the server (e.g., before other whitelist names are added)"
}

variable "ADMIN_UUID" {
  type        = string
  description = "UUID of user who will initially be able to connect to the server (see https://mcuuid.net for easy lookup)"
}

variable "DO_REGION" {
  type        = string
  description = "DigitalOcean region into which resources will be deployed"
}
```

There are several ways to pass in values for these variables. You can create a `terraform.tfvars` file that defines basic `key="string-value"` mappings line-by-line (like `DO_REGION="sfo3"`), if you're okay with those values touching disk.

You can also define an environmental variable that beings with `TF_VAR_`, followed by the name of the Terraform variable. This is a great trick--the sensitive values never touch disk and can be automatically mapped from things like CI runner tokens. If you take the former approach, though, make sure you add `*.tfvars` to your `.gitignore` file to make sure sensitive values aren't added to version control!

## SSH

Let's say we just want to spin up the droplet and start inspecting it. We don't want to hard-code user credentials as part of the VM specification, so we'll set up SSH instead. To do this, we'll take advantage of a neat provider built into Terraform to define a private key, within a `tlskey.tf` file with the following contents:

```tf
resource "tls_private_key" "tlskey" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
```

Once we've defined the TLS private key, we can use this to define the SSH key resource that will be passed into our droplet (as you may have already noticed from the `dodroplet` specification above!).

```tf
resource "digitalocean_ssh_key" "dosshkey" {
  name       = "dosshkey"
  public_key = tls_private_key.tlskey.public_key_openssh
}
```

The VM only needs the public part, so it will know to accept users logging in with that key. The private part we will keep for ourself. Specifically, we'll add the private key to our outputs; create an `outputs.tf` file and include the following:

```tf
output "PRIVATE_SSH_KEY" {
  value     = tls_private_key.tlskey.private_key_pem
  sensitive = true
}

output "VM_IP_ADDR" {
  value = digitalocean_droplet.dodroplet.ipv4_address
}
```

Once our infrastructure is deployed, we'll be able to call `terraform output -raw PRIVATE_SSH_KEY > id_rsa` to generate a key file that we can use in conjunction with an `ssh` command. You'll notice we also want to capture and report the IP address of the VM, so we know where we'll be logging into. (Since the latter value is not sensitive, it will be automatically reported by Terraform directly to the console upon deployment.)

## cloud-init

We're going to use a template data to define our "cloud-init" configuration. This will be "interpolated" using specific values we want to write into the "cloud-init" behavior. Create a `user_data.yaml.tpl` file and populate it with the following; there's a lot going on here, so stick with me and I'll explain it in just a moment:

```yaml
#cloud-config
package_update: true
package_upgrade: true

packages:
  - openjdk-21-jre-headless
  - screen

write_files:
  - path: ${PERSISTENT_VOLUME_PATH}/start_minecraft.sh
    permissions: '0755'
    content: |
      #!/bin/bash
      cd ${PERSISTENT_VOLUME_PATH}
      java -Xmx1024M -Xms1024M -jar minecraft_server.1.21.1.jar --nogui 
  - path: ${PERSISTENT_VOLUME_PATH}/server.properties
    permission: '0755'
    content: |
      difficulty=normal
      white-list=true
  - path: ${PERSISTENT_VOLUME_PATH}/ops.json
    permission: '0755'
    content: |
      [
        {
          "uuid": "${ADMIN_UUID}",
          "name": "${ADMIN_USER}",
          "level": 4
        }
      ]

runcmd:
  - mkdir -o ${PERSISTENT_VOLUME_PATH}
  - cd ${PERSISTENT_VOLUME_PATH}
  - wget -O minecraft_server.1.21.1.jar https://piston-data.mojang.com/v1/objects/59353fb40c36d304f2035d51e7d6e6baa98dc05c/server.jar
  - echo "eula=true" > ${PERSISTENT_VOLUME_PATH}/eula.txt
  - bash ${PERSISTENT_VOLUME_PATH}/start_minecraft.sh

final_message: "Minecraft server setup complete!"
```

Let's go block by block:

* After the shebang, we define several options that tell "cloud-init" to update the package index and perform any upgrades

* In the `packages` block, we list specific packages we want the VM to install, like the OpenJDK runtime

* In the `write_files` block, we define the contents (and filename, and permissions) of several files we want to write into the filesystem; these are located by the variable `${PERSISTENT_VOLUME_PATH}` (which we'll pass in to reference our mounted volume), and include things like the list of "operators" initially authorized to connect to our Minecraft server; the `server.properties` that will let us customize our Minecraft configuration (like what difficulty exists and whether or not the whitelist is enabled); and a shell script used to launch the Minecraft server by launching the "fat .JAR" with the `java` command.

* In the `runcmd` block, we define several commands that need to be run when the system is launched. Specifically, we need to (within the context of our persistent volume path) make sure the fat .JAR is downloaded; write out the EULA approval; and run the script we defined in a previous block. (You may want to check [the official page](https://www.minecraft.net/en-us/download/server) to make sure you have the latest URL for this "fat .JAR".)

* Finally, in the `final_message` block, we include a message to verify the "cloud-init" configuration has successfully been applied. This can be useful if you lose track of the startup log messages. Another useful technique is to set a custom environmental variable that you can check from the shell upon boot.

Once this file is defined, we need to tell Terraform this can be interpolated and rendered as a template. Create a `data.tf` file and add the specification for this resource:

```tf
data "template_file" "user_data_yaml" {
  template = file("${path.module}/user_data.yaml.tpl")

  vars = {
    ADMIN_USER = var.ADMIN_USER
    ADMIN_UUID = var.ADMIN_UUID
    PERSISTENT_VOLUME_PATH = "/mnt/${digitalocean_volume.dovolume.name}/minecraft"
  }
}
```

In this case, we're just passing a few variables into the template interpolation, as well as procedurally constructing the path where the persistent volume will be mounted. (This is done simply by referencing the volume name, which we can do procedurally--isn't Terraform great!?)

## Providers

If you've used Terraform before, you might recognize we haven't defined our providers yet. We are using some built-in providers, like template and TLS, but we also need to define the DigitalOcean provider. Add a `providers.tf` and we'll populate it now:

```tf
terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.DO_TOKEN
}
```

Note that we just pass through the API token from our variable inputs. Easy!

## Volume

We haven't defined our persistent volume yet. This will let us ensure the state of the server is maintained, even if the VM itself gets rebooted. This will take two steps: first, defining the volume, and second, mounting (or mapping) it to the droplet. First, create a `dovolume.tf` and populate it as follows:

```tf
resource "digitalocean_volume" "dovolume" {
  region                  = var.DO_REGION
  name                    = "dovolume"
  size                    = 100
  initial_filesystem_type = "ext4"
  description             = "Persistent storage for DOMACS server configuration and world data"
}
```

(Note that volumes, like droplets themselves, must be deployed to a a datacenter in a specific region. Since we've defined this value as a Terraform variable, ensuring both of them are co-located is a snap, even if other users deploy their infrastructure to other regions.)

Once we've defined the volume, we're ready to "mount" into the droplet--specifically, we'll need to define an "attachment" resource that tells DigitalOcean that our specific VM should mount that specific volume. Create a `domount.tf` file to do so:

```tf
resource "digitalocean_volume_attachment" "domount" {
  droplet_id = digitalocean_droplet.dodroplet.id
  volume_id  = digitalocean_volume.dovolume.id
}
```

## Domain

We could, within Minecraft, just connect to the VM's IP address--but this is inconvenient and can change if/when the VM reboots. Instead, we'll register a domain name (I have several just lying around from various side projects!) and [point it to the DigitalOcean nameservers](https://docs.digitalocean.com/products/networking/dns/getting-started/dns-registrars/). Then, create a `dodomain.tf` file that will define the domain resource that performs the A-record mapping automatically:

```tf
resource "digitalocean_domain" "dodomain" {
  name       = var.DOMAIN_NAME
  ip_address = digitalocean_droplet.dodroplet.ipv4_address
}
```

## Graphing

One handy thing you can do to verify your infrastructure is to generate a graph of the relationships Terraform has derived. (If you are on Windows, it may be easier to use WSL for the next command, since you will need a command-line vector graphics tool like GraphViz.) You can pipe the infrastructure specification into `dot` to generate a shiny SVG file:

```sh
terraform graph | dot -Tsvg -o graph.svg
```

Just don't ask me why it things the volume is related to the "cloud-init" configuration! I think some wires got crossed.

![results of terraform graph to dot svg](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/c0ghpotp9b4k52lg6mm1.png)

(If this doesn't look visually appealing, there are ways to pass these results through [other, shinier tools](https://dev.to/miketysonofthecloud/best-tools-to-visualize-your-terraform-252a).)

## Finally, Deployment!

We have a full-up infrastructure now that is ready for our Terraform commands! Assuming our variables have been defined, we're ready for the traditional three-step:

```sh
terraform init
terraform plan
terraform apply
```

To verify, you can go to your DigitalOcean control panel and look for two things:

1. Verify the project, droplet, volume, and domain are all created

2. Use the built-in console to log into the VM and look for key clues that the "cloud-init" configuration completed, like a `ps -e | grep java` to view running Java procsses; you can also use the SSH key we set up to do the same thing from your local shell, of course.

![digitalocean droplet panel](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/hcrm42obgr3gexhit6c2.png)

And of course, if everything looks great, you can log into your new persistent Minecraft server using the domain name!

![save your server!](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/aqjnp3y1lmrp23e1s3ou.png)

## Before You Commit

You should make sure your `.gitignore` file is fully populated before you commit and push your contents. This includes the `.terraform/` folder, intermediate lock and state files, and (of course) your `.tfvars` file where your sensitive secrets are stored.

## Conclusion

![we're in!](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/v2ukzfe6db6ih8qbck54.png)

Spinning up a Minecraft server is a great exercise for learning key cloud technologies. Hopefully you've seen how effective combinations of these technologies (like DigitalOcean, Terraform, and cloud-init) can be used to simplify, automate, and proceduralize how your infrastructure is deployed and orchestrated.
