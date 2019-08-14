resource "aws_vpc" "cluster-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = "${
    map(
     "Name", "terraform-eks-node-vpc",
     "kubernetes.io/cluster/${var.cluster-name}", "shared"
    )
  }"
}

resource "aws_subnet" "cluster-subnet" {
  count = 2

  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  cidr_block        = "10.0.${count.index}.0/24"
  vpc_id            = "${aws_vpc.cluster-vpc.id}"

  tags = "${
    map(
     "Name", "terraform-eks-node-subnet",
     "kubernetes.io/cluster/${var.cluster-name}", "shared"
    )
  }"
}

resource "aws_internet_gateway" "cluster-igw" {
  vpc_id = "${aws_vpc.cluster-vpc.id}"

  tags {
    Name = "terraform-eks-cluster-igw"
  }
}

resource "aws_route_table" "cluster-rt" {
  vpc_id = "${aws_vpc.cluster-vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.cluster-igw.id}"
  }
}

resource "aws_route_table_association" "cluster-rta" {
  count = 2

  subnet_id      = "${aws_subnet.cluster-subnet.*.id[count.index]}"
  route_table_id = "${aws_route_table.cluster-rt.id}"
}
