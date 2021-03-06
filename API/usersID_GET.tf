module "getUser" {
  source      = "../modules/restapi_service_method"
  http_method = "GET"
  name        = "getUser"
  service = {
    uri         = "arn:aws:apigateway:${var.region}:cognito-idp:action/AdminGetUser"
    policy_arn  = aws_iam_policy.getUser_AdminGetUser.arn
    http_method = "POST"
  }

  apigateway = {
    arn = aws_api_gateway_rest_api.OxyApi.execution_arn
    id  = aws_api_gateway_rest_api.OxyApi.id
  }

  authorizer = {
    type = "COGNITO_USER_POOLS"
    id   = aws_api_gateway_authorizer.user_pool.id
  }

  resource = aws_api_gateway_resource.UserID

  request = {
    parameters = {
      "method.request.header.Content-Type" = true
    }
    integration_parameters = {
      "integration.request.header.Content-Type" = "method.request.header.Content-Type"
    }
    timeout_ms = 29000
    templates = {
      "application/json" = <<EOF
        #set($id = $method.request.path.id)
        {
            "UserPoolId": "${var.user_pool_id}",
            "Username": "$id"
        }
        EOF
    }
  }
  responses = {
    ok = {
      integration_parameters = {
        "method.response.header.Content-Type" = "integration.response.header.Content-Type"
      }
      integration_templates = {
        "application/json" = local.getuser_response_template
      }
      integration_selection_pattern = "2\\d{2}"
      integration_status_code       = 200
      integration_content_handling  = "CONVERT_TO_TEXT"

      models = {
        "application/json" = "Empty"
      }
      parameters = {
        "method.response.header.Content-Type" = true
      }
      status_code = 200
    }
    ko_user = {
      integration_parameters = {
        "method.response.header.Content-Type" = "integration.response.header.Content-Type"
      }
      integration_templates = null
      integration_selection_pattern = "4\\d{2}"
      integration_status_code       = 400
      integration_content_handling  = null

      models = {
        "application/json" = "Error"
      }
      parameters = {
        "method.response.header.Content-Type" = true
      }
      status_code = 400
    }

    ko_server = {
        integration_parameters = {
          "method.response.header.Content-Type" = "integration.response.header.Content-Type"
        }
        integration_templates = null
        integration_selection_pattern = "5\\d{2}"
        integration_status_code       = 500
        integration_content_handling  = null

        models = {
          "application/json" = "Error"
        }
        parameters = {
          "method.response.header.Content-Type" = true
        }
        status_code = 500
      }
  }
}

locals {
  getuser_response_template = <<EOF
#set($u = $util.parseJson($util.base64Decode($input.body)))
##set($u = $util.parseJson($input.body))
#set($attrMap = {"sub":"id","email":"email"})
##select and rename attribute for confirmed and enabled users
#set($user = {})
#if($u.Enabled && $u.UserStatus.equals("CONFIRMED"))
    #foreach($attr in $u.UserAttributes)
        #if($attrMap.containsKey($attr.Name))
            #set($user[$attrMap[$attr.Name]] = $attr.Value)
        #end
    #end
#end

{#foreach($attr in $user.entrySet())
  "$attr.getKey()": "$attr.getValue()"#if($foreach.hasNext), #end
#end}

    EOF
}

resource "aws_iam_policy" "getUser_AdminGetUser" {
  name        = "cognito-getUser_AdminGetUser"
  description = "Allows AdminGetUser action on ${var.user_pool_id} user_pool"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "cognito-idp:AdminGetUser"
      ],
      "Effect": "Allow",
      "Resource": "${var.user_pool_arn}"
    }
  ]
}
EOF
}