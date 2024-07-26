locals {
  image_name = "test-cron-runner"
  stack_name = "test-playground-ecs-tasks-cron"
  schedule_expression = "cron(0 * * * ? *)"
}

# lookups

data "aws_subnets" "public" {
  tags = {
    Tier = "Public"
  }
}

# ecr

resource "aws_ecr_repository" "foo" {
  name                 = local.image_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# task definitions

resource "aws_cloudwatch_log_group" "logs" {
  name = "/ecs/${local.stack_name}/${local.image_name}"
}

resource "aws_ecs_cluster" "playground_ecs_cluster" {
  name = "${local.stack_name}-ecs-cluster"
}

resource "aws_ecs_task_definition" "ecs_task_definition" {
  family                   = "${local.stack_name}-family"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  cpu                      = 1024
  memory                   = 2048
  requires_compatibilities = ["FARGATE"]
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
  container_definitions = jsonencode([
    {
      name      = "hello-world"
      image     = "public.ecr.aws/docker/library/hello-world"
      cpu       = 256
      memory    = 512
      essential = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-create-group  = "true"
          awslogs-group         = "/ecs/${local.stack_name}/${local.image_name}"
          awslogs-region        = "eu-west-1"
          awslogs-stream-prefix = "ecs"
        }
      },
    }
  ])
}

# cron

resource "aws_cloudwatch_event_rule" "scheduled_task" {
  name = "${local.stack_name}-cron"
  description = "Runs fargate task ${local.stack_name}: ${local.schedule_expression}"
  schedule_expression = local.schedule_expression
}

resource "aws_cloudwatch_event_target" "scheduled_task" {
  rule = aws_cloudwatch_event_rule.scheduled_task.name
  arn = aws_ecs_cluster.playground_ecs_cluster.arn
  role_arn = aws_iam_role.ecs_task_execution_role.arn
  input = "{}"

  ecs_target {
    task_count = 1
    task_definition_arn = aws_ecs_task_definition.ecs_task_definition.arn
    launch_type = "FARGATE"
    platform_version = "LATEST"

    network_configuration {
      assign_public_ip = true
      subnets = data.aws_subnets.public.ids
    }
  }

  
}