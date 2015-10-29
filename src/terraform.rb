ENVIRONMENT = "test"
AZS         = [:a, :b, :c]
REGION      = "eu-west-1"
NAT_AMI     = "ami-14913f63" # amzn-ami-vpc-nat-hvm-2014.09.1.x86_64-gp2
INTERNET_GW = "#{ENVIRONMENT}-gw"

CIDR_BLOCKS = {
  public: {
    a: '10.0.0.0/24',
    b: '10.0.1.0/24',
    c: '10.0.2.0/24',
  },
  private: {
    a: '10.0.10.0/24',
    b: '10.0.11.0/24',
    c: '10.0.12.0/24',
  }
}

module SG
  class << self
    def allow_http(source)
      {
        from_port: 80,
        to_port: 80,
        protocol: "tcp"
      }.merge(source)
    end

    def allow_https(source)
      {
        from_port: 443,
        to_port: 443,
        protocol: "tcp"
      }.merge(source)
    end

    def allow_ssh(source)
      {
        from_port: 22,
        to_port: 22,
        protocol: "tcp"
      }.merge(source)
    end
  end
end

variable(:access_key, {})
variable(:secret_key, {})

provider :aws do
  access_key "${var.access_key}"
  secret_key "${var.secret_key}"
  region REGION
end

aws_vpc ENVIRONMENT do
  cidr_block "10.0.0.0/16"
  enable_dns_support true
  enable_dns_hostnames true
end

aws_internet_gateway INTERNET_GW do
  vpc_id id_of("aws_vpc", ENVIRONMENT)
end

aws_vpc_dhcp_options ENVIRONMENT do
  domain_name "#{ENVIRONMENT}.urbanautomaton.com"
  domain_name_servers ["AmazonProvidedDNS"]
end

aws_vpc_dhcp_options_association ENVIRONMENT do
  vpc_id id_of("aws_vpc", ENVIRONMENT)
  dhcp_options_id id_of("aws_vpc_dhcp_options", ENVIRONMENT)
end

AZS.each do |az|
  pub_subnet_name = "#{ENVIRONMENT}-pub-#{az}"
  int_subnet_name = "#{ENVIRONMENT}-int-#{az}"
  nat_name        = "#{ENVIRONMENT}-nat-01#{az}"

  # Public subnets
  aws_subnet pub_subnet_name do
    vpc_id id_of("aws_vpc", ENVIRONMENT)
    availability_zone "#{REGION}#{az}"
    cidr_block CIDR_BLOCKS[:public][az]
  end

  aws_route_table pub_subnet_name do
    vpc_id id_of("aws_vpc", ENVIRONMENT)
    route({
      cidr_block: "0.0.0.0/0",
      gateway_id: id_of("aws_internet_gateway", INTERNET_GW)
    })
  end

  aws_route_table_association pub_subnet_name do
    route_table_id id_of("aws_route_table", pub_subnet_name)
    subnet_id id_of("aws_subnet", pub_subnet_name)
  end

  aws_instance nat_name do
    ami NAT_AMI
    availability_zone "#{REGION}#{az}"
    subnet_id id_of("aws_subnet", pub_subnet_name)
    instance_type "t2.micro"
    associate_public_ip_address true
    source_dest_check false
  end

  # Private subnets
  aws_subnet int_subnet_name do
    vpc_id id_of("aws_vpc", ENVIRONMENT)
    availability_zone "#{REGION}#{az}"
    cidr_block CIDR_BLOCKS[:private][az]
  end

  aws_route_table int_subnet_name do
    vpc_id id_of("aws_vpc", ENVIRONMENT)
    route({
      cidr_block: "0.0.0.0/0",
      instance_id: id_of("aws_instance", nat_name)
    })
  end

  aws_route_table_association int_subnet_name do
    route_table_id id_of("aws_route_table", int_subnet_name)
    subnet_id id_of("aws_subnet", int_subnet_name)
  end
end

#
# Security Groups
#

aws_security_group "#{ENVIRONMENT}-bastion" do
  vpc_id id_of("aws_vpc", ENVIRONMENT)
  description "Bastion hosts in the #{ENVIRONMENT} environment"

  ingress(
    [
      SG.allow_ssh(cidr_blocks: ["0.0.0.0/0"])
    ]
  )
end

aws_security_group "#{ENVIRONMENT}-default" do
  vpc_id id_of("aws_vpc", ENVIRONMENT)
  description "All hosts in the #{ENVIRONMENT} environment"

  ingress(
    [
      SG.allow_ssh(
        security_groups: [id_of("aws_security_group", "#{ENVIRONMENT}-bastion")]
      )
    ]
  )
end

aws_security_group "#{ENVIRONMENT}-nat" do
  vpc_id id_of("aws_vpc", ENVIRONMENT)
  description "NAT instances in #{ENVIRONMENT} environment"

  ingress(
    [
      SG.allow_http(
        security_groups: [id_of("aws_security_group", "#{ENVIRONMENT}-default")]
      ),
      SG.allow_https(
        security_groups: [id_of("aws_security_group", "#{ENVIRONMENT}-default")]
      )
    ]
  )
end
