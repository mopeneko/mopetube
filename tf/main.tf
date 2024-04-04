provider "github" {
  token = var.github_token
}

provider "aws" {
  region = "ap-northeast-1"
}

data "github_rest_api" "package_versions" {
  endpoint = "users/${var.github_owner}/packages/container/${var.package_name}/versions"
}

data "aws_region" "current" {}

data "aws_caller_identity" "self" {}

locals {
  container_image = jsondecode(data.github_rest_api.package_versions.body)[0].metadata.container.tags[0]
  region          = data.aws_region.current.name
  account_id      = data.aws_caller_identity.self.account_id
}

resource "aws_vpc" "mopetube_vpc" {
  cidr_block                       = "10.0.0.0/16"
  assign_generated_ipv6_cidr_block = true
}

resource "aws_kms_key" "mopetube_key" {
  description             = "Key for mopetube"
  enable_key_rotation     = true
  deletion_window_in_days = 10

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "kms:*"
        Resource = "*"
        Principal = {
          Service = ["logs.${local.region}.amazonaws.com"]
          AWS     = ["arn:aws:iam::${local.account_id}:root"]
        }
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "mopetube_log_group" {
  name       = "mopetube-log-group-flow-log"
  kms_key_id = aws_kms_key.mopetube_key.arn
}

resource "aws_cloudwatch_log_group" "mopetube_log_group_app" {
  name       = "mopetube-log-group-app"
  kms_key_id = aws_kms_key.mopetube_key.arn
}

resource "aws_flow_log" "mopetube_flow_log" {
  vpc_id               = aws_vpc.mopetube_vpc.id
  log_destination      = aws_cloudwatch_log_group.mopetube_log_group.arn
  log_destination_type = "cloud-watch-logs"
  iam_role_arn         = var.vpc_flow_log_role_arn
  traffic_type         = "ALL"
}

resource "aws_subnet" "mopetube_subnet" {
  vpc_id            = aws_vpc.mopetube_vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "ap-northeast-1a"
  ipv6_cidr_block   = cidrsubnet(aws_vpc.mopetube_vpc.ipv6_cidr_block, 4, 1)
}

resource "aws_subnet" "mopetube_subnet_b" {
  vpc_id            = aws_vpc.mopetube_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-1c"
  ipv6_cidr_block   = cidrsubnet(aws_vpc.mopetube_vpc.ipv6_cidr_block, 4, 2)
}

resource "aws_subnet" "mopetube_subnet_d" {
  vpc_id            = aws_vpc.mopetube_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-northeast-1d"
  ipv6_cidr_block   = cidrsubnet(aws_vpc.mopetube_vpc.ipv6_cidr_block, 4, 3)
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

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.mopetube_igw.id
  }
}

resource "aws_route_table_association" "mopetube_route_table_association" {
  route_table_id = aws_route_table.mopetube_route_table.id
  subnet_id      = aws_subnet.mopetube_subnet.id
}

resource "aws_route_table_association" "mopetube_route_table_association_b" {
  route_table_id = aws_route_table.mopetube_route_table.id
  subnet_id      = aws_subnet.mopetube_subnet_b.id
}

resource "aws_route_table_association" "mopetube_route_table_association_d" {
  route_table_id = aws_route_table.mopetube_route_table.id
  subnet_id      = aws_subnet.mopetube_subnet_d.id
}

resource "aws_security_group" "mopetube_security_group" {
  name        = "mopetube-security-group"
  description = "Security group for mopetube"
  vpc_id      = aws_vpc.mopetube_vpc.id
  egress {
    description      = "Allow HTTPS traffic"
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"] #tfsec:ignore:aws-ec2-no-public-egress-sgr
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "mopetube_ecs_security_group" {
  name        = "mopetube-ecs-security-group"
  description = "Security group for mopetube ECS"
  vpc_id      = aws_vpc.mopetube_vpc.id
  egress {
    description      = "Allow HTTP traffic"
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"] #tfsec:ignore:aws-ec2-no-public-egress-sgr
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group_rule" "mopetube_security_group_rule" {
  description       = "Allow HTTP traffic"
  security_group_id = aws_security_group.mopetube_security_group.id
  cidr_blocks       = ["0.0.0.0/0"] #tfsec:ignore:aws-ec2-no-public-ingress-sgr
  ipv6_cidr_blocks  = ["::/0"]
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  type              = "ingress"
}

resource "aws_security_group_rule" "mopetube_ecs_security_group_rule" {
  description       = "Allow HTTP traffic"
  security_group_id = aws_security_group.mopetube_ecs_security_group.id
  cidr_blocks       = ["10.0.0.0/16"]
  ipv6_cidr_blocks  = [aws_vpc.mopetube_vpc.ipv6_cidr_block]
  from_port         = 3000
  to_port           = 3000
  protocol          = "tcp"
  type              = "ingress"
}

resource "aws_lb" "mopetube_lb" {
  name                       = "mopetube-lb"
  security_groups            = [aws_security_group.mopetube_security_group.id]
  subnets                    = [aws_subnet.mopetube_subnet.id, aws_subnet.mopetube_subnet_b.id, aws_subnet.mopetube_subnet_d.id]
  drop_invalid_header_fields = true
  internal                   = false #tfsec:ignore:aws-elb-alb-not-public
  ip_address_type            = "dualstack"
}

resource "aws_ecs_task_definition" "mopetube_task_definition" {
  family = "mopetube-task-definition"

  requires_compatibilities = ["FARGATE"]

  cpu    = "256"
  memory = "512"

  network_mode = "awsvpc"

  execution_role_arn = var.ecs_task_execution_role_arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  container_definitions = jsonencode([
    {
      name  = "mopetube"
      image = "ghcr.io/${var.github_owner}/${var.package_name}:${local.container_image}"
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
      repositoryCredentials = {
        credentialsParameter = aws_secretsmanager_secret.mopetube_github_token.arn
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.mopetube_log_group_app.name
          awslogs-region        = local.region
          awslogs-stream-prefix = "mopetube-app"
        }
      }
    }
  ])
}

resource "aws_ecs_cluster" "mopetube_cluster" {
  name = "mopetube-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_lb_target_group" "mopetube_target_group" {
  name = "mopetube-target-group"

  vpc_id = aws_vpc.mopetube_vpc.id

  port        = 3000
  protocol    = "HTTP"
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
  } }

  zone_id = aws_route53_zone.mopetube_zone.id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

resource "aws_route53_record" "mopetube_a_record" {
  name    = var.domain_name
  type    = "A"
  zone_id = aws_route53_zone.mopetube_zone.id
  alias {
    name                   = aws_lb.mopetube_lb.dns_name
    zone_id                = aws_lb.mopetube_lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "mopetube_aaaa_record" {
  name    = var.domain_name
  type    = "AAAA"
  zone_id = aws_route53_zone.mopetube_zone.id
  alias {
    name                   = aws_lb.mopetube_lb.dns_name
    zone_id                = aws_lb.mopetube_lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_acm_certificate" "mopetube_certificate" {
  domain_name       = "mopetube.com"
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "mopetube_listener" {
  load_balancer_arn = aws_lb.mopetube_lb.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.mopetube_certificate.arn

  default_action {
    type = "fixed-response"
    fixed_response {
      status_code  = "200"
      content_type = "text/plain"
      message_body = "Hello, World!"
    }
  }
}

resource "aws_lb_listener_rule" "mopetube_listener_rule" {
  listener_arn = aws_lb_listener.mopetube_listener.arn
  priority     = 100
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.mopetube_target_group.arn
  }
  condition {
    host_header {
      values = [var.domain_name]
    }
  }
}

resource "aws_secretsmanager_secret" "mopetube_github_token" {
  name                    = "mopetube-github-token"
  description             = "GitHub token for mopetube"
  recovery_window_in_days = 10
  kms_key_id              = aws_kms_key.mopetube_key.arn
}

resource "aws_secretsmanager_secret_version" "mopetube_github_token_version" {
  secret_id = aws_secretsmanager_secret.mopetube_github_token.id
  secret_string = jsonencode({
    username = var.github_owner
    password = var.github_token
  })
}

resource "aws_ecs_service" "mopetube_service" {
  name            = "mopetube-service"
  depends_on      = [aws_lb_listener.mopetube_listener]
  cluster         = aws_ecs_cluster.mopetube_cluster.id
  task_definition = aws_ecs_task_definition.mopetube_task_definition.id
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = [aws_subnet.mopetube_subnet.id, aws_subnet.mopetube_subnet_b.id, aws_subnet.mopetube_subnet_d.id]
    security_groups  = [aws_security_group.mopetube_ecs_security_group.id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.mopetube_target_group.arn
    container_name   = "mopetube"
    container_port   = "3000"
  }
}

resource "aws_appautoscaling_target" "ecs_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.mopetube_cluster.name}/${aws_ecs_service.mopetube_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = 1
  max_capacity       = 10
}

resource "aws_appautoscaling_policy" "ecs_policy" {
  name               = "mopetube-service-autoscaling"
  service_namespace  = "ecs"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = "ecs:service:DesiredCount"
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    target_value       = 75.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}
