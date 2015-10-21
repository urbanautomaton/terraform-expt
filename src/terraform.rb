ENVIRONMENT = "test"
AZS         = [:a, :b, :c]
REGION      = "eu-west-1"

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

variable(:access_key, {})
variable(:secret_key, {})

provider :aws do
  access_key "${var.access_key}"
  secret_key "${var.secret_key}"
  region REGION
end

resource :aws_vpc, "test" do
  cidr_block "10.0.0.0/16"
  enable_dns_support true
  enable_dns_hostnames true
end

resource :aws_internet_gateway, "test-gw" do
  vpc_id id_of("aws_vpc", "test")
  tags({
    "Name" => "test-gw"
  })
end

resource :aws_vpc_dhcp_options, "test" do
  domain_name "test.urbanautomaton.com"
  domain_name_servers ["AmazonProvidedDNS"]
end

resource :aws_vpc_dhcp_options_association, "test" do
  vpc_id id_of("aws_vpc", "test")
  dhcp_options_id id_of("aws_vpc_dhcp_options", "test")
end

# Public subnets
AZS.each do |az|
  subnet_name = "test-pub-#{az}"

  resource :aws_subnet, subnet_name do
    vpc_id id_of("aws_vpc", "test")
    availability_zone "#{REGION}#{az}"
    cidr_block CIDR_BLOCKS[:public][az]
  end

  resource :aws_route_table, subnet_name do
    vpc_id id_of("aws_vpc", "test")
    route({
      cidr_block: "0.0.0.0/0",
      gateway_id: id_of("aws_internet_gateway", "test-gw")
    })
  end

  resource :aws_route_table_association, subnet_name do
    route_table_id id_of("aws_route_table", subnet_name)
    subnet_id id_of("aws_subnet", subnet_name)
  end
end

# Private subnets
AZS.each do |az|
  subnet_name = "test-int-#{az}"

  resource :aws_subnet, subnet_name do
    vpc_id id_of("aws_vpc", "test")
    availability_zone "#{REGION}#{az}"
    cidr_block CIDR_BLOCKS[:private][az]
  end

  resource :aws_route_table, subnet_name do
    vpc_id id_of("aws_vpc", "test")
  end

  resource :aws_route_table_association, subnet_name do
    route_table_id id_of("aws_route_table", subnet_name)
    subnet_id id_of("aws_subnet", subnet_name)
  end
end
