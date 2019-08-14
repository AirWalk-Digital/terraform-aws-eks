resource "aws_iam_role" "node-role" {
  name = "terraform-eks-node-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = "${aws_iam_role.node-role.name}"
}

resource "aws_iam_role_policy_attachment" "node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = "${aws_iam_role.node-role.name}"
}

resource "aws_iam_role_policy_attachment" "node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = "${aws_iam_role.node-role.name}"
}

resource "aws_iam_instance_profile" "node-instancer-profile" {
  name = "terraform-eks-ip"
  role = "${aws_iam_role.node-role.name}"
}

resource "aws_security_group" "node-sg" {
  name        = "terraform-eks-node"
  vpc_id      = "${aws_vpc.cluster-vpc.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${
    map(
     "Name", "terraform-eks-node",
     "kubernetes.io/cluster/${var.cluster-name}", "owned"
    )
  }"
}

resource "aws_security_group_rule" "node-ingress-self" {
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.node-sg.id}"
  source_security_group_id = "${aws_security_group.node-sg.id}"
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "node-ingress-cluster" {
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.node-sg.id}"
  source_security_group_id = "${aws_security_group.cluster-sg.id}"
  to_port                  = 65535
  type                     = "ingress"
}

locals {
  node-userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh '${var.cluster-name}' --network-plugin=cni
USERDATA

}

resource "aws_launch_configuration" "cluster-lc" {
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.node-instancer-profile.name}"
  image_id                    = "ami-03a55127c613349a7"
  instance_type               = "m5.large"
  name_prefix                 = "terraform-eks-lc"
  security_groups             = ["${aws_security_group.node-sg.id}"]
  user_data_base64            = "${base64encode(local.node-userdata)}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "cluster-asg" {
  desired_capacity     = 2
  launch_configuration = "${aws_launch_configuration.cluster-lc.id}"
  max_size             = 2
  min_size             = 1
  name                 = "terraform-eks-asg"
  vpc_zone_identifier  = ["${aws_subnet.cluster-subnet.*.id}"]

  tag {
    key                 = "Name"
    value               = "terraform-eks-asg"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster-name}"
    value               = "owned"
    propagate_at_launch = true
  }
}
