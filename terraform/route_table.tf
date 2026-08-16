###############################################
# Public Route Table
###############################################

resource "aws_route_table" "route_table_public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-route_table_public-rt"
  }
}

###############################################
# Public Route
# Route all Internet traffic to the IGW
###############################################

resource "aws_route" "public_internet_access" {
  route_table_id = aws_route_table.route_table_public.id

  destination_cidr_block = "0.0.0.0/0"

  gateway_id = aws_internet_gateway.main.id
}

###############################################
# Associate Public Route Table
###############################################

resource "aws_route_table_association" "public_1" {

  subnet_id = aws_subnet.public_1.id

  route_table_id = aws_route_table.route_table_public.id
}

resource "aws_route_table_association" "public_2" {

  subnet_id = aws_subnet.public_2.id

  route_table_id = aws_route_table.route_table_public.id
}

###############################################
# Private Route Table
###############################################

resource "aws_route_table" "route_table_private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-route_table_private-rt"
  }
}

###############################################
# Private Route
# Route outbound traffic through NAT Gateway
###############################################

resource "aws_route" "private_internet_access" {

  route_table_id = aws_route_table.route_table_private.id

  destination_cidr_block = "0.0.0.0/0"

  nat_gateway_id = aws_nat_gateway.main.id
}

###############################################
# Associate Private Route Table
###############################################

resource "aws_route_table_association" "private_1" {

  subnet_id = aws_subnet.private_1.id

  route_table_id = aws_route_table.route_table_private.id

}

resource "aws_route_table_association" "private_2" {

  subnet_id = aws_subnet.private_2.id

  route_table_id = aws_route_table.route_table_private.id

}