{
  "widgets": [
    {
      "height": 6,
      "width": 12,
      "y": 1,
      "x": 0,
      "type": "metric",
      "properties": {
        "metrics": [
          [
            "ECS/ContainerInsights",
            "CpuUtilized",
            "ServiceName",
            "alfresco-content",
            "ClusterName",
            "tf-alf-${environment}-alf-app-services",
            {
              "label": "alfresco-content"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": true,
        "region": "eu-west-2",
        "title": "CPU Utilization",
        "stat": "Average",
        "period": 300
      }
    }
  ]
}