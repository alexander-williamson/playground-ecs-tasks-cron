locals {
  image_name = "test-cron-runnner"
  stack_name = "test-playground-ecs-tasks-cron"
}

resource "aws_ecr_repository" "foo" {
  name                 = local.image_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

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
