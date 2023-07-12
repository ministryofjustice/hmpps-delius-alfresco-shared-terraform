{
    "widgets": [
        {
            "height": 6,
            "width": 12,
            "y": 0,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "ECS/ContainerInsights", "CpuUtilized", "ServiceName", "alfresco-content", "ClusterName", "tf-alf-${var.environment_name}-alf-app-services", { "label": "alfresco-content" } ]
                ],
                "view": "timeSeries",
                "stacked": true,
                "region": "eu-west-2",
                "title": "Content CPU",
                "stat": "Average",
                "period": 300
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 0,
            "x": 12,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "ECS/ContainerInsights", "MemoryUtilized", "ServiceName", "alfresco-content", "ClusterName", "tf-alf-${var.environment_name}-alf-app-services", { "label": "alfresco-content" } ]
                ],
                "view": "timeSeries",
                "stacked": true,
                "region": "eu-west-2",
                "title": "Content Memory",
                "stat": "Average",
                "period": 300
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 6,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "ECS/ContainerInsights", "CpuUtilized", "ServiceName", "alfresco-search-solr", "ClusterName", "tf-alf-${var.environment_name}-alf-app-services", { "label": "alfresco-search-solr" } ]
                ],
                "view": "timeSeries",
                "stacked": true,
                "region": "eu-west-2",
                "title": "Search-solr CPU",
                "stat": "Average",
                "period": 300
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 6,
            "x": 12,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "ECS/ContainerInsights", "MemoryUtilized", "ServiceName", "alfresco-search-solr", "ClusterName", "tf-alf-${var.environment_name}-alf-app-services", { "label": "alfresco-search-solr" } ]
                ],
                "view": "timeSeries",
                "stacked": true,
                "region": "eu-west-2",
                "title": "Search-solr Memory",
                "stat": "Average",
                "period": 300
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 12,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "ECS/ContainerInsights", "CpuUtilized", "ServiceName", "alfresco-read", "ClusterName", "tf-alf-${var.environment_name}-alf-app-services", { "label": "alfresco-read" } ]
                ],
                "view": "timeSeries",
                "stacked": true,
                "region": "eu-west-2",
                "title": "Read CPU",
                "stat": "Average",
                "period": 300
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 12,
            "x": 12,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "ECS/ContainerInsights", "MemoryUtilized", "ServiceName", "alfresco-read", "ClusterName", "tf-alf-${var.environment_name}-alf-app-services", { "label": "alfresco-read" } ]
                ],
                "view": "timeSeries",
                "stacked": true,
                "region": "eu-west-2",
                "title": "Read Memory",
                "stat": "Average",
                "period": 300
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 18,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "ECS/ContainerInsights", "CpuUtilized", "ServiceName", "alfresco-transform", "ClusterName", "tf-alf-${var.environment_name}-alf-app-services", { "label": "alfresco-transform" } ]
                ],
                "view": "timeSeries",
                "stacked": true,
                "region": "eu-west-2",
                "title": "Transform CPU",
                "stat": "Average",
                "period": 300
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 18,
            "x": 12,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "ECS/ContainerInsights", "MemoryUtilized", "ServiceName", "alfresco-transform", "ClusterName", "tf-alf-${var.environment_name}-alf-app-services", { "label": "alfresco-transform" } ]
                ],
                "view": "timeSeries",
                "stacked": true,
                "region": "eu-west-2",
                "title": "Transform Memory",
                "stat": "Average",
                "period": 300
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 24,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "ECS/ContainerInsights", "CpuUtilized", "ServiceName", "alfresco-share-ecs", "ClusterName", "tf-alf-${var.environment_name}-alf-app-services", { "label": "alfresco-share-ecs" } ]
                ],
                "view": "timeSeries",
                "stacked": true,
                "region": "eu-west-2",
                "title": "Share-ecs CPU",
                "stat": "Average",
                "period": 300
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 24,
            "x": 12,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "ECS/ContainerInsights", "MemoryUtilized", "ServiceName", "alfresco-share-ecs", "ClusterName", "tf-alf-${var.environment_name}-alf-app-services", { "label": "alfresco-share-ecs" } ]
                ],
                "view": "timeSeries",
                "stacked": true,
                "region": "eu-west-2",
                "title": "Share-ecs Memory",
                "stat": "Average",
                "period": 300
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 30,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "ECS/ContainerInsights", "CpuUtilized", "ServiceName", "alfresco-proxy", "ClusterName", "tf-alf-${var.environment_name}-alf-app-services", { "label": "alfresco-proxy" } ]
                ],
                "view": "timeSeries",
                "stacked": true,
                "region": "eu-west-2",
                "title": "Proxy CPU",
                "stat": "Average",
                "period": 300
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 30,
            "x": 12,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "ECS/ContainerInsights", "MemoryUtilized", "ServiceName", "alfresco-proxy", "ClusterName", "tf-alf-${var.environment_name}-alf-app-services", { "label": "alfresco-proxy" } ]
                ],
                "view": "timeSeries",
                "stacked": true,
                "region": "eu-west-2",
                "title": "Proxy Memory",
                "stat": "Average",
                "period": 300
            }
        }
    ]
}