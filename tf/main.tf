provider "github" {
    token = var.github_token
}

provider aws {
    region = "ap-northeast-1"
}

data "github_rest_api" "package_versions" {
  endpoint = "users/mopeneko/packages/container/${var.package_name}/versions"
}

data "aws_region" "current" {}

data "aws_caller_identity" "self" {}

locals {
    container_image = jsondecode(data.github_rest_api.package_versions.body)[0].metadata.container.tags[0]
    region = data.aws_region.current.name
    account_id = data.aws_caller_identity.self.account_id
}

resource "aws_vpc" "mopetube_vpc" {
    cidr_block = "10.0.0.0/16"
}

resource "aws_kms_key" "mopetube_key" {
    description = "Key for mopetube"
    enable_key_rotation = true
    deletion_window_in_days = 10

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = "kms:*"
                Resource = "*"
                Principal = {
                    Service = ["logs.${local.region}.amazonaws.com"]
                    AWS = ["arn:aws:iam::${local.account_id}:root"]
                }
            }
        ]
    })
}

resource "aws_cloudwatch_log_group" "mopetube_log_group" {
    name = "mopetube-log-group"
    kms_key_id = aws_kms_key.mopetube_key.arn
}

resource "aws_flow_log" "mopetube_flow_log" {
    vpc_id = aws_vpc.mopetube_vpc.id
    log_destination = aws_cloudwatch_log_group.mopetube_log_group.arn
    log_destination_type = "cloud-watch-logs"
    iam_role_arn = var.vpc_flow_log_role_arn
    traffic_type = "ALL"
}

resource "aws_subnet" "mopetube_subnet" {
    vpc_id = aws_vpc.mopetube_vpc.id
    cidr_block = "10.0.0.0/24"
    availability_zone = "ap-northeast-1a"
}

resource "aws_subnet" "mopetube_subnet_b" {
    vpc_id = aws_vpc.mopetube_vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "ap-northeast-1c"
}

resource "aws_internet_gateway" "mopetube_igw" {
  vpc_id = aws_vpc.mopetube_vpc.id
}

resource "aws_route_table" "mopetube_route_table" {
    vpc_id = aws_vpc.mopetube_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.mopetube_igw.id
    }
}

resource "aws_route_table_association" "mopetube_route_table_association" {
    route_table_id = aws_route_table.mopetube_route_table.id
    subnet_id = aws_subnet.mopetube_subnet.id
}

resource "aws_route_table_association" "mopetube_route_table_association_b" {
    route_table_id = aws_route_table.mopetube_route_table.id
    subnet_id = aws_subnet.mopetube_subnet_b.id
}

resource "aws_security_group" "mopetube_security_group" {
    name = "mopetube-security-group"
    description = "Security group for mopetube"
    vpc_id = aws_vpc.mopetube_vpc.id
    egress {
        description = "Allow HTTPS traffic"
        from_port = 0
        to_port = 65535
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:aws-ec2-no-public-egress-sgr
    }
}

resource "aws_security_group" "mopetube_ecs_security_group" {
    name = "mopetube-ecs-security-group"
    description = "Security group for mopetube ECS"
    vpc_id = aws_vpc.mopetube_vpc.id
    egress {
        description = "Allow HTTP traffic"
        from_port = 0
        to_port = 65535
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:aws-ec2-no-public-egress-sgr
    }
}

resource "aws_security_group_rule" "mopetube_security_group_rule" {
    description = "Allow HTTP traffic"
    security_group_id = aws_security_group.mopetube_security_group.id
    cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:aws-ec2-no-public-ingress-sgr
    from_port = 443
    to_port = 443
    protocol = "tcp"
    type = "ingress"
}

resource "aws_security_group_rule" "mopetube_ecs_security_group_rule" {
    description = "Allow HTTP traffic"
    security_group_id = aws_security_group.mopetube_ecs_security_group.id
    cidr_blocks = ["10.0.0.0/16"]
    from_port = 3000
    to_port = 3000
    protocol = "tcp"
    type = "ingress"
}

resource "aws_lb" "mopetube_lb" {
    name = "mopetube-lb"
    security_groups = [aws_security_group.mopetube_security_group.id]
    subnets = [aws_subnet.mopetube_subnet.id, aws_subnet.mopetube_subnet_b.id]
    drop_invalid_header_fields = true
    internal = false #tfsec:ignore:aws-elb-alb-not-public
}

resource "aws_ecs_task_definition" "mopetube_task_definition" {
    family = "mopetube-task-definition"

    requires_compatibilities = ["FARGATE"]

    cpu = "256"
    memory = "512"

    network_mode = "awsvpc"

    execution_role_arn = var.ecs_task_execution_role_arn

    container_definitions = jsonencode([
        {
            name = "mopetube"
            image = "ghcr.io/${var.github_owner}/${var.package_name}:${local.container_image}"
            portMappings = [
                {
                    containerPort = 3000
                    hostPort = 3000
                }
            ]
            repositoryCredentials = {
                credentialsParameter = aws_secretsmanager_secret.mopetube_github_token.arn
            }
        }
    ])
}

resource "aws_ecs_cluster" "mopetube_cluster" {
    name = "mopetube-cluster"

    setting {
        name = "containerInsights"
        value = "enabled"
    }
}

resource "aws_lb_target_group" "mopetube_target_group" {
    name = "mopetube-target-group"
    
    vpc_id = aws_vpc.mopetube_vpc.id

    port = 3000
    protocol = "HTTP"
    target_type = "ip"

    health_check {
        port = 3000
        path = "/api/health"
    }
}

resource "aws_route53_zone" "mopetube_zone" {
    name = var.domain_name
}

resource "aws_route53_record" "validation" {
    for_each = { for dvo in aws_acm_certificate.mopetube_certificate.domain_validation_options : dvo.domain_name => {
        name   = dvo.resource_record_name
        type   = dvo.resource_record_type
        record = dvo.resource_record_value
    }}

    zone_id = aws_route53_zone.mopetube_zone.id
    name    = each.value.name
    type    = each.value.type
    records = [each.value.record]
    ttl     = 60
}

resource "aws_route53_record" "mopetube_a_record" {
    name = var.domain_name
    type = "A"
    zone_id = aws_route53_zone.mopetube_zone.id
    alias {
        name = aws_lb.mopetube_lb.dns_name
        zone_id = aws_lb.mopetube_lb.zone_id
        evaluate_target_health = true
    }
}

resource "aws_acm_certificate" "mopetube_certificate" {
    domain_name = "mopetube.com"
    validation_method = "DNS"
}

resource "aws_lb_listener" "mopetube_listener" {
    load_balancer_arn = aws_lb.mopetube_lb.arn
    port = "443"
    protocol = "HTTPS"
    certificate_arn = aws_acm_certificate.mopetube_certificate.arn

    default_action {
        type = "fixed-response"
        fixed_response {
            status_code = "200"
            content_type = "text/plain"
            message_body = "Hello, World!"
        }
    }
}

resource "aws_lb_listener_rule" "mopetube_listener_rule" {
    listener_arn = aws_lb_listener.mopetube_listener.arn
    priority = 100
    action {
        type = "forward"
        target_group_arn = aws_lb_target_group.mopetube_target_group.arn
    }
    condition {
        host_header {
            values = [var.domain_name]
        }
    }
}

resource "aws_secretsmanager_secret" "mopetube_github_token" {
    name = "mopetube-github-token"
    description = "GitHub token for mopetube"
    recovery_window_in_days = 10
    kms_key_id = aws_kms_key.mopetube_key.arn
}

resource "aws_secretsmanager_secret_version" "mopetube_github_token_version" {
    secret_id = aws_secretsmanager_secret.mopetube_github_token.id
    secret_string = jsonencode({
        username = var.github_owner
        password = var.github_token
    })
}

resource "aws_ecs_service" "mopetube_service" {
    name = "mopetube-service"
    depends_on = [aws_lb_listener.mopetube_listener]
    cluster = aws_ecs_cluster.mopetube_cluster.id
    task_definition = aws_ecs_task_definition.mopetube_task_definition.id
    desired_count = 1
    launch_type = "FARGATE"
    network_configuration {
        subnets = [aws_subnet.mopetube_subnet.id, aws_subnet.mopetube_subnet_b.id]
        security_groups = [aws_security_group.mopetube_ecs_security_group.id]
        assign_public_ip = true
    }
    load_balancer {
        target_group_arn = aws_lb_target_group.mopetube_target_group.arn
        container_name = "mopetube"
        container_port = "3000"
    }
}