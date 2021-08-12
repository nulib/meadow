data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_ami" "amazon_linux" {
  most_recent   = true
  owners        = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_iam_role" "meadow_ec2_role" {
  name               = "${var.stack_name}-ec2"
  description        = "Allows EC2 instances to call AWS services on your behalf."
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "meadow_ec2_role_policy" {
  role       = aws_iam_role.meadow_ec2_role.id
  policy_arn = aws_iam_policy.meadow_role_policy.arn
}

resource "aws_iam_role_policy_attachment" "bucket_ec2_role_access" {
  role       = aws_iam_role.meadow_ec2_role.name
  policy_arn = aws_iam_policy.this_bucket_policy.arn
}

resource "aws_iam_role_policy_attachment" "meadow_ec2_sqs_access" {
  role       = aws_iam_role.meadow_ec2_role.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}

resource "aws_iam_role_policy_attachment" "bucket_ec2_cloudwatch_agent_access" {
  role       = aws_iam_role.meadow_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "meadow_ec2_target_group_access" {
  role       = aws_iam_role.meadow_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/ElasticLoadBalancingReadOnly"
}

resource "aws_iam_role_policy_attachment" "meadow_ec2_transcode_passrole" {
  role       = aws_iam_role.meadow_ec2_role.name
  policy_arn = aws_iam_policy.allow_transcode.arn
}

resource "aws_iam_instance_profile" "meadow_instance_profile" {
  name = "${var.stack_name}-ec2"
  role = aws_iam_role.meadow_ec2_role.name
}

resource "aws_security_group" "meadow_ec2" {
  name          = "${var.stack_name}-ec2"
  description   = "Meadow EC2 Security Group"
  vpc_id        = var.vpc_id

  ingress {
    description   = "SSH in"
    from_port     = 22
    to_port       = 22
    protocol      = "tcp"
    cidr_blocks   = ["0.0.0.0/0"]
  }
}

data "template_file" "ec2_user_data" {
  template = file("ec2_files/startup.sh")
  vars = {
    dev_local_exs         = file("ec2_files/dev.local.exs"),
    ec2_instance_users    = join(" ", var.ec2_instance_users),
    meadow_rc             = data.template_file.ec2_meadow_config.rendered
    target_group_arn      = aws_lb_target_group.meadow_target.arn
  }
}

data "template_file" "ec2_meadow_config" {
  template = file("ec2_files/meadowrc")
  vars = merge(
    local.container_config,
    {
      meadow_ec2_hostname       = "${var.stack_name}-console.${data.aws_route53_zone.app_zone.name}",
      meadow_hostname           = aws_route53_record.app_hostname.fqdn
    }
  )
}

resource "aws_instance" "this_ec2_instance" {
  ami                           = data.aws_ami.amazon_linux.id
  instance_type                 = "t3.small"
  iam_instance_profile          = aws_iam_instance_profile.meadow_instance_profile.id
  subnet_id                     = element(tolist(data.aws_subnet_ids.public_subnets.ids), 0)
  vpc_security_group_ids        = [aws_security_group.meadow.id, aws_security_group.meadow_ec2.id]
  associate_public_ip_address   = true
  user_data                     = data.template_file.ec2_user_data.rendered

  lifecycle {
    create_before_destroy = true
    ignore_changes = [ ami, user_data, instance_type, tags ]
  }

  tags = merge(
    var.tags,
    { Name = "${var.stack_name}-console" }
  )
}

resource "aws_route53_record" "ec2_hostname" {
  zone_id = data.aws_route53_zone.app_zone.zone_id
  name    = "${var.stack_name}-console"
  type    = "A"
  records = [aws_instance.this_ec2_instance.public_ip]
  ttl     = 60
}
